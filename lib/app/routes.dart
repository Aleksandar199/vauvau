import 'package:flutter/material.dart';

import '../features/discover/presentation/discover_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';

abstract final class AppRoutes {
  static const String welcome = '/welcome';
  static const String discover = '/discover';

  static Map<String, WidgetBuilder> get map => {
        welcome: (_) => const WelcomeScreen(),
        discover: (_) => const DiscoverScreen(),
      };
}
