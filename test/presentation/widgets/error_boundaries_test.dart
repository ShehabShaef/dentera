import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/error/app_exceptions.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/repositories.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/dentera_error_widget.dart';
import 'package:dentera/presentation/widgets/dentera_snackbar.dart';
import 'package:dentera/presentation/widgets/inputs/dentera_text_field.dart';
import 'package:dentera/presentation/widgets/modals/add_patient_modal.dart';

class _LockedPatientRepo implements PatientRepository {
  @override
  Future<void> addPatient(Patient patient) async {
    throw const DatabaseLockedException(
      'SQLite database is locked: concurrent transaction contention',
    );
  }

  @override
  Future<void> deletePatient(String id) async {}

  @override
  Future<List<Patient>> getAllPatients() async => [];

  @override
  Future<Patient?> getPatientById(String id) async => null;

  @override
  Future<void> updatePatient(Patient patient) async {}
}

class _StubCaseRecordRepo implements CaseRecordRepository {
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

class _StubClinicRepo implements ClinicRepository {
  @override
  Future<void> addClinic(Clinic clinic) async {}
  @override
  Future<List<Clinic>> getAllClinics() async => [];
  @override
  Future<Clinic?> getClinicById(String id) async => null;
}

class _StubRequirementRepo implements RequirementRepository {
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
  group('DenteraErrorWidget Unit & Widget Tests', () {
    testWidgets('renders headline, descriptive message, and error icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DenteraErrorWidget(
              title: 'Clinics Unavailable',
              message: 'Unable to connect to local database storage.',
            ),
          ),
        ),
      );

      expect(find.byType(DenteraErrorWidget), findsOneWidget);
      expect(find.text('Clinics Unavailable'), findsOneWidget);
      expect(find.text('Unable to connect to local database storage.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('derives user-friendly message for DatabaseLockedException when message is omitted', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DenteraErrorWidget(
              title: 'Database Busy',
              error: DatabaseLockedException(),
            ),
          ),
        ),
      );

      expect(find.text('Database Busy'), findsOneWidget);
      expect(
        find.text('The local database is currently locked or busy. Please tap retry.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('executes onRetry callback when retry button is tapped', (WidgetTester tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DenteraErrorWidget(
              title: 'Failed to load',
              message: 'Please try again.',
              onRetry: () => retryTriggered = true,
              retryLabel: 'Try Again',
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(retryTriggered, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders compact card layout correctly without layout overflow', (WidgetTester tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 200,
              child: DenteraErrorWidget(
                isCompact: true,
                title: 'Quota Stats Error',
                message: 'Could not calculate progress.',
                onRetry: () => retryTriggered = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Quota Stats Error'), findsOneWidget);
      expect(find.text('Could not calculate progress.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(retryTriggered, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('DenteraSnackBar Global Utility Tests', () {
    testWidgets('renders error snackbar with formatted DatabaseLockedException message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    DenteraSnackBar.showError(
                      context,
                      message: 'Action Failed',
                      error: const DatabaseLockedException(),
                    );
                  },
                  child: const Text('Trigger SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger SnackBar'));
      await tester.pump(); // Start animation

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Action Failed: Database is locked or busy. Please retry.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Simulated Integration: Form Mutation Exception Boundary', () {
    testWidgets('gracefully catches DatabaseLockedException on form submit and displays error SnackBar without crashing', (WidgetTester tester) async {
      Patient? addedPatient;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientRepositoryProvider.overrideWithValue(_LockedPatientRepo()),
            caseRecordRepositoryProvider.overrideWithValue(_StubCaseRecordRepo()),
            clinicRepositoryProvider.overrideWithValue(_StubClinicRepo()),
            requirementRepositoryProvider.overrideWithValue(_StubRequirementRepo()),
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
                        onPatientAdded: (patient) => addedPatient = patient,
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

      // 1. Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('New Patient'), findsOneWidget);

      // 2. Fill required inputs with valid data
      await tester.enterText(
        find.widgetWithText(DenteraTextField, 'Patient Name *'),
        'Amira Khaled',
      );
      await tester.enterText(
        find.widgetWithText(DenteraTextField, 'Age *'),
        '30',
      );
      await tester.pumpAndSettle();

      // 3. Tap Save Patient to trigger imperative submission
      await tester.tap(find.text('Save Patient'));
      await tester.pump(); // Process the microtask and trigger SnackBar

      // 4. Assert that ScaffoldMessenger rendered DenteraSnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Failed to register patient: Database is locked or busy. Please retry.'),
        findsOneWidget,
      );

      // 5. Assert that the modal is still open and test framework did not crash
      expect(find.text('New Patient'), findsOneWidget);
      expect(addedPatient, isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
