import 'package:flutter/material.dart';

import '../../../../core/images/dog_image.dart';
import '../../../../core/theme/app_cards.dart';
import '../../domain/event_model.dart';
import '../events_strings.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.joined,
    required this.onJoin,
    required this.onOpenChat,
  });

  final EventModel event;
  final bool joined;
  final VoidCallback onJoin;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: AppCardTokens.borderRadius,
        boxShadow: AppCardTokens.softShadow(0.08),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: AppCardTokens.imageBorderRadius,
                  child: SizedBox(
                    height: 148,
                    width: double.infinity,
                    child: buildDogImage(event.imageUrl, seed: event.id),
                  ),
                ),
                const Positioned(
                  top: 8,
                  left: 8,
                  child: StatusBadge(
                    label: EventsStrings.badge,
                    tone: StatusBadgeTone.success,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitleText(text: event.title),
                const SizedBox(height: 6),
                CardLocationRow(label: event.locationName),
                const SizedBox(height: 4),
                CardTimeLabel(
                  label:
                      '${EventsStrings.when(event.dateTime)} · ${EventsStrings.timeAgo(event.createdAt)}',
                ),
                const SizedBox(height: 4),
                Text(
                  EventsStrings.interested(event.participantCount),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: AppCardTokens.actionHeight,
                  width: double.infinity,
                  child: joined
                      ? OutlinedButton.icon(
                          onPressed: onOpenChat,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppCardTokens.actionRadius,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text(EventsStrings.openChat),
                        )
                      : FilledButton.icon(
                          onPressed: onJoin,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppCardTokens.actionRadius,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: const Icon(Icons.group_add),
                          label: const Text(EventsStrings.join),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
