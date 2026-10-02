import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_time.dart';
import 'chat_ui.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.now,
    this.onReport,
    this.onTap,
  });

  final ChatMessage message;
  final DateTime now;
  final VoidCallback? onReport;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final background =
        isMine ? AppColors.primary : Colors.grey.shade200;
    final foreground = isMine ? AppColors.onPrimary : AppColors.ink;

    return Padding(
      padding: ChatUiTokens.bubbleOuterPadding,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: message.isMine ? null : onTap,
          onLongPress: message.isMine ? null : onReport,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: ChatUiTokens.bubbleRadius(isMine: isMine),
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatChatTimestamp(message.sentAt, now),
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
      ),
    );
  }
}
