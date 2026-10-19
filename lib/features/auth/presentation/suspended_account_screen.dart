import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/sign_out_action.dart';
import 'suspended_strings.dart';

/// Shown by AuthGate instead of the app while `users/{uid}.isSuspended`.
/// The rules also refuse new content from a suspended account.
class SuspendedAccountScreen extends ConsumerWidget {
  const SuspendedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block_rounded,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  SuspendedStrings.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(SuspendedStrings.body, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => confirmAndSignOut(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(SuspendedStrings.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
