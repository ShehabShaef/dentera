/// Centralized application version metadata synchronized with `pubspec.yaml`.
///
/// Under offline-first architectures, explicit version tracking allows
/// schema migrations, backup payload integrity checks, and user-facing UI
/// displays to accurately reflect release metadata without platform channel overhead.
class AppVersion {
  const AppVersion._();

  /// Semantic version string (major.minor.patch).
  static const String version = '0.7.0';

  /// Monotonically increasing build number.
  static const int buildNumber = 7;

  /// Human-readable formatted version string for UI display.
  static const String displayVersion = 'v$version (Build $buildNumber)';

  /// Release phase or channel description.
  static const String releaseStage = 'v$version - Immediate Stabilization';
}
