import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFFEA580C);
  static const Color primarySoft = Color(0xFFFFEDD5);
  static const Color primaryDeep = Color(0xFFC2410C);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightOnBackground = Color(0xFF0F172A);
  static const Color lightOutline = Color(0xFFCBD5E1);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkOnBackground = Color(0xFFF8FAFC);
  static const Color darkOutline = Color(0xFF334155);
  static const Color darkCard = Color(0xFF1E293B);

  static const Color secondary = Color(0xFF0F172A);
  static const Color onSecondary = Color(0xFFF8FAFC);

  static const Color success = Color(0xFF16A34A);
  static const Color superLike = Color(0xFF2563EB);
  static const Color cafe = Color(0xFFF59E0B);

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x140F172A),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ];
}
