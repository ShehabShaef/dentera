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
    final effectiveTextStyle = textStyle ??
        AppTextStyles.h2.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _isEnabled ? AppColors.onPrimary : AppColors.outline,
        );

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading) ...<Widget>[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
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
        gradient: _isEnabled ? AppColors.brandGradient : null,
        color: _isEnabled ? null : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
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
