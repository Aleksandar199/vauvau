import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: onDark ? 0.45 : 0.28),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.pets, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 10),
        Text(
          AppStrings.appName,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: onDark ? Colors.white : null,
          ),
        ),
      ],
    );
  }
}
