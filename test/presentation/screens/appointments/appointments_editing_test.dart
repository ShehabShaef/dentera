import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/local_notification_service.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/appointment_repository.dart';
import 'package:dentera/presentation/screens/appointments/appointments_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/modals/edit_appointment_modal.dart';

class MockAppointmentRepository implements AppointmentRepository {
  final List<Appointment> appointments = [];
  Appointment? lastUpdatedAppointment;
  String? lastDeletedId;

  @override
  Future<void> addAppointment(Appointment appointment) async {
    appointments.add(appointment);
  }

  @override
  Future<List<Appointment>> getAllAppointments() async => List.from(appointments);

  @override
  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    return appointments.where((a) {
      return a.scheduledDate.year == date.year &&
          a.scheduledDate.month == date.month &&
          a.scheduledDate.day == date.day;
    }).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async =>
      appointments.where((a) => a.patientId == patientId).toList();

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    lastUpdatedAppointment = appointment;
    final index = appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      appointments[index] = appointment;
    }
  }

  @override
  Future<void> deleteAppointment(String id) async {
    lastDeletedId = id;
    appointments.removeWhere((a) => a.id == id);
  }
}

class MockLocalNotificationService implements LocalNotificationService {
  final List<Appointment> scheduledAppointments = [];
  final List<String> canceledReminderIds = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> scheduleAppointmentReminder(
    Appointment appointment, {
    String? clinicName,
  }) async {
    scheduledAppointments.add(appointment);
    return true;
  }

  @override
  Future<void> cancelReminder(String appointmentId) async {
    canceledReminderIds.add(appointmentId);
  }

  @override
  Future<void> cancelAllReminders() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppointmentsScreen In-Place Editing & Deletion Tests', () {
    late MockAppointmentRepository mockRepo;
    late MockLocalNotificationService mockNotifications;
    late PreferencesRepository prefsRepo;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final patient1 = Patient(
      id: 'p-1',
      name: 'Ali Nasser',
      age: 30,
      gender: 'Male',
      createdAt: now,
    );

    final patient2 = Patient(
      id: 'p-2',
      name: 'Sarah Jenkins',
      age: 28,
      gender: 'Female',
      createdAt: now,
    );

    final clinic1 = const Clinic(
      id: 'c-1',
      name: 'Endodontics',
      academicYear: '5th Year',
      colorHex: '#1E568C',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'remindersEnabled': true,
      });
      mockRepo = MockAppointmentRepository();
      mockNotifications = MockLocalNotificationService();
      prefsRepo = PreferencesRepository();

      mockRepo.appointments.addAll([
        Appointment(
          id: 'apt-01',
          patientId: 'p-1',
          clinicId: 'c-1',
          scheduledDate: DateTime(today.year, today.month, today.day, 9, 30),
          status: 'Scheduled',
          procedureDescription: 'Root Canal Access',
        ),
        Appointment(
          id: 'apt-02',
          patientId: 'p-2',
          clinicId: 'c-1',
          scheduledDate: DateTime(today.year, today.month, today.day, 14, 0),
          status: 'Scheduled',
          procedureDescription: 'Obturation',
        ),
      ]);
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          appointmentRepositoryProvider.overrideWithValue(mockRepo),
          notificationServiceProvider.overrideWithValue(mockNotifications),
          preferencesRepositoryProvider.overrideWithValue(prefsRepo),
          patientListProvider.overrideWith((ref) async => [patient1, patient2]),
          clinicListProvider.overrideWith((ref) async => [clinic1]),
          dailyAppointmentsProvider.overrideWith((ref, date) async => mockRepo.getAppointmentsByDate(date)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AppointmentsScreen(),
        ),
      );
    }

    testWidgets('Tapping edit icon on Next Up card opens EditAppointmentModal and updates appointment',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Next Up'), findsOneWidget);
      expect(find.text('Ali Nasser'), findsOneWidget);

      final editButtonFinder = find.byTooltip('Edit Appointment').first;
      expect(editButtonFinder, findsOneWidget);
      await tester.tap(editButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(EditAppointmentModal), findsOneWidget);
      expect(find.text('Edit Appointment'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(EditAppointmentModal), matching: find.text('Ali Nasser')),
        findsOneWidget,
      );

      final completedChip = find.text('Completed');
      expect(completedChip, findsOneWidget);
      await tester.tap(completedChip);
      await tester.pumpAndSettle();

      final saveButton = find.text('Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(EditAppointmentModal), findsNothing);
      expect(mockRepo.lastUpdatedAppointment, isNotNull);
      expect(mockRepo.lastUpdatedAppointment!.status, 'Completed');
    });

    testWidgets('Deleting appointment from Next Up card popup menu shows confirmation and deletes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final moreFinder = find.byTooltip('Appointment actions').first;
      await tester.tap(moreFinder);
      await tester.pumpAndSettle();

      final deleteOption = find.text('Delete Appointment');
      expect(deleteOption, findsOneWidget);
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      expect(find.text('Delete Appointment'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete this appointment for Ali Nasser?'), findsOneWidget);

      final confirmDelete = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      expect(mockRepo.lastDeletedId, 'apt-01');
      expect(mockRepo.appointments.any((a) => a.id == 'apt-01'), isFalse);
    });

    testWidgets('Tapping edit icon on Later Today timeline card opens EditAppointmentModal',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Later Today'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);

      final editButtons = find.byTooltip('Edit Appointment');
      expect(editButtons, findsNWidgets(2));
      await tester.tap(editButtons.at(1));
      await tester.pumpAndSettle();

      expect(find.byType(EditAppointmentModal), findsOneWidget);
      expect(
        find.descendant(of: find.byType(EditAppointmentModal), matching: find.text('Sarah Jenkins')),
        findsOneWidget,
      );
      expect(find.text('Obturation'), findsOneWidget);
    });

    testWidgets('Deleting appointment from timeline popup menu shows confirmation and deletes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final actionMenus = find.byTooltip('Appointment actions');
      expect(actionMenus, findsNWidgets(2));
      await tester.tap(actionMenus.at(1));
      await tester.pumpAndSettle();

      final deleteOption = find.text('Delete Appointment');
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      expect(find.textContaining('Are you sure you want to delete this appointment for Sarah Jenkins?'), findsOneWidget);

      final cancelBtn = find.widgetWithText(TextButton, 'Cancel');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastDeletedId, isNull);
      expect(mockRepo.appointments.length, 2);

      await tester.tap(find.byTooltip('Appointment actions').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Appointment'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastDeletedId, 'apt-02');
      expect(mockRepo.appointments.length, 1);
    });
  });
}
