import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A primary action button with the Dentera brand gradient and 12px rounded corners.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.padding,
    this.textStyle,
    this.borderRadius = 12.0,
  });

  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final double borderRadius;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveTextColor = _isEnabled
        ? (isDark ? AppDarkColors.onPrimary : AppColors.onPrimary)
        : (isDark ? AppDarkColors.textMuted : AppColors.outline);

    final effectiveTextStyle = textStyle ??
        AppTextStyles.h2.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: effectiveTextColor,
        );

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading) ...<Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...<Widget>[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: effectiveTextStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );

    return Container(
      height: height,
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: _isEnabled
            ? (isDark ? AppDarkColors.primary : null)
            : (isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainerHigh),
        gradient: _isEnabled && !isDark ? AppColors.brandGradient : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _isEnabled && isDark
            ? [
                BoxShadow(
                  color: AppDarkColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              widthFactor: isFullWidth ? null : 1.0,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
