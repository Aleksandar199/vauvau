import 'package:flutter/material.dart';

class SplashMascot extends StatelessWidget {
  const SplashMascot({super.key, this.size = 168});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _MascotPainter()),
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      center + const Offset(6, 10),
      radius * 0.92,
      Paint()..color = const Color(0x33082F49),
    );
    canvas.drawCircle(center, radius * 0.92, Paint()..color = Colors.white);

    final head = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx, center.dy + radius * 0.06),
          radius: radius * 0.52,
        ),
      );
    canvas.drawPath(head, Paint()..color = const Color(0xFFE8C39A));

    final leftEar = Path()
      ..moveTo(center.dx - radius * 0.42, center.dy - radius * 0.08)
      ..quadraticBezierTo(
        center.dx - radius * 0.72,
        center.dy - radius * 0.55,
        center.dx - radius * 0.18,
        center.dy - radius * 0.38,
      )
      ..close();
    final rightEar = Path()
      ..moveTo(center.dx + radius * 0.42, center.dy - radius * 0.08)
      ..quadraticBezierTo(
        center.dx + radius * 0.72,
        center.dy - radius * 0.55,
        center.dx + radius * 0.18,
        center.dy - radius * 0.38,
      )
      ..close();
    final earPaint = Paint()..color = const Color(0xFF3F2A1D);
    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(rightEar, earPaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.18),
        width: radius * 0.72,
        height: radius * 0.5,
      ),
      Paint()..color = const Color(0xFF4A3428),
    );

    final eyePaint = Paint()..color = const Color(0xFF1C1917);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.16, center.dy + radius * 0.02),
      radius * 0.07,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.16, center.dy + radius * 0.02),
      radius * 0.07,
      eyePaint,
    );
    final glint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.14, center.dy - radius * 0.01),
      radius * 0.025,
      glint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.18, center.dy - radius * 0.01),
      radius * 0.025,
      glint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.16),
        width: radius * 0.22,
        height: radius * 0.14,
      ),
      Paint()..color = const Color(0xFF1C1917),
    );

    final smile = Path()
      ..moveTo(center.dx - radius * 0.12, center.dy + radius * 0.26)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.34,
        center.dx + radius * 0.12,
        center.dy + radius * 0.26,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF1C1917)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final badgeCenter = Offset(center.dx + radius * 0.42, center.dy + radius * 0.42);
    canvas.drawCircle(badgeCenter, radius * 0.2, Paint()..color = Colors.white);
    canvas.drawCircle(
      badgeCenter,
      radius * 0.2,
      Paint()
        ..color = const Color(0xFFFB7185)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _heart(canvas, badgeCenter, radius * 0.11, const Color(0xFFE11D48));
  }

  void _heart(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.7)
      ..cubicTo(
        center.dx - size * 1.2,
        center.dy + size * 0.05,
        center.dx - size * 0.7,
        center.dy - size * 0.85,
        center.dx,
        center.dy - size * 0.25,
      )
      ..cubicTo(
        center.dx + size * 0.7,
        center.dy - size * 0.85,
        center.dx + size * 1.2,
        center.dy + size * 0.05,
        center.dx,
        center.dy + size * 0.7,
      );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
