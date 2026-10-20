import 'package:flutter/material.dart';

import '../../../../core/theme/app_cards.dart';
import '../../../../core/constants/serbia_locations.dart';
import '../../data/seed_events.dart';
import '../../domain/event_model.dart';
import '../events_strings.dart';
import 'event_photo.dart';

String _locationLabel(EventModel event) {
  final cityId = EventVenues.cityIdForEvent(event);
  final city = cityId == null ? null : SerbiaLocations.cityById(cityId)?.name;
  if (city == null ||
      event.locationName.toLowerCase().contains(city.toLowerCase())) {
    return event.locationName;
  }
  return '${event.locationName}, $city';
}

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
                EventPhoto(event: event),
                Positioned(
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
                SizedBox(height: 6),
                CardLocationRow(label: _locationLabel(event)),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        EventsStrings.when(event.dateTime),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
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
                          label: Text(EventsStrings.openChat),
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
                          label: Text(EventsStrings.join),
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
