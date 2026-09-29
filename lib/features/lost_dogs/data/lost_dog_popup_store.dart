import 'package:shared_preferences/shared_preferences.dart';

abstract final class LostDogPopupStore {
  static const String key = 'has_dismissed_lost_dog_popup';

  static Future<bool> hasDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {}
  }
}
