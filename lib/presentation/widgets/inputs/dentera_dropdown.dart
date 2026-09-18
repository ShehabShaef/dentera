import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A stylized dropdown component matching the Dentera clinical design system.
class DenteraDropdown<T> extends StatelessWidget {
  const DenteraDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.prefixIcon,
    this.isExpanded = true,
    this.borderRadius = 12.0,
    this.fillColor,
  });

  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<T>? validator;
  final Widget? prefixIcon;
  final bool isExpanded;
  final double borderRadius;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveFillColor = fillColor ??
        (isDark
            ? AppDarkColors.surfaceBase
            : AppColors.surfaceContainerLowest);
    final effectiveDropdownColor = isDark
        ? AppDarkColors.surfaceContainerElevated
        : AppColors.surfaceContainerLowest;
    final effectiveTextColor =
        isDark ? AppDarkColors.textPrimary : AppColors.onSurface;
    final effectiveHintColor =
        isDark ? AppDarkColors.textPlaceholder : AppColors.outline;
    final effectiveBorderColor =
        isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant;
    final effectiveFocusBorderColor =
        isDark ? AppDarkColors.primary : AppColors.primary;
    final effectiveErrorColor =
        isDark ? AppDarkColors.statusError : AppColors.error;

    final dropdownField = DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark ? AppDarkColors.textMuted : AppColors.outline,
        size: 24,
      ),
      style: AppTextStyles.bodyMd.copyWith(color: effectiveTextColor),
      dropdownColor: effectiveDropdownColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: effectiveHintColor),
        helperText: helperText,
        helperStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
        ),
        errorText: errorText,
        errorStyle: AppTextStyles.caption.copyWith(color: effectiveErrorColor),
        filled: true,
        fillColor: effectiveFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: effectiveBorderColor,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: effectiveBorderColor,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: effectiveFocusBorderColor,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: effectiveErrorColor,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: effectiveErrorColor,
            width: 2.0,
          ),
        ),
      ),
    );

    if (label == null) {
      return dropdownField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label!,
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        dropdownField,
      ],
    );
  }
}
