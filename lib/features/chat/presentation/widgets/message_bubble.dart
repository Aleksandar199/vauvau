import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../discover/presentation/widgets/dog_photo_gallery.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_time.dart';
import 'chat_ui.dart';
import 'message_reactions.dart';
import 'message_reply.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.now,
    this.fallbackAvatarUrl = '',
    this.fallbackSenderName = '',
    this.currentUserId = '',
    this.onLongPress,
    this.onAvatarTap,
  });

  final ChatMessage message;
  final DateTime now;
  final String fallbackAvatarUrl;
  final String fallbackSenderName;
  final String currentUserId;

  /// Opens the reactions / reply menu (also from a tap on the reactions).
  final VoidCallback? onLongPress;

  /// Opens the sender's profile; only the peer's avatar is tappable.
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final background = isMine ? AppColors.primary : Colors.grey.shade200;
    final foreground = isMine ? AppColors.onPrimary : AppColors.ink;
    final avatarUrl = message.senderAvatarUrl.trim().isNotEmpty
        ? message.senderAvatarUrl
        : fallbackAvatarUrl;
    final senderName = message.senderName.trim().isNotEmpty
        ? message.senderName
        : fallbackSenderName;
    final caption = message.text.trim();

    return Padding(
      padding: ChatUiTokens.bubbleOuterPadding,
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            GestureDetector(
              key: const ValueKey('message-sender-avatar'),
              behavior: HitTestBehavior.opaque,
              onTap: onAvatarTap,
              child: SenderAvatar(url: avatarUrl, name: senderName),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: BubbleWithReactions(
                likes: message.likes,
                currentUserId: currentUserId,
                isMine: isMine,
                onReactionsTap: onLongPress,
                bubble: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: onLongPress,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: ChatUiTokens.bubbleRadius(isMine: isMine),
                      ),
                      child: Column(
                        crossAxisAlignment: isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (message.hasReply)
                            ReplyQuote(
                              senderName: message.replyToSenderName,
                              text: message.replyToText,
                              isMine: isMine,
                            ),
                          if (message.hasImage) ...[
                            const SizedBox(height: 2),
                            GestureDetector(
                              key: const ValueKey('message-image'),
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
                          if (caption.isNotEmpty) ...[
                            if (message.hasImage) const SizedBox(height: 4),
                            Text(
                              caption,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
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
          if (isMine) ...[
            const SizedBox(width: 8),
            SenderAvatar(url: avatarUrl, name: senderName),
          ],
        ],
      ),
    );
  }
}
