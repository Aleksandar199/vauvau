import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.pets,
          size: 36,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Text(
          AppStrings.appName,
          style: theme.textTheme.headlineLarge,
        ),
      ],
    );
  }
}
