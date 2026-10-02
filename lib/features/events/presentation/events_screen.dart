import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/presentation/group_chat_screen.dart';
import '../domain/event_model.dart';
import 'create_event_screen.dart';
import 'events_controller.dart';
import 'events_strings.dart';
import 'widgets/event_card.dart';

enum _EventsFilter { all, upcoming, joined }

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  _EventsFilter _filter = _EventsFilter.all;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsControllerProvider);
    final memberId = ref.watch(eventsMemberIdProvider);
    final now = DateTime.now();
    final visible = events.where((event) {
      return switch (_filter) {
        _EventsFilter.all => true,
        _EventsFilter.upcoming => event.dateTime.isAfter(now),
        _EventsFilter.joined => event.isJoined(memberId),
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(EventsStrings.title),
        actions: [
          IconButton(
            tooltip: EventsStrings.organize,
            onPressed: () => showCreateEventSheet(context),
            icon: const Icon(Icons.event_available),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Text(
            EventsStrings.banner,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: EventsStrings.filterAll,
                  selected: _filter == _EventsFilter.all,
                  onTap: () => setState(() => _filter = _EventsFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: EventsStrings.filterUpcoming,
                  selected: _filter == _EventsFilter.upcoming,
                  onTap: () => setState(() => _filter = _EventsFilter.upcoming),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: EventsStrings.filterJoined,
                  selected: _filter == _EventsFilter.joined,
                  onTap: () => setState(() => _filter = _EventsFilter.joined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => showCreateEventSheet(context),
            icon: const Icon(Icons.event_available),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            label: const Text(EventsStrings.organize),
          ),
          const SizedBox(height: 16),
          for (final event in visible) ...[
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? primary.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade400,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? primary : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
