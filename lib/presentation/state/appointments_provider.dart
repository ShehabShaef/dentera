import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/services/local_notification_service.dart';
import '../../data/database/database_providers.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/appointment_repository.dart';

/// Currently selected date in the Appointments Timeline.
final selectedScheduleDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Provides scheduled appointments for a specific date from SQLite.
///
/// **Error Propagation Architecture:**
/// Database exceptions are allowed to bubble up naturally into Riverpod's [FutureProvider.family].
/// Rather than returning `<Appointment>[]` on error (which misled users into believing no patients
/// were scheduled), [AsyncError] enables the timeline to render a distinct error card with a retry button.
final dailyAppointmentsProvider =
    FutureProvider.family<List<Appointment>, DateTime>((ref, date) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return await repository.getAppointmentsByDate(date);
});

/// Provides all appointments recorded in the local database.
///
/// **Error Propagation Architecture:**
/// Database exceptions propagate to Riverpod's [FutureProvider] wrapped in [AsyncError].
final allAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return await repository.getAllAppointments();
});

/// Provides upcoming appointments from tomorrow onward.
///
/// **Error Propagation Architecture:**
/// Exceptions from [AppointmentRepository.getAllAppointments] propagate directly,
/// allowing dashboard sections to render error states and retry buttons.
final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final allApts = await ref.watch(appointmentRepositoryProvider).getAllAppointments();
  final now = DateTime.now();
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return allApts.where((apt) => apt.scheduledDate.isAfter(todayEnd)).toList();
});

/// State notifier and coordinator for appointment lifecycle mutations and local notification synchronization.
///
/// **Notification Trigger & Ghost Alert Prevention Architecture:**
/// In offline-first dental clinical practice, students depend on device alerts to manage
/// patient chairs and clinical requirements. Under this architecture:
///
/// 1. **Atomic SQLite Mutation First:**
///    The SQLite database transaction ([AppointmentRepository]) MUST succeed and commit *before*
///    any local notification intent is scheduled or altered. If the local database query throws an
///    exception (e.g., constraint failure or disk error), execution terminates immediately and
///    no notification is scheduled. This guarantees that "ghost alerts" (notifications reminding
///    the student of an appointment that failed to save) can never occur.
///
/// 2. **Preferences Opt-Out Verification:**
///    Before scheduling a notification intent, the coordinator verifies [PreferencesRepository.getRemindersEnabled].
///    If the clinician opted out of agenda reminders, the scheduling call is quietly bypassed without
///    failing or interrupting the database mutation.
///
/// 3. **Reschedule & Stale Alert Cancellation:**
///    When updating an existing appointment, the coordinator always cancels the previous notification
///    intent for [appointment.id] first. If the appointment remains in an active (non-canceled) state,
///    a new reminder is scheduled with the updated date/time. If the status is changed to "Canceled",
///    only the cancellation is performed.
///
/// 4. **Structured Logging:**
///    Every notification lifecycle transition is logged through [AppLogger.info] for auditability.
class AppointmentsNotifier extends StateNotifier<AsyncValue<void>> {
  AppointmentsNotifier({
    required this.appointmentRepository,
    required this.notificationService,
    required this.preferencesRepository,
    this.ref,
  }) : super(const AsyncValue.data(null));

  final AppointmentRepository appointmentRepository;
  final LocalNotificationService notificationService;
  final PreferencesRepository preferencesRepository;
  final Ref? ref;

  /// Inserts a newly scheduled appointment into the SQLite database and registers its local reminder.
  ///
  /// The SQLite insert operation is executed first. If successful and reminders are enabled in preferences,
  /// invokes [LocalNotificationService.scheduleAppointmentReminder] and logs the intent.
  Future<void> addAppointment(Appointment appointment, {String? clinicName}) async {
    state = const AsyncValue.loading();
    try {
      // 1. Persist to SQLite first to prevent ghost alerts
      await appointmentRepository.addAppointment(appointment);

      // 2. Check user notification preference
      final remindersEnabled = await preferencesRepository.getRemindersEnabled();
      if (remindersEnabled) {
        final scheduled = await notificationService.scheduleAppointmentReminder(
          appointment,
          clinicName: clinicName,
        );
        if (scheduled) {
          AppLogger.info('Scheduled notification for appointment: ${appointment.id}');
        }
      } else {
        AppLogger.info(
          'Reminders disabled in preferences: skipping notification for appointment: ${appointment.id}',
        );
      }

      _invalidateProviders(appointment.scheduledDate);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates an existing appointment in SQLite, cancels any prior notification, and reschedules if active.
  ///
  /// Upon successful database update:
  /// - Cancels previous notification reminder for [appointment.id].
  /// - If the appointment status is not "Canceled" (or "Cancelled") and reminders are enabled,
  ///   schedules a new notification with the updated schedule details.
  Future<void> updateAppointment(Appointment appointment, {String? clinicName}) async {
    state = const AsyncValue.loading();
    try {
      // 1. Commit SQLite update first
      await appointmentRepository.updateAppointment(appointment);

      // 2. Always cancel prior notification intent to avoid duplicate or stale alerts
      await notificationService.cancelReminder(appointment.id);
      AppLogger.info('Canceled notification for appointment: ${appointment.id}');

      // 3. Reschedule only if appointment is not canceled/completed and reminders are enabled
      final isCanceledOrCompleted = appointment.status.toLowerCase() == 'canceled' ||
          appointment.status.toLowerCase() == 'cancelled' ||
          appointment.status.toLowerCase() == 'completed';

      if (!isCanceledOrCompleted) {
        final remindersEnabled = await preferencesRepository.getRemindersEnabled();
        if (remindersEnabled) {
          final scheduled = await notificationService.scheduleAppointmentReminder(
            appointment,
            clinicName: clinicName,
          );
          if (scheduled) {
            AppLogger.info('Scheduled notification for appointment: ${appointment.id}');
          }
        } else {
          AppLogger.info(
            'Reminders disabled in preferences: skipping reschedule for appointment: ${appointment.id}',
          );
        }
      }

      _invalidateProviders(appointment.scheduledDate);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deletes an appointment from SQLite and cancels its scheduled local notification reminder.
  Future<void> deleteAppointment(String id, {DateTime? scheduledDate}) async {
    state = const AsyncValue.loading();
    try {
      // 1. Delete from SQLite
      await appointmentRepository.deleteAppointment(id);

      // 2. Cancel registered notification intent
      await notificationService.cancelReminder(id);
      AppLogger.info('Canceled notification for appointment: $id');

      _invalidateProviders(scheduledDate);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Convenience method to cancel an appointment by setting its status to 'Canceled' in SQLite
  /// and revoking its local notification reminder.
  Future<void> cancelAppointment(Appointment appointment) async {
    final canceledAppointment = appointment.copyWith(status: 'Canceled');
    await updateAppointment(canceledAppointment);
  }

  void _invalidateProviders(DateTime? scheduledDate) {
    if (ref == null) return;
    if (scheduledDate != null) {
      ref!.invalidate(dailyAppointmentsProvider(scheduledDate));
    }
    ref!.invalidate(allAppointmentsProvider);
    ref!.invalidate(upcomingAppointmentsProvider);
  }
}

/// Riverpod StateNotifierProvider managing appointment mutations and notification synchronization.
final appointmentsNotifierProvider =
    StateNotifierProvider<AppointmentsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(appointmentRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final preferencesRepo = ref.watch(preferencesRepositoryProvider);
  return AppointmentsNotifier(
    appointmentRepository: repository,
    notificationService: notificationService,
    preferencesRepository: preferencesRepo,
    ref: ref,
  );
});

/// Backwards-compatible alias for appointments mutation provider.
final appointmentsProvider = appointmentsNotifierProvider;

