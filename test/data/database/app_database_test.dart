import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
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

  group('AppDatabase FFI Baseline Integration', () {
    test('opens singleton database instance and initializes relational schema', () async {
      final appDatabase = AppDatabase.instance;
      final db = await appDatabase.database;

      // Verify the SQLite database is open
      expect(db.isOpen, isTrue);

      // Verify PRAGMA foreign_keys is enabled
      final foreignKeysPragma = await db.rawQuery('PRAGMA foreign_keys;');
      expect(foreignKeysPragma.first.values.first, equals(1));

      // Query sqlite_master to verify that all core tables were created
      final tablesResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
      );
      final tableNames = tablesResult.map((row) => row['name'] as String).toSet();

      expect(
        tableNames,
        containsAll([
          'patients',
          'clinics',
          'requirements',
          'case_records',
          'appointments',
        ]),
      );
    });

    test('enforces foreign key cascade deletions when deleting a parent patient entity', () async {
      final appDatabase = AppDatabase.instance;
      final db = await appDatabase.database;

      // 1. Insert a parent patient record
      const patientId = 'test-patient-cascade-1';
      await db.insert('patients', {
        'id': patientId,
        'name': 'Cascade Test Patient',
        'age': 25,
        'gender': 'Male',
        'phoneNumber': '555-0199',
        'medicalHistory': 'None',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. Insert a child case record referencing the test patient and seeded requirement
      const caseRecordId = 'test-case-cascade-1';
      await db.insert('case_records', {
        'id': caseRecordId,
        'patientId': patientId,
        'requirementId': 'req-prosth-cd',
        'status': 'InProgress',
        'notes': 'Test cascade notes',
        'dateStarted': DateTime.now().toIso8601String(),
        'dateCompleted': null,
      });

      // 3. Insert a child appointment referencing the test patient and seeded clinic
      const appointmentId = 'test-appt-cascade-1';
      await db.insert('appointments', {
        'id': appointmentId,
        'patientId': patientId,
        'clinicId': 'clinic-prosth',
        'scheduledDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'status': 'Scheduled',
        'procedureDescription': 'Impression taking',
      });

      // Verify that child records exist prior to parent deletion
      final initialCaseRecords = await db.query(
        'case_records',
        where: 'patientId = ?',
        whereArgs: [patientId],
      );
      expect(initialCaseRecords, hasLength(1));

      final initialAppointments = await db.query(
        'appointments',
        where: 'patientId = ?',
        whereArgs: [patientId],
      );
      expect(initialAppointments, hasLength(1));

      // 4. Delete the parent patient entity
      final deletedRows = await db.delete(
        'patients',
        where: 'id = ?',
        whereArgs: [patientId],
      );
      expect(deletedRows, equals(1));

      // 5. Verify that SQLite ON DELETE CASCADE automatically removed child records
      final remainingCaseRecords = await db.query(
        'case_records',
        where: 'patientId = ?',
        whereArgs: [patientId],
      );
      expect(
        remainingCaseRecords,
        isEmpty,
        reason: 'Child case records must be deleted when the parent patient is deleted',
      );

      final remainingAppointments = await db.query(
        'appointments',
        where: 'patientId = ?',
        whereArgs: [patientId],
      );
      expect(
        remainingAppointments,
        isEmpty,
        reason: 'Child appointments must be deleted when the parent patient is deleted',
      );
    });

    test('supports insertion and retrieval of comprehensive anamnesis fields in patients table', () async {
      final appDatabase = AppDatabase.instance;
      final db = await appDatabase.database;

      const patientId = 'test-patient-anamnesis-1';
      await db.insert('patients', {
        'id': patientId,
        'name': 'Sami Khaled',
        'age': 32,
        'gender': 'Male',
        'phoneNumber': '+967-770001122',
        'medicalHistory': 'Controlled Type 2 Diabetes',
        'chiefComplaint': 'Severe pain in lower right first molar',
        'historyOfChiefComplaint': 'Pain began 4 days ago, spontaneous nocturnal throbbing',
        'dentalHistory': 'Restoration performed in 2024, regular dental hygiene',
        'medications': 'Metformin 500mg BID',
        'diagnosticAids': 'Periapical X-Ray showing periapical radiolucency on root apex',
        'createdAt': DateTime.now().toIso8601String(),
      });

      final rows = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [patientId],
      );

      expect(rows, hasLength(1));
      final row = rows.first;
      expect(row['chiefComplaint'], 'Severe pain in lower right first molar');
      expect(row['historyOfChiefComplaint'], 'Pain began 4 days ago, spontaneous nocturnal throbbing');
      expect(row['medicalHistory'], 'Controlled Type 2 Diabetes');
      expect(row['dentalHistory'], 'Restoration performed in 2024, regular dental hygiene');
      expect(row['medications'], 'Metformin 500mg BID');
      expect(row['diagnosticAids'], 'Periapical X-Ray showing periapical radiolucency on root apex');

      // Cleanup
      await db.delete('patients', where: 'id = ?', whereArgs: [patientId]);
    });

    test('migrates patients table from v1 to v2 adding all anamnesis columns', () async {
      final tempDbPath = p.join(
        Directory.systemTemp.path,
        'dentera_mig_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final db = await openDatabase(
          tempDbPath,
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
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
            await db.insert('patients', {
              'id': 'p-mig-1',
              'name': 'Migration Patient',
              'age': 20,
              'gender': 'Female',
              'phoneNumber': null,
              'medicalHistory': 'Penicillin Allergy',
              'createdAt': DateTime.now().toIso8601String(),
            });
          },
        );

        await db.close();

        // Open with v2 triggering migration logic
        final upgradedDb = await openDatabase(
          tempDbPath,
          version: 2,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute('ALTER TABLE patients ADD COLUMN chiefComplaint TEXT;');
              await db.execute('ALTER TABLE patients ADD COLUMN historyOfChiefComplaint TEXT;');
              await db.execute('ALTER TABLE patients ADD COLUMN dentalHistory TEXT;');
              await db.execute('ALTER TABLE patients ADD COLUMN medications TEXT;');
              await db.execute('ALTER TABLE patients ADD COLUMN diagnosticAids TEXT;');
            }
          },
        );

        final tableInfo = await upgradedDb.rawQuery('PRAGMA table_info(patients);');
        final columnNames = tableInfo.map((col) => col['name'] as String).toSet();

        expect(columnNames, containsAll([
          'chiefComplaint',
          'historyOfChiefComplaint',
          'dentalHistory',
          'medications',
          'diagnosticAids',
        ]));

        // Verify existing patient persisted through migration
        final rows = await upgradedDb.query('patients', where: 'id = ?', whereArgs: ['p-mig-1']);
        expect(rows, hasLength(1));
        expect(rows.first['name'], 'Migration Patient');
        expect(rows.first['medicalHistory'], 'Penicillin Allergy');
        expect(rows.first['chiefComplaint'], isNull);

        await upgradedDb.close();
      } finally {
        final file = File(tempDbPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    });
  });
}
