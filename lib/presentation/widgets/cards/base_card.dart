import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A foundational container card applying the 18px radius and subtle shadow from DESIGN.md.
class BaseCard extends StatelessWidget {
  const BaseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 18.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.hasShadow = true,
    this.hasBorder = true,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool hasShadow;
  final bool hasBorder;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? AppColors.surfaceContainerLowest;
    final effectiveBorderColor = borderColor ?? AppColors.outlineVariant;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              )
            : null,
        boxShadow: hasShadow ? AppColors.cardShadow : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
