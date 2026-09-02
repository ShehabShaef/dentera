import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/repositories/preferences_repository.dart';
import '../../domain/entities/entities.dart';

/// Local, offline notification service for scheduling clinical appointment reminders.
class LocalNotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    PreferencesRepository? prefsRepo,
  })  : _notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _prefsRepo = prefsRepo ?? PreferencesRepository();

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final PreferencesRepository _prefsRepo;

  static const String _channelId = 'dentera_appointments_channel';
  static const String _channelName = 'Clinical Appointments';
  static const String _channelDescription =
      'Reminders for upcoming scheduled clinical appointments and patient procedures';

  bool _isInitialized = false;

  /// Initializes the local notification plugin and sets up timezone data.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);

      // Request notification permissions dynamically on Android 13+ (API 33+)
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService init error (safe in test): $e');
    }
  }

  /// Converts an appointment ID to a valid 32-bit positive integer notification ID.
  static int notificationIdForAppointment(String appointmentId) {
    return appointmentId.hashCode.abs() % 2147483647;
  }

  /// Schedules a local notification reminder for an appointment.
  ///
  /// By default, schedules a reminder 2 hours prior to the scheduled slot.
  /// If notifications are disabled in preferences, scheduling is quietly skipped.
  Future<bool> scheduleAppointmentReminder(
    Appointment appointment, {
    String? clinicName,
  }) async {
    try {
      // 1. Check user preference opt-out
      final remindersEnabled = await _prefsRepo.getRemindersEnabled();
      if (!remindersEnabled) {
        debugPrint('Local reminders are disabled in settings. Skipping schedule.');
        return false;
      }

      if (!_isInitialized) {
        await initialize();
      }

      final now = DateTime.now();
      final appointmentTime = appointment.scheduledDate;

      if (appointmentTime.isBefore(now)) {
        debugPrint('Cannot schedule reminder for past appointment: ${appointment.id}');
        return false;
      }

      // 2. Determine optimal reminder trigger time (e.g. 2 hours before)
      DateTime reminderTime = appointmentTime.subtract(const Duration(hours: 2));
      if (reminderTime.isBefore(now)) {
        // If appointment is sooner than 2 hours, set reminder 15 minutes before, or 30 seconds from now
        reminderTime = appointmentTime.subtract(const Duration(minutes: 15));
        if (reminderTime.isBefore(now)) {
          reminderTime = now.add(const Duration(seconds: 30));
        }
      }

      final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
      final notificationId = notificationIdForAppointment(appointment.id);

      final hourStr = appointmentTime.hour.toString().padLeft(2, '0');
      final minuteStr = appointmentTime.minute.toString().padLeft(2, '0');
      final formattedTime = '$hourStr:$minuteStr';

      final department = clinicName ?? 'Clinic';
      final procedure = appointment.procedureDescription ?? 'Scheduled Procedure';

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Upcoming Clinic',
        body: '$department: $procedure at $formattedTime',
        scheduledDate: tzReminderTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('Successfully scheduled local reminder for appointment ${appointment.id} at $tzReminderTime');
      return true;
    } catch (e) {
      debugPrint('Failed to schedule local notification: $e');
      return false;
    }
  }

  /// Cancels a specific scheduled reminder by appointment ID.
  Future<void> cancelReminder(String appointmentId) async {
    try {
      final notificationId = notificationIdForAppointment(appointmentId);
      await _notificationsPlugin.cancel(id: notificationId);
      debugPrint('Cancelled notification reminder for appointment: $appointmentId');
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  /// Cancels all pending notifications across the application.
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Cancelled all pending notifications.');
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }
}

/// Riverpod provider for [LocalNotificationService].
final notificationServiceProvider = Provider<LocalNotificationService>((ref) {
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  return LocalNotificationService(prefsRepo: prefsRepo);
});
