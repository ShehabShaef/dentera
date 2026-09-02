import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A linear progress bar designed for clinical requirement quotas.
/// Displays optional label and fraction/percentage indicator.
class RequirementProgressBar extends StatelessWidget {
  const RequirementProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.valueLabel,
    this.height = 8.0,
    this.trackColor,
    this.progressGradient,
    this.progressColor,
    this.borderRadius = 9999.0,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  /// Factory for count/quota based progress (e.g. 3 of 5 completed)
  factory RequirementProgressBar.fromQuota({
    Key? key,
    required int completed,
    required int total,
    String? label,
    bool showQuotaText = true,
    double height = 8.0,
    Color? trackColor,
    Gradient? progressGradient,
    Color? progressColor,
    double borderRadius = 9999.0,
  }) {
    final double safeProgress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final String valueText = showQuotaText ? '$completed/$total' : '${(safeProgress * 100).round()}%';
    return RequirementProgressBar(
      key: key,
      progress: safeProgress,
      label: label,
      valueLabel: valueText,
      height: height,
      trackColor: trackColor,
      progressGradient: progressGradient,
      progressColor: progressColor,
      borderRadius: borderRadius,
    );
  }

  /// Value between 0.0 and 1.0
  final double progress;
  final String? label;
  final String? valueLabel;
  final double height;
  final Color? trackColor;
  final Gradient? progressGradient;
  final Color? progressColor;
  final double borderRadius;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final effectiveTrackColor = trackColor ?? AppColors.surfaceVariant;
    final effectiveGradient = progressColor == null ? (progressGradient ?? AppColors.brandGradient) : null;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null || valueLabel != null) ...<Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (label != null)
                Text(
                  label!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final progressWidth = maxWidth * clampedProgress;

            return Container(
              width: maxWidth,
              height: height,
              decoration: BoxDecoration(
                color: effectiveTrackColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Stack(
                children: <Widget>[
                  AnimatedContainer(
                    duration: animationDuration,
                    curve: Curves.easeInOut,
                    width: progressWidth,
                    height: height,
                    decoration: BoxDecoration(
                      color: effectiveGradient == null ? (progressColor ?? AppColors.primary) : null,
                      gradient: effectiveGradient,
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
