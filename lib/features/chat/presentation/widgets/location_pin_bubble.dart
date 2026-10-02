import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_time.dart';
import '../chat_strings.dart';
import 'chat_ui.dart';

class LocationPinBubble extends StatelessWidget {
  const LocationPinBubble({
    super.key,
    required this.message,
    required this.now,
  });

  final ChatMessage message;
  final DateTime now;

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
    );
  }
}
