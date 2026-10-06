import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Color skyStart = Color(0xFF0B1220);
  static const Color skyEnd = Color(0xFF0F172A);
  static const String tagline = 'Spajamo pse i vlasnike za šetnju i druženje';
  static const Duration hold = Duration(seconds: 2);
  static const String logoAsset = 'assets/images/vauvau_splash.png';

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _load;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _copySlide;
  late final Animation<double> _progress;
  Timer? _timer;
  var _opened = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _load = AnimationController(
      vsync: this,
      duration: SplashScreen.hold,
    );
    _fade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _copySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.22, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _progress = CurvedAnimation(parent: _load, curve: Curves.easeInOutCubic);
    _intro.forward();
    _load.forward();
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
    _intro.dispose();
    _pulse.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    final dogWidth = (shortest * (shortest < 600 ? 0.58 : 0.36)).clamp(
      180.0,
      300.0,
    );
    final pulse = Tween<double>(begin: 1, end: 1.015).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    return Scaffold(
      backgroundColor: SplashScreen.skyEnd,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.55, -0.8),
            radius: 1.2,
            colors: [
              Color(0x40EA580C),
              SplashScreen.skyStart,
              SplashScreen.skyEnd,
            ],
            stops: [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: ScaleTransition(
                      scale: pulse,
                      child: _DogMark(width: dogWidth),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _copySlide,
                    child: Column(
                      children: [
                        Text(
                          'VauVau',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.96),
                            fontSize: shortest < 360 ? 28 : 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          SplashScreen.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFCBD5E1),
                            fontSize: shortest < 360 ? 13.5 : 15,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: _fade,
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, child) {
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: SizedBox(
                              width: 148,
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                value: _progress.value,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: const SizedBox(height: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DogMark extends StatelessWidget {
  const _DogMark({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      SplashScreen.logoAsset,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
