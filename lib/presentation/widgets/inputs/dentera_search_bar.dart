import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A specialized search input field with leading search icon and trailing clear button.
class DenteraSearchBar extends StatefulWidget {
  const DenteraSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.borderRadius = 12.0,
    this.fillColor,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final double borderRadius;
  final Color? fillColor;
  final bool autofocus;
  final bool enabled;

  @override
  State<DenteraSearchBar> createState() => _DenteraSearchBarState();
}

class _DenteraSearchBarState extends State<DenteraSearchBar> {
  late final TextEditingController _controller;
  bool _isInternalController = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isInternalController = true;
    } else {
      _controller = widget.controller!;
    }
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveFillColor = widget.fillColor ??
        (isDark ? AppDarkColors.surfaceBase : AppColors.surfaceContainerLowest);
    final effectiveTextColor = isDark ? AppDarkColors.textPrimary : AppColors.onSurface;
    final effectiveHintColor = isDark ? AppDarkColors.textPlaceholder : AppColors.outline;
    final effectiveIconColor = isDark ? AppDarkColors.outline : AppColors.outline;
    final effectiveBorderColor = isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant;
    final effectiveFocusBorderColor = isDark ? AppDarkColors.primary : AppColors.primary;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      style: AppTextStyles.bodyMd.copyWith(color: effectiveTextColor),
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: effectiveHintColor),
        filled: true,
        fillColor: effectiveFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: effectiveIconColor,
          size: 22,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: effectiveIconColor,
                  size: 20,
                ),
                onPressed: _handleClear,
                tooltip: 'Clear search',
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: effectiveBorderColor,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: effectiveBorderColor,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: effectiveFocusBorderColor,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
