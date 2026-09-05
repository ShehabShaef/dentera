import 'package:flutter/material.dart';

import '../../core/error/app_exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/theme.dart';

/// Standardized SnackBar presentation utility for Dentera adhering to Clinical Linearity design.
///
/// ### Reactive Stream Errors vs. Imperative Action Errors:
/// In an offline-first Riverpod architecture, error handling falls into two distinct operational paradigms:
/// 1. **Reactive Stream Errors (Localized Error Boundary Widgets):**
///    When an `AsyncValue` stream or query provider fails to resolve data (e.g., `clinicListProvider`
///    or `casesByPatientProvider`), the failure represents a broken screen view state. In this scenario,
///    a localized [DenteraErrorWidget] replaces the failed section and offers an interactive "Retry" button
///    wired to `ref.invalidate(...)`. Localized error states preserve the surrounding screen chrome (navigation bars,
///    headers) while clearly notifying the user of the partial failure.
/// 2. **Imperative Action Errors (Global SnackBars):**
///    When a user triggers an active mutation (such as registering a patient, logging a case, or
///    scheduling an appointment) within a modal or form, the operation is imperative. Replacing the modal
///    with an error widget would destroy uncommitted user inputs and cause severe UX frustration. Instead,
///    imperative errors are intercepted in a local `try/catch` block and surfaced via [DenteraSnackBar.showError].
///    This transient global notification informs the user of the SQLite failure (e.g., [DatabaseLockedException]),
///    preserves their typed form inputs, and records the full stack trace through [AppLogger.error].
class DenteraSnackBar {
  DenteraSnackBar._();

  /// Displays a standardized floating error SnackBar using the current [ScaffoldMessenger].
  ///
  /// Emits an explicit [AppLogger.error] log capturing the error and stack trace context,
  /// maps known SQLite failure types to user-friendly clinical text, and renders
  /// with [AppColors.error] background styling.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(
    BuildContext context, {
    required String message,
    dynamic error,
    StackTrace? stackTrace,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Record structured log entry for diagnostic tracing
    AppLogger.error(
      'UI Error Boundary Caught Exception: ${error ?? message}',
      error,
      stackTrace,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final formattedText = _formatErrorMessage(message, error);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 3,
      backgroundColor: AppColors.error,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.onError,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formattedText,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onError,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.onError,
              onPressed: onAction ?? () {},
            )
          : null,
      duration: duration,
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Maps specific SQLite domain exceptions to clear, actionable clinical text.
  static String _formatErrorMessage(String baseMessage, dynamic error) {
    if (error is DatabaseLockedException) {
      return '$baseMessage: Database is locked or busy. Please retry.';
    }
    if (error is DatabaseReadOnlyException) {
      return '$baseMessage: Local storage is currently in read-only mode.';
    }
    if (error is DataWriteException) {
      return '$baseMessage: Could not write record to local database.';
    }
    if (error != null) {
      final str = error.toString();
      final clean = str.startsWith('Exception: ') ? str.substring(11) : str;
      if (clean.isNotEmpty && clean != baseMessage) {
        return '$baseMessage ($clean)';
      }
    }
    return baseMessage;
  }
}
