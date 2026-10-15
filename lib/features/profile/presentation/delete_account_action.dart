import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
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
  final auth = ref.read(authControllerProvider.notifier);
  final needsPassword = auth.deleteAccountRequiresPassword;
  final passwordController = TextEditingController();
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
            if (needsPassword) ...[
              const SizedBox(height: 16),
              Text(ProfileStrings.deleteAccountPasswordHint),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: AppStrings.passwordLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
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

  final password = passwordController.text;
  // Let the dialog's exit animation finish before disposing its controller.
  Future<void>.delayed(
    const Duration(milliseconds: 500),
    passwordController.dispose,
  );
  if (confirmed != true || !context.mounted) {
    return;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.maybeOf(context);

  final result = await auth.deleteAccount(
    password: needsPassword ? password : null,
  );
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
