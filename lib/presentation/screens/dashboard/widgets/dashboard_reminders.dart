import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../state/state.dart';
import '../../clinics/clinic_details_screen.dart';
import '../../patients/patient_case_sheet_screen.dart';

/// Horizontal scrolling reminder pills row dynamically populated from Riverpod clinical state.
///
/// Intelligently displays prioritized clinical reminder pills:
/// - Overdue cases (>=14 days in progress without evaluation)
/// - Imminent appointments (<2 hours)
/// - Clinical department quota pacing alerts (<25% completed)
/// - General schedule summaries
///
/// Tapping a reminder routes directly to the relevant case, appointment, or clinic screen.
class DashboardReminders extends ConsumerWidget {
  const DashboardReminders({
    super.key,
    this.reminders,
  });

  /// Optional explicit reminders list. If null, reminders are dynamically evaluated
  /// from [clinicalRemindersProvider].
  final List<ClinicalReminderItem>? reminders;

  void _handleReminderTap(BuildContext context, WidgetRef ref, ClinicalReminderItem item) {
    if (item.onTap != null) {
      item.onTap!();
      return;
    }

    if (item.caseRecord != null) {
      AppLogger.info('Navigating to PatientCaseSheetScreen for overdue case: ${item.caseRecord!.id}');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PatientCaseSheetScreen(
            patientId: item.caseRecord!.patientId,
          ),
        ),
      );
      return;
    }

    if (item.appointment != null) {
      AppLogger.info('Navigating to PatientCaseSheetScreen for imminent appointment: ${item.appointment!.id}');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PatientCaseSheetScreen(
            patientId: item.appointment!.patientId,
          ),
        ),
      );
      return;
    }

    if (item.clinic != null) {
      AppLogger.info('Navigating to ClinicDetailsScreen for lagging quota: ${item.clinic!.name}');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ClinicDetailsScreen(
            clinic: item.clinic!,
          ),
        ),
      );
      return;
    }

    if (item.category == ReminderCategory.generalSchedule) {
      AppLogger.info('Switching root navigation tab to Schedule (Appointments)');
      ref.read(rootNavigationIndexProvider.notifier).state = 3;
      return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ClinicalReminderItem> activeReminders =
        reminders ?? ref.watch(clinicalRemindersProvider);

    if (activeReminders.isEmpty) {
      AppLogger.debug('Dashboard reminders returning SizedBox.shrink() due to empty state');
      return const SizedBox.shrink();
    }

    AppLogger.debug('Dashboard reminders rendering ${activeReminders.length} dynamic reminders');

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: activeReminders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = activeReminders[index];
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          Color bgColor;
          Color textColor;
          Color borderColor;

          switch (item.type) {
            case ReminderType.alert:
              bgColor = isDark
                  ? const Color(0xFF93000A).withValues(alpha: 0.25)
                  : AppColors.error.withValues(alpha: 0.12);
              textColor = isDark ? const Color(0xFFFFB4AB) : AppColors.error;
              borderColor = isDark
                  ? const Color(0xFFBA1A1A).withValues(alpha: 0.5)
                  : AppColors.error.withValues(alpha: 0.4);
              break;
            case ReminderType.warning:
              bgColor = isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : const Color(0xFFD97706).withValues(alpha: 0.12);
              textColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);
              borderColor = isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                  : const Color(0xFFD97706).withValues(alpha: 0.4);
              break;
            case ReminderType.info:
              bgColor = isDark
                  ? AppDarkColors.primaryContainer.withValues(alpha: 0.15)
                  : AppColors.secondary.withValues(alpha: 0.1);
              textColor = isDark ? AppDarkColors.primary : AppColors.secondary;
              borderColor = isDark
                  ? AppDarkColors.primaryContainer.withValues(alpha: 0.4)
                  : AppColors.secondary.withValues(alpha: 0.25);
              break;
            case ReminderType.neutral:
              bgColor = isDark
                  ? AppDarkColors.surfaceContainerElevated
                  : AppColors.surfaceContainerHigh;
              textColor = isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant;
              borderColor = isDark
                  ? const Color(0xFF2A3D54)
                  : AppColors.outlineVariant.withValues(alpha: 0.3);
              break;
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: () => _handleReminderTap(context, ref, item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      item.icon,
                      size: 16,
                      color: textColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.message,
                      style: AppTextStyles.caption.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
