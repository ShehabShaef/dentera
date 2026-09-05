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
  Future<List<Patient>> getAllPatients() async => [];
  @override
  Future<Patient?> getPatientById(String id) async => null;
  @override
  Future<void> updatePatient(Patient patient) async {}
}

class _FakeCaseRecordRepo implements CaseRecordRepository {
  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async {}
  @override
  Future<void> deleteCaseRecord(String id) async {}
  @override
  Future<List<CaseRecord>> getAllCaseRecords() async => [];
  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async => [];
  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async => [];
  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {}
}

class _FakeClinicRepo implements ClinicRepository {
  @override
  Future<void> addClinic(Clinic clinic) async {}
  @override
  Future<List<Clinic>> getAllClinics() async => [];
  @override
  Future<Clinic?> getClinicById(String id) async => null;
}

class _FakeRequirementRepo implements RequirementRepository {
  @override
  Future<void> addRequirement(Requirement requirement) async {}
  @override
  Future<List<Requirement>> getAllRequirements() async => [];
  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async => [];
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
  });
}
