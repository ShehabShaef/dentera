import 'package:flutter/material.dart';
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

  static const List<String> _weekDays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
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

          final weekdayName = _weekDays[date.weekday - 1];

          return InkWell(
            onTap: () => onDateSelected(date),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant.withValues(alpha: 0.4),
                  width: 1.0,
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    weekdayName,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: AppTextStyles.h2.copyWith(
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
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
