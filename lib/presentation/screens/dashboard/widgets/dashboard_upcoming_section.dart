import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../state/state.dart';
import '../../patients/patient_case_sheet_screen.dart';

/// Item representation for upcoming patient appointment list.
class UpcomingPatientItem {
  const UpcomingPatientItem({
    this.patientId,
    required this.name,
    required this.timeAndClinic,
    this.accentColor = AppColors.primary,
  });

  final String? patientId;
  final String name;
  final String timeAndClinic;
  final Color accentColor;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// Section listing upcoming appointments with quick navigation.
///
/// ### Routing Mechanisms:
/// 1. **Deep Link Routing ([Navigator.push]):**
///    Tapping an individual patient item pushes [PatientCaseSheetScreen] onto the
///    active [Navigator] stack, carrying the patient's ID or entity. This maintains
///    full context isolation and standard back-stack functionality.
///
/// 2. **Tab Index Switching (Riverpod):**
///    Tapping "View Full Schedule" mutates [rootNavigationIndexProvider] to index `3`
///    (Appointments tab). This declaratively re-renders the root [IndexedStack],
///    switching the user to the full appointment agenda without destroying the
///    existing Dashboard scroll or state.
class DashboardUpcomingSection extends ConsumerWidget {
  const DashboardUpcomingSection({
    super.key,
    this.patients = const <UpcomingPatientItem>[],
    this.onViewFullSchedule,
    this.onPatientTap,
  });

  final List<UpcomingPatientItem> patients;
  final VoidCallback? onViewFullSchedule;
  final ValueChanged<UpcomingPatientItem>? onPatientTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemBg = isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest;
    final borderColor = isDark
        ? AppDarkColors.outlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.3);
    final mutedTextColor = isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final shadow = isDark ? AppDarkColors.cardShadow : AppColors.cardShadow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section Header
        Row(
          children: <Widget>[
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              "Tomorrow's Patients",
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppDarkColors.textPrimary : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Patient Items List or Zero State
        if (patients.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
                boxShadow: shadow,
              ),
              alignment: Alignment.center,
              child: Text(
                'No upcoming patients scheduled for tomorrow.',
                style: AppTextStyles.caption.copyWith(
                  color: mutedTextColor,
                ),
              ),
            ),
          )
        else
          Column(
          children: patients.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Material(
                color: itemBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    if (onPatientTap != null) {
                      onPatientTap!(item);
                    } else {
                      final targetPatientId = item.patientId ?? 'PT-1001';
                      AppLogger.info('Navigating to Patient Case Sheet for patient: $targetPatientId');
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => PatientCaseSheetScreen(
                            patientId: targetPatientId,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1.0,
                      ),
                      boxShadow: shadow,
                    ),
                    child: Row(
                      children: <Widget>[
                        // Initials Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.initials,
                            style: AppTextStyles.caption.copyWith(
                              color: item.accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name & Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.name,
                                style: AppTextStyles.bodyMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppDarkColors.textPrimary : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.timeAndClinic,
                                style: AppTextStyles.caption.copyWith(
                                  color: mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trailing Chevron
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),

        // View Full Schedule Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              if (onViewFullSchedule != null) {
                onViewFullSchedule!();
              } else {
                AppLogger.info('Switching root tab to Appointments');
                ref.read(rootNavigationIndexProvider.notifier).state = 3;
              }
            },
            child: Text(
              'View Full Schedule',
              style: AppTextStyles.caption.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
