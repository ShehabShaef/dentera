import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../../patients/patient_case_sheet_screen.dart';

/// Card widget for highlighting the next upcoming patient appointment on the dashboard.
///
/// ### Routing Mechanism:
/// Activating "View Case" pushes the detailed [PatientCaseSheetScreen] onto the
/// imperative [Navigator] stack, passing the target [patientId].
/// Unlike root tab switches (which mutate Riverpod's `rootNavigationIndexProvider`
/// to preserve [IndexedStack] tab states), case sheet navigation creates an overlay route
/// enabling back navigation and focused clinical record management.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic surface, border, and shadow adaptation for dark/light themes
    final cardBgColor = isDark
        ? theme.colorScheme.surface
        : AppColors.surfaceContainerLowest;
    final borderColor = isDark
        ? AppDarkColors.outlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.5);
    final shadow = isDark ? AppDarkColors.cardShadow : AppColors.cardShadow;

    // Accent colors adapted for contrast in dark mode
    final effectiveClinicColor = (isDark && clinicColor == AppColors.secondary)
        ? AppDarkColors.secondary
        : clinicColor;
    final procedureAccentColor =
        isDark ? AppDarkColors.tertiary : AppColors.primary;

    // Text & Avatar contrast mapping
    final avatarBg = isDark
        ? AppDarkColors.surfaceContainerHigh
        : AppColors.surfaceContainerHigh;
    final avatarTextColor = isDark
        ? AppDarkColors.textPrimary
        : AppColors.onSurfaceVariant;
    final titleTextColor = isDark
        ? AppDarkColors.textPrimary
        : AppColors.onSurface;
    final subtitleTextColor = isDark
        ? AppDarkColors.textMuted
        : AppColors.onSurfaceVariant;
    final buttonIconColor = isDark
        ? AppDarkColors.textSecondary
        : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: <Widget>[
            // Leading Accent Border Indicator
            PositionedDirectional(
              top: 0,
              bottom: 0,
              start: 0,
              width: 4,
              child: Container(color: effectiveClinicColor),
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
                          color: effectiveClinicColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.alarm_rounded,
                              size: 14,
                              color: effectiveClinicColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeWindow,
                              style: AppTextStyles.caption.copyWith(
                                color: effectiveClinicColor,
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
                          color: procedureAccentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          procedureTitle,
                          style: AppTextStyles.labelCaps.copyWith(
                            color: procedureAccentColor,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: avatarBg,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: AppTextStyles.h2.copyWith(
                            color: avatarTextColor,
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
                                color: titleTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: $patientId • $patientDetails',
                              style: AppTextStyles.caption.copyWith(
                                color: subtitleTextColor,
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
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: buttonIconColor,
                    ),
                    onPressed: () {
                      if (onViewCase != null) {
                        onViewCase!();
                      } else {
                        AppLogger.info('Navigating to Patient Case Sheet for patient: $patientId');
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => PatientCaseSheetScreen(
                              patientId: patientId,
                            ),
                          ),
                        );
                      }
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
