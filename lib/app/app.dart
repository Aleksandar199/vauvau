import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class VauVauApp extends StatelessWidget {
  const VauVauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.map,
    );
  }
}
