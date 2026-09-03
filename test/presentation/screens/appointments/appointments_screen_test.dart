import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/appointments/appointments_screen.dart';
import 'package:dentera/presentation/screens/appointments/widgets/widgets.dart';
import 'package:dentera/presentation/state/state.dart';

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

      expect(find.text('No appointments scheduled'), findsOneWidget);
      expect(find.text('Enjoy your day off or schedule a new patient.'), findsOneWidget);
      expect(find.text('Schedule Patient'), findsOneWidget);
      expect(find.byType(TimelineAppointmentCard), findsNothing);
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
  });
}
