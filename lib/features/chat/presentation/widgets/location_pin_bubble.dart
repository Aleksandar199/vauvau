import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_time.dart';
import '../chat_strings.dart';

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
    final theme = Theme.of(context);
    final background =
        isMine ? AppColors.primary : theme.colorScheme.surface;
    final foreground =
        isMine ? AppColors.onPrimary : theme.colorScheme.onSurface;
    final locationName = (message.walkLocationName != null &&
            message.walkLocationName!.trim().isNotEmpty)
        ? message.walkLocationName!.trim()
        : message.text;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
            border: isMine
                ? null
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ChatStrings.locationPinTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.85),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formatChatTimestamp(message.sentAt, now),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
