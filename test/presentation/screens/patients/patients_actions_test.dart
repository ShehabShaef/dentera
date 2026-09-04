import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/case_record_repository.dart';
import 'package:dentera/domain/repositories/clinic_repository.dart';
import 'package:dentera/domain/repositories/patient_repository.dart';
import 'package:dentera/domain/repositories/requirement_repository.dart';
import 'package:dentera/presentation/screens/patients/patient_case_sheet_screen.dart';
import 'package:dentera/presentation/screens/patients/patients_screen.dart';
import 'package:dentera/presentation/screens/patients/widgets/widgets.dart';
import 'package:dentera/presentation/widgets/modals/edit_patient_modal.dart';
import 'package:dentera/presentation/widgets/modals/evaluate_case_modal.dart';
import 'package:dentera/presentation/widgets/modals/log_case_record_modal.dart';
import 'package:dentera/presentation/widgets/modals/sort_patients_modal.dart';

class MockPatientRepository implements PatientRepository {
  MockPatientRepository(List<Patient> initial) : patients = List.from(initial);

  final List<Patient> patients;
  Patient? lastUpdatedPatient;

  @override
  Future<List<Patient>> getAllPatients() async => List.unmodifiable(patients);

  @override
  Future<Patient?> getPatientById(String id) async =>
      patients.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> addPatient(Patient patient) async {
    patients.add(patient);
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    lastUpdatedPatient = patient;
    final index = patients.indexWhere((p) => p.id == patient.id);
    if (index != -1) {
      patients[index] = patient;
    } else {
      patients.add(patient);
    }
  }

  @override
  Future<void> deletePatient(String id) async {
    patients.removeWhere((p) => p.id == id);
  }
}

class MockClinicRepository implements ClinicRepository {
  MockClinicRepository(List<Clinic> initial) : clinics = List.from(initial);

  final List<Clinic> clinics;

  @override
  Future<List<Clinic>> getAllClinics() async => List.unmodifiable(clinics);

  @override
  Future<Clinic?> getClinicById(String id) async =>
      clinics.where((c) => c.id == id).firstOrNull;

  @override
  Future<void> addClinic(Clinic clinic) async => clinics.add(clinic);
}

class MockRequirementRepository implements RequirementRepository {
  MockRequirementRepository(List<Requirement> initial) : requirements = List.from(initial);

  final List<Requirement> requirements;

  @override
  Future<List<Requirement>> getAllRequirements() async => List.unmodifiable(requirements);

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async =>
      requirements.where((r) => r.clinicId == clinicId).toList();

  @override
  Future<void> addRequirement(Requirement requirement) async => requirements.add(requirement);

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}
}

class MockCaseRecordRepository implements CaseRecordRepository {
  MockCaseRecordRepository(List<CaseRecord> initial) : cases = List.from(initial);

  final List<CaseRecord> cases;
  CaseRecord? lastAddedCase;
  CaseRecord? lastUpdatedCase;

  @override
  Future<List<CaseRecord>> getAllCaseRecords() async => List.unmodifiable(cases);

  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async =>
      cases.where((c) => c.patientId == patientId).toList();

  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async =>
      cases.where((c) => c.requirementId == requirementId).toList();

  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async {
    lastAddedCase = caseRecord;
    cases.add(caseRecord);
  }

  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {
    lastUpdatedCase = caseRecord;
    final index = cases.indexWhere((c) => c.id == caseRecord.id);
    if (index != -1) {
      cases[index] = caseRecord;
    } else {
      cases.add(caseRecord);
    }
  }

  @override
  Future<void> deleteCaseRecord(String id) async {
    cases.removeWhere((c) => c.id == id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPatient1 = Patient(
    id: 'pt-001',
    name: 'Zayd Ali',
    age: 28,
    gender: 'Male',
    phoneNumber: '+967-771111111',
    medicalHistory: 'Asthma',
    createdAt: DateTime(2026, 8, 1),
  );

  final testPatient2 = Patient(
    id: 'pt-002',
    name: 'Amal Omar',
    age: 22,
    gender: 'Female',
    phoneNumber: '+967-772222222',
    medicalHistory: 'Penicillin allergy',
    createdAt: DateTime(2026, 8, 15),
  );

  final testClinic = const Clinic(
    id: 'clinic-prosth',
    name: 'Prosthodontics',
    academicYear: '5th Year',
    colorHex: '#003E6F',
  );

  final testRequirement = const Requirement(
    id: 'req-cd',
    clinicId: 'clinic-prosth',
    title: 'Complete Denture',
    targetCount: 5,
    completedCount: 2,
  );

  final testCaseRecord = CaseRecord(
    id: 'case-101',
    patientId: 'pt-001',
    requirementId: 'req-cd',
    status: 'In Progress',
    notes: 'Initial impressions taken.',
    dateStarted: DateTime(2026, 8, 10),
  );

  group('Patients Actions and Modals Unit & Widget Tests', () {
    late MockPatientRepository mockPatientRepo;
    late MockClinicRepository mockClinicRepo;
    late MockRequirementRepository mockRequirementRepo;
    late MockCaseRecordRepository mockCaseRepo;

    setUp(() {
      mockPatientRepo = MockPatientRepository([testPatient1, testPatient2]);
      mockClinicRepo = MockClinicRepository([testClinic]);
      mockRequirementRepo = MockRequirementRepository([testRequirement]);
      mockCaseRepo = MockCaseRecordRepository([testCaseRecord]);
    });

    List<Override> buildOverrides() {
      return [
        patientRepositoryProvider.overrideWithValue(mockPatientRepo),
        clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
        requirementRepositoryProvider.overrideWithValue(mockRequirementRepo),
        caseRecordRepositoryProvider.overrideWithValue(mockCaseRepo),
      ];
    }

    testWidgets('SortPatientsModal opens, displays options, and mutates patientSortOptionProvider', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => SortPatientsModal.show(context),
                    child: const Text('Open Sort'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Sort'));
      await tester.pumpAndSettle();

      expect(find.text('Sort Patients'), findsOneWidget);
      expect(find.text('Name (A to Z)'), findsOneWidget);
      expect(find.text('Date Added (Recent first)'), findsOneWidget);
      expect(find.text('Active Case Count'), findsOneWidget);

      // Tap 'Name (A to Z)'
      await tester.tap(find.text('Name (A to Z)'));
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.text('Sort Patients'), findsNothing);
    });

    testWidgets('PatientsScreen sort button opens SortPatientsModal and sorts list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PatientsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patients'), findsOneWidget);

      // Tap sort button in AppBar
      final sortButton = find.byTooltip('Sort Patients');
      expect(sortButton, findsOneWidget);
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      expect(find.text('Sort Patients'), findsOneWidget);

      // Tap Name (A to Z)
      await tester.tap(find.text('Name (A to Z)'));
      await tester.pumpAndSettle();

      expect(find.text('Sort Patients'), findsNothing);
      expect(find.text('Amal Omar'), findsOneWidget);
      expect(find.text('Zayd Ali'), findsOneWidget);
    });

    testWidgets('EditPatientModal pre-populates patient details and saves updates to repository', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Patient? callbackUpdated;

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => EditPatientModal.show(
                      context,
                      patient: testPatient1,
                      onPatientUpdated: (p) => callbackUpdated = p,
                    ),
                    child: const Text('Edit Patient'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit Patient'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Patient Profile'), findsOneWidget);
      expect(find.text('Zayd Ali'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('+967-771111111'), findsOneWidget);
      expect(find.text('Asthma'), findsOneWidget);

      // Change name and age
      await tester.enterText(find.widgetWithText(TextFormField, 'Zayd Ali'), 'Zayd Ali Al-Hemyari');
      await tester.enterText(find.widgetWithText(TextFormField, '28'), '29');
      await tester.pump();

      // Submit
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Patient Profile'), findsNothing);
      expect(mockPatientRepo.lastUpdatedPatient, isNotNull);
      expect(mockPatientRepo.lastUpdatedPatient!.name, 'Zayd Ali Al-Hemyari');
      expect(mockPatientRepo.lastUpdatedPatient!.age, 29);
      expect(callbackUpdated?.name, 'Zayd Ali Al-Hemyari');
    });

    testWidgets('LogCaseRecordModal allows selecting clinic and requirement and adds case to repository', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      CaseRecord? loggedCase;

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => LogCaseRecordModal.show(
                      context,
                      patientId: testPatient1.id,
                      patientName: testPatient1.name,
                      onCaseLogged: (c) => loggedCase = c,
                    ),
                    child: const Text('Log Case'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Log Case'));
      await tester.pumpAndSettle();

      expect(find.text('Log Clinical Case'), findsOneWidget);
      expect(find.textContaining('Zayd Ali'), findsOneWidget);

      // Verify cascaded dropdowns loaded
      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.textContaining('Complete Denture'), findsOneWidget);

      // Add notes in notes text field
      final notesField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText?.contains('Primary impression') == true,
      );
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, 'Special tray fabrication.');
      await tester.pump();

      // Submit
      await tester.tap(find.text('Log Case Record'));
      await tester.pumpAndSettle();

      expect(find.text('Log Clinical Case'), findsNothing);
      expect(mockCaseRepo.lastAddedCase, isNotNull);
      expect(mockCaseRepo.lastAddedCase!.patientId, testPatient1.id);
      expect(mockCaseRepo.lastAddedCase!.requirementId, testRequirement.id);
      expect(loggedCase, isNotNull);
    });

    testWidgets('EvaluateCaseModal allows updating status, score, notes, and persists changes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      CaseRecord? evaluatedCase;

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => EvaluateCaseModal.show(
                      context,
                      caseRecord: testCaseRecord,
                      patientName: testPatient1.name,
                      onCaseEvaluated: (c) => evaluatedCase = c,
                    ),
                    child: const Text('Evaluate Case'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Evaluate Case'));
      await tester.pumpAndSettle();

      expect(find.text('Evaluate Case Record'), findsOneWidget);
      expect(find.textContaining('Zayd Ali'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);

      // Select 'Evaluated' status chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Evaluated'));
      await tester.pumpAndSettle();

      // Enter Grade
      final gradeFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText?.contains('9.0/10') == true,
      );
      expect(gradeFinder, findsOneWidget);
      await tester.enterText(gradeFinder, '9.5/10');
      await tester.pump();

      // Submit evaluation
      await tester.tap(find.text('Save Evaluation'));
      await tester.pumpAndSettle();

      expect(find.text('Evaluate Case Record'), findsNothing);
      expect(mockCaseRepo.lastUpdatedCase, isNotNull);
      expect(mockCaseRepo.lastUpdatedCase!.status, 'Evaluated');
      expect(mockCaseRepo.lastUpdatedCase!.notes, contains('Grade: 9.5/10'));
      expect(mockCaseRepo.lastUpdatedCase!.dateCompleted, isNotNull);
      expect(evaluatedCase?.status, 'Evaluated');
    });

    testWidgets('PatientCaseSheetScreen wires edit button, FAB, and CaseRecordCard taps', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: PatientCaseSheetScreen(patient: testPatient1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Edit button in AppBar
      final editButton = find.byTooltip('Edit Patient');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Edit Patient Profile'), findsOneWidget);
      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // 2. FAB opens LogCaseRecordModal
      final fab = find.byTooltip('Log Case Record');
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Log Clinical Case'), findsOneWidget);
      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // 3. CaseRecordCard opens EvaluateCaseModal
      expect(find.byType(CaseRecordCard), findsOneWidget);
      await tester.tap(find.byType(CaseRecordCard));
      await tester.pumpAndSettle();

      expect(find.text('Evaluate Case Record'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Evaluate Case Record'), findsNothing);
    });
  });
}
