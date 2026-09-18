import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../../state/state.dart';

/// Modal bottom sheet allowing clinical users to select the sorting order of the patient roster.
///
/// ### State Management & Reactivity:
/// Updates [patientSortOptionProvider] upon user selection. When the sort option mutates,
/// [filteredPatientListProvider] automatically recalculates the order of displayed patients
/// across all active search queries and category filters.
class SortPatientsModal extends ConsumerWidget {
  const SortPatientsModal({super.key});

  /// Convenience static helper to display the [SortPatientsModal].
  static Future<PatientSortOption?> show(BuildContext context) {
    AppLogger.info('Opened SortPatientsModal');
    return showModalBottomSheet<PatientSortOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SortPatientsModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(patientSortOptionProvider);

    final sortOptions = <Map<String, dynamic>>[
      {
        'option': PatientSortOption.name,
        'title': context.l10n.sortByName,
        'subtitle': context.l10n.sortByNameSubtitle,
        'icon': Icons.sort_by_alpha_rounded,
      },
      {
        'option': PatientSortOption.dateAdded,
        'title': context.l10n.sortByDateAdded,
        'subtitle': context.l10n.sortByDateAddedSubtitle,
        'icon': Icons.calendar_today_rounded,
      },
      {
        'option': PatientSortOption.activeCaseCount,
        'title': context.l10n.sortByActiveCases,
        'subtitle': context.l10n.sortByActiveCasesSubtitle,
        'icon': Icons.folder_shared_outlined,
      },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppDarkColors.dragHandle : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sortPatients,
                        style: AppTextStyles.h2.copyWith(
                          color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.orderPatientsSubtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.outline,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(
              height: 20,
              thickness: 0.8,
              color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant,
            ),

            // 3. Sorting Options List
            ...sortOptions.map((item) {
              final option = item['option'] as PatientSortOption;
              final title = item['title'] as String;
              final subtitle = item['subtitle'] as String;
              final icon = item['icon'] as IconData;
              final isSelected = currentSort == option;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  color: isSelected
                      ? (isDark
                          ? AppDarkColors.tealAccent.withValues(alpha: 0.15)
                          : AppColors.secondaryContainer.withValues(alpha: 0.25))
                      : (isDark
                          ? AppDarkColors.surfaceContainerHigh
                          : AppColors.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {
                      AppLogger.info('Changed patient sort option to: ${option.name}');
                      ref.read(patientSortOptionProvider.notifier).state = option;
                      Navigator.of(context).pop(option);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            icon,
                            color: isSelected
                                ? (isDark ? AppDarkColors.tealAccent : AppColors.secondary)
                                : (isDark ? AppDarkColors.textSecondary : AppColors.outline),
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  title,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark ? AppDarkColors.textPrimary : AppColors.onSurface)
                                        : (isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.caption.copyWith(
                                    color: isDark ? AppDarkColors.textSecondary : AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: isDark ? AppDarkColors.tealAccent : AppColors.secondary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
