import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/chat/data/firestore_chat_repository.dart';
import 'package:vauvau/features/chat/data/local_chat_repository.dart';
import 'package:vauvau/features/chat/domain/chat_conversation.dart';
import 'package:vauvau/features/chat/domain/chat_message.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/chat/presentation/chat_screen.dart';

/// Lets a test deliver inbox snapshots the way Firestore would.
class _LiveInboxRepository extends LocalChatRepository {
  _LiveInboxRepository({required super.seed}) : super(currentUserId: 'me');

  final _controller = StreamController<List<ChatConversation>>.broadcast();
  List<ChatConversation>? _snapshot;
  int markReadCalls = 0;

  @override
  List<ChatConversation> get currentInbox => _snapshot ?? super.currentInbox;

  @override
  Stream<List<ChatConversation>> watchInbox() async* {
    yield currentInbox;
    yield* _controller.stream;
  }

  void deliver(List<ChatConversation> next) {
    _snapshot = next;
    _controller.add(next);
  }

  @override
  void markRead(String conversationId) {
    markReadCalls++;
    deliver([
      for (final chat in currentInbox)
        if (chat.id == conversationId) chat.copyWith(unreadCount: 0) else chat,
    ]);
  }
}

ChatConversation _room({required int unread, required List<ChatMessage> messages}) {
  return ChatConversation(
    id: 'lola',
    dogId: 'lola',
    dogName: 'Lola',
    ownerName: 'Jelena',
    breed: 'Labrador',
    location: 'Novi Sad',
    photoUrl: '',
    peerUserId: 'peer',
    messages: messages,
    lastActivityAt: DateTime.now(),
    isNewMatch: false,
    unreadCount: unread,
  );
}

ChatMessage _message(String id, {required bool mine}) => ChatMessage(
      id: id,
      text: 'Poruka $id',
      sentAt: DateTime.now(),
      isMine: mine,
      senderId: mine ? 'me' : 'peer',
    );

void main() {
  group('FirestoreChatRepository unread', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreChatRepository repo;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      await firestore.collection('chats').doc('room').set({
        'participantIds': ['me', 'peer'],
        'unreadByUser': {'me': 4, 'peer': 2},
      });
      repo = FirestoreChatRepository(firestore: firestore, currentUserId: 'me');
      addTearDown(repo.dispose);
    });

    Future<Map<String, dynamic>> unreadByUser() async {
      final doc = await firestore.collection('chats').doc('room').get();
      return Map<String, dynamic>.from(doc.data()!['unreadByUser'] as Map);
    }

    test('sending a reply clears my unread count and keeps the peer one',
        () async {
      await repo.sendMessage('room', 'Evo me');

      final unread = await unreadByUser();
      expect(unread['me'], 0);
      expect(unread['peer'], 2);
    });

    test('markRead clears only my unread count', () async {
      repo.markRead('room');
      await Future<void>.delayed(Duration.zero);

      final unread = await unreadByUser();
      expect(unread['me'], 0);
      expect(unread['peer'], 2);
    });
  });

  testWidgets('messages arriving while the chat is open are marked read',
      (tester) async {
    final repo = _LiveInboxRepository(
      seed: [_room(unread: 0, messages: [_message('m1', mine: true)])],
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ChatScreen(conversationId: 'lola')),
      ),
    );
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final callsAfterOpen = repo.markReadCalls;
    expect(callsAfterOpen, greaterThan(0));

    repo.deliver([
      _room(
        unread: 3,
        messages: [
          _message('m1', mine: true),
          _message('p1', mine: false),
          _message('p2', mine: false),
          _message('p3', mine: false),
        ],
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(repo.markReadCalls, greaterThan(callsAfterOpen));
    expect(repo.currentInbox.single.unreadCount, 0);
  });
}
