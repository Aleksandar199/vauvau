import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../home/presentation/home_tab.dart';
import '../domain/chat_time.dart';
import 'chat_detail_screen.dart';
import 'chat_inbox.dart';
import 'chat_strings.dart';
import 'widgets/dog_avatar.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(chatInboxProvider);
    final now = ref.watch(chatNowProvider);
    final needle = _query.trim().toLowerCase();
    final visible = needle.isEmpty
        ? conversations
        : conversations
            .where(
              (chat) =>
                  chat.dogName.toLowerCase().contains(needle) ||
                  chat.ownerName.toLowerCase().contains(needle),
            )
            .toList();
    final newMatches = visible.where((chat) => chat.isNewMatch).toList();
    final threads = visible.where((chat) => !chat.isNewMatch).toList()
      ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

    if (conversations.isEmpty) {
      return _EmptyMatches(
        onFindFriends: () =>
            ref.read(homeTabIndexProvider.notifier).showDiscover(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: ChatStrings.searchHint,
              prefixIcon: Icon(Icons.search),
              filled: true,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text(ChatStrings.noSearchResults))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (newMatches.isNotEmpty) ...[
                      Text(
                        ChatStrings.newMatches,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: newMatches.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final chat = newMatches[index];
                            return InkWell(
                              onTap: () => _openChat(context, ref, chat.id),
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                width: 80,
                                child: Column(
                                  children: [
                                    PulseBadge(
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.primary,
                                            width: 2,
                                          ),
                                        ),
                                        child: DogAvatar(
                                          photoUrl: chat.photoUrl,
                                          size: 62,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      chat.dogName,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (threads.isNotEmpty) ...[
                      Text(
                        ChatStrings.conversations,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final chat in threads)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Theme.of(context).cardTheme.color,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: DogAvatar(photoUrl: chat.photoUrl),
                              title: Text(chat.dogName),
                              subtitle: Text(
                                '${chat.ownerName} · ${chat.lastSnippet}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatChatTimestamp(
                                      chat.lastActivityAt,
                                      now,
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (chat.unreadCount > 0) ...[
                                    const SizedBox(height: 6),
                                    PulseBadge(
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: AppColors.primary,
                                        child: Text(
                                          '${chat.unreadCount}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () => _openChat(context, ref, chat.id),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _openChat(BuildContext context, WidgetRef ref, String id) {
    ref.read(chatInboxProvider.notifier).markRead(id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ChatDetailScreen(conversationId: id),
      ),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches({required this.onFindFriends});

  final VoidCallback onFindFriends;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(Icons.chat_bubble_outline, size: 88, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            ChatStrings.emptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            ChatStrings.emptySubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: ChatStrings.findFriends,
            onPressed: onFindFriends,
          ),
        ],
      ),
    );
  }
}
