import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../legal/presentation/legal_document_screen.dart';
import '../../legal/presentation/legal_strings.dart';
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
        title: Text(ProfileStrings.deleteAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ProfileStrings.deleteAccountBody),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
                openLegalDocument(
                  context,
                  kind: LegalDocumentKind.privacy,
                );
              },
              child: Text(LegalStrings.privacyPolicy),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(ProfileStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(ProfileStrings.deleteConfirm),
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

  final result = await auth.deleteAccount();
  // Never use WidgetRef after await — Profile/Settings may already be disposed.
  if (!context.mounted) {
    if (result.success) {
      try {
        navigator.popUntil((route) => route.isFirst);
      } catch (_) {}
    }
    return;
  }

  if (result.success) {
    navigator.popUntil((route) => route.isFirst);
    return;
  }

  final message = result.error is AuthException
      ? (result.error! as AuthException).message
      : ProfileStrings.deleteAccountFailed;
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}
