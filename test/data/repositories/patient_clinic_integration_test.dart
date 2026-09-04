import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/error/exceptions.dart';
import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/data/repositories/sqlite_case_record_repository.dart';
import 'package:dentera/data/repositories/sqlite_clinic_repository.dart';
import 'package:dentera/data/repositories/sqlite_patient_repository.dart';
import 'package:dentera/data/repositories/sqlite_requirement_repository.dart';
import 'package:dentera/domain/entities/entities.dart';

import '../../setup/test_setup.dart';

/// Integration tests verifying SQLite relational persistence between [Patient],
/// [Clinic], [Requirement], and [CaseRecord] entities using `sqflite_common_ffi`.
void main() {
  setUpAll(() {
    setupDatabaseTests();
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('Patient & Relational CaseRecord SQLite Integration Tests', () {
    test('successfully inserts new patient and sequentially creates linked initial case record', () async {
      final appDb = AppDatabase.instance;
      final patientRepo = SqlitePatientRepository(appDb);
      final clinicRepo = SqliteClinicRepository(appDb);
      final requirementRepo = SqliteRequirementRepository(appDb);
      final caseRecordRepo = SqliteCaseRecordRepository(appDb);

      // Verify seeded clinics and requirements exist from initial database creation
      final clinics = await clinicRepo.getAllClinics();
      expect(clinics, isNotEmpty, reason: 'Database seeder should have populated academic clinics');

      final targetClinic = clinics.first;
      final clinicRequirements = await requirementRepo.getRequirementsByClinicId(targetClinic.id);
      expect(clinicRequirements, isNotEmpty, reason: 'Target clinic should possess seeded quota requirements');
      final targetRequirement = clinicRequirements.first;

      // 1. Insert new patient
      final patientId = 'PT-TEST-${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now();
      final newPatient = Patient(
        id: patientId,
        name: 'Fatima Al-Hassan',
        age: 28,
        gender: 'Female',
        phoneNumber: '+967-771122334',
        medicalHistory: 'None',
        createdAt: now,
      );

      await patientRepo.addPatient(newPatient);

      // 2. Extract generated UUID and insert initial CaseRecord linking patient to clinic requirement
      final caseId = 'CASE-TEST-${DateTime.now().microsecondsSinceEpoch}';
      final initialCase = CaseRecord(
        id: caseId,
        patientId: patientId,
        requirementId: targetRequirement.id,
        status: 'In Progress',
        notes: 'Initial clinical registration case for ${targetClinic.name}',
        dateStarted: now,
      );

      await caseRecordRepo.addCaseRecord(initialCase);

      // 3. Verify patient was persisted and retrievable
      final retrievedPatient = await patientRepo.getPatientById(patientId);
      expect(retrievedPatient, isNotNull);
      expect(retrievedPatient!.name, equals('Fatima Al-Hassan'));
      expect(retrievedPatient.phoneNumber, equals('+967-771122334'));

      // 4. Verify case record was linked to the patient
      final patientCases = await caseRecordRepo.getCaseRecordsByPatientId(patientId);
      expect(patientCases, hasLength(1));
      expect(patientCases.first.id, equals(caseId));
      expect(patientCases.first.patientId, equals(patientId));
      expect(patientCases.first.requirementId, equals(targetRequirement.id));
      expect(patientCases.first.status, equals('In Progress'));
      expect(patientCases.first.notes, contains(targetClinic.name));
    });

    test('enforces foreign key integrity when inserting case record with non-existent patient', () async {
      final appDb = AppDatabase.instance;
      final requirementRepo = SqliteRequirementRepository(appDb);
      final caseRecordRepo = SqliteCaseRecordRepository(appDb);

      final requirements = await requirementRepo.getAllRequirements();
      expect(requirements, isNotEmpty);
      final validRequirementId = requirements.first.id;

      const nonExistentPatientId = 'non-existent-patient-uuid-9999';

      final orphanedCase = CaseRecord(
        id: 'CASE-FAIL-${DateTime.now().microsecondsSinceEpoch}',
        patientId: nonExistentPatientId,
        requirementId: validRequirementId,
        status: 'In Progress',
        notes: 'Orphaned case should fail foreign key check',
        dateStarted: DateTime.now(),
      );

      // Expect LocalDatabaseException due to SQLite FOREIGN KEY constraint violation
      expect(
        () async => await caseRecordRepo.addCaseRecord(orphanedCase),
        throwsA(isA<LocalDatabaseException>()),
      );
    });

    test('deleting patient cascades and deletes linked case records', () async {
      final appDb = AppDatabase.instance;
      final patientRepo = SqlitePatientRepository(appDb);
      final requirementRepo = SqliteRequirementRepository(appDb);
      final caseRecordRepo = SqliteCaseRecordRepository(appDb);

      final requirements = await requirementRepo.getAllRequirements();
      final validRequirementId = requirements.first.id;

      final patientId = 'PT-CASCADE-${DateTime.now().microsecondsSinceEpoch}';
      final patient = Patient(
        id: patientId,
        name: 'Tariq Mansoor',
        age: 35,
        gender: 'Male',
        phoneNumber: '+967-779988776',
        medicalHistory: 'Penicillin allergy',
        createdAt: DateTime.now(),
      );

      await patientRepo.addPatient(patient);

      final caseId = 'CASE-CASCADE-${DateTime.now().microsecondsSinceEpoch}';
      final caseRecord = CaseRecord(
        id: caseId,
        patientId: patientId,
        requirementId: validRequirementId,
        status: 'In Progress',
        notes: 'Temporary case record',
        dateStarted: DateTime.now(),
      );

      await caseRecordRepo.addCaseRecord(caseRecord);

      // Confirm record exists
      final preDeleteCases = await caseRecordRepo.getCaseRecordsByPatientId(patientId);
      expect(preDeleteCases, hasLength(1));

      // Delete patient
      await patientRepo.deletePatient(patientId);

      // Verify cascade deleted the case record
      final postDeleteCases = await caseRecordRepo.getCaseRecordsByPatientId(patientId);
      expect(postDeleteCases, isEmpty);
    });
  });
}
