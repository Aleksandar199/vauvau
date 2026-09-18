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
                final item = items[index];
                return Material(
                  color: item.isRead
                      ? Theme.of(context).cardTheme.color
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Icon(_iconFor(item.kind), color: AppColors.primary),
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.body),
                    onTap: () => _open(context, ref, item),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(NotificationKind kind) {
    return switch (kind) {
      NotificationKind.match => Icons.favorite,
      NotificationKind.walkRequest => Icons.directions_walk,
      NotificationKind.chatMessage => Icons.chat_bubble,
    };
  }

  void _open(BuildContext context, WidgetRef ref, AppNotification item) {
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
