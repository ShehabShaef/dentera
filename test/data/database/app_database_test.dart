import 'package:flutter_test/flutter_test.dart';

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
  });
}
