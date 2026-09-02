import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Item representation for upcoming patient appointment list.
class UpcomingPatientItem {
  const UpcomingPatientItem({
    required this.name,
    required this.timeAndClinic,
    this.accentColor = AppColors.primary,
  });

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
class DashboardUpcomingSection extends StatelessWidget {
  const DashboardUpcomingSection({
    super.key,
    this.patients = const <UpcomingPatientItem>[
      UpcomingPatientItem(
        name: 'Sara Ahmed',
        timeAndClinic: '09:00 AM • Endo',
        accentColor: AppColors.primary,
      ),
      UpcomingPatientItem(
        name: 'Omar Khalid',
        timeAndClinic: '11:30 AM • Prosth',
        accentColor: AppColors.secondary,
      ),
      UpcomingPatientItem(
        name: 'Lina Mahmoud',
        timeAndClinic: '01:00 PM • Checkup',
        accentColor: AppColors.tertiary,
      ),
    ],
    this.onViewFullSchedule,
    this.onPatientTap,
  });

  final List<UpcomingPatientItem> patients;
  final VoidCallback? onViewFullSchedule;
  final ValueChanged<UpcomingPatientItem>? onPatientTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section Header
        Row(
          children: <Widget>[
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              "Tomorrow's Patients",
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Patient Items List
        Column(
          children: patients.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Material(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onPatientTap?.call(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: <Widget>[
                        // Initials Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.accentColor.withValues(alpha: 0.12),
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
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.timeAndClinic,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trailing Chevron
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.outlineVariant,
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
            onPressed: onViewFullSchedule ?? () {
              // TODO: Phase 5.4 - Navigate to Appointments Tab
            },
            child: Text(
              'View Full Schedule',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
