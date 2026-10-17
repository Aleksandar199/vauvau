import 'package:flutter/foundation.dart';
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
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.primarySoft,
      onSecondaryContainer: AppColors.ink,
      error: const Color(0xFFDC2626),
      onError: AppColors.onPrimary,
      surface: background,
      onSurface: onBackground,
      onSurfaceVariant: onBackground.withValues(alpha: 0.72),
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
        color: onBackground,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: baseText,
      // Flutter web's snapshot-based page transitions can paint or hit-test
      // a route before its RenderBox has completed layout. This is especially
      // visible when opening Stories/Highlights from an overlay.
      pageTransitionsTheme: kIsWeb
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoPageTransitionsBuilder(),
                TargetPlatform.iOS: _NoPageTransitionsBuilder(),
                TargetPlatform.macOS: _NoPageTransitionsBuilder(),
                TargetPlatform.windows: _NoPageTransitionsBuilder(),
                TargetPlatform.linux: _NoPageTransitionsBuilder(),
                TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
              },
            )
          : const PageTransitionsTheme(),
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
          // Avoid Size.fromHeight (infinite width) — it crushes Expanded
          // siblings in Rows down to one-glyph-wide text on web.
          minimumSize: const Size(64, 52),
          shape: shape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: shape,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: onBackground),
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
        selectedColor: AppColors.primary,
        backgroundColor: card,
        disabledColor: card,
        side: BorderSide(color: outline),
        // Explicit colour: a colourless chip label inherited whatever text
        // colour the surrounding widget had (white on a white card).
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: onBackground,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: AppColors.onPrimary,
        deleteIconColor: onBackground,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: AppColors.primary,
        elevation: 8,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.onPrimary : onBackground,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: onBackground,
          );
        }),
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

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
