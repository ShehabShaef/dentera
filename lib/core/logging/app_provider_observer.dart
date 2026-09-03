import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';

/// A Riverpod [ProviderObserver] that intercepts and logs state transitions,
/// provider additions, disposals, and unhandled errors throughout the application.
///
/// This provides immediate visibility into the reactive state graph of Dentera's
/// offline-first architecture, allowing developers to trace data mutations
/// and debug UI-binding lifecycles without disrupting clinical operations.
class AppProviderObserver extends ProviderObserver {
  /// Creates an [AppProviderObserver].
  const AppProviderObserver();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    final providerName = provider.name ?? provider.runtimeType.toString();
    AppLogger.debug(
      '[Riverpod State] ADD: $providerName | Initial Value: $value',
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    final providerName = provider.name ?? provider.runtimeType.toString();
    AppLogger.debug(
      '[Riverpod State] UPDATE: $providerName | Prev: $previousValue -> New: $newValue',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    final providerName = provider.name ?? provider.runtimeType.toString();
    AppLogger.debug(
      '[Riverpod State] DISPOSE: $providerName',
    );
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    final providerName = provider.name ?? provider.runtimeType.toString();
    AppLogger.error(
      '[Riverpod State] FAIL: $providerName threw an unhandled error',
      error,
      stackTrace,
    );
  }
}
