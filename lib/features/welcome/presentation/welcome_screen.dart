import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../auth/presentation/login_screen.dart';
import 'widgets/vauvau_hero_illustration.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _slate = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: _slate,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandMark(onDark: true),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final heroHeight = math.min(
                      constraints.maxHeight,
                      height * 0.55,
                    );
                    return Center(
                      child: SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: const VauVauHeroIllustration(),
                      ),
                    );
                  },
                ),
              ),
              Text(
                AppStrings.tagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFCBD5E1),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 20),
              const _PageDots(activeIndex: 0),
              const SizedBox(height: 20),
              const _StartButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: i == activeIndex ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == activeIndex
                    ? AppColors.primary
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFF97316)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73EA580C),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LoginScreen(),
            ),
          ),
          child: const SizedBox(
            height: 56,
            child: Center(
              child: Text(
                AppStrings.getStarted,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
