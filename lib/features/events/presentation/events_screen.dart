import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/presentation/group_chat_screen.dart';
import '../domain/event_model.dart';
import 'create_event_screen.dart';
import 'events_controller.dart';
import 'events_strings.dart';
import 'widgets/event_card.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsControllerProvider);
    final memberId = ref.watch(eventsMemberIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(EventsStrings.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateEventSheet(context),
        icon: const Icon(Icons.event_available),
        label: const Text(EventsStrings.organize),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Text(
            EventsStrings.banner,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => showCreateEventSheet(context),
            icon: const Icon(Icons.event_available),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            label: const Text(EventsStrings.organize),
          ),
          const SizedBox(height: 16),
          for (final event in events) ...[
            EventCard(
              event: event,
              joined: event.isJoined(memberId),
              onJoin: () => _join(context, ref, event),
              onOpenChat: () => _openChat(context, event.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _join(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
  ) async {
    await ref.read(eventsControllerProvider.notifier).join(event.id);
    if (!context.mounted) {
      return;
    }
    await _openChat(context, event.id);
  }

  Future<void> _openChat(BuildContext context, String eventId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupChatScreen(eventId: eventId),
      ),
    );
  }
}
