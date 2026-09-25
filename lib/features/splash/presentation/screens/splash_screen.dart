import 'dart:async';

import 'package:flutter/material.dart';

import '../../../auth/presentation/auth_gate.dart';
import '../widgets/splash_clouds.dart';
import '../widgets/splash_mascot.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Color skyStart = Color(0xFF38BDF8);
  static const Color skyEnd = Color(0xFF0284C7);
  static const String tagline = 'Spajamo pse i vlasnike za šetnju i druženje';
  static const Duration hold = Duration(seconds: 2);

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;
  var _opened = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _fade = CurvedAnimation(
      parent: _motion,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.78, end: 1.08).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 0.96).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 23,
      ),
    ]).animate(_motion);
    _motion.forward();
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
        transitionDuration: const Duration(milliseconds: 520),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SplashScreen.skyStart, SplashScreen.skyEnd],
          ),
        ),
        child: Stack(
          children: [
            const SplashClouds(),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: const SplashMascot(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fade,
                    child: const _OutlinedTitle(),
                  ),
                  const Spacer(flex: 2),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(32, 0, 32, 36),
                    child: Text(
                      SplashScreen.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Color(0x66082F49),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedTitle extends StatelessWidget {
  const _OutlinedTitle();

  @override
  Widget build(BuildContext context) {
    const title = 'VauVau';
    const style = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      height: 1,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          title,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..color = const Color(0xFF0F172A),
          ),
        ),
        Text(
          title,
          style: style.copyWith(
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Color(0x99082F49),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
