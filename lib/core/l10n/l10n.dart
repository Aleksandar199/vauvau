import 'app_language.dart';

/// Lightweight bilingual helper used by existing `*Strings` classes.
abstract final class L10n {
  static AppLanguage _language = AppLanguage.serbian;

  static AppLanguage get language => _language;

  static bool get isEnglish => _language == AppLanguage.english;

  static void setLanguage(AppLanguage value) {
    _language = value;
  }

  static String tr(String sr, String en) => isEnglish ? en : sr;
}
