import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dogs/presentation/dog_providers.dart';
import '../../../features/dogs/presentation/onboarding/dog_onboarding_screen.dart';
import '../../../features/home/presentation/home_shell_screen.dart';
import '../../../features/welcome/presentation/welcome_screen.dart';
import 'auth_providers.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _LoadingScaffold(),
      error: (_, _) => const HomeShellScreen(),
      data: (user) {
        if (user == null) {
          return const WelcomeScreen();
        }
        final dogs = ref.watch(ownerDogsProvider);
        return dogs.when(
          loading: () => const _LoadingScaffold(),
          error: (_, _) => const HomeShellScreen(),
          data: (list) {
            if (list.isEmpty) {
              return const DogOnboardingScreen();
            }
            return const HomeShellScreen();
          },
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
