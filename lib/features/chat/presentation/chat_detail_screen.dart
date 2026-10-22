import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/network_failure.dart';
import '../../../core/utils/message_reactions.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/data/load_discover_profile.dart';
import '../../discover/domain/discover_profile.dart';
import '../../discover/presentation/widgets/swipe_dog_card.dart';
import '../../moderation/domain/content_report.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../moderation/presentation/safety_menu.dart';
import '../../profile/presentation/owner_profile_sheet.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import 'chat_inbox.dart';
import 'chat_strings.dart';
import 'open_chats.dart';
import 'schedule_walk_sheet.dart';
import 'widgets/chat_ui.dart';
import 'widgets/dog_avatar.dart';
import 'widgets/location_picker_sheet.dart';
import 'widgets/location_pin_bubble.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_reply.dart';
import 'widgets/walk_invite_card.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focusNode = FocusNode();
  final _unreadAnchorKey = GlobalKey();
  ChatMessage? _replyTo;
  var _sendingPhoto = false;
  ChatInboxController? _inbox;
  OpenChatsController? _openChats;
  var _roomAttached = false;

  /// Unread count captured before [markRead] clears it.
  var _openUnreadCount = 0;
  var _initialScrollDone = false;
  var _initialScrollScheduled = false;
  int? _unreadAnchorIndex;
  var _lastKnownMessageCount = 0;

  /// Hydrated from the peer dog doc when the room is missing breed/location.
  String? _peerBreed;
  String? _peerLocation;
  var _peerWalking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final openChats = ref.read(openChatsProvider.notifier);
      openChats.open(widget.conversationId);
      _openChats = openChats;
      _inbox = ref.read(chatInboxProvider.notifier);
      final chat = _conversationFromInbox();
      _openUnreadCount = chat?.unreadCount ?? 0;
      _inbox!.attachRoom(widget.conversationId);
      _roomAttached = true;
      // Defer markRead until after the first scroll so unreadCount is usable.
      unawaited(_hydratePeerSubtitle(chat));
    });
  }

  Future<void> _hydratePeerSubtitle(ChatConversation? chat) async {
    if (chat == null) {
      return;
    }
    final profile = await loadDiscoverProfile(
      dogId: chat.dogId,
      ownerId: chat.peerUserId,
    );
    if (!mounted || profile == null) {
      return;
    }
    setState(() {
      _peerBreed = profile.breed.trim().isEmpty ? null : profile.breed.trim();
      _peerLocation = profile.location.trim().isEmpty
          ? null
          : profile.location.trim();
      _peerWalking = profile.walking;
    });
  }

  ChatConversation? _conversationFromInbox() {
    final conversations = ref.read(chatInboxProvider);
    for (final item in conversations) {
      if (item.id == widget.conversationId) {
        return item;
      }
    }
    return null;
  }

  @override
  void dispose() {
    // Do not use [ref] here (unsafe after unmount). Detach via cached notifier.
    WidgetsBinding.instance.removeObserver(this);
    _openChats?.close(widget.conversationId);
    if (_roomAttached) {
      _inbox?.detachRoom(widget.conversationId);
      _roomAttached = false;
    }
    _input.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
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

  /// First open: jump to first unread, or to bottom when everything is read.
  void _maybePerformInitialScroll(List<ChatMessage> messages) {
    if (_initialScrollDone || _initialScrollScheduled || messages.isEmpty) {
      return;
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

    // All read → bottom (retry until layout reports a real extent).
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
      // One more frame after content lays out with non-zero extent.
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
    _inbox?.markRead(widget.conversationId);
  }

  /// Messages that arrive while this chat is on screen are already seen.
  void _clearUnreadWhileViewing(ChatConversation chat) {
    if (!_initialScrollDone || chat.unreadCount <= 0) {
      return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return;
    }
    _inbox?.markRead(widget.conversationId);
  }

  /// Messages that arrived while the app was in the background are read as
  /// soon as the user is back in this chat (no other inbox change may come).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    final chat = _conversationFromInbox();
    if (chat != null) {
      _clearUnreadWhileViewing(chat);
    }
  }

  void _onMessagesUpdated(List<ChatMessage> messages) {
    if (!_initialScrollDone) {
      _maybePerformInitialScroll(messages);
      return;
    }
    final previous = _lastKnownMessageCount;
    _lastKnownMessageCount = messages.length;
    if (messages.length <= previous) {
      return;
    }
    // New messages while viewing: only stick to bottom if already near it.
    if (_isNearBottom) {
      _scrollToEnd();
    }
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) {
      return;
    }
    final reply = _replyTo;
    _input.clear();
    setState(() => _replyTo = null);
    _focusNode.requestFocus();
    _scrollToEnd();
    try {
      await ref
          .read(chatInboxProvider.notifier)
          .sendMessage(widget.conversationId, text, replyTo: reply);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
      setState(() => _replyTo = reply);
      showNetworkErrorSnackBar(
        context,
        error,
        fallback: ChatStrings.sendFailed,
      );
    }
  }

  Future<void> _onMessageLongPress(
    ChatMessage message,
    ChatConversation chat,
  ) async {
    final myId = ref.read(authStateProvider).asData?.value?.uid ?? '';
    final choice = await showMessageActionsSheet(
      context,
      canReport: !message.isMine,
      canReact: true,
      currentReaction: MessageReactions.reactionOf(message.likes, myId),
    );
    if (!mounted || choice == null) {
      return;
    }
    final action = choice.action;
    if (action == MessageAction.react) {
      await _react(message.id, choice.emoji);
      return;
    }
    if (action == MessageAction.reply) {
      setState(() => _replyTo = message);
      _focusNode.requestFocus();
      return;
    }
    if (action == MessageAction.report) {
      await showContentReportSheet(
        context: context,
        ref: ref,
        targetType: ReportContentType.message,
        targetId: message.id,
        reportedUserId: chat.peerUserId,
        // Lets the admin open and delete the exact message.
        contextId: widget.conversationId,
        targetName: message.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<ChatConversation>>(chatInboxProvider, (previous, next) {
      for (final item in next) {
        if (item.id == widget.conversationId) {
          _onMessagesUpdated(item.messages);
          _clearUnreadWhileViewing(item);
          return;
        }
      }
    });

    final conversations = ref.watch(chatInboxProvider);
    ChatConversation? found;
    for (final item in conversations) {
      if (item.id == widget.conversationId) {
        found = item;
        break;
      }
    }

    if (found == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(ChatStrings.missingChat)),
      );
    }

    final open = found;
    // First paint may already have messages cached before listen fires.
    if (!_initialScrollDone && open.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onMessagesUpdated(open.messages);
        }
      });
    }

    final now = ref.watch(chatNowProvider);
    final me = ref.watch(authStateProvider).asData?.value;
    final myAvatar = me?.ownerAvatarUrl ?? '';
    final myName = (me?.displayName ?? '').trim().isEmpty
        ? 'Ti'
        : me!.displayName!.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _openSenderProfile(context, open),
          child: Row(
            children: [
              DogAvatar(photoUrl: open.photoUrl, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      open.title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      ChatStrings.peerSubtitle(
                        breed: (_peerBreed ?? open.breed).trim(),
                        location: (_peerLocation ?? open.location).trim(),
                        walking: _peerWalking,
                        isNewMatch: open.isNewMatch,
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _peerWalking
                            ? const Color(0xFF16A34A)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _openSchedule(context),
            icon: const Icon(Icons.pets),
          ),
          SafetyMenuButton(
            reportedUserId: open.peerUserId,
            targetId: open.peerUserId.isEmpty ? open.dogId : open.peerUserId,
            onBlocked: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: open.messages.length,
              itemBuilder: (context, index) {
                final message = open.messages[index];
                Widget child;
                if (message.isWalkInvite) {
                  child = WalkInviteCard(
                    message: message,
                    now: now,
                    onAccept: () =>
                        _respond(message.id, WalkInviteStatus.accepted),
                    onDecline: () =>
                        _respond(message.id, WalkInviteStatus.declined),
                  );
                } else if (message.isLocationPin) {
                  child = LocationPinBubble(
                    message: message,
                    now: now,
                    currentUserId: me?.uid ?? '',
                    onLongPress: () => _onMessageLongPress(message, open),
                  );
                } else {
                  child = MessageBubble(
                    message: message,
                    now: now,
                    currentUserId: me?.uid ?? '',
                    fallbackAvatarUrl: message.isMine ? myAvatar : '',
                    fallbackSenderName: message.isMine
                        ? myName
                        : open.ownerName,
                    onAvatarTap: message.isMine
                        ? null
                        : () => _openOwnerProfile(context, message, open),
                    onLongPress: () => _onMessageLongPress(message, open),
                  );
                }
                if (index == open.messages.length - 1 &&
                    open.lastMessageSeenByPeer) {
                  child = Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      child,
                      Padding(
                        key: const ValueKey('message-seen'),
                        padding: const EdgeInsets.fromLTRB(0, 0, 56, 4),
                        child: Text(
                          ChatStrings.seen,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  );
                }
                if (index == _unreadAnchorIndex) {
                  return KeyedSubtree(key: _unreadAnchorKey, child: child);
                }
                return child;
              },
            ),
          ),
          if (_replyTo != null)
            ReplyComposeBanner(
              senderName: _replyTo!.isMine
                  ? myName
                  : (_replyTo!.senderName.trim().isNotEmpty
                        ? _replyTo!.senderName
                        : open.ownerName),
              text: _replyTo!.previewText,
              onCancel: () => setState(() => _replyTo = null),
            ),
          if (_sendingPhoto)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          ChatInputBar(
            controller: _input,
            focusNode: _focusNode,
            onSend: _send,
            onAttach: () => _openAttachMenu(context),
            attachTooltip: ChatStrings.attach,
            hintText: ChatStrings.composeHint,
            sendTooltip: ChatStrings.send,
            enabled: !_sendingPhoto,
          ),
        ],
      ),
    );
  }

  Future<void> _react(String messageId, String? emoji) async {
    try {
      await ref
          .read(chatInboxProvider.notifier)
          .setMessageReaction(
            conversationId: widget.conversationId,
            messageId: messageId,
            emoji: emoji,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showNetworkErrorSnackBar(context, error);
    }
  }

  Future<void> _respond(String messageId, WalkInviteStatus status) async {
    try {
      await ref
          .read(chatInboxProvider.notifier)
          .respondToWalkInvite(
            conversationId: widget.conversationId,
            messageId: messageId,
            status: status,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showNetworkErrorSnackBar(
        context,
        error,
        fallback: ChatStrings.walkRespondFailed,
      );
    }
  }

  /// Avatar next to a message → the person who sent it (owner profile with
  /// their dogs), not straight to the dog.
  Future<void> _openOwnerProfile(
    BuildContext context,
    ChatMessage message,
    ChatConversation chat,
  ) {
    final name = message.senderName.trim();
    return showOwnerProfileSheet(
      context,
      userId: chat.peerUserId,
      fallbackName: name.isNotEmpty ? name : chat.ownerName,
      fallbackAvatarUrl: message.senderAvatarUrl,
      fallbackDogs: [_profileFromChat(chat)],
    );
  }

  /// App bar → the peer's dog in this chat.
  Future<void> _openSenderProfile(
    BuildContext context,
    ChatConversation chat,
  ) async {
    DiscoverProfile? profile;
    try {
      profile = await _loadPeerProfile(chat);
    } catch (_) {
      profile = null;
    }
    profile ??= _profileFromChat(chat);
    if (!context.mounted) {
      return;
    }
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DogDetailSheet(profile: profile!),
    );
  }

  DiscoverProfile _profileFromChat(ChatConversation chat) {
    return DiscoverProfile(
      id: chat.dogId.isEmpty ? chat.peerUserId : chat.dogId,
      ownerId: chat.peerUserId,
      name: chat.dogName,
      ownerName: chat.ownerName,
      breed: chat.breed,
      ageYears: 0,
      gender: '',
      size: 'srednji',
      location: chat.location.isEmpty ? 'Srbija' : chat.location,
      bio: '',
      photoUrls: chat.photoUrl.isEmpty ? const [] : [chat.photoUrl],
    );
  }

  Future<DiscoverProfile?> _loadPeerProfile(ChatConversation chat) {
    return loadDiscoverProfile(dogId: chat.dogId, ownerId: chat.peerUserId);
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    final location = await showLocationPickerSheet(context);
    if (location == null || location.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(chatInboxProvider.notifier)
          .sendLocationPin(
            conversationId: widget.conversationId,
            locationName: location,
          );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showNetworkErrorSnackBar(
        context,
        error,
        fallback: ChatStrings.locationFailed,
      );
    }
  }

  Future<void> _openSchedule(BuildContext context) async {
    await showScheduleWalkSheet(
      context: context,
      onSend: (walkTime, location) async {
        try {
          await ref
              .read(chatInboxProvider.notifier)
              .sendWalkInvite(
                conversationId: widget.conversationId,
                walkTime: walkTime,
                walkLocationName: location,
              );
        } catch (error) {
          if (!context.mounted) {
            return;
          }
          showNetworkErrorSnackBar(
            context,
            error,
            fallback: ChatStrings.walkInviteFailed,
          );
        }
      },
    );
  }

  Future<void> _openAttachMenu(BuildContext context) async {
    // Await the attach sheet fully before opening the next sheet — popping and
    // immediately showing another modal fails on many mobile devices.
    final action = await showAppBottomSheet<_ChatAttachAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: Text(ChatStrings.addPhoto),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_ChatAttachAction.photo),
              ),
              ListTile(
                leading: const Icon(Icons.pets),
                title: Text(ChatStrings.scheduleWalk),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ChatAttachAction.scheduleWalk),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(ChatStrings.sendLocation),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ChatAttachAction.sendLocation),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || action == null) {
      return;
    }
    switch (action) {
      case _ChatAttachAction.photo:
        await _pickPhoto();
      case _ChatAttachAction.scheduleWalk:
        await _openSchedule(context);
      case _ChatAttachAction.sendLocation:
        await _openLocationPicker(context);
    }
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
                title: Text(ChatStrings.gallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(ChatStrings.camera),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(ChatStrings.cancel),
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
      await ref
          .read(chatInboxProvider.notifier)
          .sendPhoto(widget.conversationId, file, replyTo: reply);
      _scrollToEnd();
    } catch (error) {
      if (mounted) {
        showNetworkErrorSnackBar(
          context,
          error,
          fallback: ChatStrings.photoFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingPhoto = false);
      }
    }
  }
}

enum _ChatAttachAction { photo, scheduleWalk, sendLocation }
