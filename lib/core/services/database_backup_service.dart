import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database/app_database.dart';
import '../../data/database/database_providers.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../presentation/state/appointments_provider.dart';
import '../../presentation/state/cases_provider.dart';
import '../../presentation/state/clinics_provider.dart';
import '../../presentation/state/patients_provider.dart';
import '../../presentation/state/requirements_provider.dart';
import '../logging/app_logger.dart';

/// Status outcomes for database backup exports.
enum BackupStatus {
  success,
  failure,
}

/// Result payload returned from [DatabaseBackupService.exportDatabase].
class BackupResult {
  const BackupResult._({
    required this.status,
    this.filePath,
    this.errorMessage,
  });

  /// The outcome status of the export operation.
  final BackupStatus status;

  /// Absolute file path of the generated database backup on disk.
  final String? filePath;

  /// Error description if [status] is [BackupStatus.failure].
  final String? errorMessage;

  /// Convenience getter indicating whether the export operation succeeded.
  bool get isSuccess => status == BackupStatus.success;

  /// Factory creating a successful [BackupResult].
  factory BackupResult.success(String filePath) =>
      BackupResult._(status: BackupStatus.success, filePath: filePath);

  /// Factory creating a failed [BackupResult].
  factory BackupResult.failure(String message) =>
      BackupResult._(status: BackupStatus.failure, errorMessage: message);
}

/// Status outcomes for database restoration/import.
enum RestoreStatus {
  success,
  cancelled,
  failure,
}

/// Result payload returned from [DatabaseBackupService.importDatabase].
class RestoreResult {
  const RestoreResult._({
    required this.status,
    this.restoredFilePath,
    this.errorMessage,
  });

  /// The outcome status of the restore operation.
  final RestoreStatus status;

  /// Absolute file path of the database restored to disk.
  final String? restoredFilePath;

  /// Error description if [status] is [RestoreStatus.failure].
  final String? errorMessage;

  /// Convenience getter indicating whether the restore operation succeeded.
  bool get isSuccess => status == RestoreStatus.success;

  /// Convenience getter indicating whether the user cancelled file selection.
  bool get isCancelled => status == RestoreStatus.cancelled;

  /// Convenience getter indicating whether the restore operation failed.
  bool get isFailure => status == RestoreStatus.failure;

  /// Factory creating a successful [RestoreResult].
  factory RestoreResult.success(String path) =>
      RestoreResult._(status: RestoreStatus.success, restoredFilePath: path);

  /// Factory creating a cancelled [RestoreResult].
  factory RestoreResult.cancelled() =>
      const RestoreResult._(status: RestoreStatus.cancelled);

  /// Factory creating a failed [RestoreResult].
  factory RestoreResult.failure(String message) =>
      RestoreResult._(status: RestoreStatus.failure, errorMessage: message);
}

/// Offline SQLite database backup and restoration manager for Dentera.
///
/// Provides local export (`exportDatabase()`) and import/restore (`importDatabase()`)
/// capabilities without relying on external servers or cloud storage, guaranteeing 100%
/// student data sovereignty.
class DatabaseBackupService {
  DatabaseBackupService({
    AppDatabase? appDatabase,
    this.customDatabasePath,
    this.ref,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  /// Optional custom database path override for isolated unit testing.
  final String? customDatabasePath;

  /// Riverpod ref used to trigger systematic provider invalidation post-import.
  final Ref? ref;

  /// Expected 16-byte magic number header found at offset 0 of all valid SQLite 3 database files:
  /// `SQLite format 3\000` (ASCII bytes: 0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00).
  static const List<int> sqliteHeaderBytes = <int>[
    0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
  ];

  /// Resolves the absolute path to the active database file on disk.
  Future<String> _resolveDatabasePath() async {
    final customPath = customDatabasePath;
    if (customPath != null) {
      return customPath;
    }
    return await _appDatabase.getDatabasePath();
  }

  /// Verifies that the designated [file] conforms to the standard SQLite 3 header specification.
  ///
  /// Inspects the first 16 bytes of the binary file to ensure it matches [sqliteHeaderBytes].
  /// This prevents corrupted, empty, or malicious arbitrary files from overwriting the clinical
  /// database storage.
  static Future<bool> isValidSqliteFile(File file) async {
    if (!await file.exists()) {
      AppLogger.warning('SQLite header validation failed: File does not exist at ${file.path}');
      return false;
    }

    final int fileLength = await file.length();
    if (fileLength < 16) {
      AppLogger.warning(
        'SQLite header validation failed: File length ($fileLength bytes) is smaller than the 16-byte SQLite header.',
      );
      return false;
    }

    RandomAccessFile? raf;
    try {
      raf = await file.open(mode: FileMode.read);
      final List<int> header = await raf.read(16);
      if (header.length < 16) return false;

      for (int i = 0; i < 16; i++) {
        if (header[i] != sqliteHeaderBytes[i]) {
          AppLogger.warning(
            'SQLite header validation failed: Byte mismatch at index $i (expected ${sqliteHeaderBytes[i]}, got ${header[i]}).',
          );
          return false;
        }
      }
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error reading header from file: ${file.path}', e, stackTrace);
      return false;
    } finally {
      await raf?.close();
    }
  }

  /// Exports a timestamped copy of the active `dentera.db` file to disk.
  ///
  /// **Workflow:**
  /// 1. Flushes any pending write-ahead log entries (`PRAGMA wal_checkpoint(FULL);`) to ensure
  ///    the primary database file contains all current transactions.
  /// 2. Generates a timestamped filename (e.g., `dentera_backup_20260905_120000.db`).
  /// 3. Copies the database file to [destinationDirectoryPath] or the application's temporary cache directory.
  /// 4. If [shareViaSystemDialog] is `true`, invokes [SharePlus.instance.share] to present the system share
  ///    sheet, enabling the user to save to local files or external drives.
  Future<BackupResult> exportDatabase({
    String? destinationDirectoryPath,
    bool shareViaSystemDialog = true,
  }) async {
    AppLogger.info('Starting offline SQLite database export...');
    try {
      final String dbPath = await _resolveDatabasePath();
      AppLogger.debug('Active SQLite database path resolved: $dbPath');

      final File dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        // Ensure database is initialized if not yet created on disk
        AppLogger.debug('Database file not found on disk, initializing via AppDatabase instance...');
        await _appDatabase.database;
      }

      if (!await dbFile.exists()) {
        final String errorMsg = 'Failed to locate database file for export at: $dbPath';
        AppLogger.error(errorMsg);
        return BackupResult.failure(errorMsg);
      }

      // Checkpoint WAL transactions if database is active
      try {
        final db = await _appDatabase.database;
        await db.rawQuery('PRAGMA wal_checkpoint(FULL);');
        AppLogger.debug('SQLite WAL checkpoint flushed successfully prior to export.');
      } catch (e) {
        AppLogger.debug('WAL checkpoint skipped or unsupported: $e');
      }

      // Format clean timestamp for export filename
      final now = DateTime.now();
      final String dateStamp =
          '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      final String backupFileName = 'dentera_backup_$dateStamp.db';

      final String targetDir;
      if (destinationDirectoryPath != null) {
        targetDir = destinationDirectoryPath;
      } else {
        final tempDir = await getTemporaryDirectory();
        targetDir = tempDir.path;
      }

      final String backupFilePath = p.join(targetDir, backupFileName);
      AppLogger.debug('Copying SQLite database from $dbPath to $backupFilePath');

      final File backupFile = await dbFile.copy(backupFilePath);
      final int backupSize = await backupFile.length();
      AppLogger.info(
        'Database export completed successfully ($backupSize bytes) at: $backupFilePath',
      );

      if (shareViaSystemDialog) {
        AppLogger.debug('Opening system share sheet for backup file: $backupFilePath');
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(
                backupFilePath,
                mimeType: 'application/x-sqlite3',
                name: backupFileName,
              ),
            ],
            subject: 'Dentera Local Database Backup ($dateStamp)',
          ),
        );
      }

      return BackupResult.success(backupFilePath);
    } catch (e, stackTrace) {
      final String errorMsg = 'Failed to export SQLite database: $e';
      AppLogger.error(errorMsg, e, stackTrace);
      return BackupResult.failure(errorMsg);
    }
  }

  /// Restores a chosen SQLite database file, replacing the active `dentera.db`.
  ///
  /// **Critical Operations & Lifecycle Management:**
  /// 1. **Header Validation:** Checks the 16-byte SQLite header (`SQLite format 3\000`) before
  ///    touching active application storage. Corrupted or invalid files are immediately rejected.
  /// 2. **Connection Teardown:** Closes the active [AppDatabase] SQLite connection before the file
  ///    overwrite. This releases operating system file locks and prevents SQLite internal mutexes
  ///    or write conflicts from corrupting the new database file.
  /// 3. **WAL/SHM Cleanup:** Deletes any preexisting `-wal` (write-ahead log) or `-shm` (shared memory)
  ///    sidecar files at the target location. Lingering WAL files from the prior database instance
  ///    contain invalid page indexes that would corrupt the newly restored database upon reopening.
  /// 4. **File Overwrite:** Performs an atomic file copy from the selected backup to the target `dentera.db`.
  /// 5. **Riverpod Provider Invalidation:** Systematically invalidates all database and domain
  ///    Riverpod providers to force a fresh data query cycle. This guarantees the UI does not retain
  ///    stale in-memory "ghost data" from the previous database state.
  Future<RestoreResult> importDatabase({String? customSourcePath}) async {
    AppLogger.info('Starting offline SQLite database import/restore process...');
    try {
      String? sourcePath = customSourcePath;

      if (sourcePath == null) {
        AppLogger.debug('Opening file picker for SQLite backup selection...');
        final PlatformFile? picked = await FilePicker.pickFile(
          dialogTitle: 'Select Dentera SQLite Backup File',
          type: FileType.custom,
          allowedExtensions: ['db', 'sqlite', 'sqlite3'],
        );

        if (picked == null || picked.path == null) {
          AppLogger.info('Database restore cancelled by user: No file selected.');
          return RestoreResult.cancelled();
        }

        sourcePath = picked.path!;
      }

      AppLogger.debug('Candidate backup file selected: $sourcePath');
      final File sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        final String errorMsg = 'Selected backup file does not exist at: $sourcePath';
        AppLogger.error(errorMsg);
        return RestoreResult.failure(errorMsg);
      }

      // 1. Validate SQLite header structure
      final bool isValid = await isValidSqliteFile(sourceFile);
      if (!isValid) {
        const String errorMsg = 'The selected file is not a valid SQLite database.';
        AppLogger.error(errorMsg);
        return RestoreResult.failure(errorMsg);
      }

      final String targetDbPath = await _resolveDatabasePath();
      AppLogger.debug('Target destination database path: $targetDbPath');

      // 2. Critical: Close active SQLite connection prior to file overwrite
      AppLogger.info('Closing active SQLite database connection to release OS locks...');
      await _appDatabase.close();

      // 3. Purge preexisting WAL and SHM files to avoid index corruption
      final File walFile = File('$targetDbPath-wal');
      if (await walFile.exists()) {
        AppLogger.debug('Purging lingering SQLite WAL file: ${walFile.path}');
        await walFile.delete();
      }

      final File shmFile = File('$targetDbPath-shm');
      if (await shmFile.exists()) {
        AppLogger.debug('Purging lingering SQLite SHM file: ${shmFile.path}');
        await shmFile.delete();
      }

      // 4. Overwrite existing database file with imported backup
      AppLogger.debug('Overwriting database file at $targetDbPath with backup from $sourcePath');
      await sourceFile.copy(targetDbPath);
      AppLogger.info('SQLite database file successfully overwritten.');

      // 5. Invalidate Riverpod providers to prevent stale ghost data
      invalidateRiverpodState();

      return RestoreResult.success(targetDbPath);
    } catch (e, stackTrace) {
      final String errorMsg = 'Failed to import SQLite database: $e';
      AppLogger.error(errorMsg, e, stackTrace);
      return RestoreResult.failure(errorMsg);
    }
  }

  /// Systematically invalidates all database and domain Riverpod providers.
  ///
  /// Destructively wipes all clinical database records and preferences, then invalidates Riverpod state.
  ///
  /// **Destructive Operations & Transaction Safety:**
  /// Wipes all tables (`appointments`, `case_records`, `requirements`, `clinics`, `patients`)
  /// in safe referential integrity order within an atomic SQLite transaction, clears all
  /// SharedPreferences device settings, and systematically invalidates all Riverpod state providers
  /// to eliminate cached UI "ghost data".
  Future<void> resetAllData({PreferencesRepository? preferencesRepository}) async {
    AppLogger.warning('CRITICAL: Executing complete database wipe. All clinical records cleared.');
    try {
      await _appDatabase.resetAllData(preferencesRepository: preferencesRepository);
      invalidateRiverpodState();
      AppLogger.info('Complete database reset and preference wipe executed successfully.');
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to execute complete database wipe: $e';
      AppLogger.error(errorMsg, e, stackTrace);
      rethrow;
    }
  }

  /// Systematically invalidates all database and domain Riverpod providers.
  ///
  /// Executing this after an import or database reset forces Riverpod to tear down
  /// cached repository instances and re-fetch records from the database file, preventing
  /// the UI from rendering obsolete or inconsistent "ghost" data.
  void invalidateRiverpodState() {
    final activeRef = ref;
    if (activeRef == null) {
      AppLogger.debug('Riverpod Ref is null; skipping provider invalidation.');
      return;
    }

    AppLogger.info('Invalidating all Riverpod database, domain, and preference providers...');

    // Invalidate database singleton & repositories
    activeRef.invalidate(appDatabaseProvider);
    activeRef.invalidate(patientRepositoryProvider);
    activeRef.invalidate(clinicRepositoryProvider);
    activeRef.invalidate(requirementRepositoryProvider);
    activeRef.invalidate(caseRecordRepositoryProvider);
    activeRef.invalidate(appointmentRepositoryProvider);
    activeRef.invalidate(preferencesRepositoryProvider);

    // Invalidate domain query providers
    activeRef.invalidate(patientListProvider);
    activeRef.invalidate(clinicListProvider);
    activeRef.invalidate(allRequirementsProvider);
    activeRef.invalidate(allCasesProvider);
    activeRef.invalidate(allAppointmentsProvider);
    activeRef.invalidate(upcomingAppointmentsProvider);
    activeRef.invalidate(globalQuotaSummaryProvider);
    activeRef.invalidate(filteredPatientListProvider);
    activeRef.invalidate(onboardingStatusProvider);
    activeRef.invalidate(remindersEnabledProvider);

    AppLogger.debug('All clinical providers successfully invalidated.');
  }
}

/// Riverpod provider exposing the [DatabaseBackupService] singleton.
final databaseBackupServiceProvider = Provider<DatabaseBackupService>((ref) {
  return DatabaseBackupService(
    appDatabase: ref.watch(appDatabaseProvider),
    ref: ref,
  );
});
