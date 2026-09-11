import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:dentera/data/database/app_database.dart';

import '../../setup/test_setup.dart';

void main() {
  setUpAll(() {
    setupDatabaseTests();
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('SQLite Database Integrity Audit & Corruption Recovery', () {
    test('auditDatabaseIntegrity returns true for healthy database', () async {
      final appDb = AppDatabase.instance;
      final isHealthy = await appDb.auditDatabaseIntegrity();
      expect(isHealthy, isTrue);

      final db = await appDb.database;
      final results = await db.rawQuery('PRAGMA integrity_check;');
      expect(results, isNotEmpty);
      expect(results.first.values.first.toString().trim().toLowerCase(), equals('ok'));
    });

    test('auditDatabaseIntegrity returns false when query fails or database is closed without auto-recovery', () async {
      final appDb = AppDatabase.instance;

      // Create a secondary database and close it to induce a failure on query
      final tempDb = await openDatabase(inMemoryDatabasePath);
      await tempDb.close();

      final result = await appDb.auditDatabaseIntegrity(
        targetDatabase: tempDb,
        autoRecover: false,
      );

      expect(result, isFalse);
    });

    test('recoverCorruptedDatabase preserves corrupted file and recreates fresh database with seed data', () async {
      final appDb = AppDatabase.instance;

      // 1. Ensure database exists and has an active file
      final db = await appDb.database;
      expect(db.isOpen, isTrue);
      final dbPath = await appDb.getDatabasePath();
      final originalFile = File(dbPath);
      expect(await originalFile.exists(), isTrue);

      // 2. Trigger recoverCorruptedDatabase
      final recoveredDb = await appDb.recoverCorruptedDatabase();
      expect(recoveredDb.isOpen, isTrue);

      // 3. Verify backup file was created with .corrupted_<timestamp>.bak pattern
      final docDir = await getApplicationDocumentsDirectory();
      final backupFiles = docDir
          .listSync()
          .where((entity) =>
              entity is File && entity.path.contains('.corrupted_') && entity.path.endsWith('.bak'))
          .toList();

      expect(backupFiles, isNotEmpty);

      // Clean up backup file created during test
      for (final file in backupFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 4. Verify that re-created database passes integrity check and contains seeded data
      final isHealthyAfterRecovery = await appDb.auditDatabaseIntegrity();
      expect(isHealthyAfterRecovery, isTrue);

      final clinicsCount = Sqflite.firstIntValue(
        await recoveredDb.rawQuery('SELECT COUNT(*) FROM clinics;'),
      );
      expect(clinicsCount, greaterThan(0));

      final reqsCount = Sqflite.firstIntValue(
        await recoveredDb.rawQuery('SELECT COUNT(*) FROM requirements;'),
      );
      expect(reqsCount, greaterThan(0));
    });

    test('auditDatabaseIntegrity triggers automatic recovery when corruption occurs', () async {
      final appDb = AppDatabase.instance;

      // Ensure database is initialized
      await appDb.database;

      // Closed target DB simulates an unrecoverable corrupted database connection
      final failingDb = await openDatabase(inMemoryDatabasePath);
      await failingDb.close();

      final passed = await appDb.auditDatabaseIntegrity(
        targetDatabase: failingDb,
        autoRecover: true,
      );

      expect(passed, isFalse);

      // After autoRecover: true, appDb should have re-initialized a fresh healthy database
      final activeDb = await appDb.database;
      expect(activeDb.isOpen, isTrue);

      final isHealthy = await appDb.auditDatabaseIntegrity();
      expect(isHealthy, isTrue);

      // Clean up any generated backup files
      final docDir = await getApplicationDocumentsDirectory();
      final backupFiles = docDir
          .listSync()
          .where((entity) =>
              entity is File && entity.path.contains('.corrupted_') && entity.path.endsWith('.bak'))
          .toList();
      for (final file in backupFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    });
  });
}
