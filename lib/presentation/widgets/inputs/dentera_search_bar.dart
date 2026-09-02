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
    final effectiveFillColor = widget.fillColor ?? AppColors.surfaceContainerLowest;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
        filled: true,
        fillColor: effectiveFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.outline,
          size: 22,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.outline,
                  size: 20,
                ),
                onPressed: _handleClear,
                tooltip: 'Clear search',
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: const BorderSide(
            color: AppColors.outlineVariant,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: const BorderSide(
            color: AppColors.outlineVariant,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
