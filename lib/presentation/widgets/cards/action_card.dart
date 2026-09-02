import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// An interactive extension of [BaseCard] with ripple feedback on tap.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
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
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
