import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const double radius = 20;

  static ThemeData light() {
    return _theme(
      brightness: Brightness.light,
      background: AppColors.lightBackground,
      onBackground: AppColors.lightOnBackground,
      outline: AppColors.lightOutline,
      card: AppColors.lightCard,
    );
  }

  static ThemeData dark() {
    return _theme(
      brightness: Brightness.dark,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkOnBackground,
      outline: AppColors.darkOutline,
      card: AppColors.darkCard,
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color onBackground,
    required Color outline,
    required Color card,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      error: const Color(0xFFDC2626),
      onError: AppColors.onPrimary,
      surface: background,
      onSurface: onBackground,
      outline: outline,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    final baseText = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.6,
        color: onBackground,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
        color: onBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: onBackground,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: onBackground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: onBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: onBackground,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.onPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: baseText.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: baseText.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: shape,
          foregroundColor: onBackground,
          side: BorderSide(color: outline),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selectedColor: AppColors.primarySoft,
        backgroundColor: card,
        side: BorderSide(color: outline),
        labelStyle: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: AppColors.primarySoft,
        elevation: 8,
        labelTextStyle: WidgetStatePropertyAll(
          baseText.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: const Color(0x140F172A),
        shape: shape,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
      ),
    );
  }
}
