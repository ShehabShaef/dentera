import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/patients/patients_screen.dart';
import 'package:dentera/presentation/screens/patients/widgets/widgets.dart';
import 'package:dentera/presentation/state/state.dart';

void main() {
  group('Patients Roster Screen Widget Tests', () {
    testWidgets('PatientListCard renders patient details and handles onTap', (WidgetTester tester) async {
      bool tapped = false;
      final patient = Patient(
        id: 'PT-1001',
        name: 'Sara Ahmed',
        age: 23,
        gender: 'Female',
        phoneNumber: '+967-771234567',
        medicalHistory: 'None',
        createdAt: DateTime.parse('2026-08-20T10:00:00.000Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PatientListCard(
              patient: patient,
              subtitle: 'Next Appt: Tomorrow, 09:00 AM',
              tags: const <String>['Endo - Tooth 46', 'Pending Sign-off'],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Sara Ahmed'), findsOneWidget);
      expect(find.text('SA'), findsOneWidget);
      expect(find.text('Next Appt: Tomorrow, 09:00 AM'), findsOneWidget);
      expect(find.text('Endo - Tooth 46'), findsOneWidget);
      expect(find.text('Pending Sign-off'), findsOneWidget);

      await tester.tap(find.text('Sara Ahmed'));
      expect(tapped, isTrue);
    });

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
      Patient(
        id: 'PT-1002',
        name: 'Omar Khalid',
        age: 45,
        gender: 'Male',
        phoneNumber: '+967-772345678',
        medicalHistory: 'Hypertension',
        createdAt: DateTime.parse('2026-08-22T14:30:00.000Z'),
      ),
    ];

    testWidgets('PatientsScreen renders search bar, filter chips, and roster', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => dummyPatients),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: const MaterialApp(
            home: PatientsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('Search by name or phone...'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active Cases'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      expect(find.text('Omar Khalid'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('PatientsScreen filters roster on search and shows zero state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => dummyPatients),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: const MaterialApp(
            home: PatientsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search for specific patient
      await tester.enterText(find.byType(TextField), 'Omar');
      await tester.pumpAndSettle();

      expect(find.text('Omar Khalid'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsNothing);

      // Search for non-existent patient
      await tester.enterText(find.byType(TextField), 'NonExistentPatientXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No patients found'), findsOneWidget);
      expect(find.text('No patient records match "NonExistentPatientXYZ".'), findsOneWidget);
    });

    testWidgets('PatientsScreen changes filter category on pill tap', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          patientListProvider.overrideWith((ref) async => dummyPatients),
          allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
          allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          clinicListProvider.overrideWith((ref) async => <Clinic>[]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PatientsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(container.read(patientFilterCategoryProvider), 'All');

      await tester.tap(find.text('Active Cases'));
      await tester.pumpAndSettle();

      expect(container.read(patientFilterCategoryProvider), 'Active Cases');
      // With no cases, zero state is shown for Active Cases
      expect(find.text('No patients found under "Active Cases".'), findsOneWidget);
    });
  });
}
