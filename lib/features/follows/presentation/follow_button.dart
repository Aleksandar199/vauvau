import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'follow_controller.dart';
import 'follows_strings.dart';

/// Prati / Pratite for a dog's owner. Following is per owner account, so every
/// dog of the same owner shows the same state. Hidden for my own dogs.
class FollowButton extends ConsumerWidget {
  const FollowButton({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  final String ownerId;
  final String ownerName;

  Future<void> _tap(BuildContext context, WidgetRef ref, bool following) async {
    final controller = ref.read(followControllerProvider.notifier);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (following) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(FollowsStrings.unfollowTitle(ownerName)),
          content: Text(FollowsStrings.unfollowBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(FollowsStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(FollowsStrings.unfollow),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
      try {
        await controller.unfollow(ownerId);
      } catch (_) {
        messenger?.showSnackBar(
          SnackBar(content: Text(FollowsStrings.unfollowFailed)),
        );
      }
      return;
    }
    try {
      await controller.follow(ownerId);
      messenger?.showSnackBar(
        SnackBar(content: Text(FollowsStrings.followedToast(ownerName))),
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(FollowsStrings.followFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(socialUserIdProvider);
    if (ownerId.isEmpty || ownerId == me) {
      return const SizedBox.shrink();
    }
    final following = ref.watch(isFollowingProvider(ownerId));
    final busy = ref.watch(
      followControllerProvider.select((pending) => pending.containsKey(ownerId)),
    );
    final label = following ? FollowsStrings.following : FollowsStrings.follow;
    final icon = following
        ? Icons.how_to_reg_rounded
        : Icons.person_add_alt_1_rounded;
    return FilledButton.tonalIcon(
      key: const ValueKey('follow-owner-button'),
      onPressed: busy ? null : () => _tap(context, ref, following),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: following
            ? AppColors.primarySoft
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: AppColors.primaryDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
