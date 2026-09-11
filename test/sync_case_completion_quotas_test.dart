import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/data/repositories/sqlite_case_record_repository.dart';
import 'package:dentera/data/repositories/sqlite_clinic_repository.dart';
import 'package:dentera/data/repositories/sqlite_patient_repository.dart';
import 'package:dentera/data/repositories/sqlite_requirement_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/repositories.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/inputs/dentera_text_field.dart';
import 'package:dentera/presentation/widgets/modals/add_patient_modal.dart';
import 'package:dentera/presentation/widgets/modals/evaluate_case_modal.dart';

import 'setup/test_setup.dart';

class _FakePatientRepo implements PatientRepository {
  @override
  Future<void> addPatient(Patient patient) async {}
  @override
  Future<void> deletePatient(String id) async {}
  @override
  Future<void> deletePatients(List<String> ids) async {}
  @override
  Future<List<Patient>> getAllPatients() async => [];
  @override
  Future<Patient?> getPatientById(String id) async => null;
  @override
  Future<void> updatePatient(Patient patient) async {}
}

class _CaptureCaseRecordRepo implements CaseRecordRepository {
  CaseRecord? lastAddedCase;
  CaseRecord? lastUpdatedCase;

  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async {
    lastAddedCase = caseRecord;
  }

  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {
    lastUpdatedCase = caseRecord;
  }

  @override
  Future<void> deleteCaseRecord(String id) async {}
  @override
  Future<List<CaseRecord>> getAllCaseRecords() async => [];
  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async => [];
  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async => [];
}

class _FakeClinicRepo implements ClinicRepository {
  _FakeClinicRepo(this.clinics);
  final List<Clinic> clinics;

  @override
  Future<void> addClinic(Clinic clinic) async {}
  @override
  Future<void> updateClinic(Clinic clinic) async {}
  @override
  Future<void> deleteClinic(String id) async {}
  @override
  Future<void> deleteClinics(List<String> ids) async {}
  @override
  Future<List<Clinic>> getAllClinics() async => clinics;
  @override
  Future<Clinic?> getClinicById(String id) async =>
      clinics.where((c) => c.id == id).firstOrNull;
}

class _FakeRequirementRepo implements RequirementRepository {
  _FakeRequirementRepo(this.requirements);
  final List<Requirement> requirements;

  @override
  Future<void> addRequirement(Requirement requirement) async {}
  @override
  Future<void> updateRequirement(Requirement requirement) async {}
  @override
  Future<void> deleteRequirement(String id) async {}
  @override
  Future<void> deleteRequirements(List<String> ids) async {}
  @override
  Future<List<Requirement>> getAllRequirements() async => requirements;
  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async =>
      requirements.where((r) => r.clinicId == clinicId).toList();
  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}
}

void main() {
  setUpAll(() {
    setupDatabaseTests();
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
  });

  group('SQLite Case Completion & Quota Synchronization Integration Tests', () {
    test('Marking case as Completed or Evaluated automatically increments requirement completedCount in SQLite', () async {
      final appDb = AppDatabase.instance;
      final patientRepo = SqlitePatientRepository(appDb);
      final clinicRepo = SqliteClinicRepository(appDb);
      final requirementRepo = SqliteRequirementRepository(appDb);
      final caseRecordRepo = SqliteCaseRecordRepository(appDb);

      // Create clinic and requirement
      final clinicId = 'clinic-sync-${DateTime.now().microsecondsSinceEpoch}';
      await clinicRepo.addClinic(Clinic(
        id: clinicId,
        name: 'Prosthodontics Dept',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      ));

      final reqId = 'req-sync-${DateTime.now().microsecondsSinceEpoch}';
      await requirementRepo.addRequirement(Requirement(
        id: reqId,
        clinicId: clinicId,
        title: 'Complete Denture Trial',
        targetCount: 5,
        completedCount: 0,
      ));

      // Create patient
      final patientId = 'pt-sync-${DateTime.now().microsecondsSinceEpoch}';
      await patientRepo.addPatient(Patient(
        id: patientId,
        name: 'Kareem Naji',
        age: 40,
        gender: 'Male',
        createdAt: DateTime.now(),
      ));

      // 1. Add In-Progress Case Record
      final caseId = 'case-sync-${DateTime.now().microsecondsSinceEpoch}';
      final initialCase = CaseRecord(
        id: caseId,
        patientId: patientId,
        requirementId: reqId,
        status: 'In Progress',
        notes: 'Preliminary impression taken',
        dateStarted: DateTime.now(),
      );
      await caseRecordRepo.addCaseRecord(initialCase);

      // Verify requirement quota count is still 0
      var reqs = await requirementRepo.getRequirementsByClinicId(clinicId);
      expect(reqs.first.completedCount, 0);

      // 2. Mark Case as Completed -> requirement completedCount should increment to 1
      final completedCase = initialCase.copyWith(
        status: 'Completed',
        dateCompleted: DateTime.now(),
      );
      await caseRecordRepo.updateCaseRecord(completedCase);

      reqs = await requirementRepo.getRequirementsByClinicId(clinicId);
      expect(reqs.first.completedCount, 1);

      // 3. Mark Case as Evaluated -> transition between Completed and Evaluated keeps completedCount at 1
      final evaluatedCase = completedCase.copyWith(
        status: 'Evaluated',
        notes: 'Grade: 9.5/10\nExcellent adaptation',
      );
      await caseRecordRepo.updateCaseRecord(evaluatedCase);

      reqs = await requirementRepo.getRequirementsByClinicId(clinicId);
      expect(reqs.first.completedCount, 1);

      // 4. Change back to In Progress -> requirement completedCount should decrement to 0
      final reopenedCase = evaluatedCase.copyWith(
        status: 'In Progress',
      );
      await caseRecordRepo.updateCaseRecord(reopenedCase);

      reqs = await requirementRepo.getRequirementsByClinicId(clinicId);
      expect(reqs.first.completedCount, 0);

      // 5. Direct completion again -> increments back to 1
      await caseRecordRepo.updateCaseRecord(completedCase);
      reqs = await requirementRepo.getRequirementsByClinicId(clinicId);
      expect(reqs.first.completedCount, 1);

      // 6. Delete completed case -> decrements back to 0
      await caseRecordRepo.deleteCaseRecord(caseId);
      reqs = await requirementRepo.getRequirementsByClinicId(clinicId);
      expect(reqs.first.completedCount, 0);
    });
  });

  group('EvaluateCaseModal State Invalidation & Quota Recalculation Widget Tests', () {
    testWidgets('EvaluateCaseModal invalidates requirements and quotas upon saving evaluation', (WidgetTester tester) async {
      final captureCaseRepo = _CaptureCaseRecordRepo();

      final initialCase = CaseRecord(
        id: 'case-test-eval',
        patientId: 'p-eval',
        requirementId: 'req-eval',
        status: 'In Progress',
        dateStarted: DateTime.parse('2026-09-01T10:00:00.000Z'),
      );

      const fakeReq = Requirement(
        id: 'req-eval',
        clinicId: 'clinic-1',
        title: 'Complete Denture',
        targetCount: 5,
        completedCount: 0,
      );
      final fakeReqRepo = _FakeRequirementRepo([fakeReq]);
      final fakeClinicRepo = _FakeClinicRepo([]);

      final container = ProviderContainer(
        overrides: [
          caseRecordRepositoryProvider.overrideWithValue(captureCaseRepo),
          requirementRepositoryProvider.overrideWithValue(fakeReqRepo),
          clinicRepositoryProvider.overrideWithValue(fakeClinicRepo),
          allRequirementsProvider.overrideWith((ref) async => [fakeReq]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    EvaluateCaseModal.show(
                      context,
                      caseRecord: initialCase,
                      patientName: 'Bilal Saleh',
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open EvaluateCaseModal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Evaluate Case Record'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Select 'Completed' ChoiceChip
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Tap Save Evaluation
      await tester.tap(find.text('Save Evaluation'));
      await tester.pumpAndSettle();

      // Verify modal closed
      expect(find.text('Evaluate Case Record'), findsNothing);

      // Verify updateCaseRecord was invoked with 'Completed' status
      expect(captureCaseRepo.lastUpdatedCase, isNotNull);
      expect(captureCaseRepo.lastUpdatedCase!.id, 'case-test-eval');
      expect(captureCaseRepo.lastUpdatedCase!.status, 'Completed');

      container.dispose();
    });
  });

  group('AddPatientModal Dynamic Custom Clinic & Requirement Binding Tests', () {
    testWidgets('dynamically displays custom clinic and procedural requirement from SQLite providers', (WidgetTester tester) async {
      Patient? createdPatient;
      final captureCaseRepo = _CaptureCaseRecordRepo();

      const customClinic = Clinic(
        id: 'clinic-custom-ortho',
        name: 'Orthodontics',
        academicYear: '5th Year',
        colorHex: '#006A64',
      );

      const customReq = Requirement(
        id: 'req-custom-bracket',
        clinicId: 'clinic-custom-ortho',
        title: 'Bracket Placement',
        targetCount: 4,
        completedCount: 0,
      );

      final fakeClinicRepo = _FakeClinicRepo([customClinic]);
      final fakeReqRepo = _FakeRequirementRepo([customReq]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientRepositoryProvider.overrideWithValue(_FakePatientRepo()),
            caseRecordRepositoryProvider.overrideWithValue(captureCaseRepo),
            clinicRepositoryProvider.overrideWithValue(fakeClinicRepo),
            requirementRepositoryProvider.overrideWithValue(fakeReqRepo),
            allClinicsProvider.overrideWith((ref) async => <Clinic>[customClinic]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[customReq]),
            requirementsByClinicProvider('clinic-custom-ortho')
                .overrideWith((ref) async => <Requirement>[customReq]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AddPatientModal.show(
                      context,
                      onPatientAdded: (patient) => createdPatient = patient,
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify custom clinic badge is present and active
      expect(find.text('Orthodontics'), findsOneWidget);

      // Verify dynamic procedural requirement selector is populated
      expect(find.text('Main Case / Procedure'), findsOneWidget);
      expect(find.text('Select main case / procedure'), findsOneWidget);

      // Fill in required name and age
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Patient Name *'), 'Mona Saeed');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Age *'), '22');
      await tester.pumpAndSettle();

      // Explicitly select procedure from mandatory dropdown
      await tester.tap(find.text('Select main case / procedure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bracket Placement (0/4)').last);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      // Assert patient created and case record bound to custom requirement
      expect(createdPatient, isNotNull);
      expect(createdPatient!.name, 'Mona Saeed');

      expect(captureCaseRepo.lastAddedCase, isNotNull);
      expect(captureCaseRepo.lastAddedCase!.requirementId, 'req-custom-bracket');
      expect(captureCaseRepo.lastAddedCase!.status, 'In Progress');
    });
  });
}
