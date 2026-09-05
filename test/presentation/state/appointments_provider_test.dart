import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/local_notification_service.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/appointment_repository.dart';
import 'package:dentera/presentation/state/appointments_provider.dart';

class MockAppointmentRepository implements AppointmentRepository {
  final List<Appointment> addedAppointments = [];
  final List<Appointment> updatedAppointments = [];
  final List<String> deletedIds = [];

  bool shouldThrowOnAdd = false;
  bool shouldThrowOnUpdate = false;
  bool shouldThrowOnDelete = false;

  @override
  Future<void> addAppointment(Appointment appointment) async {
    if (shouldThrowOnAdd) {
      throw Exception('SQLite insert failed: disk I/O error');
    }
    addedAppointments.add(appointment);
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    if (shouldThrowOnUpdate) {
      throw Exception('SQLite update failed: record locked');
    }
    updatedAppointments.add(appointment);
  }

  @override
  Future<void> deleteAppointment(String id) async {
    if (shouldThrowOnDelete) {
      throw Exception('SQLite delete failed: foreign key constraint');
    }
    deletedIds.add(id);
  }

  @override
  Future<List<Appointment>> getAllAppointments() async => addedAppointments;

  @override
  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async => [];

  @override
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async => [];
}

class MockLocalNotificationService implements LocalNotificationService {
  final List<Appointment> scheduledAppointments = [];
  final List<String> scheduledClinicNames = [];
  final List<String> canceledReminderIds = [];
  int cancelAllCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> scheduleAppointmentReminder(
    Appointment appointment, {
    String? clinicName,
  }) async {
    scheduledAppointments.add(appointment);
    if (clinicName != null) {
      scheduledClinicNames.add(clinicName);
    }
    return true;
  }

  @override
  Future<void> cancelReminder(String appointmentId) async {
    canceledReminderIds.add(appointmentId);
  }

  @override
  Future<void> cancelAllReminders() async {
    cancelAllCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppointmentRepository mockRepo;
  late MockLocalNotificationService mockNotificationService;
  late PreferencesRepository prefsRepo;

  final sampleAppointment = Appointment(
    id: 'apt-uuid-101',
    patientId: 'patient-1',
    clinicId: 'clinic-endo',
    scheduledDate: DateTime.now().add(const Duration(days: 1)),
    procedureDescription: 'Root Canal Obturation',
    status: 'Scheduled',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'remindersEnabled': true,
    });
    mockRepo = MockAppointmentRepository();
    mockNotificationService = MockLocalNotificationService();
    prefsRepo = PreferencesRepository();
  });

  group('AppointmentsNotifier Lifecycle & Notification Triggers', () {
    test('addAppointment persists to SQLite and invokes scheduleAppointmentReminder exactly once', () async {
      final notifier = AppointmentsNotifier(
        appointmentRepository: mockRepo,
        notificationService: mockNotificationService,
        preferencesRepository: prefsRepo,
      );

      await notifier.addAppointment(sampleAppointment, clinicName: 'Endodontics');

      // Assert SQLite persistence
      expect(mockRepo.addedAppointments.length, equals(1));
      expect(mockRepo.addedAppointments.first.id, equals('apt-uuid-101'));

      // Assert notification scheduling
      expect(mockNotificationService.scheduledAppointments.length, equals(1));
      expect(mockNotificationService.scheduledAppointments.first.id, equals('apt-uuid-101'));
      expect(mockNotificationService.scheduledClinicNames, contains('Endodontics'));

      // Cancel should not be touched
      expect(mockNotificationService.canceledReminderIds, isEmpty);
    });

    test('addAppointment silently bypasses scheduling when reminders are disabled in preferences', () async {
      await prefsRepo.setRemindersEnabled(false);

      final notifier = AppointmentsNotifier(
        appointmentRepository: mockRepo,
        notificationService: mockNotificationService,
        preferencesRepository: prefsRepo,
      );

      await notifier.addAppointment(sampleAppointment, clinicName: 'Endodontics');

      // SQLite mutation must still succeed
      expect(mockRepo.addedAppointments.length, equals(1));

      // Notification schedule should be skipped
      expect(mockNotificationService.scheduledAppointments, isEmpty);
      expect(mockNotificationService.canceledReminderIds, isEmpty);
    });

    test('addAppointment aborts notification scheduling when SQLite insertion throws (prevents ghost alerts)', () async {
      mockRepo.shouldThrowOnAdd = true;

      final notifier = AppointmentsNotifier(
        appointmentRepository: mockRepo,
        notificationService: mockNotificationService,
        preferencesRepository: prefsRepo,
      );

      expect(
        () async => await notifier.addAppointment(sampleAppointment),
        throwsA(isA<Exception>()),
      );

      // Verify no notification was scheduled for nonexistent appointment
      expect(mockNotificationService.scheduledAppointments, isEmpty);
      expect(mockNotificationService.canceledReminderIds, isEmpty);
    });

    test('updateAppointment cancels prior reminder and reschedules with updated details', () async {
      final notifier = AppointmentsNotifier(
        appointmentRepository: mockRepo,
        notificationService: mockNotificationService,
        preferencesRepository: prefsRepo,
      );

      final updatedAppointment = sampleAppointment.copyWith(
        scheduledDate: DateTime.now().add(const Duration(days: 3)),
        procedureDescription: 'Rescheduled Root Canal',
      );

      await notifier.updateAppointment(updatedAppointment, clinicName: 'Endodontics');

      // SQLite update called
      expect(mockRepo.updatedAppointments.length, equals(1));

      // Cancel reminder called exactly once for appointment ID
      expect(mockNotificationService.canceledReminderIds.length, equals(1));
      expect(mockNotificationService.canceledReminderIds.first, equals('apt-uuid-101'));

      // Reschedule called exactly once with updated appointment
      expect(mockNotificationService.scheduledAppointments.length, equals(1));
      expect(
        mockNotificationService.scheduledAppointments.first.procedureDescription,
        equals('Rescheduled Root Canal'),
      );
    });

    test('updateAppointment cancels prior reminder and DOES NOT reschedule if status is "Canceled"', () async {
      final notifier = AppointmentsNotifier(
        appointmentRepository: mockRepo,
        notificationService: mockNotificationService,
        preferencesRepository: prefsRepo,
      );

      final canceledAppointment = sampleAppointment.copyWith(status: 'Canceled');

      await notifier.updateAppointment(canceledAppointment);

      // SQLite update called
      expect(mockRepo.updatedAppointments.length, equals(1));

      // Cancel reminder called
      expect(mockNotificationService.canceledReminderIds.length, equals(1));
      expect(mockNotificationService.canceledReminderIds.first, equals('apt-uuid-101'));

      // Reschedule MUST NOT be invoked for canceled appointment
      expect(mockNotificationService.scheduledAppointments, isEmpty);
    });

    test('updateAppointment cancels prior reminder and DOES NOT reschedule if reminders are disabled', () async {
      await prefsRepo.setRemindersEnabled(false);

      final notifier = AppointmentsNotifier(
        appointmentRepository: mockRepo,
        notificationService: mockNotificationService,
        preferencesRepository: prefsRepo,
      );

      await notifier.updateAppointment(sampleAppointment);

      // Old notification intent revoked
      expect(mockNotificationService.canceledReminderIds.length, equals(1));

      // Reschedule skipped
      expect(mockNotificationService.scheduledAppointments, isEmpty);
    });

    test('deleteAppointment deletes from SQLite and cancels reminder exactly once', () async {
      final notifier = AppointmentsNotifier(
        appointmentRepository: mockRepo,
        notificationService: mockNotificationService,
        preferencesRepository: prefsRepo,
      );

      await notifier.deleteAppointment('apt-uuid-101');

      // SQLite deletion
      expect(mockRepo.deletedIds.length, equals(1));
      expect(mockRepo.deletedIds.first, equals('apt-uuid-101'));

      // Cancel reminder
      expect(mockNotificationService.canceledReminderIds.length, equals(1));
      expect(mockNotificationService.canceledReminderIds.first, equals('apt-uuid-101'));
      expect(mockNotificationService.scheduledAppointments, isEmpty);
    });

    test('cancelAppointment helper updates status to Canceled and revokes reminder', () async {
      final notifier = AppointmentsNotifier(
        appointmentRepository: mockRepo,
        notificationService: mockNotificationService,
        preferencesRepository: prefsRepo,
      );

      await notifier.cancelAppointment(sampleAppointment);

      expect(mockRepo.updatedAppointments.length, equals(1));
      expect(mockRepo.updatedAppointments.first.status, equals('Canceled'));

      expect(mockNotificationService.canceledReminderIds.length, equals(1));
      expect(mockNotificationService.canceledReminderIds.first, equals('apt-uuid-101'));
      expect(mockNotificationService.scheduledAppointments, isEmpty);
    });
  });

  group('Riverpod Provider Container Integration Tests', () {
    test('appointmentsNotifierProvider wires dependencies and processes mutations via container', () async {
      final container = ProviderContainer(
        overrides: [
          appointmentRepositoryProvider.overrideWithValue(mockRepo),
          notificationServiceProvider.overrideWithValue(mockNotificationService),
          preferencesRepositoryProvider.overrideWithValue(prefsRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(appointmentsNotifierProvider.notifier);

      await notifier.addAppointment(sampleAppointment);

      expect(mockRepo.addedAppointments.length, equals(1));
      expect(mockNotificationService.scheduledAppointments.length, equals(1));
      expect(container.read(appointmentsNotifierProvider).hasValue, isTrue);

      await notifier.deleteAppointment(sampleAppointment.id);

      expect(mockRepo.deletedIds.length, equals(1));
      expect(mockNotificationService.canceledReminderIds.length, equals(1));
    });
  });
}
