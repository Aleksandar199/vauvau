import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/notifications/presentation/push_navigation.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

class VauVauApp extends StatelessWidget {
  const VauVauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
