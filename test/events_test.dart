import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/events/data/local_events_repository.dart';
import 'package:vauvau/features/events/data/seed_events.dart';
import 'package:vauvau/features/events/presentation/events_controller.dart';
import 'package:vauvau/features/events/presentation/events_screen.dart';
import 'package:vauvau/features/events/presentation/events_strings.dart';
import 'package:vauvau/features/groups/presentation/group_chat_screen.dart';

void main() {
  test('formats event time in 24-hour HH:mm', () {
    expect(EventsStrings.when(DateTime(2026, 10, 3, 17)), 'Subota 17:00');
    expect(EventsStrings.when(DateTime(2026, 10, 3, 9, 5)), 'Subota 09:05');
  });

  testWidgets('shows seeded events and joins walk chat', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final repo = LocalEventsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const MaterialApp(home: EventsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(EventsStrings.title), findsOneWidget);
    expect(find.text(EventsStrings.banner), findsOneWidget);
    expect(find.text(EventsStrings.organize), findsWidgets);
    expect(find.text(SeedEvents.all.first.title), findsOneWidget);
    expect(find.text(EventsStrings.join), findsWidgets);

    await tester.tap(find.text(EventsStrings.join).first);
    await tester.pump();
    await tester.pump();

    expect(find.byType(GroupChatScreen), findsOneWidget);
    expect(find.text('Ti se pridružio/la šetnji! 🐾'), findsWidgets);
  });
}
