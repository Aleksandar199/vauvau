import 'package:flutter/material.dart';

/// User-selectable app appearance (persisted in settings).
enum AppThemePreference {
  /// Brand dark slate (`AppColors.darkBackground`) — default.
  dark,

  /// Light / white surfaces.
  light;

  String get code => name;

  ThemeMode get themeMode => switch (this) {
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.light => ThemeMode.light,
      };

  static AppThemePreference fromCode(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'light' => AppThemePreference.light,
      _ => AppThemePreference.dark,
    };
  }
}
