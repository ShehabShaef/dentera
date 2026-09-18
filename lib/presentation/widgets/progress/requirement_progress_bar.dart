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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveTrackColor = trackColor ??
        (isDark ? const Color(0xFF1E293B) : AppColors.surfaceVariant);
    final effectiveProgressColor = progressColor ??
        (isDark ? AppDarkColors.primary : null);
    final effectiveGradient = effectiveProgressColor == null
        ? (progressGradient ?? AppColors.brandGradient)
        : null;
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
                    color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppDarkColors.primary : AppColors.primary,
                    fontWeight: FontWeight.w700,
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
                border: isDark ? Border.all(color: const Color(0xFF2A3C53), width: 1) : null,
              ),
              child: Stack(
                children: <Widget>[
                  AnimatedContainer(
                    duration: animationDuration,
                    curve: Curves.easeInOut,
                    width: progressWidth,
                    height: height,
                    decoration: BoxDecoration(
                      color: effectiveGradient == null ? (effectiveProgressColor ?? AppColors.primary) : null,
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
