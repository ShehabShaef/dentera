import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'buttons/primary_button.dart';

/// A standardized, reusable empty state widget adhering to Dentera's Clinical Linearity design.
///
/// Designed to visually inform dental students when queries or repository methods return
/// zero records (e.g., empty clinic rosters, zero scheduled appointments, empty patient
/// directories, or unpopulated clinical case sheets).
///
/// Displays a centered graphic or circular icon, a prominent headline, descriptive guidance
/// styled with [AppColors.textSecondary], and an optional primary call-to-action button.
class DenteraEmptyState extends StatelessWidget {
  /// Creates a [DenteraEmptyState].
  ///
  /// Either [icon] or [graphic] should typically be provided to give the user a clear
  /// visual indicator of the empty context.
  const DenteraEmptyState({
    super.key,
    this.icon,
    this.graphic,
    required this.title,
    required this.subtitle,
    this.actionButton,
    this.actionText,
    this.onAction,
    this.actionIcon,
    this.isCompact = false,
  });

  /// The primary Material [IconData] representing the empty domain context.
  final IconData? icon;

  /// An optional custom graphic or SVG widget to display in place of the default icon circle.
  final Widget? graphic;

  /// Prominent header text explaining the empty status (e.g., 'No clinics added yet').
  final String title;

  /// Explanatory guidance text assisting the user on next steps, styled with [AppColors.textSecondary].
  final String subtitle;

  /// An optional pre-built action button widget (e.g., a customized [PrimaryButton]).
  final Widget? actionButton;

  /// An optional text label to automatically construct a [PrimaryButton] when [actionButton] is omitted.
  final String? actionText;

  /// Optional callback executed when the auto-constructed action button is pressed.
  final VoidCallback? onAction;

  /// Optional icon widget displayed inside the auto-constructed action button.
  final Widget? actionIcon;

  /// Whether to render a compact layout suitable for embedded cards, nested tabs, or constrained dialogs.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    // Resolve the action button widget if convenience parameters were provided
    Widget? resolvedAction = actionButton;
    if (resolvedAction == null && actionText != null && onAction != null) {
      resolvedAction = PrimaryButton(
        isFullWidth: false,
        text: actionText!,
        icon: actionIcon,
        onPressed: onAction,
      );
    }

    final double iconContainerSize = isCompact ? 56.0 : 72.0;
    final double iconSize = isCompact ? 28.0 : 36.0;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: isCompact ? 16.0 : 32.0,
      vertical: isCompact ? 24.0 : 48.0,
    );

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // 1. Visual Graphic or Styled Circular Icon Container
            if (graphic != null)
              graphic!
            else if (icon != null)
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: AppColors.outline,
                ),
              ),

            if (graphic != null || icon != null)
              SizedBox(height: isCompact ? 12.0 : 16.0),

            // 2. Primary Title Header
            Text(
              title,
              style: isCompact
                  ? AppTextStyles.h2.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    )
                  : AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6.0),

            // 3. Descriptive Subtitle / Guidance
            Text(
              subtitle,
              style: isCompact
                  ? AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    )
                  : AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
              textAlign: TextAlign.center,
            ),

            // 4. Optional Call-To-Action Button
            if (resolvedAction != null) ...<Widget>[
              SizedBox(height: isCompact ? 16.0 : 20.0),
              resolvedAction,
            ],
          ],
        ),
      ),
    );
  }
}
