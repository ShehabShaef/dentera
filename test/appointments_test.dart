import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/appointments/appointments_screen.dart';
import 'package:dentera/presentation/screens/appointments/widgets/widgets.dart';

import 'package:dentera/presentation/state/state.dart';

void main() {
  group('Appointments Timeline Screen Widget Tests', () {
    testWidgets('DateSelectorStrip renders dates and calls onDateSelected', (WidgetTester tester) async {
      DateTime? selected;
      final today = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DateSelectorStrip(
              selectedDate: today,
              onDateSelected: (date) => selected = date,
            ),
          ),
        ),
      );

      expect(find.text('${today.day}'), findsOneWidget);

      // Tap next day
      final tomorrow = today.add(const Duration(days: 1));
      await tester.tap(find.text('${tomorrow.day}').first);
      expect(selected?.day, tomorrow.day);
    });

    testWidgets('TimelineAppointmentCard renders time, name, procedure, and handles tap', (WidgetTester tester) async {
      bool tapped = false;
      final appointment = Appointment(
        id: 'apt-02',
        patientId: 'PT-1002',
        clinicId: 'clinic-pediatric',
        scheduledDate: DateTime.now(),
        status: 'Scheduled',
        procedureDescription: 'Pediatric Care',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimelineAppointmentCard(
              appointment: appointment,
              patientName: 'Sarah Jenkins',
              clinicName: 'Pediatric Dentistry',
              timeFormatted: '01:00 PM',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('01:00 PM'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Pediatric Dentistry • Pediatric Care'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);

      await tester.tap(find.text('Sarah Jenkins'));
      expect(tapped, isTrue);
    });

    testWidgets('AppointmentsScreen renders schedule, next up, timeline, and toggles empty state', (WidgetTester tester) async {
      final today = DateTime.now();
      final dummyAppointments = [
        Appointment(
          id: 'apt-01',
          patientId: 'PT-2049',
          clinicId: 'clinic-surgery',
          scheduledDate: today.copyWith(hour: 10, minute: 30),
          status: 'Confirmed',
          procedureDescription: 'Extraction - Tooth 38',
        ),
        Appointment(
          id: 'apt-02',
          patientId: 'PT-1002',
          clinicId: 'clinic-pediatric',
          scheduledDate: today.copyWith(hour: 13, minute: 0),
          status: 'Scheduled',
          procedureDescription: 'Pediatric Care',
        ),
        Appointment(
          id: 'apt-03',
          patientId: 'PT-1003',
          clinicId: 'clinic-endo',
          scheduledDate: today.copyWith(hour: 15, minute: 30),
          status: 'Scheduled',
          procedureDescription: 'Root Canal Therapy',
        ),
      ];

      final dummyPatients = [
        Patient(id: 'PT-2049', name: 'Ali Nasser', age: 45, gender: 'Male', createdAt: today),
        Patient(id: 'PT-1002', name: 'Sarah Jenkins', age: 24, gender: 'Female', createdAt: today),
        Patient(id: 'PT-1003', name: 'Michael Chang', age: 31, gender: 'Male', createdAt: today),
      ];

      final dummyClinics = [
        const Clinic(id: 'clinic-surgery', name: 'Oral Surgery', academicYear: '5th Year', colorHex: '#2E3F50'),
        const Clinic(id: 'clinic-pediatric', name: 'Pediatric Dentistry', academicYear: '5th Year', colorHex: '#4A6572'),
        const Clinic(id: 'clinic-endo', name: 'Endodontics', academicYear: '5th Year', colorHex: '#1E568C'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) async {
              if (date.year == today.year && date.month == today.month && date.day == today.day) {
                return dummyAppointments;
              }
              return <Appointment>[];
            }),
            patientListProvider.overrideWith((ref) async => dummyPatients),
            clinicListProvider.overrideWith((ref) async => dummyClinics),
          ],
          child: const MaterialApp(
            home: AppointmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Appointments'), findsOneWidget);
      expect(find.text('Next Up'), findsOneWidget);
      expect(find.text('Ali Nasser'), findsOneWidget);
      expect(find.text('Open Case Sheet'), findsOneWidget);
      expect(find.text('Later Today'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Michael Chang'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Select a future date with no appointments
      final futureDate = DateTime.now().add(const Duration(days: 4));
      await tester.tap(find.text('${futureDate.day}').first);
      await tester.pumpAndSettle();

      expect(find.text('No appointments scheduled'), findsOneWidget);
      expect(find.text('Schedule Patient'), findsOneWidget);
    });
  });
}
