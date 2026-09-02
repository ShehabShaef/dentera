import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A stylized circular progress indicator with gradient stroke and centered statistics.
class CircularProgressRing extends StatelessWidget {
  const CircularProgressRing({
    super.key,
    required this.progress,
    this.size = 80.0,
    this.strokeWidth = 8.0,
    this.trackColor,
    this.gradient,
    this.progressColor,
    this.centerText,
    this.centerTextStyle,
    this.child,
    this.showPercentage = true,
  });

  /// Progress value between 0.0 and 1.0
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? trackColor;
  final Gradient? gradient;
  final Color? progressColor;
  final String? centerText;
  final TextStyle? centerTextStyle;
  final Widget? child;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final effectiveTrackColor = trackColor ?? AppColors.surfaceVariant;
    final effectiveGradient = progressColor == null
        ? (gradient ??
            const SweepGradient(
              startAngle: -math.pi / 2,
              endAngle: 3 * math.pi / 2,
              colors: <Color>[AppColors.primary, AppColors.secondary],
            ))
        : null;

    final String displayText = centerText ?? '${(clampedProgress * 100).round()}%';
    final effectiveTextStyle = centerTextStyle ??
        AppTextStyles.h2.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: clampedProgress,
              strokeWidth: strokeWidth,
              trackColor: effectiveTrackColor,
              gradient: effectiveGradient,
              progressColor: progressColor,
            ),
          ),
          if (child != null)
            child!
          else if (showPercentage || centerText != null)
            Text(
              displayText,
              style: effectiveTextStyle,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.gradient,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Gradient? gradient;
  final Color? progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Draw progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (progressColor != null) {
      progressPaint.color = progressColor!;
    } else if (gradient != null) {
      progressPaint.shader = gradient!.createShader(rect);
    } else {
      progressPaint.color = AppColors.primary;
    }

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.gradient != gradient;
  }
}
