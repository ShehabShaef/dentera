import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../widgets/widgets.dart';

/// Overview card presenting global quota metrics and department breakdowns.
class DashboardProgressCard extends StatelessWidget {
  const DashboardProgressCard({
    super.key,
    this.overallProgress = 0.68,
    this.overallPercentageText = '68%',
    this.requirements = const <ClinicQuotaSummary>[
      ClinicQuotaSummary(clinicName: 'Prosthodontics', completed: 8, total: 10),
      ClinicQuotaSummary(clinicName: 'Endodontics', completed: 4, total: 5),
    ],
  });

  final double overallProgress;
  final String overallPercentageText;
  final List<ClinicQuotaSummary> requirements;

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Reqs',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Clinic Quota Progress Bars
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: requirements.map((quota) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: RequirementProgressBar.fromQuota(
                    label: quota.clinicName,
                    completed: quota.completed,
                    total: quota.total,
                    height: 8.0,
                    trackColor: AppColors.surfaceContainerHighest,
                    progressColor: AppColors.secondary,
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
