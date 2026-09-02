import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  group('ScheduleAppointmentModal Widget Tests', () {
    testWidgets('ScheduleAppointmentModal renders selectors and submits appointment', (WidgetTester tester) async {
      Appointment? scheduledAppointment;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScheduleAppointmentModal.show(
                      context,
                      initialDate: DateTime(2026, 9, 2),
                      onAppointmentScheduled: (apt) => scheduledAppointment = apt,
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Appointment'), findsOneWidget);
      expect(find.text('Patient *'), findsOneWidget);
      expect(find.text('Procedure / Requirement *'), findsOneWidget);
      expect(find.text('OPERATIVE'), findsOneWidget);
      expect(find.text('PROSTHO'), findsOneWidget);
      expect(find.text('Date *'), findsOneWidget);
      expect(find.text('Wed, Sep 2, 2026'), findsOneWidget);
      expect(find.text('Time *'), findsOneWidget);
      expect(find.text('Confirm Appointment'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Select Endo procedure
      await tester.tap(find.text('ENDO'));
      await tester.pumpAndSettle();

      // Enter clinical notes
      await tester.enterText(
        find.widgetWithText(DenteraTextField, 'Clinical Notes / Tooth Number (Optional)'),
        'Obturation session',
      );
      await tester.pumpAndSettle();

      // Tap Confirm Appointment
      await tester.tap(find.text('Confirm Appointment'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('Schedule Appointment'), findsNothing);

      // Appointment created properly
      expect(scheduledAppointment, isNotNull);
      expect(scheduledAppointment!.patientId, 'PT-1001');
      expect(scheduledAppointment!.procedureDescription, contains('Endo - Root Canal (Tooth 46) - Obturation session'));
      expect(scheduledAppointment!.status, 'Scheduled');
      expect(scheduledAppointment!.scheduledDate.year, 2026);
      expect(scheduledAppointment!.scheduledDate.month, 9);
      expect(scheduledAppointment!.scheduledDate.day, 2);
    });
  });
}
