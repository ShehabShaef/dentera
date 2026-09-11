import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import 'appointments_provider.dart';
import 'cases_provider.dart';
import 'clinics_provider.dart';
import 'requirements_provider.dart';

/// Semantic classification of clinical reminder pills.
enum ReminderType {
  alert,
  warning,
  info,
  neutral,
}

/// Category of clinical concern represented by the reminder pill.
enum ReminderCategory {
  overdueCase,
  imminentAppointment,
  laggingQuota,
  generalSchedule,
}

/// Clinical reminder item data model for dynamic dashboard alerts.
class ClinicalReminderItem {
  const ClinicalReminderItem({
    required this.id,
    required this.message,
    required this.icon,
    this.type = ReminderType.info,
    this.category = ReminderCategory.generalSchedule,
    this.caseRecord,
    this.appointment,
    this.clinic,
    this.onTap,
  });

  final String id;
  final String message;
  final IconData icon;
  final ReminderType type;
  final ReminderCategory category;
  final CaseRecord? caseRecord;
  final Appointment? appointment;
  final Clinic? clinic;
  final VoidCallback? onTap;
}

/// Reference clock provider for deterministic time evaluations in tests and live usage.
final clinicalRemindersClockProvider = Provider<DateTime>((ref) => DateTime.now());

/// Dynamically evaluates SQLite clinical streams to generate prioritized reminder pills:
/// 1. Overdue cases in "In Progress" status for >=14 days without an evaluation.
/// 2. Imminent appointments starting within the next 2 hours.
/// 3. Department quota pacing alerts for clinics below 25% completed requirements.
/// 4. General schedule counters for today and upcoming appointments.
final clinicalRemindersProvider = Provider<List<ClinicalReminderItem>>((ref) {
  final now = ref.watch(clinicalRemindersClockProvider);
  final today = DateTime(now.year, now.month, now.day);

  final cases = ref.watch(allCasesProvider).valueOrNull ?? const <CaseRecord>[];
  final allApts = ref.watch(allAppointmentsProvider).valueOrNull ?? const <Appointment>[];
  final todayApts = ref.watch(dailyAppointmentsProvider(today)).valueOrNull ?? const <Appointment>[];
  final upcomingApts = ref.watch(upcomingAppointmentsProvider).valueOrNull ?? const <Appointment>[];
  final clinics = ref.watch(clinicListProvider).valueOrNull ?? const <Clinic>[];
  final allRequirements = ref.watch(allRequirementsProvider).valueOrNull ?? const <Requirement>[];

  final items = <ClinicalReminderItem>[];

  // 1. Overdue Cases Alert (In Progress >= 14 days without completion/evaluation)
  for (final c in cases) {
    final isCompleted = c.dateCompleted != null || c.status.toLowerCase() == 'completed';
    final isInProgress = c.status.toLowerCase() == 'in progress' || (!isCompleted && c.status.isNotEmpty);

    if (isInProgress && !isCompleted) {
      final diffDays = now.difference(c.dateStarted).inDays;
      if (diffDays >= 14) {
        final shortId = c.id.length > 6 ? c.id.substring(0, 6) : c.id;
        items.add(
          ClinicalReminderItem(
            id: 'overdue-case-${c.id}',
            message: 'Case #$shortId: overdue ($diffDays days in progress)',
            icon: Icons.warning_amber_rounded,
            type: ReminderType.alert,
            category: ReminderCategory.overdueCase,
            caseRecord: c,
          ),
        );
      }
    }
  }

  // 2. Imminent Appointments Warning (starting within next 2 hours)
  final candidateApts = <String, Appointment>{};
  for (final apt in todayApts) {
    candidateApts[apt.id] = apt;
  }
  for (final apt in allApts) {
    candidateApts[apt.id] = apt;
  }

  for (final apt in candidateApts.values) {
    final status = apt.status.toLowerCase();
    if (status == 'cancelled' || status == 'completed') continue;

    final diff = apt.scheduledDate.difference(now);
    if (!diff.isNegative && diff <= const Duration(hours: 2)) {
      final minutes = diff.inMinutes;
      final timeStr = minutes <= 0
          ? 'starting now'
          : minutes < 60
              ? 'starting in ${minutes}m'
              : 'starting in ${(minutes / 60).toStringAsFixed(1)}h';

      items.add(
        ClinicalReminderItem(
          id: 'imminent-apt-${apt.id}',
          message: 'Appointment $timeStr (Patient #${apt.patientId})',
          icon: Icons.alarm,
          type: ReminderType.warning,
          category: ReminderCategory.imminentAppointment,
          appointment: apt,
        ),
      );
    }
  }

  // 3. Department Quota Pacing Alert (< 25% completed near evaluation deadlines)
  for (final clinic in clinics) {
    final clinicReqs = allRequirements.where((r) => r.clinicId == clinic.id).toList();
    if (clinicReqs.isNotEmpty) {
      final totalTarget = clinicReqs.fold(0, (sum, r) => sum + r.targetCount);
      final totalCompleted = clinicReqs.fold(0, (sum, r) => sum + r.completedCount);

      if (totalTarget > 0) {
        final progressFraction = totalCompleted / totalTarget;
        if (progressFraction < 0.25) {
          final percent = (progressFraction * 100).round();
          items.add(
            ClinicalReminderItem(
              id: 'quota-pacing-${clinic.id}',
              message: '${clinic.name} quota lagging ($percent% / Target: $totalTarget)',
              icon: Icons.pie_chart_outline_rounded,
              type: ReminderType.warning,
              category: ReminderCategory.laggingQuota,
              clinic: clinic,
            ),
          );
        }
      }
    }
  }

  // 4. General Schedule Counters (fallback / supplementary schedule view)
  final hasImminent = items.any((i) => i.category == ReminderCategory.imminentAppointment);
  final pendingOrScheduledToday = todayApts.where((apt) {
    final status = apt.status.toLowerCase();
    return status == 'pending' || status == 'scheduled' || status == 'confirmed';
  }).toList();

  if (pendingOrScheduledToday.isNotEmpty && !hasImminent) {
    items.add(
      ClinicalReminderItem(
        id: 'today-apts-summary',
        message: '${pendingOrScheduledToday.length} appointment(s) scheduled today',
        icon: Icons.schedule,
        type: ReminderType.warning,
        category: ReminderCategory.generalSchedule,
      ),
    );
  }

  if (upcomingApts.isNotEmpty) {
    items.add(
      ClinicalReminderItem(
        id: 'upcoming-apts-summary',
        message: '${upcomingApts.length} upcoming appointment(s) scheduled',
        icon: Icons.event_note,
        type: ReminderType.info,
        category: ReminderCategory.generalSchedule,
      ),
    );
  }

  return items;
});
