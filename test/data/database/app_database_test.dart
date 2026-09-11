import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:dentera/core/error/exceptions.dart';
import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/data/repositories/sqlite_appointment_repository.dart';
import 'package:dentera/data/repositories/sqlite_case_record_repository.dart';
import 'package:dentera/data/repositories/sqlite_case_visit_repository.dart';
import 'package:dentera/data/repositories/sqlite_clinic_repository.dart';
import 'package:dentera/data/repositories/sqlite_patient_repository.dart';
import 'package:dentera/data/repositories/sqlite_requirement_repository.dart';
import 'package:dentera/domain/entities/entities.dart';

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
          'case_visits',
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

    test('SqliteClinicRepository batch deletes clinics and cascades deletion to child requirements and appointments', () async {
      final appDb = AppDatabase.instance;
      final db = await appDb.database;
      final clinicRepo = SqliteClinicRepository(appDb);

      const c1Id = 'batch-clinic-1';
      const c2Id = 'batch-clinic-2';
      const testPatientId = 'patient-for-batch-clinic-test';

      await db.insert('patients', {
        'id': testPatientId,
        'name': 'Patient For Clinic Batch Test',
        'age': 22,
        'gender': 'Female',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await clinicRepo.addClinic(const Clinic(id: c1Id, name: 'Batch Clinic 1', academicYear: '5th Year', colorHex: '#003E6F'));
      await clinicRepo.addClinic(const Clinic(id: c2Id, name: 'Batch Clinic 2', academicYear: '5th Year', colorHex: '#006A64'));

      // Insert requirement referencing c1Id
      await db.insert('requirements', {
        'id': 'batch-req-1',
        'clinicId': c1Id,
        'title': 'Batch Req 1',
        'targetCount': 5,
        'completedCount': 0,
      });

      // Insert appointment referencing c2Id and testPatientId
      await db.insert('appointments', {
        'id': 'batch-appt-1',
        'patientId': testPatientId,
        'clinicId': c2Id,
        'scheduledDate': DateTime.now().toIso8601String(),
        'status': 'Scheduled',
        'procedureDescription': 'Consultation',
      });

      // Batch delete both clinics
      await clinicRepo.deleteClinics([c1Id, c2Id]);

      // Verify clinics are removed
      final remainingClinics = await db.query('clinics', where: 'id IN (?, ?)', whereArgs: [c1Id, c2Id]);
      expect(remainingClinics, isEmpty);

      // Verify child requirement was cascade deleted
      final remainingReqs = await db.query('requirements', where: 'id = ?', whereArgs: ['batch-req-1']);
      expect(remainingReqs, isEmpty);

      // Verify child appointment was cascade deleted
      final remainingAppts = await db.query('appointments', where: 'id = ?', whereArgs: ['batch-appt-1']);
      expect(remainingAppts, isEmpty);

      // Clean up test patient
      await db.delete('patients', where: 'id = ?', whereArgs: [testPatientId]);
    });

    test('SqlitePatientRepository batch deletes patients and cascades deletion to child cases and appointments', () async {
      final appDb = AppDatabase.instance;
      final db = await appDb.database;
      final patientRepo = SqlitePatientRepository(appDb);

      const p1Id = 'batch-patient-1';
      const p2Id = 'batch-patient-2';

      await patientRepo.addPatient(Patient(
        id: p1Id,
        name: 'Batch Patient 1',
        age: 28,
        gender: 'Male',
        createdAt: DateTime.now(),
      ));
      await patientRepo.addPatient(Patient(
        id: p2Id,
        name: 'Batch Patient 2',
        age: 34,
        gender: 'Female',
        createdAt: DateTime.now(),
      ));

      // Insert child case record referencing p1Id and seeded requirement
      await db.insert('case_records', {
        'id': 'batch-case-1',
        'patientId': p1Id,
        'requirementId': 'req-prosth-cd',
        'status': 'In Progress',
        'notes': 'Test notes',
        'dateStarted': DateTime.now().toIso8601String(),
        'dateCompleted': null,
      });

      // Insert child appointment referencing p2Id and seeded clinic
      await db.insert('appointments', {
        'id': 'batch-appt-p2',
        'patientId': p2Id,
        'clinicId': 'clinic-prosth',
        'scheduledDate': DateTime.now().toIso8601String(),
        'status': 'Scheduled',
        'procedureDescription': 'Checkup',
      });

      // Batch delete both patients
      await patientRepo.deletePatients([p1Id, p2Id]);

      // Verify patients are removed
      final remainingPatients = await db.query('patients', where: 'id IN (?, ?)', whereArgs: [p1Id, p2Id]);
      expect(remainingPatients, isEmpty);

      // Verify child case record cascade deleted
      final remainingCases = await db.query('case_records', where: 'id = ?', whereArgs: ['batch-case-1']);
      expect(remainingCases, isEmpty);

      // Verify child appointment cascade deleted
      final remainingAppts = await db.query('appointments', where: 'id = ?', whereArgs: ['batch-appt-p2']);
      expect(remainingAppts, isEmpty);
    });

    test('SqliteClinicRepository.updateClinic updates clinic fields and throws RecordNotFoundException on non-existent clinic', () async {
      final appDb = AppDatabase.instance;
      final clinicRepo = SqliteClinicRepository(appDb);

      const testClinicId = 'clinic-to-update-1';
      final initialClinic = Clinic(
        id: testClinicId,
        name: 'Original Clinic Name',
        academicYear: '5th Year',
        colorHex: '#112233',
      );

      await clinicRepo.addClinic(initialClinic);

      final updatedClinic = Clinic(
        id: testClinicId,
        name: 'Updated Clinic Name',
        academicYear: '4th Year',
        colorHex: '#445566',
      );

      await clinicRepo.updateClinic(updatedClinic);

      final retrieved = await clinicRepo.getClinicById(testClinicId);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Updated Clinic Name'));
      expect(retrieved.academicYear, equals('4th Year'));
      expect(retrieved.colorHex, equals('#445566'));

      final nonExistentClinic = Clinic(
        id: 'non-existent-clinic-id',
        name: 'Ghost Clinic',
        academicYear: '5th Year',
        colorHex: '#FFFFFF',
      );

      expect(
        () => clinicRepo.updateClinic(nonExistentClinic),
        throwsA(isA<RecordNotFoundException>()),
      );
    });

    test('SqliteRequirementRepository.updateRequirement updates requirement fields and throws RecordNotFoundException on non-existent requirement', () async {
      final appDb = AppDatabase.instance;
      final reqRepo = SqliteRequirementRepository(appDb);

      const testReqId = 'req-to-update-1';
      final initialReq = Requirement(
        id: testReqId,
        clinicId: 'clinic-prosth',
        title: 'Original Requirement Title',
        targetCount: 4,
        completedCount: 0,
      );

      await reqRepo.addRequirement(initialReq);

      final updatedReq = Requirement(
        id: testReqId,
        clinicId: 'clinic-prosth',
        title: 'Modified Requirement Title',
        targetCount: 10,
        completedCount: 2,
      );

      await reqRepo.updateRequirement(updatedReq);

      final reqs = await reqRepo.getRequirementsByClinicId('clinic-prosth');
      final retrieved = reqs.firstWhere((r) => r.id == testReqId);
      expect(retrieved.title, equals('Modified Requirement Title'));
      expect(retrieved.targetCount, equals(10));
      expect(retrieved.completedCount, equals(2));

      final nonExistentReq = Requirement(
        id: 'non-existent-req-id',
        clinicId: 'clinic-prosth',
        title: 'Ghost Requirement',
        targetCount: 1,
        completedCount: 0,
      );

      expect(
        () => reqRepo.updateRequirement(nonExistentReq),
        throwsA(isA<RecordNotFoundException>()),
      );
    });

    test('SqliteRequirementRepository.deleteRequirements batch deletes requirements and cascades deletion to child case records', () async {
      final appDb = AppDatabase.instance;
      final db = await appDb.database;
      final reqRepo = SqliteRequirementRepository(appDb);
      final patientRepo = SqlitePatientRepository(appDb);

      const patientId = 'test-patient-req-cascade';
      await patientRepo.addPatient(Patient(
        id: patientId,
        name: 'Req Cascade Patient',
        age: 30,
        gender: 'Male',
        createdAt: DateTime.now(),
      ));

      const r1Id = 'batch-delete-req-1';
      const r2Id = 'batch-delete-req-2';

      await reqRepo.addRequirement(Requirement(
        id: r1Id,
        clinicId: 'clinic-prosth',
        title: 'Batch Req 1',
        targetCount: 5,
        completedCount: 0,
      ));
      await reqRepo.addRequirement(Requirement(
        id: r2Id,
        clinicId: 'clinic-prosth',
        title: 'Batch Req 2',
        targetCount: 3,
        completedCount: 0,
      ));

      // Insert child case records for both requirements
      await db.insert('case_records', {
        'id': 'case-req-1',
        'patientId': patientId,
        'requirementId': r1Id,
        'status': 'In Progress',
        'notes': 'Test case 1',
        'dateStarted': DateTime.now().toIso8601String(),
        'dateCompleted': null,
      });

      await db.insert('case_records', {
        'id': 'case-req-2',
        'patientId': patientId,
        'requirementId': r2Id,
        'status': 'In Progress',
        'notes': 'Test case 2',
        'dateStarted': DateTime.now().toIso8601String(),
        'dateCompleted': null,
      });

      // Batch delete both requirements
      await reqRepo.deleteRequirements([r1Id, r2Id]);

      // Verify requirements are deleted
      final remainingReqs = await db.query('requirements', where: 'id IN (?, ?)', whereArgs: [r1Id, r2Id]);
      expect(remainingReqs, isEmpty);

      // Verify child case records were cascade deleted
      final remainingCases = await db.query('case_records', where: 'id IN (?, ?)', whereArgs: ['case-req-1', 'case-req-2']);
      expect(remainingCases, isEmpty);

      // Clean up patient
      await patientRepo.deletePatient(patientId);
    });

    test('SqliteCaseRecordRepository.deleteCaseRecord decrements requirement completedCount atomically when deleting a completed case', () async {
      final appDb = AppDatabase.instance;
      final reqRepo = SqliteRequirementRepository(appDb);
      final patientRepo = SqlitePatientRepository(appDb);
      final caseRepo = SqliteCaseRecordRepository(appDb);

      const patientId = 'patient-case-delete-sync';
      await patientRepo.addPatient(Patient(
        id: patientId,
        name: 'Case Sync Patient',
        age: 26,
        gender: 'Female',
        createdAt: DateTime.now(),
      ));

      const reqId = 'req-case-delete-sync';
      await reqRepo.addRequirement(const Requirement(
        id: reqId,
        clinicId: 'clinic-prosth',
        title: 'Quota Decrement Target',
        targetCount: 5,
        completedCount: 0,
      ));

      const caseId = 'case-to-delete-sync';
      final completedCase = CaseRecord(
        id: caseId,
        patientId: patientId,
        requirementId: reqId,
        status: 'Completed',
        notes: 'Finished treatment',
        dateStarted: DateTime.now(),
        dateCompleted: DateTime.now(),
      );

      // Inserting completed case should increment completedCount to 1
      await caseRepo.addCaseRecord(completedCase);

      final reqAfterAdd = await reqRepo.getRequirementsByClinicId('clinic-prosth');
      final updatedReq = reqAfterAdd.firstWhere((r) => r.id == reqId);
      expect(updatedReq.completedCount, equals(1));

      // Deleting the completed case should atomically decrement completedCount back to 0
      await caseRepo.deleteCaseRecord(caseId);

      final reqAfterDelete = await reqRepo.getRequirementsByClinicId('clinic-prosth');
      final decrementedReq = reqAfterDelete.firstWhere((r) => r.id == reqId);
      expect(decrementedReq.completedCount, equals(0));

      // Clean up
      await reqRepo.deleteRequirement(reqId);
      await patientRepo.deletePatient(patientId);
    });

    test('SqliteAppointmentRepository.updateAppointment and deleteAppointment properly mutate and remove appointments', () async {
      final appDb = AppDatabase.instance;
      final aptRepo = SqliteAppointmentRepository(appDb);
      final patientRepo = SqlitePatientRepository(appDb);

      const patientId = 'patient-apt-crud-test';
      await patientRepo.addPatient(Patient(
        id: patientId,
        name: 'Apt Test Patient',
        age: 32,
        gender: 'Male',
        createdAt: DateTime.now(),
      ));

      const aptId = 'apt-crud-test-1';
      final initialApt = Appointment(
        id: aptId,
        patientId: patientId,
        clinicId: 'clinic-prosth',
        scheduledDate: DateTime(2026, 9, 15, 10, 0),
        status: 'Scheduled',
        procedureDescription: 'Initial Consultation',
      );

      await aptRepo.addAppointment(initialApt);

      final updatedApt = initialApt.copyWith(
        scheduledDate: DateTime(2026, 9, 15, 14, 30),
        status: 'Completed',
        procedureDescription: 'Follow-up Procedure',
      );

      await aptRepo.updateAppointment(updatedApt);

      final apts = await aptRepo.getAppointmentsByDate(DateTime(2026, 9, 15));
      expect(apts.length, equals(1));
      expect(apts.first.status, equals('Completed'));
      expect(apts.first.procedureDescription, equals('Follow-up Procedure'));
      expect(apts.first.scheduledDate.hour, equals(14));

      await aptRepo.deleteAppointment(aptId);

      final remainingApts = await aptRepo.getAppointmentsByDate(DateTime(2026, 9, 15));
      expect(remainingApts, isEmpty);

      // Clean up patient
      await patientRepo.deletePatient(patientId);
    });

    test('SqliteCaseVisitRepository supports CRUD, batch insertion, and ordered retrieval', () async {
      final appDb = AppDatabase.instance;
      final visitRepo = SqliteCaseVisitRepository(appDb);
      final caseRepo = SqliteCaseRecordRepository(appDb);
      final patientRepo = SqlitePatientRepository(appDb);

      const patientId = 'patient-visit-test-1';
      await patientRepo.addPatient(Patient(
        id: patientId,
        name: 'Visit Test Patient',
        age: 29,
        gender: 'Female',
        createdAt: DateTime.now(),
      ));

      const caseId = 'case-visit-test-1';
      await caseRepo.addCaseRecord(CaseRecord(
        id: caseId,
        patientId: patientId,
        requirementId: 'req-prosth-cd',
        status: 'In Progress',
        notes: 'Multi-visit treatment',
        dateStarted: DateTime.now(),
      ));

      final visits = [
        const CaseVisit(
          id: 'visit-1',
          caseRecordId: caseId,
          visitNumber: 1,
          title: 'Primary Impressions',
          status: 'Completed',
          notes: 'Alginate impressions taken',
        ),
        const CaseVisit(
          id: 'visit-2',
          caseRecordId: caseId,
          visitNumber: 2,
          title: 'Final Impressions',
          status: 'Pending',
        ),
        const CaseVisit(
          id: 'visit-3',
          caseRecordId: caseId,
          visitNumber: 3,
          title: 'Jaw Relation & Wax Try-in',
          status: 'Pending',
        ),
      ];

      // Batch insert visits
      await visitRepo.addCaseVisits(visits);

      // Retrieve visits by caseRecordId and verify ordering by visitNumber ASC
      final retrieved = await visitRepo.getVisitsByCaseRecordId(caseId);
      expect(retrieved.length, equals(3));
      expect(retrieved[0].visitNumber, equals(1));
      expect(retrieved[0].title, equals('Primary Impressions'));
      expect(retrieved[0].status, equals('Completed'));
      expect(retrieved[1].visitNumber, equals(2));
      expect(retrieved[2].visitNumber, equals(3));

      // Update visit-2
      final updatedVisit2 = retrieved[1].copyWith(
        status: 'Completed',
        notes: 'Border molding and PVS impression successful',
        dateCompleted: DateTime.now(),
      );
      await visitRepo.updateCaseVisit(updatedVisit2);

      final reFetched = await visitRepo.getVisitsByCaseRecordId(caseId);
      expect(reFetched[1].status, equals('Completed'));
      expect(reFetched[1].notes, equals('Border molding and PVS impression successful'));
      expect(reFetched[1].dateCompleted, isNotNull);

      // Delete individual visit
      await visitRepo.deleteCaseVisit('visit-3');
      final afterDelete = await visitRepo.getVisitsByCaseRecordId(caseId);
      expect(afterDelete.length, equals(2));

      // Clean up case and patient
      await caseRepo.deleteCaseRecord(caseId);
      await patientRepo.deletePatient(patientId);
    });

    test('enforces foreign key cascade deletion from case_records to case_visits', () async {
      final appDb = AppDatabase.instance;
      final db = await appDb.database;
      final visitRepo = SqliteCaseVisitRepository(appDb);
      final caseRepo = SqliteCaseRecordRepository(appDb);
      final patientRepo = SqlitePatientRepository(appDb);

      const patientId = 'patient-cascade-visit';
      await patientRepo.addPatient(Patient(
        id: patientId,
        name: 'Cascade Patient',
        age: 40,
        gender: 'Male',
        createdAt: DateTime.now(),
      ));

      const caseId = 'case-cascade-visit-1';
      await caseRepo.addCaseRecord(CaseRecord(
        id: caseId,
        patientId: patientId,
        requirementId: 'req-prosth-cd',
        status: 'In Progress',
        dateStarted: DateTime.now(),
      ));

      await visitRepo.addCaseVisits([
        const CaseVisit(
          id: 'cv-cascade-1',
          caseRecordId: caseId,
          visitNumber: 1,
          title: 'Visit 1',
        ),
        const CaseVisit(
          id: 'cv-cascade-2',
          caseRecordId: caseId,
          visitNumber: 2,
          title: 'Visit 2',
        ),
      ]);

      expect(await visitRepo.getVisitsByCaseRecordId(caseId), hasLength(2));

      // Delete the parent case_record
      await caseRepo.deleteCaseRecord(caseId);

      // Verify that case_visits were cascade deleted by SQLite
      final remainingVisits = await db.query(
        'case_visits',
        where: 'caseRecordId = ?',
        whereArgs: [caseId],
      );
      expect(remainingVisits, isEmpty);

      // Clean up patient
      await patientRepo.deletePatient(patientId);
    });

    test('migrates database from v2 to v3 creating case_visits table', () async {
      final tempDbPath = p.join(
        Directory.systemTemp.path,
        'dentera_mig_v3_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        // Create DB at version 2
        final db = await openDatabase(
          tempDbPath,
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE patients (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                age INTEGER NOT NULL,
                gender TEXT NOT NULL,
                phoneNumber TEXT,
                medicalHistory TEXT,
                chiefComplaint TEXT,
                historyOfChiefComplaint TEXT,
                dentalHistory TEXT,
                medications TEXT,
                diagnosticAids TEXT,
                createdAt TEXT NOT NULL
              );
            ''');
            await db.execute('''
              CREATE TABLE case_records (
                id TEXT PRIMARY KEY,
                patientId TEXT NOT NULL,
                requirementId TEXT NOT NULL,
                status TEXT NOT NULL,
                notes TEXT,
                dateStarted TEXT NOT NULL,
                dateCompleted TEXT
              );
            ''');
          },
        );

        await db.close();

        // Upgrade to v3
        final upgradedDb = await openDatabase(
          tempDbPath,
          version: 3,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 3) {
              await db.execute('''
                CREATE TABLE IF NOT EXISTS case_visits (
                  id TEXT PRIMARY KEY,
                  caseRecordId TEXT NOT NULL,
                  visitNumber INTEGER NOT NULL,
                  title TEXT NOT NULL,
                  status TEXT NOT NULL DEFAULT 'Pending',
                  notes TEXT,
                  dateScheduled TEXT,
                  dateCompleted TEXT,
                  FOREIGN KEY (caseRecordId) REFERENCES case_records (id) ON DELETE CASCADE
                );
              ''');
            }
          },
        );

        final tableInfo = await upgradedDb.rawQuery('PRAGMA table_info(case_visits);');
        final columnNames = tableInfo.map((col) => col['name'] as String).toSet();

        expect(columnNames, containsAll([
          'id',
          'caseRecordId',
          'visitNumber',
          'title',
          'status',
          'notes',
          'dateScheduled',
          'dateCompleted',
        ]));

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
