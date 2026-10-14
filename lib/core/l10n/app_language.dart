import 'package:flutter/material.dart';

enum AppLanguage {
  serbian('sr', 'Srpski', 'Serbian'),
  english('en', 'English', 'English');

  const AppLanguage(this.code, this.labelSr, this.labelEn);

  final String code;
  final String labelSr;
  final String labelEn;

  Locale get locale => Locale(code);

  String get label => this == AppLanguage.english ? labelEn : labelSr;

  static const supported = AppLanguage.values;

  static AppLanguage fromCode(String? code) {
    final normalized = (code ?? '').trim().toLowerCase();
    for (final language in values) {
      if (language.code == normalized) {
        return language;
      }
    }
    return AppLanguage.serbian;
  }
}
