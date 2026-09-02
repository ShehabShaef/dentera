import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A secondary outlined button with a 1px primary border and 12px rounded corners.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
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
    this.borderColor,
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
  final Color? borderColor;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = _isEnabled
        ? (borderColor ?? AppColors.primary)
        : AppColors.outlineVariant;

    final effectiveTextStyle = textStyle ??
        AppTextStyles.h2.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _isEnabled ? (borderColor ?? AppColors.primary) : AppColors.outline,
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
              valueColor: AlwaysStoppedAnimation<Color>(
                _isEnabled ? AppColors.primary : AppColors.outline,
              ),
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
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
