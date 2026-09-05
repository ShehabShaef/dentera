import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/local_notification_service.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/appointment_repository.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

class _FakeAppointmentRepository implements AppointmentRepository {
  @override
  Future<void> addAppointment(Appointment appointment) async {}

  @override
  Future<void> updateAppointment(Appointment appointment) async {}

  @override
  Future<void> deleteAppointment(String id) async {}

  @override
  Future<List<Appointment>> getAllAppointments() async => <Appointment>[];

  @override
  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async => <Appointment>[];

  @override
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async => <Appointment>[];
}

class _FakeNotificationService implements LocalNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> cancelAllReminders() async {}

  @override
  Future<void> cancelReminder(String appointmentId) async {}

  @override
  Future<bool> scheduleAppointmentReminder(
    Appointment appointment, {
    String? clinicName,
  }) async => true;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScheduleAppointmentModal Widget Tests', () {
    final dummyPatients = [
      Patient(
        id: 'PT-1001',
        name: 'Sara Ahmed',
        age: 23,
        gender: 'Female',
        createdAt: DateTime.now(),
      ),
    ];

    final dummyClinics = [
      const Clinic(
        id: 'c-endo',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#1E568C',
      ),
    ];

    testWidgets('ScheduleAppointmentModal renders selectors and submits appointment', (WidgetTester tester) async {
      Appointment? scheduledAppointment;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => dummyPatients),
            clinicListProvider.overrideWith((ref) async => dummyClinics),
            appointmentRepositoryProvider.overrideWithValue(_FakeAppointmentRepository()),
            notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
            dailyAppointmentsProvider.overrideWith((ref, date) async => <Appointment>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      ScheduleAppointmentModal.show(
                        context,
                        initialDate: DateTime(2026, 9, 2),
                        referenceDateTime: DateTime(2026, 9, 1),
                        onAppointmentScheduled: (apt) => scheduledAppointment = apt,
                      );
                    },
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Appointment'), findsOneWidget);
      expect(find.text('Patient *'), findsOneWidget);
      expect(find.text('Clinic / Department *'), findsOneWidget);
      expect(find.text('Date *'), findsOneWidget);
      expect(find.text('Wed, Sep 2, 2026'), findsOneWidget);
      expect(find.text('Time *'), findsOneWidget);
      expect(find.text('Save Appointment'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Select Patient
      await tester.tap(find.byKey(const Key('patient_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sara Ahmed (PT-1001)').last);
      await tester.pumpAndSettle();

      // Select Clinic
      await tester.tap(find.byKey(const Key('clinic_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Endodontics').last);
      await tester.pumpAndSettle();

      // Enter clinical notes
      await tester.enterText(
        find.widgetWithText(DenteraTextField, 'Clinical Notes / Tooth Number (Optional)'),
        'Obturation session',
      );
      await tester.pumpAndSettle();

      // Tap Save Appointment
      await tester.tap(find.text('Save Appointment'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('Schedule Appointment'), findsNothing);

      // Appointment created properly
      expect(scheduledAppointment, isNotNull);
      expect(scheduledAppointment!.patientId, 'PT-1001');
      expect(scheduledAppointment!.clinicId, 'c-endo');
      expect(scheduledAppointment!.procedureDescription, contains('Endodontics - Obturation session'));
      expect(scheduledAppointment!.status, 'Scheduled');
      expect(scheduledAppointment!.scheduledDate.year, 2026);
      expect(scheduledAppointment!.scheduledDate.month, 9);
      expect(scheduledAppointment!.scheduledDate.day, 2);
    });

    testWidgets('ScheduleAppointmentModal rejects past date/time scheduling and renders validation error', (WidgetTester tester) async {
      Appointment? scheduledAppointment;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => dummyPatients),
            clinicListProvider.overrideWith((ref) async => dummyClinics),
            appointmentRepositoryProvider.overrideWithValue(_FakeAppointmentRepository()),
            notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
            dailyAppointmentsProvider.overrideWith((ref, date) async => <Appointment>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      ScheduleAppointmentModal.show(
                        context,
                        initialDate: DateTime(2026, 8, 15),
                        referenceDateTime: DateTime(2026, 9, 1),
                        onAppointmentScheduled: (apt) => scheduledAppointment = apt,
                      );
                    },
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Select Patient
      await tester.tap(find.byKey(const Key('patient_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sara Ahmed (PT-1001)').last);
      await tester.pumpAndSettle();

      // Select Clinic
      await tester.tap(find.byKey(const Key('clinic_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Endodontics').last);
      await tester.pumpAndSettle();

      // Tap Save Appointment -> Fails validation due to past date
      await tester.tap(find.text('Save Appointment'));
      await tester.pumpAndSettle();

      // Error message is displayed on screen
      expect(find.text('Cannot schedule appointments in the past'), findsOneWidget);
      expect(scheduledAppointment, isNull);
    });
  });
}
