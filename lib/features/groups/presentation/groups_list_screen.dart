import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/groups_models.dart';
import 'group_chat_screen.dart';
import 'groups_controller.dart';
import 'groups_strings.dart';
import 'widgets/group_card.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsControllerProvider);
    final memberId = ref.watch(groupsMemberIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(GroupsStrings.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            GroupsStrings.subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final group in groups) ...[
            GroupCard(
              group: group,
              isMember: group.isMember(memberId),
              onJoin: () => _join(context, ref, group),
              onOpenChat: () => _openChat(context, group),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _join(
    BuildContext context,
    WidgetRef ref,
    BreedGroup group,
  ) async {
    await ref.read(groupsControllerProvider.notifier).join(group.id);
    if (!context.mounted) {
      return;
    }
    await _openChat(context, group);
  }

  Future<void> _openChat(BuildContext context, BreedGroup group) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupChatScreen(groupId: group.id),
      ),
    );
  }
}
