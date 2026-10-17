import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feed_state.dart';
import '../domain/app_notification.dart';
import 'notification_controller.dart';
import 'notification_routing.dart';
import 'notification_strings.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(NotificationStrings.title),
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
        child: Column(
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
      child: Text(NotificationStrings.markAll),
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
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    return Material(
      color: unread
          ? AppColors.primary.withValues(alpha: 0.05)
          : surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openNotification(context, ref, item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  color: AppColors.primary.withValues(alpha: 0.14),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconFor(item.kind),
                    color: AppColors.primaryDeep,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            unread ? FontWeight.bold : FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      NotificationStrings.timeAgo(item.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
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
    NotificationKind.like => Icons.favorite_border,
    NotificationKind.superLike => Icons.star,
    NotificationKind.groupMessage => Icons.groups_outlined,
    NotificationKind.eventMessage => Icons.event_outlined,
    NotificationKind.follow => Icons.person_add_alt_1_rounded,
    NotificationKind.storyLike => Icons.favorite_rounded,
    NotificationKind.storyReply => Icons.auto_stories_outlined,
  };
}

Future<void> _openNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification item,
) async {
  ref.read(notificationControllerProvider.notifier).markRead(item.id);
  await openAppNotification(context, ref, item);
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return FeedStateView(
      icon: Icons.notifications_none,
      title: NotificationStrings.empty,
      subtitle: NotificationStrings.emptySubtitle,
      padding: EdgeInsets.all(24),
    );
  }
}
