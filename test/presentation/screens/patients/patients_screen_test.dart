import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/patient_repository.dart';
import 'package:dentera/presentation/screens/patients/patients_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  group('PatientsScreen Zero State Widget Tests', () {
    final dummyPatients = <Patient>[
      Patient(
        id: 'PT-1001',
        name: 'Sara Ahmed',
        age: 23,
        gender: 'Female',
        phoneNumber: '+967-771234567',
        medicalHistory: 'No known allergies',
        createdAt: DateTime.parse('2026-08-20T10:00:00.000Z'),
      ),
    ];

    testWidgets('PatientsScreen renders DenteraEmptyState with action button when patientListProvider emits empty array',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => <Patient>[]),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PatientsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert that unified zero state component renders
      expect(find.byType(DenteraEmptyState), findsOneWidget);

      // Assert text content
      expect(find.text('No patients found'), findsOneWidget);
      expect(
        find.text('Add your first patient to start tracking clinical requirements.'),
        findsOneWidget,
      );
      expect(find.text('Add First Patient'), findsOneWidget);

      // Verify no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('PatientsScreen renders DenteraEmptyState when search query matches zero records',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => dummyPatients),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PatientsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query that has no match
      await tester.enterText(find.byType(TextField), 'NonExistentPatient');
      await tester.pumpAndSettle();

      // Assert unified zero state component renders
      expect(find.byType(DenteraEmptyState), findsOneWidget);
      expect(find.text('No patients found'), findsOneWidget);
      expect(find.text('No patient records match "NonExistentPatient".'), findsOneWidget);

      // Verify no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('PatientsScreen Multi-Select Batch Deletion Tests', () {
    late FakePatientRepository fakeRepo;
    final testPatients = <Patient>[
      Patient(
        id: 'PT-1001',
        name: 'Sara Ahmed',
        age: 23,
        gender: 'Female',
        phoneNumber: '+967-771234567',
        medicalHistory: 'No known allergies',
        createdAt: DateTime.parse('2026-08-20T10:00:00.000Z'),
      ),
      Patient(
        id: 'PT-1002',
        name: 'Bilal Salem',
        age: 30,
        gender: 'Male',
        phoneNumber: '+967-777654321',
        medicalHistory: 'Hypertension',
        createdAt: DateTime.parse('2026-08-21T10:00:00.000Z'),
      ),
    ];

    setUp(() {
      fakeRepo = FakePatientRepository(List.from(testPatients));
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          patientRepositoryProvider.overrideWithValue(fakeRepo),
          patientListProvider.overrideWith((ref) async => fakeRepo.getAllPatients()),
          allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
          allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          upcomingAppointmentsProvider.overrideWith((ref) async => <Appointment>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PatientsScreen(),
        ),
      );
    }

    testWidgets('3-dots menu displays Sort Patients and Delete Patients options',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 3-dots popup menu
      final popupFinder = find.byType(PopupMenuButton<String>);
      expect(popupFinder, findsOneWidget);
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      // Assert popup items
      expect(find.text('Sort Patients'), findsOneWidget);
      expect(find.text('Delete Patients'), findsOneWidget);
    });

    testWidgets('Selecting Sort Patients opens SortPatientsModal with sort options',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open popup and select Sort Patients
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort Patients'));
      await tester.pumpAndSettle();

      // Assert SortPatientsModal options
      expect(find.byType(SortPatientsModal), findsOneWidget);
      expect(find.text('Name (A to Z)'), findsOneWidget);
      expect(find.text('Date Added (Recent first)'), findsOneWidget);
      expect(find.text('Active Case Count'), findsOneWidget);
    });

    testWidgets('Selecting Delete Patients enters selection mode with contextual action bar and checkboxes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open popup and select Delete Patients
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Patients'));
      await tester.pumpAndSettle();

      // Contextual action bar assertions
      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Delete (0)'), findsOneWidget);

      // FAB is hidden in selection mode
      expect(find.byType(FloatingActionButton), findsNothing);

      // Checkboxes appear for each patient card
      expect(find.byType(CircularCheckbox), findsNWidgets(2));
    });

    testWidgets('Tapping patient card toggles selection and updates count',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Patients'));
      await tester.pumpAndSettle();

      // Tap first patient card
      await tester.tap(find.text('Sara Ahmed'));
      await tester.pumpAndSettle();

      expect(find.text('1 Selected'), findsOneWidget);
      expect(find.text('Delete (1)'), findsOneWidget);

      // Tap again to unselect
      await tester.tap(find.text('Sara Ahmed'));
      await tester.pumpAndSettle();

      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Delete (0)'), findsOneWidget);
    });

    testWidgets('Tapping Select All selects all patients and toggles to Deselect All',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Patients'));
      await tester.pumpAndSettle();

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      expect(find.text('2 Selected'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);
      expect(find.text('Delete (2)'), findsOneWidget);

      // Tap Deselect All
      await tester.tap(find.text('Deselect All'));
      await tester.pumpAndSettle();

      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Delete (0)'), findsOneWidget);
    });

    testWidgets('Tapping Cancel exits selection mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Patients'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert normal state restored
      expect(find.text('Patients'), findsOneWidget);
      expect(find.byType(CircularCheckbox), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Batch deletion confirmation modal warns about cascade deletion and deletes selected patients',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Patients'));
      await tester.pumpAndSettle();

      // Select first patient
      await tester.tap(find.text('Sara Ahmed'));
      await tester.pumpAndSettle();

      // Tap Delete (1)
      await tester.tap(find.text('Delete (1)'));
      await tester.pumpAndSettle();

      // Safety warning dialog asserts
      expect(find.text('Delete Selected Patients?'), findsOneWidget);
      expect(
        find.textContaining('permanently remove all associated clinical case records and scheduled appointments'),
        findsOneWidget,
      );

      // Tap Delete in dialog
      final deleteConfirmButton = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(deleteConfirmButton);
      await tester.pumpAndSettle();

      // Verify repository execution
      expect(fakeRepo.lastDeletedPatientIds, ['PT-1001']);
      expect(fakeRepo.patients.length, 1);
      expect(fakeRepo.patients.first.id, 'PT-1002');

      // Assert selection mode exited
      expect(find.text('Patients'), findsOneWidget);
    });
  });
}

class FakePatientRepository implements PatientRepository {
  final List<Patient> patients;
  List<String> lastDeletedPatientIds = [];

  FakePatientRepository(this.patients);

  @override
  Future<void> addPatient(Patient patient) async => patients.add(patient);

  @override
  Future<List<Patient>> getAllPatients() async => patients;

  @override
  Future<Patient?> getPatientById(String id) async =>
      patients.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> updatePatient(Patient patient) async {
    final idx = patients.indexWhere((p) => p.id == patient.id);
    if (idx != -1) patients[idx] = patient;
  }

  @override
  Future<void> deletePatient(String id) async {
    lastDeletedPatientIds = [id];
    patients.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> deletePatients(List<String> ids) async {
    lastDeletedPatientIds = List.from(ids);
    patients.removeWhere((p) => ids.contains(p.id));
  }
}

