import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/appointments/appointments_screen.dart';
import 'package:dentera/presentation/screens/appointments/widgets/widgets.dart';

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
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppointmentsScreen(),
          ),
        ),
      );

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
