import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_time.dart';
import '../chat_strings.dart';

class WalkInviteCard extends StatelessWidget {
  const WalkInviteCard({
    super.key,
    required this.message,
    required this.now,
    this.onAccept,
    this.onDecline,
  });

  final ChatMessage message;
  final DateTime now;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final pending = message.status == WalkInviteStatus.pending;
    final canRespond = pending && !message.isMine && onAccept != null;
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(ChatStrings.walkInviteTitle),
                const SizedBox(height: 6),
                Text(
                  message.walkLocationName ?? message.text,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (message.walkTime != null)
                  Text(
                    formatWalkStamp(message.walkTime!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8),
                Text(
                  _statusLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: message.status == WalkInviteStatus.accepted
                            ? AppColors.success
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                if (canRespond) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onAccept,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            backgroundColor: AppColors.success,
                          ),
                          child: const Text(ChatStrings.accept),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text(ChatStrings.decline),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatChatTimestamp(message.sentAt, now),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _statusLabel {
    return switch (message.status) {
      WalkInviteStatus.accepted => ChatStrings.walkAccepted,
      WalkInviteStatus.declined => ChatStrings.walkDeclined,
      WalkInviteStatus.pending =>
        message.isMine ? ChatStrings.walkPending : ChatStrings.walkInviteTitle,
      null => ChatStrings.walkPending,
    };
  }
}
