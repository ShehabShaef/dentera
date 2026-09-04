import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
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
        'title': 'Name (A to Z)',
        'subtitle': 'Alphabetical order by patient name',
        'icon': Icons.sort_by_alpha_rounded,
      },
      {
        'option': PatientSortOption.dateAdded,
        'title': 'Date Added (Recent first)',
        'subtitle': 'Order by newest registered patient',
        'icon': Icons.calendar_today_rounded,
      },
      {
        'option': PatientSortOption.activeCaseCount,
        'title': 'Active Case Count',
        'subtitle': 'Prioritize patients with in-progress clinical procedures',
        'icon': Icons.folder_shared_outlined,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
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
                  color: AppColors.outlineVariant,
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
                        'Sort Patients',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Order patient roster by clinical criteria',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.outline),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8, color: AppColors.outlineVariant),

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
                      ? AppColors.secondaryContainer.withValues(alpha: 0.25)
                      : AppColors.surfaceContainerLow,
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
                            color: isSelected ? AppColors.secondary : AppColors.outline,
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
                                    color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.secondary,
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
