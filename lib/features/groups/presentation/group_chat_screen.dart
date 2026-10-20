import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../core/network/network_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/message_reactions.dart';
import '../../chat/domain/chat_message.dart';
import '../../chat/domain/chat_time.dart';
import '../../chat/presentation/chat_strings.dart';
import '../../chat/presentation/schedule_walk_sheet.dart';
import '../../chat/presentation/widgets/chat_ui.dart';
import '../../chat/presentation/widgets/message_reactions.dart';
import '../../chat/presentation/widgets/message_reply.dart';
import '../../chat/presentation/widgets/walk_invite_card.dart';
import '../../discover/presentation/widgets/dog_photo_gallery.dart';
import '../../events/presentation/events_controller.dart';
import '../../profile/presentation/owner_profile_sheet.dart';
import '../domain/groups_models.dart';
import 'groups_controller.dart';
import 'groups_strings.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({super.key, this.groupId, this.eventId})
    : assert(groupId != null || eventId != null);

  final String? groupId;
  final String? eventId;

  bool get isEvent => eventId != null;

  String get threadId => eventId ?? groupId!;

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode(debugLabel: 'GroupChatInput');
  final _scroll = ScrollController();
  final _unreadAnchorKey = GlobalKey();
  var _sendingPhoto = false;
  GroupMessage? _replyTo;

  /// Unread count captured before [markRead] clears it.
  var _openUnreadCount = 0;
  var _initialScrollDone = false;
  var _initialScrollScheduled = false;
  int? _unreadAnchorIndex;
  var _lastKnownMessageCount = 0;
  var _unreadCaptured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _captureUnreadBeforeMarkRead();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _captureUnreadBeforeMarkRead() {
    if (_unreadCaptured) {
      return;
    }
    _unreadCaptured = true;
    if (widget.isEvent) {
      for (final thread in ref.read(joinedEventThreadsProvider)) {
        if (thread.event.id == widget.threadId) {
          _openUnreadCount = thread.unreadCount;
          return;
        }
      }
    } else {
      for (final thread in ref.read(joinedGroupThreadsProvider)) {
        if (thread.group.id == widget.threadId) {
          _openUnreadCount = thread.unreadCount;
          return;
        }
      }
    }
    // Fallback from lastRead + messages if inbox thread is not ready yet.
    _openUnreadCount = _computeUnreadFromLastRead();
  }

  int _computeUnreadFromLastRead() {
    final messages = _currentMessages();
    final lastRead = widget.isEvent
        ? ref.read(eventLastReadProvider(widget.threadId)).asData?.value
        : ref.read(groupLastReadProvider(widget.threadId)).asData?.value;
    if (lastRead == null || messages.isEmpty) {
      return 0;
    }
    var unread = 0;
    for (final message in messages) {
      if (!message.isMine && message.createdAt.isAfter(lastRead)) {
        unread++;
      }
    }
    return unread;
  }

  List<GroupMessage> _currentMessages() {
    if (widget.isEvent) {
      return ref.read(eventMessagesProvider(widget.threadId)).asData?.value ??
          const [];
    }
    return ref.read(groupMessagesProvider(widget.threadId)).asData?.value ??
        const [];
  }

  void _keepInputFocused() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sendingPhoto) {
        return;
      }
      _inputFocus.requestFocus();
    });
  }

  bool get _isNearBottom {
    if (!_scroll.hasClients) {
      return true;
    }
    final position = _scroll.position;
    return position.maxScrollExtent - position.pixels <= 120;
  }

  void _scrollToEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) {
        return;
      }
      final target = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  void _markRead() {
    if (widget.isEvent) {
      ref.read(eventsControllerProvider.notifier).markRead(widget.threadId);
    } else {
      ref.read(groupsControllerProvider.notifier).markRead(widget.threadId);
    }
  }

  /// First open: jump to first unread, or to bottom when everything is read.
  void _maybePerformInitialScroll(List<GroupMessage> messages) {
    if (_initialScrollDone || _initialScrollScheduled || messages.isEmpty) {
      return;
    }
    if (!_unreadCaptured) {
      _captureUnreadBeforeMarkRead();
    }
    _initialScrollScheduled = true;
    final unread = _openUnreadCount.clamp(0, messages.length);
    if (unread > 0) {
      final index = (messages.length - unread).clamp(0, messages.length - 1);
      setState(() => _unreadAnchorIndex = index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final ctx = _unreadAnchorKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.08,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        } else {
          _jumpToEndWithRetry();
        }
        _finishInitialScroll(messages.length);
      });
      return;
    }

    // All read → latest message at the bottom.
    _jumpToEndWithRetry(then: () => _finishInitialScroll(messages.length));
  }

  void _jumpToEndWithRetry({VoidCallback? then, int attemptsLeft = 3}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
      if (attemptsLeft > 1 &&
          _scroll.hasClients &&
          _scroll.position.maxScrollExtent <= 0) {
        _jumpToEndWithRetry(then: then, attemptsLeft: attemptsLeft - 1);
        return;
      }
      if (attemptsLeft > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
          then?.call();
        });
        WidgetsBinding.instance.scheduleFrame();
        return;
      }
      then?.call();
    });
    // A short, non-scrollable chat triggers no further frames on its own,
    // so the callback (and markRead after it) would otherwise never run.
    WidgetsBinding.instance.scheduleFrame();
  }

  void _finishInitialScroll(int messageCount) {
    if (_initialScrollDone || !mounted) {
      return;
    }
    _initialScrollDone = true;
    _unreadAnchorIndex = null;
    _lastKnownMessageCount = messageCount;
    _markRead();
  }

  void _onMessagesUpdated(List<GroupMessage> messages) {
    if (!_initialScrollDone) {
      _maybePerformInitialScroll(messages);
      return;
    }
    final previous = _lastKnownMessageCount;
    _lastKnownMessageCount = messages.length;
    if (messages.length <= previous) {
      return;
    }
    _markRead();
    if (_isNearBottom) {
      _scrollToEnd();
    }
  }

  Future<void> _sendText() async {
    final text = _input.text;
    if (text.trim().isEmpty) {
      return;
    }
    final reply = _replyTo;
    _input.clear();
    setState(() => _replyTo = null);
    _keepInputFocused();
    if (widget.isEvent) {
      await ref
          .read(eventsControllerProvider.notifier)
          .sendText(widget.threadId, text, replyTo: reply);
    } else {
      await ref
          .read(groupsControllerProvider.notifier)
          .sendText(widget.threadId, text, replyTo: reply);
    }
    if (!mounted) {
      return;
    }
    _scrollToEnd();
    _keepInputFocused();
  }

  Future<void> _openAttachMenu() async {
    final action = await showAppBottomSheet<_GroupAttachAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pets),
                title: Text(ChatStrings.scheduleWalk),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _GroupAttachAction.scheduleWalk,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(GroupsStrings.addPhoto),
                onTap: () =>
                    Navigator.pop(sheetContext, _GroupAttachAction.photo),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case _GroupAttachAction.scheduleWalk:
        await _openScheduleWalk();
      case _GroupAttachAction.photo:
        await _pickPhoto();
    }
  }

  Future<void> _openScheduleWalk() async {
    await showScheduleWalkSheet(
      context: context,
      onSend: (walkTime, location) async {
        if (widget.isEvent) {
          await ref
              .read(eventsControllerProvider.notifier)
              .sendWalkInvite(
                eventId: widget.threadId,
                walkTime: walkTime,
                walkLocationName: location,
              );
        } else {
          await ref
              .read(groupsControllerProvider.notifier)
              .sendWalkInvite(
                groupId: widget.threadId,
                walkTime: walkTime,
                walkLocationName: location,
              );
        }
        _scrollToEnd();
      },
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showAppBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(GroupsStrings.gallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(GroupsStrings.camera),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(GroupsStrings.cancel),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) {
      return;
    }
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 72,
    );
    if (file == null || !mounted) {
      return;
    }
    final reply = _replyTo;
    setState(() {
      _sendingPhoto = true;
      _replyTo = null;
    });
    try {
      if (widget.isEvent) {
        await ref
            .read(eventsControllerProvider.notifier)
            .sendPhoto(widget.threadId, file, replyTo: reply);
      } else {
        await ref
            .read(groupsControllerProvider.notifier)
            .sendPhoto(widget.threadId, file, replyTo: reply);
      }
      _scrollToEnd();
    } catch (error) {
      if (mounted) {
        showNetworkErrorSnackBar(
          context,
          error,
          fallback: GroupsStrings.photoFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingPhoto = false);
      }
    }
  }

  Future<void> _respondToWalk(
    GroupMessage message,
    GroupWalkInviteStatus status,
  ) async {
    if (widget.isEvent) {
      await ref
          .read(eventsControllerProvider.notifier)
          .respondToWalkInvite(
            eventId: widget.threadId,
            messageId: message.id,
            status: status,
          );
    } else {
      await ref
          .read(groupsControllerProvider.notifier)
          .respondToWalkInvite(
            groupId: widget.threadId,
            messageId: message.id,
            status: status,
          );
    }
  }

  Future<void> _onMessageLongPress(GroupMessage message) async {
    final choice = await showMessageActionsSheet(
      context,
      canReport: false,
      canReact: true,
      currentReaction: MessageReactions.reactionOf(
        message.likes,
        ref.read(groupsMemberIdProvider),
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    if (choice.action == MessageAction.react) {
      await _react(message.id, choice.emoji);
      return;
    }
    if (choice.action != MessageAction.reply) {
      return;
    }
    setState(() => _replyTo = message);
    _inputFocus.requestFocus();
  }

  /// Avatar next to a message → the sender's own profile (with their dogs).
  Future<void> _openSenderProfile(GroupMessage message) {
    return showOwnerProfileSheet(
      context,
      userId: message.senderId.trim(),
      fallbackName: message.senderName,
      fallbackAvatarUrl: message.senderAvatarUrl,
    );
  }

  Future<void> _react(String messageId, String? emoji) async {
    try {
      if (widget.isEvent) {
        await ref
            .read(eventsControllerProvider.notifier)
            .setMessageReaction(
              eventId: widget.threadId,
              messageId: messageId,
              emoji: emoji,
            );
      } else {
        await ref
            .read(groupsControllerProvider.notifier)
            .setMessageReaction(
              groupId: widget.threadId,
              messageId: messageId,
              emoji: emoji,
            );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showNetworkErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEvent) {
      ref.listen<AsyncValue<List<GroupMessage>>>(
        eventMessagesProvider(widget.threadId),
        (previous, next) {
          final messages = next.asData?.value;
          if (messages != null) {
            _onMessagesUpdated(messages);
          }
        },
      );
    } else {
      ref.listen<AsyncValue<List<GroupMessage>>>(
        groupMessagesProvider(widget.threadId),
        (previous, next) {
          final messages = next.asData?.value;
          if (messages != null) {
            _onMessagesUpdated(messages);
          }
        },
      );
    }

    final group = widget.isEvent
        ? null
        : ref.watch(groupByIdProvider(widget.threadId));
    final event = widget.isEvent
        ? ref.watch(eventByIdProvider(widget.threadId))
        : null;
    final messages = widget.isEvent
        ? ref.watch(eventMessagesProvider(widget.threadId)).value ??
              const <GroupMessage>[]
        : ref.watch(groupMessagesProvider(widget.threadId)).value ??
              const <GroupMessage>[];
    final title = event?.title ?? group?.title ?? GroupsStrings.title;
    final count = event?.participantCount ?? group?.displayMemberCount ?? 0;
    final imageUrl = event?.imageUrl ?? group?.imageUrl;
    final memberId = ref.watch(groupsMemberIdProvider);
    final now = DateTime.now();

    // First paint may already have cached messages before listen fires.
    if (!_initialScrollDone && messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onMessagesUpdated(messages);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              key: const ValueKey('group-chat-header-photo'),
              // Thumbnail stays cropped; tap shows the whole photo.
              onTap: isUnusableDogPhotoUrl(imageUrl)
                  ? null
                  : () => showDogPhotoViewer(
                        context,
                        photos: [imageUrl!.trim()],
                        seed: widget.threadId,
                      ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: buildDogImage(imageUrl, seed: widget.threadId),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    GroupsStrings.memberCount(count),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(child: Text(GroupsStrings.emptyChat))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUnreadAnchor = _unreadAnchorIndex == index;
                      Widget child;
                      if (message.isWalkInvite) {
                        child = WalkInviteCard(
                          message: _groupWalkAsChat(message, memberId),
                          now: now,
                          acceptedCount: message.acceptedCount,
                          viewerAlreadyResponded: message.hasUserResponded(
                            memberId,
                          ),
                          onAccept: () => _respondToWalk(
                            message,
                            GroupWalkInviteStatus.accepted,
                          ),
                          onDecline: () => _respondToWalk(
                            message,
                            GroupWalkInviteStatus.declined,
                          ),
                        );
                      } else {
                        child = _GroupMessageBubble(
                          message: message,
                          now: now,
                          currentUserId: memberId,
                          onAvatarTap: message.isMine
                              ? null
                              : () => _openSenderProfile(message),
                          onLongPress: () => _onMessageLongPress(message),
                        );
                      }
                      if (!isUnreadAnchor) {
                        return child;
                      }
                      return KeyedSubtree(key: _unreadAnchorKey, child: child);
                    },
                  ),
          ),
          if (_sendingPhoto) const LinearProgressIndicator(minHeight: 2),
          if (_replyTo != null)
            ReplyComposeBanner(
              senderName: _replyTo!.senderName,
              text: _replyTo!.preview,
              onCancel: () => setState(() => _replyTo = null),
            ),
          ChatInputBar(
            controller: _input,
            focusNode: _inputFocus,
            onSend: _sendText,
            onAttach: _openAttachMenu,
            attachIcon: Icons.add_circle_outline,
            attachTooltip: ChatStrings.attach,
            hintText: GroupsStrings.composeHint,
            sendTooltip: GroupsStrings.send,
            enabled: !_sendingPhoto,
          ),
        ],
      ),
    );
  }
}

enum _GroupAttachAction { scheduleWalk, photo }

ChatMessage _groupWalkAsChat(GroupMessage message, String viewerId) {
  final personalStatus = message.acceptedByUserIds.contains(viewerId)
      ? WalkInviteStatus.accepted
      : message.declinedByUserIds.contains(viewerId)
      ? WalkInviteStatus.declined
      : WalkInviteStatus.pending;
  return ChatMessage(
    id: message.id,
    text: message.text,
    sentAt: message.createdAt,
    isMine: message.isMine,
    senderName: message.senderName,
    senderAvatarUrl: message.senderAvatarUrl,
    type: ChatMessageType.walkInvite,
    status: personalStatus,
    walkTime: message.walkTime,
    walkLocationName: message.walkLocationName,
  );
}

class _GroupMessageBubble extends StatelessWidget {
  const _GroupMessageBubble({
    required this.message,
    required this.now,
    this.currentUserId = '',
    this.onAvatarTap,
    this.onLongPress,
  });

  final GroupMessage message;
  final DateTime now;
  final String currentUserId;
  final VoidCallback? onAvatarTap;

  /// Reactions / reply menu (also from a tap on the reactions).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final background = mine ? AppColors.primary : Colors.grey.shade200;
    final foreground = mine ? AppColors.onPrimary : AppColors.ink;
    return Padding(
      padding: ChatUiTokens.bubbleOuterPadding,
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            GestureDetector(
              key: const ValueKey('group-sender-avatar'),
              behavior: HitTestBehavior.opaque,
              onTap: onAvatarTap,
              child: SenderAvatar(
                url: message.senderAvatarUrl,
                name: message.senderName,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: BubbleWithReactions(
              likes: message.likes,
              currentUserId: currentUserId,
              isMine: mine,
              onReactionsTap: onLongPress,
              bubble: GestureDetector(
                onLongPress: onLongPress,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: ChatUiTokens.bubbleRadius(isMine: mine),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Column(
                        crossAxisAlignment: mine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!mine)
                            Text(
                              message.senderName,
                              style: TextStyle(
                                color: foreground.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          if (message.hasReply)
                            ReplyQuote(
                              senderName: message.replyToSenderName,
                              text: message.replyToText,
                              isMine: mine,
                            ),
                          if (message.hasImage) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              key: const ValueKey('group-message-image'),
                              onTap: () => showDogPhotoViewer(
                                context,
                                photos: [message.imageUrl],
                                seed: message.id,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: 160,
                                  width: double.infinity,
                                  child: buildDogImage(
                                    message.imageUrl,
                                    seed: message.id,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (message.text.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              message.text,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatChatTimestamp(message.createdAt, now),
                                style: TextStyle(
                                  color: foreground.withValues(alpha: 0.65),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (mine) ...[
            const SizedBox(width: 8),
            SenderAvatar(
              url: message.senderAvatarUrl,
              name: message.senderName,
            ),
          ],
        ],
      ),
    );
  }
}
