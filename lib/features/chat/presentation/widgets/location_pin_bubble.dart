import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_time.dart';
import '../chat_strings.dart';
import 'chat_ui.dart';
import 'message_bubble.dart';

class LocationPinBubble extends StatelessWidget {
  const LocationPinBubble({
    super.key,
    required this.message,
    required this.now,
    this.currentUserId = '',
    this.onToggleLike,
  });

  final ChatMessage message;
  final DateTime now;
  final String currentUserId;
  final VoidCallback? onToggleLike;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final background =
        isMine ? AppColors.primary : Colors.grey.shade200;
    final foreground =
        isMine ? AppColors.onPrimary : AppColors.ink;
    final locationName = (message.walkLocationName != null &&
            message.walkLocationName!.trim().isNotEmpty)
        ? message.walkLocationName!.trim()
        : message.text;
    final showLike = ChatLikeIndicator.isShown(message);

    return Padding(
      padding: ChatUiTokens.bubbleOuterPadding,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: ChatUiTokens.bubbleRadius(isMine: isMine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ChatStrings.locationPinTitle,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: foreground, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locationName,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatChatTimestamp(message.sentAt, now),
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.65),
                        fontSize: 10,
                      ),
                    ),
                    if (showLike) ...[
                      const SizedBox(width: 8),
                      ChatLikeIndicator(
                        message: message,
                        currentUserId: currentUserId,
                        foreground: foreground,
                        onToggleLike: onToggleLike,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
