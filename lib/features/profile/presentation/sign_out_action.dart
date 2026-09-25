import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import 'profile_strings.dart';

Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(ProfileStrings.signOutTitle),
        content: const Text(ProfileStrings.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(ProfileStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(ProfileStrings.signOut),
          ),
        ],
      );
    },
  );
  if (confirmed == true && context.mounted) {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
