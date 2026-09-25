import 'package:flutter/material.dart';

class SplashClouds extends StatelessWidget {
  const SplashClouds({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _CloudPainter(),
      size: Size.infinite,
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    _cloud(canvas, paint, Offset(size.width * 0.12, size.height * 0.08), 42);
    _cloud(canvas, paint, Offset(size.width * 0.72, size.height * 0.06), 54);
    _cloud(canvas, paint, Offset(size.width * 0.86, size.height * 0.18), 36);
    _cloud(canvas, paint, Offset(size.width * 0.08, size.height * 0.22), 30);
    _cloud(
      canvas,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
      Offset(size.width * 0.55, size.height * 0.14),
      48,
    );
  }

  void _cloud(Canvas canvas, Paint paint, Offset origin, double radius) {
    canvas.drawCircle(origin, radius, paint);
    canvas.drawCircle(origin + Offset(radius * 0.85, 8), radius * 0.78, paint);
    canvas.drawCircle(origin + Offset(-radius * 0.7, 10), radius * 0.62, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: origin + Offset(radius * 0.1, radius * 0.45),
        width: radius * 2.6,
        height: radius * 1.15,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
