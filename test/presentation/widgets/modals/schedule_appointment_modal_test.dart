import 'dart:async';

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
import 'package:dentera/presentation/widgets/inputs/inputs.dart';
import 'package:dentera/presentation/widgets/modals/schedule_appointment_modal.dart';

/// Test mock implementation of [AppointmentRepository] to verify SQLite insertion parameters.
class MockAppointmentRepository implements AppointmentRepository {
  Appointment? lastAddedAppointment;

  @override
  Future<void> addAppointment(Appointment appointment) async {
    lastAddedAppointment = appointment;
  }

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

/// Fake [LocalNotificationService] to prevent unmocked platform channel invocations during testing.
class FakeNotificationService implements LocalNotificationService {
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

  group('ScheduleAppointmentModal Relational Query & Interaction Tests', () {
    final testDate = DateTime(2026, 9, 15);

    final dummyPatients = [
      Patient(
        id: 'PT-1001',
        name: 'Sara Ahmed',
        age: 23,
        gender: 'Female',
        createdAt: DateTime.now(),
      ),
      Patient(
        id: 'PT-1002',
        name: 'Omar Khalid',
        age: 45,
        gender: 'Male',
        createdAt: DateTime.now(),
      ),
    ];

    final dummyClinics = [
      const Clinic(
        id: 'c-pros',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      ),
      const Clinic(
        id: 'c-endo',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#1E568C',
      ),
    ];

    testWidgets('renders dynamic dropdowns and passes exact relational IDs to repository',
        (WidgetTester tester) async {
      final mockRepo = MockAppointmentRepository();
      Appointment? callbackAppointment;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => dummyPatients),
            clinicListProvider.overrideWith((ref) async => dummyClinics),
            appointmentRepositoryProvider.overrideWithValue(mockRepo),
            notificationServiceProvider.overrideWithValue(FakeNotificationService()),
            dailyAppointmentsProvider.overrideWith((ref, date) async => <Appointment>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ScheduleAppointmentModal.show(
                      context,
                      initialDate: testDate,
                      onAppointmentScheduled: (apt) => callbackAppointment = apt,
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Appointment'), findsOneWidget);
      expect(find.text('Patient *'), findsOneWidget);
      expect(find.text('Clinic / Department *'), findsOneWidget);
      expect(find.text('Date *'), findsOneWidget);
      expect(find.text('Tue, Sep 15, 2026'), findsOneWidget);
      expect(find.text('Save Appointment'), findsOneWidget);

      // 2. Open Patient dropdown and select 'Sara Ahmed (PT-1001)'
      await tester.tap(find.byKey(const Key('patient_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sara Ahmed (PT-1001)').last);
      await tester.pumpAndSettle();

      // 3. Open Clinic dropdown and select 'Endodontics'
      await tester.tap(find.byKey(const Key('clinic_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Endodontics').last);
      await tester.pumpAndSettle();

      // 4. Enter optional clinical notes
      await tester.enterText(
        find.widgetWithText(DenteraTextField, 'Clinical Notes / Tooth Number (Optional)'),
        'Tooth 46 - Obturation',
      );
      await tester.pumpAndSettle();

      // 5. Submit appointment
      await tester.tap(find.byKey(const Key('save_appointment_button')));
      await tester.pumpAndSettle();

      // 6. Verify modal popped
      expect(find.text('Schedule Appointment'), findsNothing);

      // 7. Verify SQLite repository received the true relational IDs and collision-free UUID
      expect(mockRepo.lastAddedAppointment, isNotNull);
      expect(mockRepo.lastAddedAppointment!.id, isNotNull);
      expect(mockRepo.lastAddedAppointment!.id.length, 36);
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
      expect(uuidRegex.hasMatch(mockRepo.lastAddedAppointment!.id), isTrue);
      expect(mockRepo.lastAddedAppointment!.patientId, 'PT-1001');
      expect(mockRepo.lastAddedAppointment!.clinicId, 'c-endo');
      expect(
        mockRepo.lastAddedAppointment!.procedureDescription,
        'Endodontics - Tooth 46 - Obturation',
      );
      expect(mockRepo.lastAddedAppointment!.status, 'Scheduled');
      expect(mockRepo.lastAddedAppointment!.scheduledDate.year, 2026);
      expect(mockRepo.lastAddedAppointment!.scheduledDate.month, 9);
      expect(mockRepo.lastAddedAppointment!.scheduledDate.day, 15);

      // Verify callback received exact matching entity
      expect(callbackAppointment, isNotNull);
      expect(callbackAppointment!.patientId, 'PT-1001');
      expect(callbackAppointment!.clinicId, 'c-endo');
    });

    testWidgets('guards against submission when patient or clinic is not selected',
        (WidgetTester tester) async {
      final mockRepo = MockAppointmentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => dummyPatients),
            clinicListProvider.overrideWith((ref) async => dummyClinics),
            appointmentRepositoryProvider.overrideWithValue(mockRepo),
            notificationServiceProvider.overrideWithValue(FakeNotificationService()),
            dailyAppointmentsProvider.overrideWith((ref, date) async => <Appointment>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ScheduleAppointmentModal.show(context);
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap Save Appointment immediately without selections
      await tester.tap(find.byKey(const Key('save_appointment_button')));
      await tester.pumpAndSettle();

      // Verify validation prevented submission
      expect(find.text('Schedule Appointment'), findsOneWidget);
      expect(mockRepo.lastAddedAppointment, isNull);
      expect(find.text('Please select a patient'), findsOneWidget);
      expect(find.text('Please select a clinic'), findsOneWidget);
    });

    testWidgets('gracefully displays loading states when providers are pending',
        (WidgetTester tester) async {
      final patientCompleter = Completer<List<Patient>>();
      final clinicCompleter = Completer<List<Clinic>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) => patientCompleter.future),
            clinicListProvider.overrideWith((ref) => clinicCompleter.future),
            notificationServiceProvider.overrideWithValue(FakeNotificationService()),
            dailyAppointmentsProvider.overrideWith((ref, date) async => <Appointment>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ScheduleAppointmentModal.show(context);
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pump(); // Initial frame before completers resolve

      expect(find.text('Loading patients...'), findsOneWidget);
      expect(find.text('Loading clinics...'), findsOneWidget);

      // Complete futures
      patientCompleter.complete(dummyPatients);
      clinicCompleter.complete(dummyClinics);
      await tester.pumpAndSettle();

      expect(find.text('Select patient...'), findsOneWidget);
      expect(find.text('Select clinic...'), findsOneWidget);
    });
  });
}
