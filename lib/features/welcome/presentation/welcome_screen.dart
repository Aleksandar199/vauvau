import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/illustration_placeholder.dart';
import '../../../core/widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandMark(),
              ),
              const SizedBox(height: 24),
              const Expanded(child: IllustrationPlaceholder()),
              const SizedBox(height: 24),
              Text(
                AppStrings.tagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: AppStrings.getStarted,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.login);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
