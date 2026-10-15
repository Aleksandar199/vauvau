import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_message.dart';
import 'message_reactions.dart';

/// Small circular sender avatar used next to chat bubbles.
class SenderAvatar extends StatelessWidget {
  const SenderAvatar({
    super.key,
    required this.url,
    required this.name,
    this.size = 32,
  });

  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? 'Č' : name.trim()[0].toUpperCase();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.trim().isEmpty
            ? ColoredBox(
                color: AppColors.primarySoft,
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.4,
                    ),
                  ),
                ),
              )
            : buildDogImage(url, seed: url, width: size, height: size),
      ),
    );
  }
}

/// Quoted original message shown inside a bubble.
class ReplyQuote extends StatelessWidget {
  const ReplyQuote({
    super.key,
    required this.senderName,
    required this.text,
    required this.isMine,
  });

  final String senderName;
  final String text;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final bar = isMine ? Colors.white.withValues(alpha: 0.85) : AppColors.primary;
    final bg = isMine
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.primary.withValues(alpha: 0.1);
    final titleColor =
        isMine ? Colors.white : AppColors.primaryDeep;
    final bodyColor =
        isMine ? Colors.white.withValues(alpha: 0.9) : AppColors.ink;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: bar, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName.trim().isEmpty ? 'Poruka' : senderName.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text.trim().isEmpty ? '…' : text.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: bodyColor,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compose bar preview while drafting a reply.
class ReplyComposeBanner extends StatelessWidget {
  const ReplyComposeBanner({
    super.key,
    required this.senderName,
    required this.text,
    required this.onCancel,
  });

  final String senderName;
  final String text;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Odgovor za ${senderName.trim().isEmpty ? 'poruku' : senderName.trim()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    ChatMessage.clipReplyText(text, 80),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Otkaži odgovor',
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

enum MessageAction { react, reply, report }

/// What the user picked in the long-press menu. For [MessageAction.react],
/// [emoji] is the new reaction (null = remove mine).
class MessageActionChoice {
  const MessageActionChoice(this.action, {this.emoji});

  final MessageAction action;
  final String? emoji;
}

/// Long-press menu: emoji reactions on top, then reply / report.
Future<MessageActionChoice?> showMessageActionsSheet(
  BuildContext context, {
  required bool canReport,
  bool canReact = false,
  String? currentReaction,
}) {
  unawaited(HapticFeedback.selectionClick());
  return showModalBottomSheet<MessageActionChoice>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canReact)
              ReactionPickerRow(
                current: currentReaction,
                onSelected: (emoji) => Navigator.pop(
                  sheetContext,
                  MessageActionChoice(MessageAction.react, emoji: emoji),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Odgovori na poruku'),
              onTap: () => Navigator.pop(
                sheetContext,
                const MessageActionChoice(MessageAction.reply),
              ),
            ),
            if (canReport)
              ListTile(
                leading: Icon(Icons.flag_outlined, color: Colors.red.shade400),
                title: const Text('Prijavi poruku'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  const MessageActionChoice(MessageAction.report),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Otkaži'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      );
    },
  );
}
