import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_gate.dart';
import 'routes.dart';

class VauVauApp extends StatelessWidget {
  const VauVauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      routes: AppRoutes.map,
    );
  }
}
