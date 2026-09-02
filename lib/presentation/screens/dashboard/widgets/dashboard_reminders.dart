import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

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

/// Horizontal scrolling reminder pills row.
class DashboardReminders extends StatelessWidget {
  const DashboardReminders({
    super.key,
    this.reminders = const <ClinicalReminderItem>[
      ClinicalReminderItem(
        message: 'Lab work due: Crown prep (Sara A.)',
        icon: Icons.warning_amber_rounded,
        type: ReminderType.warning,
      ),
      ClinicalReminderItem(
        message: 'Sign 2 endo charts by EOD',
        icon: Icons.info_outline_rounded,
        type: ReminderType.info,
      ),
      ClinicalReminderItem(
        message: 'Restock matrix bands',
        icon: Icons.inventory_2_outlined,
        type: ReminderType.neutral,
      ),
    ],
  });

  final List<ClinicalReminderItem> reminders;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reminders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = reminders[index];
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
