import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../buttons/secondary_button.dart';

/// A dedicated, standardized error presentation widget adhering to Dentera's Clinical Linearity design.
///
/// Supports two visual modes:
/// - Full-viewport/spacious mode ([isCompact] = false): Centered icon, title, description, and retry button
///   ideal for primary screen states (such as [PatientsScreen] or [AppointmentsScreen]).
/// - Compact card mode ([isCompact] = true): Streamlined horizontal or tight vertical layout designed
///   for nested dashboard cards and timeline sub-sections.
class DenteraErrorState extends StatelessWidget {
  const DenteraErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
    this.retryText = 'Retry',
    this.isCompact = false,
  });

  /// Primary error header text.
  final String title;

  /// Detailed human-readable error or diagnosis description.
  final String message;

  /// Optional callback invoked when the user taps the retry button.
  final VoidCallback? onRetry;

  /// Label displayed on the retry action button.
  final String retryText;

  /// Whether to render a compact container suitable for card embeds.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: SecondaryButton(
                  isFullWidth: false,
                  height: 36,
                  text: retryText,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  onPressed: onRetry,
                  borderColor: AppColors.error,
                  textStyle: AppTextStyles.labelCaps.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: AppColors.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 20),
              SecondaryButton(
                isFullWidth: false,
                text: retryText,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
