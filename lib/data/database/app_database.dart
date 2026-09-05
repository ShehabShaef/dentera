import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';
import '../repositories/preferences_repository.dart';
import 'database_seeder.dart';

/// Singleton manager for the local SQLite database in Dentera.
class AppDatabase {
  AppDatabase._internal();

  /// Visible for testing to inject custom/in-memory SQLite databases.
  AppDatabase.withDatabase(this._database);

  static final AppDatabase instance = AppDatabase._internal();

  static const String dbName = 'dentera.db';
  static const int dbVersion = 1;

  Database? _database;

  /// Returns the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Returns the absolute filesystem path to the active [dentera.db] SQLite file.
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return p.join(documentsDirectory.path, dbName);
  }

  /// Internal database initialization routine.
  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasePath();

      return await openDatabase(
        dbPath,
        version: dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to initialize local database: $e', e);
    }
  }

  /// Ensures foreign key integrity constraints are strictly enforced.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Creates the relational schema for all domain tables and pre-populates default academic data.
  ///
  /// **Why Seeding Occurs During [onCreate]:**
  /// The [onCreate] callback executes exclusively when the local SQLite database file is first created
  /// on disk. Executing [DatabaseSeeder.seedInitialData] immediately following the schema batch commit
  /// ensures that the application is initialized with essential academic departments and requirement
  /// quotas right after onboarding without manual configuration or network connectivity.
  ///
  /// **Relational Integrity & Foreign Keys:**
  /// Foreign key constraints (`PRAGMA foreign_keys = ON`) are established in [_onConfigure] prior
  /// to [onCreate]. Because [DatabaseSeeder] inserts parent clinic records prior to child requirements,
  /// foreign key referential integrity is preserved seamlessly without constraint violations.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Patients table
    batch.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        phoneNumber TEXT,
        medicalHistory TEXT,
        createdAt TEXT NOT NULL
      );
    ''');

    // 2. Clinics table
    batch.execute('''
      CREATE TABLE clinics (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        academicYear TEXT NOT NULL,
        colorHex TEXT NOT NULL
      );
    ''');

    // 3. Requirements table
    batch.execute('''
      CREATE TABLE requirements (
        id TEXT PRIMARY KEY,
        clinicId TEXT NOT NULL,
        title TEXT NOT NULL,
        targetCount INTEGER NOT NULL,
        completedCount INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (clinicId) REFERENCES clinics (id) ON DELETE CASCADE
      );
    ''');

    // 4. Case Records table
    batch.execute('''
      CREATE TABLE case_records (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        requirementId TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        dateStarted TEXT NOT NULL,
        dateCompleted TEXT,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (requirementId) REFERENCES requirements (id) ON DELETE CASCADE
      );
    ''');

    // 5. Appointments table
    batch.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        clinicId TEXT NOT NULL,
        scheduledDate TEXT NOT NULL,
        status TEXT NOT NULL,
        procedureDescription TEXT,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (clinicId) REFERENCES clinics (id) ON DELETE CASCADE
      );
    ''');

    await batch.commit();

    // Pre-populate default academic clinics and baseline requirement quotas.
    await DatabaseSeeder.seedInitialData(db);
  }

  /// Closes the active database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Completely resets all operational SQLite tables while preserving the underlying relational schema.
  ///
  /// **Foreign Key Deletion Ordering:**
  /// Foreign key referential integrity is strictly enforced (`PRAGMA foreign_keys = ON;`).
  /// Attempting to delete records from parent tables (`clinics` or `patients`) before their referencing
  /// child tables are cleared will trigger an SQLite foreign key constraint failure (`FOREIGN KEY constraint failed`).
  /// To ensure atomic and constraint-safe deletion, records must be deleted in strict leaf-to-root order:
  /// 1. `appointments` - references `patients(id)` and `clinics(id)`
  /// 2. `case_records` - references `patients(id)` and `requirements(id)`
  /// 3. `requirements` - references `clinics(id)`
  /// 4. `clinics` - root academic clinic department records
  /// 5. `patients` - root patient profile records
  ///
  /// **Transaction Safety:**
  /// All `DELETE FROM` statements are enclosed within an atomic transaction. If any error occurs,
  /// the transaction rolls back cleanly without leaving partial deletions.
  ///
  /// **Local Preferences Reset:**
  /// Also clears persisted device settings in [PreferencesRepository], ensuring onboarding status,
  /// doctor credentials, and notification preferences are wiped in synchronization with the database.
  ///
  /// **UI Ghost Data Prevention via Riverpod:**
  /// Following this database purge, calling components or services must invalidate all
  /// cached Riverpod providers (`patientListProvider`, `clinicListProvider`, etc.).
  /// Without systematic provider invalidation, in-memory Riverpod caches would continue serving
  /// obsolete "ghost data" until the application process is terminated.
  Future<void> resetAllData({PreferencesRepository? preferencesRepository}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawDelete('DELETE FROM appointments;');
      await txn.rawDelete('DELETE FROM case_records;');
      await txn.rawDelete('DELETE FROM requirements;');
      await txn.rawDelete('DELETE FROM clinics;');
      await txn.rawDelete('DELETE FROM patients;');
    });

    final prefsRepo = preferencesRepository ?? PreferencesRepository();
    await prefsRepo.clearAll();
  }
}
