import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../state/state.dart';

/// Clinical reminder item data model.
class ClinicalReminderItem {
  const ClinicalReminderItem({
    required this.message,
    required this.icon,
    this.type = ReminderType.info,
  });

  final String message;
  final IconData icon;
  final ReminderType type;
}

enum ReminderType { warning, info, neutral }

/// Horizontal scrolling reminder pills row dynamically populated from Riverpod SQLite state.
///
/// **Architecture Note (v0.4 UI Scope Reduction):**
/// In v0.4, all hardcoded visual mock reminders ('Review clinical quota targets',
/// 'Sign completed charts by EOD', 'Restock procedural supplies') were pruned.
/// This widget now dynamically evaluates active appointments from [dailyAppointmentsProvider]
/// and [upcomingAppointmentsProvider]. If no appointments require immediate clinical attention,
/// it gracefully returns [SizedBox.shrink] without consuming layout space.
class DashboardReminders extends ConsumerWidget {
  const DashboardReminders({
    super.key,
    this.reminders,
  });

  /// Optional explicit reminders list. If null, reminders are dynamically evaluated
  /// from Riverpod appointment state.
  final List<ClinicalReminderItem>? reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<ClinicalReminderItem> activeReminders;

    if (reminders != null) {
      activeReminders = reminders!;
    } else {
      activeReminders = <ClinicalReminderItem>[];

      final todayApts = ref.watch(dailyAppointmentsProvider(DateTime.now())).valueOrNull ?? const [];
      final upcomingApts = ref.watch(upcomingAppointmentsProvider).valueOrNull ?? const [];

      // Check for pending or scheduled appointments today
      final pendingOrScheduledToday = todayApts.where((apt) {
        final status = apt.status.toLowerCase();
        return status == 'pending' || status == 'scheduled' || status == 'confirmed';
      }).toList();

      if (pendingOrScheduledToday.isNotEmpty) {
        activeReminders.add(
          ClinicalReminderItem(
            message: '${pendingOrScheduledToday.length} appointment(s) scheduled today',
            icon: Icons.schedule,
            type: ReminderType.warning,
          ),
        );
      }

      // Check for upcoming appointments tomorrow and beyond
      if (upcomingApts.isNotEmpty) {
        activeReminders.add(
          ClinicalReminderItem(
            message: '${upcomingApts.length} upcoming appointment(s) scheduled',
            icon: Icons.event_note,
            type: ReminderType.info,
          ),
        );
      }
    }

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
          Color bgColor;
          Color textColor;
          Color borderColor;

          switch (item.type) {
            case ReminderType.warning:
              bgColor = AppColors.error.withValues(alpha: 0.1);
              textColor = AppColors.error;
              borderColor = AppColors.error.withValues(alpha: 0.25);
              break;
            case ReminderType.info:
              bgColor = AppColors.secondary.withValues(alpha: 0.1);
              textColor = AppColors.secondary;
              borderColor = AppColors.secondary.withValues(alpha: 0.25);
              break;
            case ReminderType.neutral:
              bgColor = AppColors.surfaceContainerHigh;
              textColor = AppColors.onSurfaceVariant;
              borderColor = AppColors.outlineVariant.withValues(alpha: 0.3);
              break;
          }

          return Container(
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
