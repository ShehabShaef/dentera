import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme.dart';

/// A stylized text field component matching the Dentera clinical design system.
/// Displays an optional top-aligned label in Caption style.
class DenteraTextField extends StatelessWidget {
  const DenteraTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onTap,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.validator,
    this.inputFormatters,
    this.borderRadius = 12.0,
    this.fillColor,
  });

  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final double borderRadius;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final effectiveFillColor = fillColor ?? AppColors.surfaceContainerLowest;

    final inputField = TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: AppTextStyles.bodyMd.copyWith(
        color: enabled ? AppColors.onSurface : AppColors.outline,
      ),
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      onSaved: onSaved,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
        helperText: helperText,
        helperStyle: AppTextStyles.caption,
        errorText: errorText,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        filled: true,
        fillColor: effectiveFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefix: prefix,
        suffix: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.outlineVariant,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.outlineVariant,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.surfaceContainerHigh,
            width: 1.0,
          ),
        ),
      ),
    );

    if (label == null) {
      return inputField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label!,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        inputField,
      ],
    );
  }
}
