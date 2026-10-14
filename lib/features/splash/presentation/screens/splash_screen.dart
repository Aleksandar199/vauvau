import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_gate.dart';

/// Single full-screen splash — only [logoAsset], no native-icon "cube" handoff.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Matches the branded app dark theme (`AppColors.darkBackground`).
  static const Color background = AppColors.darkBackground;
  static const String tagline = 'Spajamo pse i vlasnike za šetnju i druženje';
  static const Duration hold = Duration(seconds: 2);
  static const String logoAsset = 'assets/images/vauvau_splash.png';

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  var _opened = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: SplashScreen.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _timer = Timer(SplashScreen.hold, _openApp);
  }

  Future<void> _openApp() async {
    if (!mounted || _opened) {
      return;
    }
    _opened = true;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const AuthGate();
        },
        transitionDuration: const Duration(milliseconds: 420),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the active theme surface so splash matches the rest of the app
    // (defaults to dark blue until the user picks light in Settings).
    final bg = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: bg,
      body: SizedBox.expand(
        child: ColoredBox(
          color: bg,
          child: const Image(
            image: AssetImage(SplashScreen.logoAsset),
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
