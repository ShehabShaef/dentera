import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/error/exceptions.dart';

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

  /// Internal database initialization routine.
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = p.join(documentsDirectory.path, dbName);

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

  /// Creates the relational schema for all domain tables.
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
  }

  /// Closes the active database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
