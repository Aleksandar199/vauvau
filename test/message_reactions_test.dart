import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/utils/message_reactions.dart';
import 'package:vauvau/features/chat/data/firestore_chat_repository.dart';
import 'package:vauvau/features/chat/domain/chat_conversation.dart';
import 'package:vauvau/features/chat/domain/chat_message.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/chat/presentation/chat_screen.dart';
import 'package:vauvau/features/chat/presentation/widgets/message_bubble.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/groups/data/firestore_groups_repository.dart';
import 'package:vauvau/features/profile/data/owner_public_profile.dart';
import 'package:vauvau/features/profile/presentation/owner_profile_sheet.dart';

final _now = DateTime(2026, 10, 15, 12);

ChatConversation _chat(List<ChatMessage> messages) {
  return ChatConversation(
    id: 'lola',
    dogId: 'lola',
    dogName: 'Lola',
    ownerName: 'Jelena',
    breed: 'Labrador',
    location: 'Novi Sad',
    photoUrl: '',
    peerUserId: 'jelena',
    messages: messages,
    lastActivityAt: _now,
    isNewMatch: false,
  );
}

Future<void> _pumpChat(WidgetTester tester, List<ChatMessage> messages) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatSeedProvider.overrideWith((ref) => [_chat(messages)]),
        chatNowProvider.overrideWith((ref) => _now),
      ],
      child: const MaterialApp(home: ChatScreen(conversationId: 'lola')),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Finder _badgeText(String text) => find.descendant(
  of: find.byKey(const ValueKey('message-reactions')),
  matching: find.text(text),
);

void main() {
  group('MessageReactions', () {
    test('a bare uid is a heart, uid:emoji any other reaction', () {
      const likes = ['ana', 'bob:😂', 'cira:😂'];
      expect(MessageReactions.reactionOf(likes, 'ana'), '❤️');
      expect(MessageReactions.reactionOf(likes, 'bob'), '😂');
      expect(MessageReactions.reactionOf(likes, 'me'), isNull);
      expect(MessageReactions.summary(likes), [
        (emoji: '😂', count: 2),
        (emoji: '❤️', count: 1),
      ]);
    });

    test('one reaction per user: a new emoji replaces the old one', () {
      var likes = <String>['ana'];
      likes = MessageReactions.apply(likes, 'me', '👍');
      expect(likes, ['ana', 'me:👍']);
      likes = MessageReactions.apply(likes, 'me', '❤️');
      expect(likes, ['ana', 'me']);
      likes = MessageReactions.apply(likes, 'me', null);
      expect(likes, ['ana']);
      expect(
        () => MessageReactions.apply(likes, 'me', '💩'),
        throwsArgumentError,
      );
    });
  });

  group('repositories', () {
    test('chat: swapping my reaction keeps the peer one', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = FirestoreChatRepository(
        firestore: firestore,
        currentUserId: 'me',
      );
      addTearDown(repo.dispose);
      final roomId = repo.openFromMatch(
        profile: const DiscoverProfile(
          id: 'lola',
          ownerId: 'jelena',
          name: 'Lola',
          ownerName: 'Jelena',
          breed: 'Labrador',
          ageYears: 2,
          gender: 'ženski',
          size: 'srednji',
          location: 'Novi Sad',
          bio: '',
          photoUrls: [],
        ),
        myUserId: 'me',
        myDogId: 'rex',
      );
      final message = firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc('m1');
      await message.set({
        'senderId': 'jelena',
        'text': 'Ćao',
        'timestamp': _now,
        'likes': ['jelena:😂'],
      });
      repo.attachRoom(roomId);
      await Future<void>.delayed(Duration.zero);

      await repo.setMessageReaction(
        conversationId: roomId,
        messageId: 'm1',
        emoji: '👍',
      );
      await repo.setMessageReaction(
        conversationId: roomId,
        messageId: 'm1',
        emoji: '😮',
      );
      expect((await message.get())['likes'], ['jelena:😂', 'me:😮']);

      await repo.setMessageReaction(conversationId: roomId, messageId: 'm1');
      expect((await message.get())['likes'], ['jelena:😂']);
    });

    test('group: reaction is stored in likes', () async {
      final firestore = FakeFirebaseFirestore();
      final message = firestore
          .collection('breed_groups')
          .doc('g1')
          .collection('messages')
          .doc('m1');
      await message.set({'senderId': 'other', 'text': 'Zdravo'});
      final repo = FirestoreGroupsRepository(
        firestore: firestore,
        currentUserId: 'me',
        senderName: 'Ja',
        senderAvatarUrl: '',
      );

      await repo.setMessageReaction(
        groupId: 'g1',
        messageId: 'm1',
        emoji: '🙏',
      );
      expect((await message.get())['likes'], ['me:🙏']);
    });
  });

  group('chat UI', () {
    testWidgets('long press shows emoji; the pick appears under the bubble', (
      tester,
    ) async {
      await _pumpChat(tester, [
        ChatMessage(
          id: 'm1',
          text: 'Vidimo se u parku',
          sentAt: _now,
          isMine: false,
          senderId: 'jelena',
        ),
      ]);
      // No heart button on messages any more.
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.byKey(const ValueKey('message-reactions')), findsNothing);

      await tester.longPress(find.text('Vidimo se u parku'));
      await tester.pumpAndSettle();
      for (final emoji in messageReactionEmojis) {
        expect(find.byKey(ValueKey('reaction-$emoji')), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('reaction-😂')));
      await tester.pumpAndSettle();
      expect(_badgeText('😂'), findsOneWidget);

      // Picking the same emoji again removes it.
      await tester.longPress(find.text('Vidimo se u parku'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reaction-😂')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('message-reactions')), findsNothing);
    });

    testWidgets('peer reaction on my orange bubble shows on a light badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
                id: 'mine',
                text: 'Zdravo',
                sentAt: _now,
                isMine: true,
                likes: const ['jelena', 'ana:😂'],
              ),
              now: _now,
              currentUserId: 'me',
            ),
          ),
        ),
      );
      expect(_badgeText('❤️'), findsOneWidget);
      expect(_badgeText('😂'), findsOneWidget);
      expect(_badgeText('2'), findsOneWidget);
      final badge = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('message-reactions')),
          matching: find.byType(Container),
        ),
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(
        decoration.color,
        Theme.of(tester.element(find.byType(Scaffold))).colorScheme.surface,
      );
    });
  });

  group('owner profile', () {
    test('loads the public profile and the owner dogs', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('jelena').set({
        'name': 'Jelena',
        'customPhotoUrl': 'https://example.com/jelena.jpg',
        'cityName': 'Novi Sad',
        'neighborhoodName': 'Liman',
        'bio': 'Volim duge šetnje.',
      });
      await firestore.collection('dogs').doc('lola').set({
        'ownerId': 'jelena',
        'ownerName': 'Jelena',
        'name': 'Lola',
        'breed': 'Labrador',
      });
      await firestore.collection('dogs').doc('rex').set({
        'ownerId': 'marko',
        'name': 'Rex',
      });

      final profile = await loadOwnerPublicProfile(
        'jelena',
        firestore: firestore,
      );

      expect(profile, isNotNull);
      expect(profile!.name, 'Jelena');
      expect(profile.photoUrl, 'https://example.com/jelena.jpg');
      expect(profile.location, contains('Novi Sad'));
      expect(profile.bio, 'Volim duge šetnje.');
      expect(profile.dogs.map((dog) => dog.name), ['Lola']);
    });

    testWidgets('sheet shows the loaded person, not only the fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OwnerProfileSheet(
              userId: 'jelena',
              fallbackName: 'J.',
              loader: (_) async => const OwnerPublicProfile(
                userId: 'jelena',
                name: 'Jelena Petrović',
                photoUrl: '',
                location: 'Novi Sad, Liman',
                bio: 'Volim duge šetnje.',
                dogs: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jelena Petrović'), findsOneWidget);
      expect(find.text('Novi Sad, Liman'), findsOneWidget);
      expect(find.text('Volim duge šetnje.'), findsOneWidget);
    });
  });
}
