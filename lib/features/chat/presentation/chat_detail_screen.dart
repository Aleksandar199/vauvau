import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/walk_locations.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import 'chat_inbox.dart';
import 'chat_strings.dart';
import 'schedule_walk_sheet.dart';
import 'widgets/dog_avatar.dart';
import 'widgets/location_pin_bubble.dart';
import 'widgets/message_bubble.dart';
import 'widgets/walk_invite_card.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatInboxProvider.notifier).markRead(widget.conversationId);
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    ref.read(chatInboxProvider.notifier).sendMessage(
          widget.conversationId,
          _input.text,
        );
    _input.clear();
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatInboxProvider, (previous, next) => _scrollToEnd());

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
        body: const Center(child: Text(ChatStrings.missingChat)),
      );
    }

    final open = found;
    final now = ref.watch(chatNowProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
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
                    ChatStrings.online,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.success,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: ChatStrings.scheduleWalk,
            onPressed: () => _openSchedule(context),
            icon: const Icon(Icons.pets),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: open.messages.length,
              itemBuilder: (context, index) {
                final message = open.messages[index];
                if (message.isWalkInvite) {
                  return WalkInviteCard(
                    message: message,
                    now: now,
                    onAccept: () => _respond(
                      message.id,
                      WalkInviteStatus.accepted,
                    ),
                    onDecline: () => _respond(
                      message.id,
                      WalkInviteStatus.declined,
                    ),
                  );
                }
                if (message.isLocationPin) {
                  return LocationPinBubble(message: message, now: now);
                }
                return MessageBubble(message: message, now: now);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: ChatStrings.attach,
                    onPressed: () => _openAttachMenu(context),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: ChatStrings.composeHint,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: ChatStrings.send,
                    onPressed: _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _respond(String messageId, WalkInviteStatus status) {
    ref.read(chatInboxProvider.notifier).respondToWalkInvite(
          conversationId: widget.conversationId,
          messageId: messageId,
          status: status,
        );
  }

  Future<void> _openSchedule(BuildContext context) {
    return showScheduleWalkSheet(
      context: context,
      onSend: (walkTime, location) {
        ref.read(chatInboxProvider.notifier).sendWalkInvite(
              conversationId: widget.conversationId,
              walkTime: walkTime,
              walkLocationName: location,
            );
      },
    );
  }

  Future<void> _openAttachMenu(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pets),
                title: const Text(ChatStrings.scheduleWalk),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openSchedule(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text(ChatStrings.sendLocation),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref.read(chatInboxProvider.notifier).sendLocationPin(
                        conversationId: widget.conversationId,
                        locationName: scheduledWalkLocations.first,
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
