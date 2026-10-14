import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_language.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme_preference.dart';
import '../domain/app_settings.dart';

abstract final class AppSettingsStore {
  static const _walks = 'vauvau.settings.notifyWalkRequests';
  static const _messages = 'vauvau.settings.notifyMessages';
  static const _matches = 'vauvau.settings.notifyNewMatches';
  static const _radius = 'vauvau.settings.radiusKm';
  static const _map = 'vauvau.settings.showLocationOnMap';
  static const _push = 'vauvau.settings.pushPrompted';
  static const _language = 'vauvau.settings.language';
  static const _theme = 'vauvau.settings.themePreference';

  static Future<AppSettings> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = AppLanguage.fromCode(prefs.getString(_language));
      L10n.setLanguage(language);
      return AppSettings(
        notifyWalkRequests: prefs.getBool(_walks) ?? true,
        notifyMessages: prefs.getBool(_messages) ?? true,
        notifyNewMatches: prefs.getBool(_matches) ?? true,
        radiusKm: prefs.getDouble(_radius) ?? 20,
        showLocationOnMap: prefs.getBool(_map) ?? true,
        pushPrompted: prefs.getBool(_push) ?? false,
        language: language,
        themePreference: AppThemePreference.fromCode(prefs.getString(_theme)),
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  static Future<void> write(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_walks, settings.notifyWalkRequests);
      await prefs.setBool(_messages, settings.notifyMessages);
      await prefs.setBool(_matches, settings.notifyNewMatches);
      await prefs.setDouble(_radius, settings.radiusKm);
      await prefs.setBool(_map, settings.showLocationOnMap);
      await prefs.setBool(_push, settings.pushPrompted);
      await prefs.setString(_language, settings.language.code);
      await prefs.setString(_theme, settings.themePreference.code);
      L10n.setLanguage(settings.language);
    } catch (_) {}
  }
}
