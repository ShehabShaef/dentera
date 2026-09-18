import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../widgets/widgets.dart';

/// Overview card presenting global quota metrics and department breakdowns.
class DashboardProgressCard extends StatelessWidget {
  const DashboardProgressCard({
    super.key,
    this.overallProgress = 0.0,
    this.overallPercentageText = '0%',
    this.requirements = const <ClinicQuotaSummary>[],
  });

  final double overallProgress;
  final String overallPercentageText;
  final List<ClinicQuotaSummary> requirements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final metricColor = isDark ? AppDarkColors.primary : AppColors.secondary;
    final mutedTextColor = isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant;
    final trackColor = isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerHighest;

    return BaseCard(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Circular Metric
          CircularProgressRing(
            size: 96,
            strokeWidth: 8,
            progress: overallProgress,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  overallPercentageText,
                  style: AppTextStyles.h2.copyWith(
                    color: metricColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.reqs,
                  style: AppTextStyles.labelCaps.copyWith(
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Clinic Quota Progress Bars or Zero State
          Expanded(
            child: requirements.isEmpty
                ? Text(
                    context.l10n.noActiveRequirements,
                    style: AppTextStyles.caption.copyWith(
                      color: mutedTextColor,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: requirements.map((quota) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: RequirementProgressBar.fromQuota(
                          label: quota.clinicName,
                          completed: quota.completed,
                          total: quota.total,
                          height: 8.0,
                          trackColor: trackColor,
                          progressColor: metricColor,
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Data holder for dashboard quota summary row.
class ClinicQuotaSummary {
  const ClinicQuotaSummary({
    required this.clinicName,
    required this.completed,
    required this.total,
  });

  final String clinicName;
  final int completed;
  final int total;
}
