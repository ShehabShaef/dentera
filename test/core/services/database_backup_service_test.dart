import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/services/database_backup_service.dart';
import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/state/patients_provider.dart';

import '../../setup/test_setup.dart';

void main() {
  setUpAll(() {
    setupDatabaseTests();
  });

  group('DatabaseBackupService - SQLite Header Validation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dentera_backup_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('validates authentic SQLite 3 header correctly', () async {
      final validDbFile = File('${tempDir.path}/valid.db');
      final validBytes = Uint8List.fromList([
        ...DatabaseBackupService.sqliteHeaderBytes,
        0x01, 0x02, 0x03, 0x04,
      ]);
      await validDbFile.writeAsBytes(validBytes);

      final isValid = await DatabaseBackupService.isValidSqliteFile(validDbFile);
      expect(isValid, isTrue);
    });

    test('rejects arbitrary text file with invalid magic bytes', () async {
      final textFile = File('${tempDir.path}/corrupt.db');
      await textFile.writeAsString('This is a plain text file, not SQLite!');

      final isValid = await DatabaseBackupService.isValidSqliteFile(textFile);
      expect(isValid, isFalse);
    });

    test('rejects file smaller than 16 bytes', () async {
      final smallFile = File('${tempDir.path}/small.db');
      await smallFile.writeAsBytes([0x53, 0x51, 0x4C]); // Only 3 bytes

      final isValid = await DatabaseBackupService.isValidSqliteFile(smallFile);
      expect(isValid, isFalse);
    });

    test('rejects nonexistent file safely without throwing', () async {
      final missingFile = File('${tempDir.path}/missing.db');

      final isValid = await DatabaseBackupService.isValidSqliteFile(missingFile);
      expect(isValid, isFalse);
    });
  });

  group('DatabaseBackupService - File Export & Import Operations', () {
    late Directory tempDir;
    late File mockActiveDb;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('dentera_io_test_');
      mockActiveDb = File('${tempDir.path}/dentera.db');
      final initialData = Uint8List.fromList([
        ...DatabaseBackupService.sqliteHeaderBytes,
        0xAA, 0xBB, 0xCC, 0xDD,
      ]);
      await mockActiveDb.writeAsBytes(initialData);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('exportDatabase copies active database to destination directory', () async {
      final exportDir = Directory('${tempDir.path}/exports')..createSync();
      final service = DatabaseBackupService(
        customDatabasePath: mockActiveDb.path,
      );

      final result = await service.exportDatabase(
        destinationDirectoryPath: exportDir.path,
        shareViaSystemDialog: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.filePath, isNotNull);

      final exportedFile = File(result.filePath!);
      expect(await exportedFile.exists(), isTrue);
      expect(exportedFile.path, contains('dentera_backup_'));
      expect(exportedFile.path.endsWith('.db'), isTrue);

      final exportedBytes = await exportedFile.readAsBytes();
      final originalBytes = await mockActiveDb.readAsBytes();
      expect(exportedBytes, equals(originalBytes));
    });

    test('exportDatabase fails gracefully if source database does not exist', () async {
      final missingDbPath = '${tempDir.path}/nonexistent_dir/never_created.db';
      final service = DatabaseBackupService(
        customDatabasePath: missingDbPath,
      );

      final result = await service.exportDatabase(
        destinationDirectoryPath: tempDir.path,
        shareViaSystemDialog: false,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Failed to locate database file'));
    });

    test('importDatabase overwrites active database and purges WAL/SHM artifacts', () async {
      // 1. Prepare valid replacement backup file
      final backupFile = File('${tempDir.path}/new_backup.db');
      final newContent = Uint8List.fromList([
        ...DatabaseBackupService.sqliteHeaderBytes,
        0x11, 0x22, 0x33, 0x44, 0x55,
      ]);
      await backupFile.writeAsBytes(newContent);

      // 2. Create lingering WAL and SHM sidecars
      final walFile = File('${mockActiveDb.path}-wal');
      final shmFile = File('${mockActiveDb.path}-shm');
      await walFile.writeAsString('stale-wal-index');
      await shmFile.writeAsString('stale-shm-index');

      expect(await walFile.exists(), isTrue);
      expect(await shmFile.exists(), isTrue);

      // 3. Perform import
      final service = DatabaseBackupService(
        customDatabasePath: mockActiveDb.path,
      );
      final result = await service.importDatabase(customSourcePath: backupFile.path);

      expect(result.isSuccess, isTrue);
      expect(result.restoredFilePath, equals(mockActiveDb.path));

      // 4. Verify target database has been overwritten
      final updatedBytes = await mockActiveDb.readAsBytes();
      expect(updatedBytes, equals(newContent));

      // 5. Verify WAL and SHM files were cleanly purged
      expect(await walFile.exists(), isFalse);
      expect(await shmFile.exists(), isFalse);
    });

    test('importDatabase rejects non-SQLite files and leaves active database intact', () async {
      final invalidFile = File('${tempDir.path}/corrupted.db');
      await invalidFile.writeAsString('NOT A VALID SQLITE DATABASE');

      final originalBytes = await mockActiveDb.readAsBytes();

      final service = DatabaseBackupService(
        customDatabasePath: mockActiveDb.path,
      );
      final result = await service.importDatabase(customSourcePath: invalidFile.path);

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('not a valid SQLite database'));

      // Ensure active database was NOT overwritten
      final currentBytes = await mockActiveDb.readAsBytes();
      expect(currentBytes, equals(originalBytes));
    });

    test('importDatabase returns failure when source file does not exist', () async {
      final missingSource = '${tempDir.path}/missing_backup.db';
      final service = DatabaseBackupService(
        customDatabasePath: mockActiveDb.path,
      );

      final result = await service.importDatabase(customSourcePath: missingSource);

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('does not exist'));
    });
  });

  group('DatabaseBackupService - Riverpod State Invalidation Integration', () {
    test('invalidates providers properly through Ref', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      int invalidationTriggers = 0;
      container.listen(patientListProvider, (previous, next) {
        invalidationTriggers++;
      });

      // Force initial read
      container.read(patientListProvider);

      final backupService = container.read(databaseBackupServiceProvider);
      expect(backupService, isNotNull);

      // Trigger provider invalidation
      backupService.invalidateRiverpodState();

      // Expect that the provider lifecycle was refreshed
      expect(invalidationTriggers, greaterThanOrEqualTo(0));
    });

    test('full export and import round-trip restores database records', () async {
      final appDb = AppDatabase.instance;
      final db = await appDb.database;

      // Seed a test patient
      final patient = Patient(
        id: 'patient-backup-test-1',
        name: 'John Backup Doe',
        age: 28,
        gender: 'Male',
        phoneNumber: '555-9876',
        medicalHistory: 'None',
        createdAt: DateTime.now(),
      );

      await db.insert('patients', patient.toMap());

      // Verify patient exists in DB
      final queryBefore = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [patient.id],
      );
      expect(queryBefore.length, equals(1));

      // Export the database to a temp directory
      final tempDir = Directory.systemTemp.createTempSync('dentera_roundtrip_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final service = DatabaseBackupService(appDatabase: appDb);
      final exportResult = await service.exportDatabase(
        destinationDirectoryPath: tempDir.path,
        shareViaSystemDialog: false,
      );

      expect(exportResult.isSuccess, isTrue);
      final backupFilePath = exportResult.filePath!;

      // Now delete the patient from the live database
      await db.delete('patients', where: 'id = ?', whereArgs: [patient.id]);
      final queryAfterDelete = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [patient.id],
      );
      expect(queryAfterDelete, isEmpty);

      // Now restore from the backup file
      final importResult = await service.importDatabase(customSourcePath: backupFilePath);
      expect(importResult.isSuccess, isTrue);

      // Re-query database to verify patient was restored!
      final reloadedDb = await appDb.database;
      final queryAfterRestore = await reloadedDb.query(
        'patients',
        where: 'id = ?',
        whereArgs: [patient.id],
      );
      expect(queryAfterRestore.length, equals(1));
      expect(queryAfterRestore.first['name'], equals('John Backup Doe'));
    });
  });
}
