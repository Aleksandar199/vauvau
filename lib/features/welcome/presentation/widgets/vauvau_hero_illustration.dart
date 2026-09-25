import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class VauVauHeroIllustration extends StatefulWidget {
  const VauVauHeroIllustration({super.key});

  static const List<String> assetCandidates = [
    'assets/images/vauvau_hero.png',
    'assets/images/vauvau_logo.png',
  ];

  @override
  State<VauVauHeroIllustration> createState() => _VauVauHeroIllustrationState();
}

class _VauVauHeroIllustrationState extends State<VauVauHeroIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _assetPath;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _resolveHeroAsset();
  }

  Future<void> _resolveHeroAsset() async {
    for (final path in VauVauHeroIllustration.assetCandidates) {
      try {
        await rootBundle.load(path);
        if (mounted) {
          setState(() => _assetPath = path);
        }
        return;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final breathe = math.sin(t * math.pi * 2);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFBEB),
                Color(0xFFFFF7ED),
                Color(0xFFF5E6C8),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40EA580C),
                blurRadius: 32,
                offset: Offset(0, 18),
              ),
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _RadarPainter(progress: t)),
                _floatingPaw(
                  alignment: const Alignment(-0.72, -0.62),
                  phase: 0.08,
                  size: 28,
                  t: t,
                ),
                _floatingPaw(
                  alignment: const Alignment(0.78, -0.48),
                  phase: 0.34,
                  size: 22,
                  t: t,
                ),
                _floatingPaw(
                  alignment: const Alignment(-0.78, 0.58),
                  phase: 0.61,
                  size: 20,
                  t: t,
                ),
                _floatingPaw(
                  alignment: const Alignment(0.7, 0.66),
                  phase: 0.82,
                  size: 26,
                  t: t,
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, breathe * 8),
                    child: Transform.scale(
                      scale: 0.96 + breathe * 0.035,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide * 0.58;
          if (_assetPath != null) {
            return Image.asset(
              _assetPath!,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return CustomPaint(
                  size: Size.square(size),
                  painter: const _VauVauMascotPainter(),
                );
              },
            );
          }
          return CustomPaint(
            size: Size.square(size),
            painter: const _VauVauMascotPainter(),
          );
        },
      ),
    );
  }

  Widget _floatingPaw({
    required Alignment alignment,
    required double phase,
    required double size,
    required double t,
  }) {
    final wave = math.sin((t + phase) * math.pi * 2);
    final opacity = 0.12 + 0.22 * (0.5 + 0.5 * wave);
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(wave * 4, wave * -10),
        child: Icon(
          Icons.pets,
          size: size,
          color: AppColors.primary.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.46;
    for (var i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1;
      final radius = maxRadius * (0.28 + 0.72 * p);
      final fade = (1 - p);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = AppColors.primary.withValues(alpha: fade * 0.08),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = AppColors.primary.withValues(alpha: fade * 0.42),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _VauVauMascotPainter extends CustomPainter {
  const _VauVauMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.height * 0.04);
    final radius = size.shortestSide / 2;

    _paw(
      canvas,
      Offset(center.dx - radius * 0.62, center.dy + radius * 0.52),
      radius * 0.28,
      const Color(0xFFFDBA74),
    );
    _paw(
      canvas,
      Offset(center.dx + radius * 0.62, center.dy + radius * 0.5),
      radius * 0.3,
      AppColors.primary,
    );

    canvas.drawCircle(
      center + Offset(radius * 0.04, radius * 0.1),
      radius * 0.72,
      Paint()..color = const Color(0x330F172A),
    );
    canvas.drawCircle(center, radius * 0.7, Paint()..color = Colors.white);

    final head = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx, center.dy + radius * 0.04),
          radius: radius * 0.42,
        ),
      );
    canvas.drawPath(head, Paint()..color = const Color(0xFFE8C39A));

    final leftEar = Path()
      ..moveTo(center.dx - radius * 0.34, center.dy - radius * 0.06)
      ..quadraticBezierTo(
        center.dx - radius * 0.58,
        center.dy - radius * 0.46,
        center.dx - radius * 0.14,
        center.dy - radius * 0.3,
      )
      ..close();
    final rightEar = Path()
      ..moveTo(center.dx + radius * 0.34, center.dy - radius * 0.06)
      ..quadraticBezierTo(
        center.dx + radius * 0.58,
        center.dy - radius * 0.46,
        center.dx + radius * 0.14,
        center.dy - radius * 0.3,
      )
      ..close();
    final earPaint = Paint()..color = const Color(0xFF3F2A1D);
    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(rightEar, earPaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.14),
        width: radius * 0.58,
        height: radius * 0.4,
      ),
      Paint()..color = const Color(0xFF4A3428),
    );

    final eyePaint = Paint()..color = const Color(0xFF1C1917);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.13, center.dy + radius * 0.01),
      radius * 0.055,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.13, center.dy + radius * 0.01),
      radius * 0.055,
      eyePaint,
    );
    final glint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.115, center.dy - radius * 0.008),
      radius * 0.02,
      glint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.145, center.dy - radius * 0.008),
      radius * 0.02,
      glint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.12),
        width: radius * 0.18,
        height: radius * 0.11,
      ),
      Paint()..color = const Color(0xFF1C1917),
    );

    final smile = Path()
      ..moveTo(center.dx - radius * 0.1, center.dy + radius * 0.2)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.27,
        center.dx + radius * 0.1,
        center.dy + radius * 0.2,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF1C1917)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    _paw(
      canvas,
      Offset(center.dx + radius * 0.38, center.dy + radius * 0.38),
      radius * 0.16,
      const Color(0xFFEA580C),
    );
  }

  void _paw(Canvas canvas, Offset center, double size, Color color) {
    final pad = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size * 0.18),
        width: size * 1.15,
        height: size * 0.92,
      ),
      pad,
    );
    const toes = [
      Offset(-0.42, -0.42),
      Offset(-0.14, -0.58),
      Offset(0.14, -0.58),
      Offset(0.42, -0.42),
    ];
    for (final toe in toes) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + size * toe.dx, center.dy + size * toe.dy),
          width: size * 0.34,
          height: size * 0.42,
        ),
        pad,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
