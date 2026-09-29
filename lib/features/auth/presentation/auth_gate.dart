import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dogs/presentation/dog_providers.dart';
import '../../../features/dogs/presentation/onboarding/dog_onboarding_controller.dart';
import '../../../features/dogs/presentation/onboarding/dog_onboarding_screen.dart';
import '../../../features/home/presentation/home_shell_screen.dart';
import 'auth_providers.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    ref.watch(dogOnboardingControllerProvider.notifier);

    return authState.when(
      loading: () => const _LoadingScaffold(),
      error: (_, _) => const HomeShellScreen(),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        final dogs = ref.watch(ownerDogsProvider);
        if (dogs.hasError && !dogs.hasValue) {
          return const HomeShellScreen();
        }
        if (dogs.isLoading || !dogs.hasValue) {
          return const _LoadingScaffold();
        }
        if (dogs.requireValue.isEmpty) {
          return const DogOnboardingScreen();
        }
        return const HomeShellScreen();
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
