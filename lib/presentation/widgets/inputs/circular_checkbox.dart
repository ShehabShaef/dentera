import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// A circular selection checkbox designed for multi-select batch operations.
///
/// Features animated border/fill transitions and a centered checkmark icon
/// when selected.
class CircularCheckbox extends StatelessWidget {
  const CircularCheckbox({
    super.key,
    required this.isSelected,
    required this.onChanged,
    this.activeColor = AppColors.error,
    this.inactiveBorderColor = AppColors.outlineVariant,
    this.size = 24.0,
  });

  /// Whether the checkbox is currently checked.
  final bool isSelected;

  /// Callback triggered when the checkbox is tapped.
  final ValueChanged<bool>? onChanged;

  /// The fill color when [isSelected] is true. Defaults to [AppColors.error].
  final Color activeColor;

  /// The border color when [isSelected] is false.
  final Color inactiveBorderColor;

  /// The diameter of the circular checkbox.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isSelected,
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(!isSelected) : null,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? activeColor : Colors.transparent,
            border: Border.all(
              color: isSelected ? activeColor : inactiveBorderColor,
              width: 2.0,
            ),
          ),
          alignment: Alignment.center,
          child: isSelected
              ? Icon(
                  Icons.check_rounded,
                  size: size * 0.65,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
