import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A circular or squircle icon button supporting brand gradients and subtle borders.
class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isCircular = false,
    this.isGradient = false,
    this.size = 48.0,
    this.iconSize = 24.0,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.tooltip,
    this.hasShadow = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final bool isCircular;
  final bool isGradient;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final String? tooltip;
  final bool hasShadow;

  bool get _isEnabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = isCircular
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(borderRadius);

    final effectiveBgColor = backgroundColor ??
        (isGradient
            ? null
            : (_isEnabled
                ? AppColors.surfaceContainerLowest
                : AppColors.surfaceContainerHigh));

    final effectiveIconColor = iconColor ??
        (isGradient
            ? AppColors.onPrimary
            : (_isEnabled ? AppColors.onSurfaceVariant : AppColors.outline));

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isGradient ? null : effectiveBgColor,
        gradient: (isGradient && _isEnabled) ? AppColors.brandGradient : null,
        borderRadius: effectiveBorderRadius,
        border: (borderColor != null || (!isGradient && backgroundColor == null))
            ? Border.all(
                color: borderColor ?? AppColors.outlineVariant,
                width: 1.0,
              )
            : null,
        boxShadow: hasShadow ? AppColors.cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: effectiveBorderRadius,
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: effectiveIconColor,
                size: iconSize,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
