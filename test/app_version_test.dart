import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/constants/app_version.dart';
import 'package:dentera/presentation/state/state.dart';

void main() {
  group('AppVersion & appVersionProvider Tests', () {
    test('AppVersion constants match v0.7.0 milestone specification', () {
      expect(AppVersion.version, '0.7.0');
      expect(AppVersion.buildNumber, 7);
      expect(AppVersion.displayVersion, 'v0.7.0 (Build 7)');
      expect(AppVersion.releaseStage, contains('Immediate Stabilization'));
    });

    test('appVersionProvider exposes AppVersion.displayVersion', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final versionString = container.read(appVersionProvider);
      expect(versionString, 'v0.7.0 (Build 7)');
    });

    test('appVersionProvider supports custom override for testing environments', () {
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWithValue('v1.0.0-test (Build 99)'),
        ],
      );
      addTearDown(container.dispose);

      final versionString = container.read(appVersionProvider);
      expect(versionString, 'v1.0.0-test (Build 99)');
    });
  });
}
