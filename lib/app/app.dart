import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../core/crash/crash_reporting.dart';
import '../core/l10n/app_language.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/notifications/presentation/push_navigation.dart';
import '../features/profile/presentation/profile_controller.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import 'offline_gate.dart';

class VauVauApp extends ConsumerWidget {
  const VauVauApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(
      appSettingsProvider.select((settings) => settings.language),
    );
    final themeMode = ref.watch(
      appSettingsProvider.select(
        (settings) => settings.themePreference.themeMode,
      ),
    );
    L10n.setLanguage(language);

    ref.listen(authStateProvider, (previous, next) {
      unawaited(
        CrashReporting.setUserId(next.asData?.value?.uid),
      );
    });

    return MaterialApp(
      title: AppStrings.appName,
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: language.locale,
      supportedLocales: [
        for (final item in AppLanguage.supported) item.locale,
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return _LanguageRebuildScope(
          language: language,
          child: OfflineGate(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const SplashScreen(),
    );
  }
}

/// Marks the tree when language changes so MaterialApp rebuilds route content
/// without remounting the navigator.
class _LanguageRebuildScope extends InheritedWidget {
  const _LanguageRebuildScope({
    required this.language,
    required super.child,
  });

  final AppLanguage language;

  @override
  bool updateShouldNotify(_LanguageRebuildScope oldWidget) {
    return language != oldWidget.language;
  }
}
