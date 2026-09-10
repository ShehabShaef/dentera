import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_version.dart';

/// Provides the centralized application version string for UI display.
///
/// Returns [AppVersion.displayVersion] which accurately reflects the active
/// application version and build number configured in `pubspec.yaml`.
final appVersionProvider = Provider<String>((ref) {
  return AppVersion.displayVersion;
});
