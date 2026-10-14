import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_strings.dart';

Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  // Capture notifiers / messenger before any await — Settings may dispose
  // while the confirm dialog or sign-out is in flight.
  final auth = ref.read(authControllerProvider.notifier);

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFB91C1C),
                  size: 30,
                ),
              ),
              SizedBox(height: 18),
              Text(
                ProfileStrings.signOutTitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                ProfileStrings.signOutBody,
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    dialogContext,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(ProfileStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(ProfileStrings.signOut),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  if (!context.mounted) {
    // Still attempt sign-out so the session does not linger.
    await auth.signOut();
    return;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.maybeOf(context);

  final result = await auth.signOut();
  // Do not touch WidgetRef after the await — the calling route may be gone.

  try {
    navigator.popUntil((route) => route.isFirst);
  } catch (_) {}

  if (!result.success && context.mounted) {
    final message = result.error is AuthException
        ? (result.error! as AuthException).message
        : ProfileStrings.signOutFailed;
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
