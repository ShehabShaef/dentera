import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/appointments/appointments_screen.dart';
import 'package:dentera/presentation/screens/appointments/widgets/widgets.dart';
import 'package:dentera/presentation/screens/patients/patient_case_sheet_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

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
  group('AppointmentsScreen Reactive State Widget Tests', () {
    final today = DateTime.now();

    final dummyAppointments = [
      Appointment(
        id: 'apt-01',
        patientId: 'p-1',
        clinicId: 'c-1',
        scheduledDate: DateTime(today.year, today.month, today.day, 9, 30),
        status: 'Confirmed',
        procedureDescription: 'Root Canal Access',
      ),
      Appointment(
        id: 'apt-02',
        patientId: 'p-2',
        clinicId: 'c-2',
        scheduledDate: DateTime(today.year, today.month, today.day, 11, 0),
        status: 'Scheduled',
        procedureDescription: 'Complete Denture Secondary Impression',
      ),
      Appointment(
        id: 'apt-03',
        patientId: 'p-3',
        clinicId: 'c-1',
        scheduledDate: DateTime(today.year, today.month, today.day, 14, 15),
        status: 'Scheduled',
        procedureDescription: 'Obturation',
      ),
    ];

    final dummyPatients = [
      Patient(
        id: 'p-1',
        name: 'Ali Nasser',
        age: 35,
        gender: 'Male',
        createdAt: DateTime.now(),
      ),
      Patient(
        id: 'p-2',
        name: 'Sarah Jenkins',
        age: 28,
        gender: 'Female',
        createdAt: DateTime.now(),
      ),
    ];

    final dummyClinics = [
      const Clinic(
        id: 'c-1',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#1E568C',
      ),
      const Clinic(
        id: 'c-2',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      ),
    ];

    testWidgets('renders timeline appointment cards reactively from dailyAppointmentsProvider',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) async => dummyAppointments),
            patientListProvider.overrideWith((ref) async => dummyPatients),
            clinicListProvider.overrideWith((ref) async => dummyClinics),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AppointmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen Header
      expect(find.text('Appointments'), findsOneWidget);

      // Next Up Highlight Card
      expect(find.text('Next Up'), findsOneWidget);
      expect(find.text('Ali Nasser'), findsOneWidget);
      expect(find.text('Endodontics - Root Canal Access'), findsOneWidget);
      expect(find.text('Open Case Sheet'), findsOneWidget);

      // Later Today Chronological Section
      expect(find.text('Later Today'), findsOneWidget);
      expect(find.byType(TimelineAppointmentCard), findsNWidgets(2));
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Patient #p-3'), findsOneWidget); // Fallback mapping for non-cached patient
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders zero state UI when dailyAppointmentsProvider returns empty list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) async => <Appointment>[]),
            patientListProvider.overrideWith((ref) async => dummyPatients),
            clinicListProvider.overrideWith((ref) async => dummyClinics),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AppointmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DenteraEmptyState), findsOneWidget);
      expect(find.text('No appointments scheduled'), findsOneWidget);
      expect(find.text('Enjoy your day off or schedule a new patient.'), findsOneWidget);
      expect(find.text('Schedule Patient'), findsOneWidget);
      expect(find.byType(TimelineAppointmentCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays CircularProgressIndicator while dailyAppointmentsProvider is loading',
        (WidgetTester tester) async {
      final completer = Completer<List<Appointment>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) => completer.future),
            patientListProvider.overrideWith((ref) async => dummyPatients),
            clinicListProvider.overrideWith((ref) async => dummyClinics),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AppointmentsScreen(),
          ),
        ),
      );

      // Initial pump: loading
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete future and settle
      completer.complete(dummyAppointments);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Next Up'), findsOneWidget);
    });

    testWidgets('Tapping settings icon in AppBar mutates rootNavigationIndexProvider to Profile tab (4)',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          rootNavigationIndexProvider.overrideWith((ref) => 3),
          dailyAppointmentsProvider.overrideWith((ref, date) async => dummyAppointments),
          patientListProvider.overrideWith((ref) async => dummyPatients),
          clinicListProvider.overrideWith((ref) async => dummyClinics),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AppointmentsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 3);

      final settingsBtnFinder = find.byIcon(Icons.settings_outlined);
      expect(settingsBtnFinder, findsOneWidget);
      await tester.tap(settingsBtnFinder);
      await tester.pumpAndSettle();

      expect(container.read(rootNavigationIndexProvider), 4);
    });

    testWidgets('Tapping "Open Case Sheet" on Next Up card pushes PatientCaseSheetScreen',
        (WidgetTester tester) async {
      final navObserver = TestNavigatorObserver();
      final container = ProviderContainer(
        overrides: [
          dailyAppointmentsProvider.overrideWith((ref, date) async => dummyAppointments),
          patientListProvider.overrideWith((ref) async => dummyPatients),
          clinicListProvider.overrideWith((ref) async => dummyClinics),
          patientByIdProvider.overrideWith((ref, id) {
            return dummyPatients.firstWhere((p) => p.id == id, orElse: () => dummyPatients.first);
          }),
          casesByPatientProvider.overrideWith((ref, id) async => <CaseRecord>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            navigatorObservers: [navObserver],
            home: const AppointmentsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final openCaseFinder = find.text('Open Case Sheet');
      expect(openCaseFinder, findsOneWidget);
      await tester.ensureVisible(openCaseFinder);
      await tester.tap(openCaseFinder);
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseSheetScreen), findsOneWidget);
      expect(navObserver.pushedRoutes.length, greaterThanOrEqualTo(2));

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PatientCaseSheetScreen), findsNothing);
      expect(find.byType(AppointmentsScreen), findsOneWidget);
    });

    testWidgets('Tapping TimelineAppointmentCard in Later Today section pushes PatientCaseSheetScreen',
        (WidgetTester tester) async {
      final navObserver = TestNavigatorObserver();
      final container = ProviderContainer(
        overrides: [
          dailyAppointmentsProvider.overrideWith((ref, date) async => dummyAppointments),
          patientListProvider.overrideWith((ref) async => dummyPatients),
          clinicListProvider.overrideWith((ref) async => dummyClinics),
          patientByIdProvider.overrideWith((ref, id) {
            return dummyPatients.firstWhere((p) => p.id == id, orElse: () => dummyPatients.first);
          }),
          casesByPatientProvider.overrideWith((ref, id) async => <CaseRecord>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            navigatorObservers: [navObserver],
            home: const AppointmentsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sarahCardFinder = find.text('Sarah Jenkins');
      expect(sarahCardFinder, findsOneWidget);
      await tester.ensureVisible(sarahCardFinder);
      await tester.tap(sarahCardFinder);
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseSheetScreen), findsOneWidget);
      expect(navObserver.pushedRoutes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('Standalone TimelineAppointmentCard default onTap pushes PatientCaseSheetScreen',
        (WidgetTester tester) async {
      final navObserver = TestNavigatorObserver();
      final container = ProviderContainer(
        overrides: [
          patientByIdProvider.overrideWith((ref, id) {
            return dummyPatients.firstWhere((p) => p.id == id, orElse: () => dummyPatients.first);
          }),
          casesByPatientProvider.overrideWith((ref, id) async => <CaseRecord>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            navigatorObservers: [navObserver],
            home: Scaffold(
              body: TimelineAppointmentCard(
                appointment: dummyAppointments.first,
                patientName: 'Ali Nasser',
                clinicName: 'Endodontics',
                timeFormatted: '09:30 AM',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ali Nasser'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseSheetScreen), findsOneWidget);
      expect(navObserver.pushedRoutes.length, greaterThanOrEqualTo(2));
    });
  });
}
