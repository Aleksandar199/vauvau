/// Build number of this app (the `+N` in pubspec.yaml `version:`).
/// Keep in sync: `test/app_update_test.dart` fails when they differ.
const int kAppBuildNumber = 10;

/// Google Play listing of the Android app.
const String kPlayStoreWebUrl =
    'https://play.google.com/store/apps/details?id=com.vauvau.app';
const String kPlayStoreMarketUrl = 'market://details?id=com.vauvau.app';

/// `app_config/android` in Firestore (admin-edited).
///  - `minBuild`: older builds must update (blocking dialog).
///  - `latestBuild`: older builds are offered an update (can be dismissed).
class AppUpdateConfig {
  const AppUpdateConfig({this.minBuild = 0, this.latestBuild = 0});

  final int minBuild;
  final int latestBuild;

  factory AppUpdateConfig.fromMap(Map<String, dynamic>? data) {
    int read(Object? value) => value is num ? value.toInt() : 0;
    return AppUpdateConfig(
      minBuild: read(data?['minBuild']),
      latestBuild: read(data?['latestBuild']),
    );
  }

  AppUpdateStatus statusFor(int build) {
    if (minBuild > build) {
      return AppUpdateStatus.required;
    }
    if (latestBuild > build) {
      return AppUpdateStatus.available;
    }
    return AppUpdateStatus.upToDate;
  }
}

enum AppUpdateStatus { upToDate, available, required }
