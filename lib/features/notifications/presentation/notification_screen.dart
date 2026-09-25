import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../discover/data/mock_discover_profiles.dart';
import '../../discover/domain/discover_profile.dart';
import '../../home/presentation/home_tab.dart';
import '../domain/app_notification.dart';
import 'notification_controller.dart';
import 'notification_strings.dart';

const Color _notificationCard = Color(0xFF1E2230);

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(NotificationStrings.title),
        actions: [
          if (items.any((item) => !item.isRead))
            TextButton(
              onPressed: () =>
                  ref.read(notificationControllerProvider.notifier).markAllRead(),
              child: const Text(NotificationStrings.markAll),
            ),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyNotifications()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _NotificationCard(item: items[index]);
              },
            ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !item.isRead;
    return Material(
      color: _notificationCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openNotification(context, ref, item),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread ? AppColors.primary : const Color(0x33FFFFFF),
              width: unread ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.22),
                  child: Icon(_iconFor(item.kind), color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        NotificationStrings.timeAgo(item.createdAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: _UnreadAccentDot(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadAccentDot extends StatelessWidget {
  const _UnreadAccentDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

IconData _iconFor(NotificationKind kind) {
  return switch (kind) {
    NotificationKind.match => Icons.favorite,
    NotificationKind.walkRequest => Icons.directions_walk,
    NotificationKind.chatMessage => Icons.chat_bubble,
  };
}

void _openNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification item,
) {
  ref.read(notificationControllerProvider.notifier).markRead(item.id);
  if (item.kind == NotificationKind.walkRequest) {
    ref.read(homeTabIndexProvider.notifier).showMap();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    return;
  }
  DiscoverProfile profile = mockDiscoverProfiles.first;
  for (final dog in mockDiscoverProfiles) {
    if (dog.id == item.dogId) {
      profile = dog;
      break;
    }
  }
  final chatId = ref.read(chatInboxProvider.notifier).openFromMatch(profile);
  ref.read(homeTabIndexProvider.notifier).showMessages();
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => ChatScreen(conversationId: chatId),
    ),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              NotificationStrings.empty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
