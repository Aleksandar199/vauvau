import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';

  static Map<String, WidgetBuilder> get map => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
      };
}
