/// Versi APK ini, untuk dibandingkan dengan `minimum_supported_version` dari
/// Firebase Remote Config.
///
/// Diisi oleh tool/build_release.ps1 dari `pubspec.yaml` lewat
/// `--dart-define=APP_VERSION=...`; defaultnya sengaja sama dengan versi publik
/// supaya build manual `flutter build apk` tidak langsung dianggap tertinggal.
const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0',
);
