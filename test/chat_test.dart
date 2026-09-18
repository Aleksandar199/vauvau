import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/chat/domain/chat_conversation.dart';
import 'package:vauvau/features/chat/domain/chat_message.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/chat/presentation/chat_screen.dart';
import 'package:vauvau/features/chat/presentation/chat_strings.dart';
import 'package:vauvau/features/chat/presentation/matches_screen.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/home/presentation/home_tab.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

final _now = DateTime(2026, 9, 18, 18, 4);

ChatConversation _chat({
  required String id,
  required String name,
  required String owner,
  List<ChatMessage> messages = const [],
  bool isNewMatch = false,
  int unreadCount = 0,
}) {
  return ChatConversation(
    id: id,
    dogId: id,
    dogName: name,
    ownerName: owner,
    breed: 'Labrador',
    location: 'Novi Sad - Liman',
    photoUrl: 'https://example.com/dog.jpg',
    messages: messages,
    lastActivityAt: _now,
    isNewMatch: isNewMatch,
    unreadCount: unreadCount,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  required List<ChatConversation> seed,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverImageFactoryProvider.overrideWith((ref) {
          return (_) => MemoryImage(_transparentPng);
        }),
        chatSeedProvider.overrideWith((ref) => seed),
        chatNowProvider.overrideWith((ref) => _now),
      ],
      child: child,
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('matches list shows new matches and conversations', (tester) async {
    await _pump(
      tester,
      seed: [
        _chat(id: 'kiki', name: 'Kiki', owner: 'Stefan', isNewMatch: true),
        _chat(
          id: 'lola',
          name: 'Lola',
          owner: 'Jelena',
          unreadCount: 1,
          messages: [
            ChatMessage(
              id: 'm1',
              text: 'Vidimo se u Limanskom parku u 18h!',
              sentAt: _now,
              isMine: false,
            ),
          ],
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: MatchesScreen())),
    );

    expect(find.text(ChatStrings.newMatches), findsOneWidget);
    expect(find.text('Kiki'), findsOneWidget);
    expect(find.text(ChatStrings.conversations), findsOneWidget);
    expect(find.text('Lola'), findsOneWidget);
    expect(find.textContaining('Jelena'), findsOneWidget);
    expect(find.textContaining('Vidimo se u Limanskom parku u 18h!'), findsOneWidget);
    expect(find.text('18:04'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('empty matches state is in Serbian', (tester) async {
    await _pump(
      tester,
      seed: const [],
      child: const MaterialApp(home: Scaffold(body: MatchesScreen())),
    );

    expect(find.text(ChatStrings.emptyTitle), findsOneWidget);
    expect(find.text(ChatStrings.emptySubtitle), findsOneWidget);
    expect(find.text(ChatStrings.findFriends), findsOneWidget);
  });

  testWidgets('sending a message appends it to the thread', (tester) async {
    await _pump(
      tester,
      seed: [
        _chat(
          id: 'lola',
          name: 'Lola',
          owner: 'Jelena',
          messages: [
            ChatMessage(
              id: 'm1',
              text: 'Ćao!',
              sentAt: _now,
              isMine: false,
            ),
          ],
        ),
      ],
      child: const MaterialApp(
        home: ChatScreen(conversationId: 'lola'),
      ),
    );

    expect(find.text('Ćao!'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Vidimo se u parku!');
    await tester.tap(find.byTooltip(ChatStrings.send));
    await tester.pump();

    expect(find.text('Vidimo se u parku!'), findsOneWidget);
  });

  testWidgets('find friends switches to the discover tab', (tester) async {
    await _pump(
      tester,
      seed: const [],
      child: const MaterialApp(home: Scaffold(body: MatchesScreen())),
    );

    await tester.tap(find.text(ChatStrings.findFriends));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MatchesScreen)),
    );
    expect(container.read(homeTabIndexProvider), 0);
  });

  testWidgets('search filters conversations by dog name', (tester) async {
    await _pump(
      tester,
      seed: [
        _chat(id: 'lola', name: 'Lola', owner: 'Jelena'),
        _chat(id: 'rex', name: 'Rex', owner: 'Marko'),
      ],
      child: const MaterialApp(home: Scaffold(body: MatchesScreen())),
    );

    await tester.enterText(find.byType(TextField), 'Rex');
    await tester.pump();

    expect(find.text('Rex'), findsWidgets);
    expect(find.text('Lola'), findsNothing);
  });

  testWidgets('walk invite can be sent and accepted', (tester) async {
    await _pump(
      tester,
      seed: [
        _chat(
          id: 'lola',
          name: 'Lola',
          owner: 'Jelena',
          messages: [
            ChatMessage(
              id: 'invite-1',
              text: 'Poziv na šetnju: Dunavski Park',
              sentAt: _now,
              isMine: false,
              type: ChatMessageType.walkInvite,
              status: WalkInviteStatus.pending,
              walkTime: _now,
              walkLocationName: 'Dunavski Park',
            ),
          ],
        ),
      ],
      child: const MaterialApp(
        home: ChatScreen(conversationId: 'lola'),
      ),
    );

    expect(find.text(ChatStrings.accept), findsOneWidget);
    await tester.tap(find.text(ChatStrings.accept));
    await tester.pump();

    expect(find.text(ChatStrings.walkAccepted), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChatScreen)),
    );
    expect(container.read(scheduledWalksProvider), isNotEmpty);
  });
}
