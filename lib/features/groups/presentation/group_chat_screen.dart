import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/images/dog_image.dart';
import '../../../core/network/network_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/domain/chat_time.dart';
import '../../chat/presentation/widgets/chat_ui.dart';
import '../../events/presentation/events_controller.dart';
import '../domain/groups_models.dart';
import 'groups_controller.dart';
import 'groups_strings.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({
    super.key,
    this.groupId,
    this.eventId,
  }) : assert(groupId != null || eventId != null);

  final String? groupId;
  final String? eventId;

  bool get isEvent => eventId != null;

  String get threadId => eventId ?? groupId!;

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  var _sendingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
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
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _markRead() {
    if (widget.isEvent) {
      ref.read(eventsControllerProvider.notifier).markRead(widget.threadId);
    } else {
      ref.read(groupsControllerProvider.notifier).markRead(widget.threadId);
    }
  }

  Future<void> _sendText() async {
    final text = _input.text;
    if (text.trim().isEmpty) {
      return;
    }
    _input.clear();
    if (widget.isEvent) {
      await ref.read(eventsControllerProvider.notifier).sendText(
            widget.threadId,
            text,
          );
    } else {
      await ref.read(groupsControllerProvider.notifier).sendText(
            widget.threadId,
            text,
          );
    }
    _scrollToEnd();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text(GroupsStrings.gallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text(GroupsStrings.camera),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text(GroupsStrings.cancel),
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
    final file = await ImagePicker().pickImage(source: source, imageQuality: 72);
    if (file == null || !mounted) {
      return;
    }
    setState(() => _sendingPhoto = true);
    try {
      if (widget.isEvent) {
        await ref.read(eventsControllerProvider.notifier).sendPhoto(
              widget.threadId,
              file,
            );
      } else {
        await ref.read(groupsControllerProvider.notifier).sendPhoto(
              widget.threadId,
              file,
            );
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

  @override
  Widget build(BuildContext context) {
    ref.listen(groupMessagesProvider(widget.groupId ?? '__none__'), (_, _) {
      if (!widget.isEvent) {
        _markRead();
      }
    });
    ref.listen(eventMessagesProvider(widget.eventId ?? '__none__'), (_, _) {
      if (widget.isEvent) {
        _markRead();
      }
    });
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
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 36,
                height: 36,
                child: buildDogImage(imageUrl, seed: widget.threadId),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                ? const Center(child: Text(GroupsStrings.emptyChat))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _GroupMessageBubble(
                        message: messages[index],
                        now: now,
                      );
                    },
                  ),
          ),
          if (_sendingPhoto) const LinearProgressIndicator(minHeight: 2),
          ChatInputBar(
            controller: _input,
            onSend: _sendText,
            onAttach: _pickPhoto,
            attachIcon: Icons.photo_camera_outlined,
            attachTooltip: GroupsStrings.addPhoto,
            hintText: GroupsStrings.composeHint,
            sendTooltip: GroupsStrings.send,
            enabled: !_sendingPhoto,
          ),
        ],
      ),
    );
  }
}

class _GroupMessageBubble extends StatelessWidget {
  const _GroupMessageBubble({
    required this.message,
    required this.now,
  });

  final GroupMessage message;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final background = mine ? AppColors.primary : Colors.grey.shade200;
    final foreground = mine ? AppColors.onPrimary : AppColors.ink;
    return Padding(
      padding: ChatUiTokens.bubbleOuterPadding,
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            _SenderAvatar(
              url: message.senderAvatarUrl,
              name: message.senderName,
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
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
                  crossAxisAlignment:
                      mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                    if (message.hasImage) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
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
                    Text(
                      formatChatTimestamp(message.createdAt, now),
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.65),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (mine) ...[
            const SizedBox(width: 8),
            _SenderAvatar(
              url: message.senderAvatarUrl,
              name: message.senderName,
            ),
          ],
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? 'Č' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primarySoft,
      backgroundImage: url.trim().isEmpty ? null : NetworkImage(url),
      child: url.trim().isEmpty
          ? Text(
              letter,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}
