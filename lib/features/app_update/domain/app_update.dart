/// Google Play listing of the Android app.
const String kPlayStoreWebUrl =
    'https://play.google.com/store/apps/details?id=com.vauvau.app';
const String kPlayStoreMarketUrl = 'market://details?id=com.vauvau.app';

/// Apple ID of the iOS app (App Store Connect → App Information → Apple ID,
/// only digits). Empty until the app exists in the App Store: then iOS shows
/// no update prompt – it must never send an iPhone to Google Play.
const String kAppStoreId = '';

/// Store the update prompt reads its config from and opens.
enum AppStorePlatform {
  android,
  ios;

  /// `app_config/{docId}` in Firestore.
  String get configDocId => name;

  /// Links tried in order; empty = no store to open (no prompt).
  List<Uri> get storeUris => switch (this) {
        AppStorePlatform.android => [
            Uri.parse(kPlayStoreMarketUrl),
            Uri.parse(kPlayStoreWebUrl),
          ],
        AppStorePlatform.ios => kAppStoreId.isEmpty
            ? const []
            : [
                Uri.parse('itms-apps://apps.apple.com/app/id$kAppStoreId'),
                Uri.parse('https://apps.apple.com/app/id$kAppStoreId'),
              ],
      };
}

/// `app_config/android` or `app_config/ios` in Firestore (admin-edited).
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
