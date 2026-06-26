/// App version — keep in sync with pubspec.yaml version field.
///
/// Displayed on the splash screen and in profile.
class AppVersion {
  AppVersion._();

  /// The semantic version string (e.g. "1.0.1").
  static const String version = '1.0.21';

  /// The build number (e.g. 16).
  static const int buildNumber = 21;

  /// Full version string for display (e.g. "v1.0.16").
  static const String display = 'v$version';
}
