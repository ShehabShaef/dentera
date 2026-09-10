import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/repositories/repositories.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

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

class _FakeCaseRecordRepo implements CaseRecordRepository {
  final List<CaseRecord> savedCases = [];
  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async {
    savedCases.add(caseRecord);
  }
  @override
  Future<void> deleteCaseRecord(String id) async {}
  @override
  Future<List<CaseRecord>> getAllCaseRecords() async => savedCases;
  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async =>
      savedCases.where((c) => c.patientId == patientId).toList();
  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async =>
      savedCases.where((c) => c.requirementId == requirementId).toList();
  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {}
}

class _FakeClinicRepo implements ClinicRepository {
  _FakeClinicRepo([List<Clinic>? clinics]) : clinics = clinics ?? [];
  final List<Clinic> clinics;
  @override
  Future<void> addClinic(Clinic clinic) async => clinics.add(clinic);
  @override
  Future<void> deleteClinic(String id) async => clinics.removeWhere((c) => c.id == id);
  @override
  Future<void> deleteClinics(List<String> ids) async => clinics.removeWhere((c) => ids.contains(c.id));
  @override
  Future<List<Clinic>> getAllClinics() async => clinics;
  @override
  Future<Clinic?> getClinicById(String id) async {
    return clinics.cast<Clinic?>().firstWhere((c) => c?.id == id, orElse: () => null);
  }
}

class _FakeRequirementRepo implements RequirementRepository {
  _FakeRequirementRepo([List<Requirement>? requirements])
      : requirements = requirements ?? [];
  final List<Requirement> requirements;
  @override
  Future<void> addRequirement(Requirement requirement) async => requirements.add(requirement);
  @override
  Future<List<Requirement>> getAllRequirements() async => requirements;
  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async {
    return requirements.where((r) => r.clinicId == clinicId).toList();
  }
  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}
}

void main() {
  group('AddPatientModal Widget Tests', () {
    testWidgets('AddPatientModal renders form inputs and enforces validation', (WidgetTester tester) async {
      Patient? createdPatient;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientRepositoryProvider.overrideWithValue(_FakePatientRepo()),
            caseRecordRepositoryProvider.overrideWithValue(_FakeCaseRecordRepo()),
            clinicRepositoryProvider.overrideWithValue(_FakeClinicRepo()),
            requirementRepositoryProvider.overrideWithValue(_FakeRequirementRepo()),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AddPatientModal.show(
                        context,
                        onPatientAdded: (patient) => createdPatient = patient,
                      );
                    },
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('New Patient'), findsOneWidget);
      expect(find.text('Patient Name *'), findsOneWidget);
      expect(find.text('Age *'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Assign to Clinic'), findsOneWidget);
      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.text('Save Patient'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Save Patient without filling form -> Validation triggers
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the patient name'), findsOneWidget);
      expect(find.text('Enter age'), findsOneWidget);
      expect(createdPatient, isNull);

      // Fill in Name and Age
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Patient Name *'), 'Layla Al-Yamani');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Age *'), '28');
      await tester.pumpAndSettle();

      // Expand Optional Details
      await tester.tap(find.text('Add Contact & Details (Optional)'));
      await tester.pumpAndSettle();

      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Medical History / Allergies'), findsOneWidget);

      await tester.enterText(find.widgetWithText(DenteraTextField, 'Phone Number'), '+967-771122334');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Medical History / Allergies'), 'No known drug allergies');
      await tester.pumpAndSettle();

      // Tap Save Patient
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('New Patient'), findsNothing);

      // Patient was created properly
      expect(createdPatient, isNotNull);
      expect(createdPatient!.id, isNotNull);
      expect(createdPatient!.id.length, 36);
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
      expect(uuidRegex.hasMatch(createdPatient!.id), isTrue);
      expect(createdPatient!.name, 'Layla Al-Yamani');
      expect(createdPatient!.age, 28);
      expect(createdPatient!.gender, 'Male');
      expect(createdPatient!.phoneNumber, '+967-771122334');
      expect(createdPatient!.medicalHistory, 'No known drug allergies');
    });

    testWidgets('AddPatientModal rejects negative age inputs and blocks submission', (WidgetTester tester) async {
      Patient? createdPatient;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientRepositoryProvider.overrideWithValue(_FakePatientRepo()),
            caseRecordRepositoryProvider.overrideWithValue(_FakeCaseRecordRepo()),
            clinicRepositoryProvider.overrideWithValue(_FakeClinicRepo()),
            requirementRepositoryProvider.overrideWithValue(_FakeRequirementRepo()),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AddPatientModal.show(
                        context,
                        onPatientAdded: (patient) => createdPatient = patient,
                      );
                    },
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Enter valid name, but negative age
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Patient Name *'), 'Invalid Age Patient');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Age *'), '-5');
      await tester.pumpAndSettle();

      // Tap Save Patient
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      // Assert error message is displayed
      expect(find.text('Cannot be negative'), findsOneWidget);
      // Assert modal remains open and no patient was created
      expect(find.text('New Patient'), findsOneWidget);
      expect(createdPatient, isNull);
    });

    testWidgets('AddPatientModal enforces mandatory Main Case selection and binds explicitly chosen requirement',
        (WidgetTester tester) async {
      const clinic1 = Clinic(
        id: 'clinic-prosth',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      );
      const clinic2 = Clinic(
        id: 'clinic-endo',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#2E3F50',
      );

      const reqProsth1 = Requirement(
        id: 'req-prosth-cd',
        clinicId: 'clinic-prosth',
        title: 'Complete Denture',
        targetCount: 4,
        completedCount: 1,
      );
      const reqProsth2 = Requirement(
        id: 'req-prosth-rpd',
        clinicId: 'clinic-prosth',
        title: 'Removable Partial Denture',
        targetCount: 2,
        completedCount: 0,
      );

      final patientRepo = _FakePatientRepo();
      final caseRepo = _FakeCaseRecordRepo();
      final clinicRepo = _FakeClinicRepo([clinic1, clinic2]);
      final reqRepo = _FakeRequirementRepo([reqProsth1, reqProsth2]);

      Patient? createdPatient;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientRepositoryProvider.overrideWithValue(patientRepo),
            caseRecordRepositoryProvider.overrideWithValue(caseRepo),
            clinicRepositoryProvider.overrideWithValue(clinicRepo),
            requirementRepositoryProvider.overrideWithValue(reqRepo),
            clinicListProvider.overrideWith((ref) async => [clinic1, clinic2]),
            requirementsByClinicProvider('clinic-prosth')
                .overrideWith((ref) async => [reqProsth1, reqProsth2]),
            requirementsByClinicProvider('clinic-endo')
                .overrideWith((ref) async => <Requirement>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AddPatientModal.show(
                      context,
                      onPatientAdded: (p) => createdPatient = p,
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify Main Case / Procedure dropdown is present
      expect(find.text('Main Case / Procedure'), findsOneWidget);
      expect(find.text('Select main case / procedure'), findsOneWidget);

      // Fill in Name and Age
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Patient Name *'), 'Ahmed Tariq');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Age *'), '30');
      await tester.pumpAndSettle();

      // Attempt to save without selecting Main Case -> Validation fails
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a main case / procedure'), findsOneWidget);
      expect(createdPatient, isNull);
      expect(caseRepo.savedCases, isEmpty);

      // Explicitly select the SECOND requirement (Removable Partial Denture) instead of first
      await tester.tap(find.text('Select main case / procedure'));
      await tester.pumpAndSettle();

      expect(find.text('Complete Denture (1/4)'), findsWidgets);
      expect(find.text('Removable Partial Denture (0/2)'), findsWidgets);

      await tester.tap(find.text('Removable Partial Denture (0/2)').last);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      // Modal is dismissed and patient is registered
      expect(find.text('New Patient'), findsNothing);
      expect(createdPatient, isNotNull);
      expect(createdPatient!.name, 'Ahmed Tariq');

      // Assert CaseRecord was created with explicitly chosen requirement (req-prosth-rpd), not first
      expect(caseRepo.savedCases.length, 1);
      final initialCase = caseRepo.savedCases.first;
      expect(initialCase.patientId, createdPatient!.id);
      expect(initialCase.requirementId, 'req-prosth-rpd');
      expect(initialCase.status, 'In Progress');
    });

    testWidgets('Switching clinic dynamically loads clinic requirements and resets requirement selection',
        (WidgetTester tester) async {
      const clinic1 = Clinic(
        id: 'clinic-prosth',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      );
      const clinic2 = Clinic(
        id: 'clinic-endo',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#2E3F50',
      );

      const reqProsth1 = Requirement(
        id: 'req-prosth-cd',
        clinicId: 'clinic-prosth',
        title: 'Complete Denture',
        targetCount: 4,
        completedCount: 1,
      );
      const reqEndo1 = Requirement(
        id: 'req-endo-anterior',
        clinicId: 'clinic-endo',
        title: 'Anterior RCT',
        targetCount: 3,
        completedCount: 1,
      );

      final patientRepo = _FakePatientRepo();
      final caseRepo = _FakeCaseRecordRepo();
      final clinicRepo = _FakeClinicRepo([clinic1, clinic2]);
      final reqRepo = _FakeRequirementRepo([reqProsth1, reqEndo1]);

      Patient? createdPatient;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientRepositoryProvider.overrideWithValue(patientRepo),
            caseRecordRepositoryProvider.overrideWithValue(caseRepo),
            clinicRepositoryProvider.overrideWithValue(clinicRepo),
            requirementRepositoryProvider.overrideWithValue(reqRepo),
            clinicListProvider.overrideWith((ref) async => [clinic1, clinic2]),
            requirementsByClinicProvider('clinic-prosth')
                .overrideWith((ref) async => [reqProsth1]),
            requirementsByClinicProvider('clinic-endo')
                .overrideWith((ref) async => [reqEndo1]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AddPatientModal.show(
                      context,
                      onPatientAdded: (p) => createdPatient = p,
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Fill in Name and Age
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Patient Name *'), 'Fatima Ali');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Age *'), '25');
      await tester.pumpAndSettle();

      // Select Prosthodontics requirement
      await tester.tap(find.text('Select main case / procedure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Denture (1/4)').last);
      await tester.pumpAndSettle();

      // Switch clinic to Endodontics
      await tester.tap(find.text('Endodontics'));
      await tester.pumpAndSettle();

      // Requirement selection must be reset to hint
      expect(find.text('Select main case / procedure'), findsOneWidget);

      // Open dropdown -> Now only contains Endodontics requirements
      await tester.tap(find.text('Select main case / procedure'));
      await tester.pumpAndSettle();

      expect(find.text('Anterior RCT (1/3)'), findsWidgets);
      expect(find.text('Complete Denture (1/4)'), findsNothing);

      // Select Endodontics requirement
      await tester.tap(find.text('Anterior RCT (1/3)').last);
      await tester.pumpAndSettle();

      // Save Patient
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      expect(createdPatient, isNotNull);
      expect(caseRepo.savedCases.length, 1);
      expect(caseRepo.savedCases.first.requirementId, 'req-endo-anterior');
    });
  });
}
