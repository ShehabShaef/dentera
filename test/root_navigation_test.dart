import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/appointments/appointments_screen.dart';
import 'package:dentera/presentation/screens/clinics/clinics_screen.dart';
import 'package:dentera/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:dentera/presentation/screens/patients/patients_screen.dart';
import 'package:dentera/presentation/screens/profile/profile_screen.dart';
import 'package:dentera/presentation/screens/root_navigation_screen.dart';

import 'package:dentera/presentation/state/state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Shehab Shaif',
      'academicYear': '5th Year',
      'university': "University of Sana'a",
      'hasCompletedOnboarding': true,
    });
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

  group('RootNavigationScreen Widget Tests', () {
    testWidgets('Renders all 5 BottomNavigationBar items and switches tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
            upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
            patientListProvider.overrideWith((ref) => dummyPatients),
            allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
            clinicListProvider.overrideWith((ref) => <Clinic>[]),
          ],
          child: const MaterialApp(
            home: RootNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check BottomNavigationBar items
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Clinics'), findsOneWidget);
      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Check default active screen is DashboardScreen
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Switch to Clinics tab (Index 1)
      await tester.tap(find.text('Clinics'));
      await tester.pumpAndSettle();
      expect(find.byType(ClinicsScreen), findsOneWidget);

      // Switch to Patients tab (Index 2)
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientsScreen), findsOneWidget);

      // Switch to Schedule tab (Index 3)
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentsScreen), findsOneWidget);

      // Switch to Profile tab (Index 4)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Switch back to Dashboard (Index 0)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('IndexedStack preserves state when switching away and returning', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
            upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
            patientListProvider.overrideWith((ref) => dummyPatients),
            allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
            clinicListProvider.overrideWith((ref) => <Clinic>[]),
          ],
          child: const MaterialApp(
            home: RootNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Patients tab (Index 2)
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Enter search filter
      await tester.enterText(find.byType(TextField), 'Omar');
      await tester.pumpAndSettle();

      expect(find.text('Omar Khalid'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsNothing);

      // Switch to Schedule tab (Index 3)
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentsScreen), findsOneWidget);

      // Switch back to Patients tab (Index 2)
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Verified search state was preserved via IndexedStack
      expect(find.text('Omar Khalid'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsNothing);
    });
  });
}
