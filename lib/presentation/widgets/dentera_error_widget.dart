import 'package:flutter/material.dart';

import '../../core/error/app_exceptions.dart';
import '../../core/logging/app_logger.dart';
import 'feedback/error_state_widget.dart';

/// Standardized localized error boundary widget adhering to Dentera's Clinical Linearity design.
///
/// ### Reactive Stream Errors vs. Imperative Action Errors:
/// In an offline-first Riverpod architecture, error presentation is bifurcated:
/// 1. **Reactive Stream Errors (Localized Error Boundary Widgets):**
///    When an `AsyncValue` stream or query provider fails to resolve data (such as `clinicListProvider`
///    or `patientByIdProvider`), the failure indicates that a specific screen section cannot be built.
///    Using [DenteraErrorWidget] localized in place of the broken section preserves the surrounding
///    scaffold and navigation chrome, while providing clear diagnostic messaging and an active
///    "Retry" button wired to `ref.invalidate(...)`.
/// 2. **Imperative Action Errors (Global SnackBars):**
///    In contrast, when an imperative mutation fails (such as an SQLite constraint failure or
///    database lock during form submission), replacing the user's active input form with an error widget
///    would destroy draft data and disrupt clinical workflows. Imperative failures must be caught in
///    `try/catch` blocks and presented non-destructively using [DenteraSnackBar].
class DenteraErrorWidget extends StatelessWidget {
  const DenteraErrorWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.error,
    this.stackTrace,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.isCompact = false,
  });

  /// Primary headline summarizing the failure.
  final String title;

  /// Optional specific failure description. If omitted, a friendly message is derived from [error].
  final String? message;

  /// The underlying exception or error object caught by the error boundary.
  final dynamic error;

  /// The stack trace associated with [error].
  final StackTrace? stackTrace;

  /// Callback executed when the user taps the retry button (e.g., `() => ref.invalidate(...)`).
  final VoidCallback? onRetry;

  /// Label rendered on the retry action button.
  final String retryLabel;

  /// Whether to render a compact container suitable for card embeds or nested dashboard sections.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    // Record structured log entry for diagnostic tracing on every render of the error boundary
    AppLogger.error(
      'UI Error Boundary Caught Exception: ${error ?? message ?? title}',
      error,
      stackTrace,
    );

    final displayMessage = _resolveErrorMessage();

    return DenteraErrorState(
      title: title,
      message: displayMessage,
      onRetry: onRetry,
      retryText: retryLabel,
      isCompact: isCompact,
    );
  }

  /// Resolves the user-facing message from explicit parameter or SQLite exception taxonomy.
  String _resolveErrorMessage() {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    if (error is DatabaseLockedException) {
      return 'The local database is currently locked or busy. Please tap retry.';
    }
    if (error is DatabaseReadOnlyException) {
      return 'The offline database is operating in read-only mode.';
    }
    if (error is DataWriteException) {
      return 'Failed to read or persist data in local storage.';
    }
    if (error != null) {
      final str = error.toString();
      return str.startsWith('Exception: ') ? str.substring(11) : str;
    }
    return 'An unexpected error occurred while loading clinical data. Please try again.';
  }
}
