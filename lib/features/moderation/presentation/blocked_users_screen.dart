import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/data/owner_public_profile.dart';
import 'block_controller.dart';
import 'moderation_strings.dart';

/// Users I blocked, with an "Odblokiraj" action for each.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersStreamProvider);
    final ids = (blocked.value ?? const <String>{}).toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(ModerationStrings.blockedUsers)),
      body: blocked.isLoading && !blocked.hasValue
          ? const Center(child: CircularProgressIndicator())
          : ids.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.block_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ModerationStrings.blockedEmpty,
                          key: const ValueKey('blocked-empty'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: ids.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  // Keyed by user: otherwise the next row inherits the removed row's
                  // cached name and spinner.
                  itemBuilder: (context, i) =>
                      _BlockedTile(key: ValueKey(ids[i]), userId: ids[i]),
                ),
    );
  }
}

class _BlockedTile extends ConsumerStatefulWidget {
  const _BlockedTile({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<_BlockedTile> createState() => _BlockedTileState();
}

class _BlockedTileState extends ConsumerState<_BlockedTile> {
  late final Future<OwnerPublicProfile?> _profile = _load();
  var _busy = false;

  Future<OwnerPublicProfile?> _load() async {
    try {
      return await ref.read(ownerProfileLoaderProvider)(widget.userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _unblock(String name) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ModerationStrings.unblockTitle),
        content: Text(ModerationStrings.unblockBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(ModerationStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(ModerationStrings.unblock),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(blockControllerProvider).unblock(widget.userId);
      messenger?.showSnackBar(
        SnackBar(content: Text(ModerationStrings.unblockDone)),
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(ModerationStrings.unblockFailed)),
      );
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OwnerPublicProfile?>(
      future: _profile,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = (profile?.name.trim().isNotEmpty ?? false)
            ? profile!.name.trim()
            : ModerationStrings.unknownUser;
        final photo = profile?.photoUrl ?? '';
        return ListTile(
          key: ValueKey('blocked-${widget.userId}'),
          leading: ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: photo.isEmpty
                  ? const ColoredBox(
                      color: AppColors.primarySoft,
                      child: Icon(Icons.person, color: AppColors.primaryDeep),
                    )
                  : DogImage(url: photo, seed: widget.userId),
            ),
          ),
          title: Text(name),
          trailing: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton(
                  key: ValueKey('unblock-${widget.userId}'),
                  onPressed: () => _unblock(name),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text(ModerationStrings.unblock),
                ),
        );
      },
    );
  }
}
