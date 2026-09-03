import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/logging/app_logger.dart';
import 'package:dentera/core/logging/app_provider_observer.dart';

void main() {
  group('AppLogger Unit Tests', () {
    test('AppLogger methods execute cleanly without throwing', () {
      expect(
        () => AppLogger.debug('Diagnostic SQLite query trace: SELECT * FROM patients'),
        returnsNormally,
      );

      expect(
        () => AppLogger.info('Domain milestone: Patient Jane Doe inserted successfully'),
        returnsNormally,
      );

      expect(
        () => AppLogger.warning('Recoverable warning: Notification permission not granted'),
        returnsNormally,
      );

      expect(
        () => AppLogger.error(
          'Critical failure: SQLite transaction aborted',
          Exception('Database disk full'),
          StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });

  group('AppProviderObserver Lifecycle Tests', () {
    test('intercepts provider addition, updates, disposals, and errors seamlessly', () {
      final observer = const AppProviderObserver();
      final container = ProviderContainer(
        observers: [observer],
      );

      // 1. Test Provider Addition & Update via StateProvider
      final testCounterProvider = StateProvider<int>((ref) => 10, name: 'testCounterProvider');

      // Trigger didAddProvider
      final initialVal = container.read(testCounterProvider);
      expect(initialVal, 10);

      // Trigger didUpdateProvider
      container.read(testCounterProvider.notifier).state = 25;
      expect(container.read(testCounterProvider), 25);

      // 2. Test Provider Failure via throwing Provider
      final failingProvider = Provider<String>((ref) {
        throw StateError('Simulated clinical provider failure');
      }, name: 'failingProvider');

      // Trigger providerDidFail
      expect(
        () => container.read(failingProvider),
        throwsA(isA<StateError>()),
      );

      // 3. Trigger didDisposeProvider
      expect(() => container.dispose(), returnsNormally);
    });

    test('handles autoDispose providers and their disposal events', () {
      final container = ProviderContainer(
        observers: [const AppProviderObserver()],
      );

      final autoDisposeProvider = Provider.autoDispose<String>(
        (ref) => 'Transient Offline Value',
        name: 'autoDisposeProvider',
      );

      final subscription = container.listen(autoDisposeProvider, (_, _) {});
      expect(container.read(autoDisposeProvider), 'Transient Offline Value');

      // Closing subscription causes autoDispose
      subscription.close();
      expect(() => container.dispose(), returnsNormally);
    });
  });
}
