import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';

/// Horizontal scrolling calendar strip widget for day selection.
class DateSelectorStrip extends StatelessWidget {
  const DateSelectorStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysCount = 14,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int daysCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    // Generate dates starting from 2 days before today/selectedDate
    final startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day).subtract(const Duration(days: 2));

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: daysCount,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          final weekdayName = DateFormat.E(locale).format(date);

          return InkWell(
            onTap: () => onDateSelected(date),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppDarkColors.primaryTeal : AppColors.primary)
                    : (isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppDarkColors.primaryTeal : AppColors.primary)
                      : (isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.4)),
                  width: 1.0,
                ),
                boxShadow: isDark ? AppDarkColors.cardShadow : AppColors.cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    weekdayName,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? (isDark ? AppDarkColors.onPrimary : AppColors.onPrimary)
                          : (isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: AppTextStyles.h2.copyWith(
                      color: isSelected
                          ? (isDark ? AppDarkColors.onPrimary : AppColors.onPrimary)
                          : (isDark ? AppDarkColors.textPrimary : AppColors.onSurface),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
