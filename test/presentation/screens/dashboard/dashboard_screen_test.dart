import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/widgets.dart';
import 'package:dentera/presentation/screens/patients/patient_case_sheet_screen.dart';
import 'package:dentera/presentation/state/state.dart';

/// Test navigator observer to capture push transitions and inspect routes.
class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Shehab',
      'academicYear': '5th Year',
      'university': "University of Sana'a",
      'hasCompletedOnboarding': true,
    });
  });

  final dummyPatients = <Patient>[
    Patient(
      id: 'PT-2049',
      name: 'Ali Nasser',
      age: 45,
      gender: 'Male',
      phoneNumber: '+967-771122334',
      medicalHistory: 'None',
      createdAt: DateTime.parse('2026-08-20T10:00:00.000Z'),
    ),
    Patient(
      id: 'PT-1001',
      name: 'Sara Ahmed',
      age: 23,
      gender: 'Female',
      phoneNumber: '+967-771234567',
      medicalHistory: 'No allergies',
      createdAt: DateTime.parse('2026-08-20T10:00:00.000Z'),
    ),
  ];

  final dummyAppointment = Appointment(
    id: 'apt-001',
    patientId: 'PT-2049',
    clinicId: 'clinic-prosth',
    scheduledDate: DateTime.now(),
    status: 'Confirmed',
    procedureDescription: 'Prosthodontics - Metal Denture',
  );

  group('DashboardScreen Interaction & Navigation Tests', () {
    testWidgets('Tapping avatar in DashboardHeader mutates rootNavigationIndexProvider to Profile tab (4)', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          rootNavigationIndexProvider.overrideWith((ref) => 0),
          dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          patientListProvider.overrideWith((ref) => dummyPatients),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state is 0 (Dashboard)
      expect(container.read(rootNavigationIndexProvider), 0);

      // Tap on the Avatar (shows initials "SH")
      final avatarFinder = find.text('SH');
      expect(avatarFinder, findsOneWidget);
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Assert state updated to 4 (Profile)
      expect(container.read(rootNavigationIndexProvider), 4);
    });

    testWidgets('Tapping "View Full Schedule" mutates rootNavigationIndexProvider to Appointments tab (3)', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          rootNavigationIndexProvider.overrideWith((ref) => 0),
          dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          patientListProvider.overrideWith((ref) => dummyPatients),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 0);

      // Find and tap "View Full Schedule"
      final scheduleBtnFinder = find.text('View Full Schedule');
      expect(scheduleBtnFinder, findsOneWidget);
      await tester.ensureVisible(scheduleBtnFinder);
      await tester.tap(scheduleBtnFinder);
      await tester.pumpAndSettle();

      // Assert state updated to 3 (Appointments / Schedule)
      expect(container.read(rootNavigationIndexProvider), 3);
    });

    testWidgets('Tapping "View Case" pushes PatientCaseSheetScreen for the appointment patient', (WidgetTester tester) async {
      final navObserver = TestNavigatorObserver();
      final container = ProviderContainer(
        overrides: [
          dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[dummyAppointment]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          patientListProvider.overrideWith((ref) => dummyPatients),
          patientByIdProvider.overrideWith((ref, id) {
            return dummyPatients.firstWhere((p) => p.id == id, orElse: () => dummyPatients.first);
          }),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          casesByPatientProvider.overrideWith((ref, id) => <CaseRecord>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorObservers: [navObserver],
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find "View Case" button on the appointment card
      final viewCaseFinder = find.text('View Case');
      expect(viewCaseFinder, findsOneWidget);
      await tester.ensureVisible(viewCaseFinder);
      await tester.tap(viewCaseFinder);
      await tester.pumpAndSettle();

      // Assert PatientCaseSheetScreen is pushed to the navigation stack
      expect(find.byType(PatientCaseSheetScreen), findsOneWidget);
      expect(navObserver.pushedRoutes.length, greaterThanOrEqualTo(2));

      // Pop back to ensure clean stack pop
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PatientCaseSheetScreen), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Tapping an upcoming patient item pushes PatientCaseSheetScreen for that patient', (WidgetTester tester) async {
      final navObserver = TestNavigatorObserver();
      final container = ProviderContainer(
        overrides: [
          dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          patientListProvider.overrideWith((ref) => dummyPatients),
          patientByIdProvider.overrideWith((ref, id) {
            return dummyPatients.firstWhere((p) => p.id == id, orElse: () => dummyPatients.first);
          }),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          casesByPatientProvider.overrideWith((ref, id) => <CaseRecord>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorObservers: [navObserver],
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find "Sara Ahmed" in Tomorrow's Patients
      final patientFinder = find.text('Sara Ahmed');
      expect(patientFinder, findsOneWidget);
      await tester.ensureVisible(patientFinder);
      await tester.tap(patientFinder);
      await tester.pumpAndSettle();

      // Assert PatientCaseSheetScreen was pushed
      expect(find.byType(PatientCaseSheetScreen), findsOneWidget);
      expect(navObserver.pushedRoutes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('Standalone DashboardUpcomingSection default callbacks function without throwing', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardUpcomingSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap View Full Schedule default callback
      await tester.tap(find.text('View Full Schedule'));
      await tester.pumpAndSettle();
      expect(container.read(rootNavigationIndexProvider), 3);
    });

    testWidgets('Standalone DashboardHeader default callback mutates rootNavigationIndexProvider to 4', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardHeader(
                doctorName: 'Dr. Shehab',
                academicYear: '5th Year',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SH'));
      await tester.pumpAndSettle();
      expect(container.read(rootNavigationIndexProvider), 4);
    });
  });
}
