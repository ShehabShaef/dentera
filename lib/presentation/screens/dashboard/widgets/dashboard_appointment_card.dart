import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../widgets/widgets.dart';

/// Card widget for highlighting the next upcoming patient appointment on the dashboard.
class DashboardAppointmentCard extends StatelessWidget {
  const DashboardAppointmentCard({
    super.key,
    required this.patientName,
    required this.patientId,
    required this.patientDetails,
    required this.timeWindow,
    required this.procedureTitle,
    this.clinicColor = AppColors.secondary,
    this.onViewCase,
  });

  final String patientName;
  final String patientId;
  final String patientDetails;
  final String timeWindow;
  final String procedureTitle;
  final Color clinicColor;
  final VoidCallback? onViewCase;

  String get _initials {
    final parts = patientName.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return patientName.substring(0, patientName.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: <Widget>[
            // Left Accent Border Indicator
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 4,
              child: Container(color: clinicColor),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Badges: Time & Clinic/Procedure
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: clinicColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.alarm_rounded,
                              size: 14,
                              color: clinicColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeWindow,
                              style: AppTextStyles.caption.copyWith(
                                color: clinicColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Procedure Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          procedureTitle,
                          style: AppTextStyles.labelCaps.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Patient Details
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceContainerHigh,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              patientName,
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: $patientId • $patientDetails',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // View Case Button
                  SecondaryButton(
                    text: 'View Case',
                    height: 40,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    onPressed: onViewCase ?? () {
                      // TODO: Phase 6.2 - Open Patient Case Sheet
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
