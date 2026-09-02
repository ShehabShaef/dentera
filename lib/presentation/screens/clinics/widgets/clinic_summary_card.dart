import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../widgets/widgets.dart';

/// Card widget visualizing departmental clinical progress and top quota requirements.
class ClinicSummaryCard extends StatelessWidget {
  const ClinicSummaryCard({
    super.key,
    required this.clinic,
    required this.requirements,
    this.onTap,
  });

  final Clinic clinic;
  final List<Requirement> requirements;
  final VoidCallback? onTap;

  Color get _clinicColor {
    try {
      final hex = clinic.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.secondary;
    }
  }

  int get _totalTarget => requirements.fold(0, (sum, r) => sum + r.targetCount);
  int get _totalCompleted => requirements.fold(0, (sum, r) => sum + r.completedCount);
  int get _remainingCount => (_totalTarget - _totalCompleted).clamp(0, 9999);

  int get _completionPercentage {
    if (_totalTarget == 0) return 0;
    return ((_totalCompleted / _totalTarget) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final topRequirements = requirements.take(3).toList();

    return BaseCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header: Clinic Title & Percentage Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  clinic.name,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _clinicColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '$_completionPercentage% Complete',
                  style: AppTextStyles.caption.copyWith(
                    color: _clinicColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Body: Top Requirements
          if (topRequirements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No requirements assigned yet.',
                style: AppTextStyles.caption.copyWith(color: AppColors.outline),
              ),
            )
          else
            ...topRequirements.map((req) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: RequirementProgressBar.fromQuota(
                  label: req.title,
                  completed: req.completedCount,
                  total: req.targetCount,
                  height: 8.0,
                  trackColor: AppColors.surfaceVariant,
                  progressColor: _clinicColor,
                ),
              );
            }),

          const Divider(
            color: AppColors.outlineVariant,
            height: 24,
            thickness: 0.8,
          ),

          // Footer: Requirements left & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  '$_remainingCount requirements left',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SecondaryButton(
                isFullWidth: false,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                text: 'View Cases',
                borderColor: AppColors.primary,
                onPressed: onTap ?? () {
                  // TODO: Phase 6.3 - Navigate to clinic_details_prosthodontics
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
