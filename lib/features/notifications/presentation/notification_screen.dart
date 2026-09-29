import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../chat/presentation/chat_detail_screen.dart';
import '../../chat/presentation/chat_inbox.dart';
import '../../discover/data/load_discover_profile.dart';
import '../../discover/data/mock_discover_profiles.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/discover_controller.dart';
import '../../discover/presentation/widgets/swipe_dog_card.dart';
import '../../home/presentation/home_tab.dart';
import '../domain/app_notification.dart';
import 'notification_controller.dart';
import 'notification_strings.dart';

const Color _notificationCard = Color(0xFF1E2230);

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(NotificationStrings.title),
        actions: const [_MarkAllReadButton()],
      ),
      body: const NotificationsInbox(),
    );
  }
}

Future<void> showNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.78;
      return SizedBox(
        height: height,
        child: const Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      NotificationStrings.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _MarkAllReadButton(),
                ],
              ),
            ),
            Expanded(child: NotificationsInbox()),
          ],
        ),
      );
    },
  );
}

class _MarkAllReadButton extends ConsumerWidget {
  const _MarkAllReadButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(
      notificationControllerProvider.select(
        (items) => items.any((item) => !item.isRead),
      ),
    );
    if (!hasUnread) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () =>
          ref.read(notificationControllerProvider.notifier).markAllRead(),
      child: const Text(NotificationStrings.markAll),
    );
  }
}

class NotificationsInbox extends ConsumerWidget {
  const NotificationsInbox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationControllerProvider);
    if (items.isEmpty) {
      return const _EmptyNotifications();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _NotificationCard(item: items[index]);
      },
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
        NotificationKind.like => Icons.favorite,
  };
}

Future<void> _openNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification item,
) async {
  ref.read(notificationControllerProvider.notifier).markRead(item.id);
  if (item.kind == NotificationKind.walkRequest) {
    ref.read(homeTabIndexProvider.notifier).showMap();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    return;
  }
  if (item.kind == NotificationKind.like) {
    final host = Navigator.of(context).context;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    final profile = await _resolveSenderProfile(ref, item);
    if (!host.mounted || profile == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: host,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DogDetailSheet(
        profile: profile,
        onMessage: () {
          Navigator.of(sheetContext).pop();
          _openChat(host, ref, profile);
        },
      ),
    );
    return;
  }
  DiscoverProfile? profile = await _resolveSenderProfile(ref, item);
  profile ??= _catalogOrMock(ref, item.dogId);
  if (!context.mounted) {
    return;
  }
  _openChat(context, ref, profile);
}

Future<DiscoverProfile?> _resolveSenderProfile(
  WidgetRef ref,
  AppNotification item,
) async {
  try {
    final loaded = await loadDiscoverProfile(
      dogId: item.dogId,
      ownerId: item.fromUserId,
    );
    if (loaded != null) {
      return loaded;
    }
  } catch (_) {}
  return _catalogMatch(ref, item);
}

DiscoverProfile? _catalogMatch(WidgetRef ref, AppNotification item) {
  final catalog = ref.read(discoverControllerProvider).catalog;
  for (final dog in catalog) {
    if (item.dogId != null &&
        item.dogId!.isNotEmpty &&
        dog.id == item.dogId) {
      return dog;
    }
    if (item.fromUserId != null &&
        item.fromUserId!.isNotEmpty &&
        dog.ownerId == item.fromUserId) {
      return dog;
    }
  }
  return null;
}

DiscoverProfile _catalogOrMock(WidgetRef ref, String? dogId) {
  final match = _catalogMatch(
    ref,
    AppNotification(
      id: '',
      kind: NotificationKind.like,
      title: '',
      body: '',
      createdAt: DateTime.now(),
      dogId: dogId,
    ),
  );
  if (match != null) {
    return match;
  }
  for (final dog in mockDiscoverProfiles) {
    if (dog.id == dogId) {
      return dog;
    }
  }
  return mockDiscoverProfiles.first;
}

void _openChat(
  BuildContext context,
  WidgetRef ref,
  DiscoverProfile profile,
) {
  final chatId = ref.read(chatInboxProvider.notifier).openFromMatch(profile);
  ref.read(homeTabIndexProvider.notifier).showMessages();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChatDetailScreen(conversationId: chatId),
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
