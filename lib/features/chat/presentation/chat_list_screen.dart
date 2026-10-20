import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feed_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/ui_bits.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/widgets/swipe_dog_card.dart';
import '../../events/domain/event_model.dart';
import '../../events/presentation/events_controller.dart';
import '../../groups/domain/groups_models.dart';
import '../../groups/presentation/group_chat_screen.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../home/presentation/home_tab.dart';
import '../../moderation/domain/content_report.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_time.dart';
import 'chat_detail_screen.dart';
import 'chat_inbox.dart';
import 'chat_strings.dart';
import 'incoming_likes.dart';
import 'widgets/chat_ui.dart';
import 'widgets/dog_avatar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final inboxLoaded = ref.watch(chatInboxLoadedProvider);
    final conversations = ref.watch(visibleConversationsProvider);
    final groupThreads = ref.watch(joinedGroupThreadsProvider);
    final eventThreads = ref.watch(joinedEventThreadsProvider);
    final incomingLikes = ref.watch(incomingLikesProvider);
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
    final directThreads = visible.where((chat) => !chat.isNewMatch).toList();
    final visibleGroups = needle.isEmpty
        ? groupThreads
        : [
            for (final thread in groupThreads)
              if (thread.group.title.toLowerCase().contains(needle)) thread,
          ];
    final visibleEvents = needle.isEmpty
        ? eventThreads
        : [
            for (final thread in eventThreads)
              if (thread.event.title.toLowerCase().contains(needle) ||
                  thread.event.locationName.toLowerCase().contains(needle))
                thread,
          ];
    final merged = <_InboxEntry>[
      for (final chat in directThreads) _InboxEntry.direct(chat),
      for (final thread in visibleGroups) _InboxEntry.group(thread),
      for (final thread in visibleEvents) _InboxEntry.event(thread),
    ]..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

    return Column(
      children: [
        if (inboxLoaded && incomingLikes.isNotEmpty)
          _IncomingLikesBar(
            likes: incomingLikes,
            onOpenProfile: (profile) => _openLikeProfile(context, ref, profile),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            enabled: inboxLoaded,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: !inboxLoaded
                ? const _InboxLoadingSkeleton(key: ValueKey('inbox-loading'))
                : conversations.isEmpty &&
                        groupThreads.isEmpty &&
                        eventThreads.isEmpty &&
                        incomingLikes.isEmpty
                    ? _EmptyMatches(
                        key: const ValueKey('inbox-empty'),
                        onFindFriends: () => ref
                            .read(homeTabIndexProvider.notifier)
                            .showDiscover(),
                      )
                    : visible.isEmpty &&
                            visibleGroups.isEmpty &&
                            visibleEvents.isEmpty
                        ? Center(
                            key: ValueKey('inbox-no-search'),
                            child: Text(ChatStrings.noSearchResults),
                          )
                        : ListView(
                            key: const ValueKey('inbox-list'),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              if (newMatches.isNotEmpty) ...[
                                Text(
                                  ChatStrings.newMatches,
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
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
                                        onTap: () =>
                                            _openChat(context, ref, chat.id),
                                        onLongPress: () =>
                                            showContentReportSheet(
                                          context: context,
                                          ref: ref,
                                          targetType: ReportContentType.dog,
                                          targetId: chat.dogId,
                                          reportedUserId: chat.peerUserId,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        child: SizedBox(
                                          width: 80,
                                          child: Column(
                                            children: [
                                              PulseBadge(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(3),
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
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],
                              if (merged.isNotEmpty) ...[
                                Text(
                                  ChatStrings.conversations,
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                for (final entry in merged)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color:
                                          Theme.of(context).cardTheme.color,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        leading: DogAvatar(
                                          photoUrl: entry.photoUrl,
                                          size: ChatUiTokens.avatarSize,
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                entry.title,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (entry.badge.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primarySoft,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                ),
                                                child: Text(
                                                  entry.badge,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        subtitle: Text(
                                          entry.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              formatChatTimestamp(
                                                entry.lastActivityAt,
                                                now,
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            if (entry.unreadCount > 0) ...[
                                              const SizedBox(height: 6),
                                              UnreadCountBadge(
                                                count: entry.unreadCount,
                                              ),
                                            ],
                                          ],
                                        ),
                                        onTap: () => switch (entry.kind) {
                                          _InboxKind.event => _openEvent(
                                              context,
                                              ref,
                                              entry.id,
                                            ),
                                          _InboxKind.group => _openGroup(
                                              context,
                                              ref,
                                              entry.id,
                                            ),
                                          _InboxKind.direct => _openChat(
                                              context,
                                              ref,
                                              entry.id,
                                            ),
                                        },
                                        onLongPress:
                                            entry.kind != _InboxKind.direct
                                                ? null
                                                : () => showContentReportSheet(
                                                      context: context,
                                                      ref: ref,
                                                      targetType:
                                                          ReportContentType
                                                              .dog,
                                                      targetId:
                                                          entry.reportTargetId,
                                                      reportedUserId:
                                                          entry.reportUserId,
                                                    ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
          ),
        ),
      ],
    );
  }

  void _openChat(BuildContext context, WidgetRef ref, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ChatDetailScreen(conversationId: id),
      ),
    );
  }

  void _openEvent(BuildContext context, WidgetRef ref, String eventId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupChatScreen(eventId: eventId),
      ),
    );
  }

  void _openGroup(BuildContext context, WidgetRef ref, String groupId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupChatScreen(groupId: groupId),
      ),
    );
  }

  Future<void> _openLikeProfile(
    BuildContext context,
    WidgetRef ref,
    DiscoverProfile profile,
  ) {
    return showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DogDetailSheet(
        profile: profile,
      ),
    );
  }
}

class _IncomingLikesBar extends StatelessWidget {
  const _IncomingLikesBar({
    required this.likes,
    required this.onOpenProfile,
  });

  final List<IncomingLike> likes;
  final ValueChanged<DiscoverProfile> onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ChatStrings.newLikes,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: likes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final like = likes[index];
                final photo = like.profile.imageUrl;
                return InkWell(
                  onTap: () => onOpenProfile(like.profile),
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE11D48),
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 62,
                              height: 62,
                              child: buildDogImage(
                                photo,
                                seed: like.profile.id,
                                width: 62,
                                height: 62,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          like.profile.name,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxLoadingSkeleton extends StatelessWidget {
  const _InboxLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            children: [
              SoftPlaceholder(width: 48, height: 48, borderRadius: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SoftPlaceholder(
                        width: 140,
                        height: 14,
                        borderRadius: 8,
                      ),
                    ),
                    SizedBox(height: 8),
                    SoftPlaceholder(height: 12, borderRadius: 8),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SoftPlaceholder(width: 36, height: 12, borderRadius: 8),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches({super.key, required this.onFindFriends});

  final VoidCallback onFindFriends;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
          SizedBox(height: 16),
          Text(
            ChatStrings.emptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: 8),
          Text(
            ChatStrings.emptySubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.68),
                ),
          ),
          SizedBox(height: 24),
          PrimaryButton(
            label: ChatStrings.findFriends,
            onPressed: onFindFriends,
          ),
        ],
      ),
    );
  }
}

enum _InboxKind { direct, group, event }

class _InboxEntry {
  const _InboxEntry._({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.photoUrl,
    required this.lastActivityAt,
    required this.unreadCount,
    required this.kind,
    required this.reportTargetId,
    this.reportUserId = '',
  });

  factory _InboxEntry.direct(ChatConversation chat) {
    return _InboxEntry._(
      id: chat.id,
      title: chat.dogName,
      subtitle: '${chat.ownerName} · ${chat.lastSnippet}',
      photoUrl: chat.photoUrl,
      lastActivityAt: chat.lastActivityAt,
      unreadCount: chat.unreadCount,
      kind: _InboxKind.direct,
      reportTargetId: chat.dogId,
      reportUserId: chat.peerUserId,
    );
  }

  factory _InboxEntry.group(GroupInboxThread thread) {
    return _InboxEntry._(
      id: thread.group.id,
      title: thread.group.title,
      subtitle: thread.lastMessage.isEmpty
          ? thread.group.description
          : thread.lastMessage,
      photoUrl: thread.group.imageUrl,
      lastActivityAt: thread.lastActivityAt,
      unreadCount: thread.unreadCount,
      kind: _InboxKind.group,
      reportTargetId: thread.group.id,
    );
  }

  factory _InboxEntry.event(EventInboxThread thread) {
    return _InboxEntry._(
      id: thread.event.id,
      title: thread.event.title,
      subtitle: thread.lastMessage.isEmpty
          ? thread.event.locationName
          : thread.lastMessage,
      photoUrl: thread.event.imageUrl,
      lastActivityAt: thread.lastActivityAt,
      unreadCount: thread.unreadCount,
      kind: _InboxKind.event,
      reportTargetId: thread.event.id,
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final String photoUrl;
  final DateTime lastActivityAt;
  final int unreadCount;
  final _InboxKind kind;
  final String reportTargetId;
  final String reportUserId;

  String get badge => switch (kind) {
        _InboxKind.group => ChatStrings.groupBadge,
        _InboxKind.event => ChatStrings.eventBadge,
        _InboxKind.direct => '',
      };
}
