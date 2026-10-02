import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_strings.dart';

const _danger = Color(0xFFB91C1C);

Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.warning_amber_rounded, color: _danger, size: 36),
        title: const Text(ProfileStrings.deleteAccountTitle),
        content: const Text(ProfileStrings.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(ProfileStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(ProfileStrings.deleteConfirm),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final auth = ref.read(authControllerProvider.notifier);
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.maybeOf(context);

  final success = await auth.deleteAccount();
  if (success) {
    navigator.popUntil((route) => route.isFirst);
    return;
  }

  final error = ref.read(authControllerProvider).error;
  final message = error is AuthException
      ? error.message
      : ProfileStrings.deleteAccountFailed;
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}
