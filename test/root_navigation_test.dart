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

  final overrides = [
    dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
    upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
    patientListProvider.overrideWith((ref) => dummyPatients),
    allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
    allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
    clinicListProvider.overrideWith((ref) => <Clinic>[]),
  ];

  group('RootNavigationScreen Widget Tests', () {
    testWidgets('Renders all 5 BottomNavigationBar items and switches tabs via tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
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

    testWidgets('PageView with AutomaticKeepAliveClientMixin preserves state across tab navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
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

      // Verified search state was preserved via AutomaticKeepAliveClientMixin
      expect(find.text('Omar Khalid'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsNothing);
    });

    testWidgets('Horizontal drag gestures swipe smoothly between adjacent tabs and update provider', (WidgetTester tester) async {
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RootNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially at tab 0 (Dashboard)
      expect(container.read(rootNavigationIndexProvider), 0);
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Swipe Left to advance from Dashboard (0) to Clinics (1)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 1);
      expect(find.byType(ClinicsScreen), findsOneWidget);

      // Swipe Left to advance from Clinics (1) to Patients (2)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 2);
      expect(find.byType(PatientsScreen), findsOneWidget);

      // Swipe Right to return from Patients (2) to Clinics (1)
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 1);
      expect(find.byType(ClinicsScreen), findsOneWidget);

      // Swipe Right to return from Clinics (1) to Dashboard (0)
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 0);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('RTL directionality naturally reverses horizontal swipe navigation', (WidgetTester tester) async {
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: RootNavigationScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially at tab 0 in RTL mode
      expect(container.read(rootNavigationIndexProvider), 0);
      expect(find.byType(DashboardScreen), findsOneWidget);

      // In RTL, dragging right (positive X) advances to next page (1: Clinics)
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 1);
      expect(find.byType(ClinicsScreen), findsOneWidget);

      // In RTL, dragging left (negative X) returns to previous page (0: Dashboard)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 0);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Programmatic navigation updates PageController smoothly', (WidgetTester tester) async {
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RootNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Programmatically jump to Profile tab (index 4)
      container.read(rootNavigationIndexProvider.notifier).state = 4;
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);

      // Programmatically jump to Schedule tab (index 3)
      container.read(rootNavigationIndexProvider.notifier).state = 3;
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentsScreen), findsOneWidget);
    });
  });
}
