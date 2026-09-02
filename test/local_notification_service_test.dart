import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/local_notification_service.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalNotificationService & Offline Reminders Tests', () {
    late PreferencesRepository prefsRepo;
    late LocalNotificationService notificationService;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'remindersEnabled': true,
      });
      prefsRepo = PreferencesRepository();
      notificationService = LocalNotificationService(prefsRepo: prefsRepo);
    });

    test('notificationIdForAppointment generates valid positive 32-bit int', () {
      final id1 = LocalNotificationService.notificationIdForAppointment('apt-1001');
      final id2 = LocalNotificationService.notificationIdForAppointment('apt-1002');

      expect(id1, isPositive);
      expect(id2, isPositive);
      expect(id1, isNot(equals(id2)));
    });

    test('scheduleAppointmentReminder skips if reminders are disabled in preferences', () async {
      await prefsRepo.setRemindersEnabled(false);

      final apt = Appointment(
        id: 'apt-01',
        patientId: 'PT-1001',
        clinicId: 'c-pros',
        scheduledDate: DateTime.now().add(const Duration(days: 1, hours: 2)),
        procedureDescription: 'Complete Denture',
      );

      final scheduled = await notificationService.scheduleAppointmentReminder(
        apt,
        clinicName: 'Prosthodontics',
      );

      expect(scheduled, isFalse);
    });

    test('scheduleAppointmentReminder rejects past appointment times', () async {
      final pastApt = Appointment(
        id: 'apt-past',
        patientId: 'PT-1001',
        clinicId: 'c-pros',
        scheduledDate: DateTime.now().subtract(const Duration(hours: 3)),
        procedureDescription: 'Past checkup',
      );

      final scheduled = await notificationService.scheduleAppointmentReminder(
        pastApt,
        clinicName: 'Prosthodontics',
      );

      expect(scheduled, isFalse);
    });

    test('cancelReminder and cancelAllReminders execute cleanly', () async {
      expect(() async => await notificationService.cancelReminder('apt-01'), returnsNormally);
      expect(() async => await notificationService.cancelAllReminders(), returnsNormally);
    });
  });
}
