import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/state/state.dart';

void main() {
  final fixedClock = DateTime(2026, 9, 11, 14, 0); // 2:00 PM

  group('Dynamic Clinical Reminders Provider Tests (Issue #21)', () {
    test('returns empty reminders list when no clinical records exist', () {
      final container = ProviderContainer(
        overrides: [
          clinicalRemindersClockProvider.overrideWithValue(fixedClock),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          allAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          dailyAppointmentsProvider(DateTime(fixedClock.year, fixedClock.month, fixedClock.day))
              .overrideWith((ref) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
        ],
      );
      addTearDown(container.dispose);

      final reminders = container.read(clinicalRemindersProvider);
      expect(reminders, isEmpty);
    });

    test('generates alert pill for In Progress case older than 14 days without evaluation', () {
      final overdueCase = CaseRecord(
        id: 'case-overdue-1',
        patientId: 'PT-101',
        requirementId: 'req-1',
        status: 'In Progress',
        dateStarted: fixedClock.subtract(const Duration(days: 16)),
        dateCompleted: null,
      );
      final recentCase = CaseRecord(
        id: 'case-recent-2',
        patientId: 'PT-102',
        requirementId: 'req-1',
        status: 'In Progress',
        dateStarted: fixedClock.subtract(const Duration(days: 5)),
        dateCompleted: null,
      );
      final completedOldCase = CaseRecord(
        id: 'case-completed-3',
        patientId: 'PT-103',
        requirementId: 'req-1',
        status: 'Completed',
        dateStarted: fixedClock.subtract(const Duration(days: 25)),
        dateCompleted: fixedClock.subtract(const Duration(days: 5)),
      );

      final container = ProviderContainer(
        overrides: [
          clinicalRemindersClockProvider.overrideWithValue(fixedClock),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[overdueCase, recentCase, completedOldCase]),
          allAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          dailyAppointmentsProvider(DateTime(fixedClock.year, fixedClock.month, fixedClock.day))
              .overrideWith((ref) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
        ],
      );
      addTearDown(container.dispose);

      final reminders = container.read(clinicalRemindersProvider);
      expect(reminders.length, 1);

      final alert = reminders.first;
      expect(alert.type, ReminderType.alert);
      expect(alert.category, ReminderCategory.overdueCase);
      expect(alert.caseRecord, overdueCase);
      expect(alert.message, contains('overdue (16 days in progress)'));
    });

    test('generates warning pill for appointments starting within next 2 hours', () {
      final imminentApt = Appointment(
        id: 'apt-imminent',
        patientId: 'PT-201',
        clinicId: 'clinic-endo',
        scheduledDate: fixedClock.add(const Duration(minutes: 45)),
        status: 'Scheduled',
        procedureDescription: 'Root Canal Obturation',
      );
      final distantApt = Appointment(
        id: 'apt-distant',
        patientId: 'PT-202',
        clinicId: 'clinic-prosth',
        scheduledDate: fixedClock.add(const Duration(hours: 4)),
        status: 'Scheduled',
        procedureDescription: 'Crown Preparation',
      );
      final cancelledApt = Appointment(
        id: 'apt-cancelled',
        patientId: 'PT-203',
        clinicId: 'clinic-perio',
        scheduledDate: fixedClock.add(const Duration(minutes: 30)),
        status: 'Cancelled',
      );

      final container = ProviderContainer(
        overrides: [
          clinicalRemindersClockProvider.overrideWithValue(fixedClock),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          allAppointmentsProvider.overrideWith((ref) => <Appointment>[imminentApt, distantApt, cancelledApt]),
          dailyAppointmentsProvider(DateTime(fixedClock.year, fixedClock.month, fixedClock.day))
              .overrideWith((ref) => <Appointment>[imminentApt, distantApt, cancelledApt]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
        ],
      );
      addTearDown(container.dispose);

      final reminders = container.read(clinicalRemindersProvider);
      final imminentReminders =
          reminders.where((r) => r.category == ReminderCategory.imminentAppointment).toList();

      expect(imminentReminders.length, 1);
      final item = imminentReminders.first;
      expect(item.type, ReminderType.warning);
      expect(item.appointment, imminentApt);
      expect(item.message, contains('starting in 45m'));
      expect(item.message, contains('PT-201'));
    });

    test('evaluates clinical department quota pacing and generates alert below 25%', () {
      const clinicProsth = Clinic(
        id: 'clinic-prosth',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      );
      const clinicOperative = Clinic(
        id: 'clinic-op',
        name: 'Operative',
        academicYear: '5th Year',
        colorHex: '#006A64',
      );

      final reqs = <Requirement>[
        // Prosth: 2 / 20 = 10% (<25% -> alert)
        const Requirement(id: 'r1', clinicId: 'clinic-prosth', title: 'Complete Denture', targetCount: 10, completedCount: 1),
        const Requirement(id: 'r2', clinicId: 'clinic-prosth', title: 'RPD Framework', targetCount: 10, completedCount: 1),
        // Operative: 8 / 10 = 80% (>=25% -> on track)
        const Requirement(id: 'r3', clinicId: 'clinic-op', title: 'Class II Composite', targetCount: 10, completedCount: 8),
      ];

      final container = ProviderContainer(
        overrides: [
          clinicalRemindersClockProvider.overrideWithValue(fixedClock),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          allAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          dailyAppointmentsProvider(DateTime(fixedClock.year, fixedClock.month, fixedClock.day))
              .overrideWith((ref) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[clinicProsth, clinicOperative]),
          allRequirementsProvider.overrideWith((ref) => reqs),
        ],
      );
      addTearDown(container.dispose);

      final reminders = container.read(clinicalRemindersProvider);
      final quotaReminders =
          reminders.where((r) => r.category == ReminderCategory.laggingQuota).toList();

      expect(quotaReminders.length, 1);
      final quotaAlert = quotaReminders.first;
      expect(quotaAlert.clinic, clinicProsth);
      expect(quotaAlert.type, ReminderType.warning);
      expect(quotaAlert.message, contains('Prosthodontics quota lagging (10% / Target: 20)'));
    });
  });
}
