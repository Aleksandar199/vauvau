import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_time.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.now,
  });

  final ChatMessage message;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final background = isMine
        ? AppColors.primary
        : Theme.of(context).colorScheme.surface;
    final foreground = isMine
        ? AppColors.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 6),
              bottomRight: Radius.circular(isMine ? 6 : 18),
            ),
            boxShadow: AppColors.cardShadow,
            border: isMine
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(
                          alpha: 0.4,
                        ),
                  ),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: foreground,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                formatChatTimestamp(message.sentAt, now),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
