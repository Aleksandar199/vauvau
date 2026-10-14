import '../../../core/l10n/app_language.dart';
import '../../../core/theme/app_theme_preference.dart';

class AppSettings {
  const AppSettings({
    this.notifyWalkRequests = true,
    this.notifyMessages = true,
    this.notifyNewMatches = true,
    this.radiusKm = 20,
    this.showLocationOnMap = true,
    this.pushPrompted = false,
    this.language = AppLanguage.serbian,
    this.themePreference = AppThemePreference.dark,
  });

  final bool notifyWalkRequests;
  final bool notifyMessages;
  final bool notifyNewMatches;
  final double radiusKm;
  final bool showLocationOnMap;
  final bool pushPrompted;
  final AppLanguage language;
  final AppThemePreference themePreference;

  AppSettings copyWith({
    bool? notifyWalkRequests,
    bool? notifyMessages,
    bool? notifyNewMatches,
    double? radiusKm,
    bool? showLocationOnMap,
    bool? pushPrompted,
    AppLanguage? language,
    AppThemePreference? themePreference,
  }) {
    return AppSettings(
      notifyWalkRequests: notifyWalkRequests ?? this.notifyWalkRequests,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyNewMatches: notifyNewMatches ?? this.notifyNewMatches,
      radiusKm: radiusKm ?? this.radiusKm,
      showLocationOnMap: showLocationOnMap ?? this.showLocationOnMap,
      pushPrompted: pushPrompted ?? this.pushPrompted,
      language: language ?? this.language,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}
