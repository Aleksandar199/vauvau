import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/firebase/firestore_auth_guard.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/chat/data/local_chat_repository.dart';
import 'package:vauvau/features/chat/domain/chat_conversation.dart';
import 'package:vauvau/features/chat/domain/chat_message.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/chat/presentation/chat_screen.dart';
import 'package:vauvau/features/chat/presentation/chat_strings.dart';
import 'package:vauvau/features/groups/domain/groups_models.dart';
import 'package:vauvau/features/notifications/domain/app_notification.dart';

final _now = DateTime(2026, 10, 22, 12);

ChatMessage _msg(String id, {required bool mine, required DateTime at}) {
  return ChatMessage(id: id, text: 'Poruka $id', sentAt: at, isMine: mine);
}

ChatConversation _chat({
  required List<ChatMessage> messages,
  int? peerUnread,
  DateTime? lastActivityAt,
}) {
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
    lastActivityAt: lastActivityAt ?? _now,
    peerUnreadCount: peerUnread,
  );
}

BreedGroup _group({DateTime? lastMessageAt}) {
  return BreedGroup(
    id: 'g',
    title: 'Labradori',
    description: '',
    imageUrl: '',
    memberIds: const ['me'],
    memberCount: 1,
    lastMessageAt: lastMessageAt,
  );
}

GroupMessage _groupMessage(DateTime at) {
  return GroupMessage(
    id: 'gm',
    senderId: 'ana',
    senderName: 'Ana',
    senderAvatarUrl: '',
    text: 'Ćao',
    imageUrl: '',
    createdAt: at,
    isMine: false,
  );
}

void main() {
  group('inbox order', () {
    test('group thread uses the newest of messages and lastMessageAt', () {
      final older = _now.subtract(const Duration(hours: 3));
      final thread = GroupInboxThread.fromMessages(
        group: _group(lastMessageAt: _now),
        messages: [_groupMessage(older)],
      );
      expect(thread.lastActivityAt, _now);

      final fromMessages = GroupInboxThread.fromMessages(
        group: _group(lastMessageAt: older),
        messages: [_groupMessage(_now)],
      );
      expect(fromMessages.lastActivityAt, _now);
    });

    test('a thread without any message sorts last, not on top', () {
      final empty = GroupInboxThread.fromMessages(
        group: _group(),
        messages: const [],
      );
      expect(empty.lastActivityAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('seen (Viđeno)', () {
    final earlier = _now.subtract(const Duration(minutes: 5));

    test('my last message is seen once the peer has 0 unread', () {
      final chat = _chat(
        messages: [_msg('m1', mine: true, at: earlier)],
        peerUnread: 0,
      );
      expect(chat.lastMessageSeenByPeer, isTrue);
    });

    test('not seen while the peer still has unread messages', () {
      final chat = _chat(
        messages: [_msg('m1', mine: true, at: earlier)],
        peerUnread: 1,
      );
      expect(chat.lastMessageSeenByPeer, isFalse);
    });

    test('not for the peer message, unknown rooms or unsaved sends', () {
      expect(
        _chat(
          messages: [_msg('m1', mine: false, at: earlier)],
          peerUnread: 0,
        ).lastMessageSeenByPeer,
        isFalse,
      );
      expect(
        _chat(messages: [_msg('m1', mine: true, at: earlier)])
            .lastMessageSeenByPeer,
        isFalse,
      );
      expect(
        _chat(
          messages: [_msg('local-1', mine: true, at: earlier)],
          peerUnread: 0,
        ).lastMessageSeenByPeer,
        isFalse,
      );
      // Room update (peer +1) not in yet: the room is older than the message.
      expect(
        _chat(
          messages: [_msg('m2', mine: true, at: _now)],
          peerUnread: 0,
          lastActivityAt: earlier,
        ).lastMessageSeenByPeer,
        isFalse,
      );
    });

    testWidgets('chat shows Viđeno under my last message', (tester) async {
      Future<void> pump(int peerUnread) async {
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              chatSeedProvider.overrideWith(
                (ref) => [
                  _chat(
                    messages: [
                      _msg('m0', mine: false, at: earlier),
                      _msg('m1', mine: true, at: earlier),
                    ],
                    peerUnread: peerUnread,
                  ),
                ],
              ),
              chatNowProvider.overrideWith((ref) => _now),
            ],
            child: const MaterialApp(home: ChatScreen(conversationId: 'lola')),
          ),
        );
        await tester.pump();
        await tester.pump();
      }

      await pump(0);
      expect(find.text(ChatStrings.seen), findsOneWidget);

      await pump(1);
      expect(find.text(ChatStrings.seen), findsNothing);
    });
  });

  group('chat repository lifetime', () {
    test('profile updates do not rebuild the chat repository', () async {
      final auth = StreamController<AppUser?>();
      addTearDown(auth.close);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => auth.stream),
          chatSeedProvider.overrideWith((ref) => const []),
        ],
      );
      addTearDown(container.dispose);
      container.listen(chatRepositoryProvider, (_, _) {});

      auth.add(const AppUser(uid: 'me', displayName: 'Marko'));
      await Future<void>.delayed(Duration.zero);
      await container.read(firestoreAuthReadyProvider.future);
      await Future<void>.delayed(Duration.zero);
      final first = container.read(chatRepositoryProvider);

      // users/{uid} snapshot with other fields (e.g. right after a reload).
      auth.add(const AppUser(uid: 'me', displayName: 'Marko', bio: 'Novi'));
      await Future<void>.delayed(Duration.zero);
      expect(identical(container.read(chatRepositoryProvider), first), isTrue);

      // A new name is used for the next messages, still the same repository.
      auth.add(const AppUser(uid: 'me', displayName: 'Marko M.'));
      await Future<void>.delayed(Duration.zero);
      expect(identical(container.read(chatRepositoryProvider), first), isTrue);
      expect((first as LocalChatRepository).currentUserName, 'Marko M.');

      // Another account gets a fresh repository.
      auth.add(const AppUser(uid: 'other', displayName: 'Ana'));
      await Future<void>.delayed(Duration.zero);
      expect(identical(container.read(chatRepositoryProvider), first), isFalse);
    });
  });

  group('notifications by day', () {
    AppNotification note(String id, DateTime at) => AppNotification(
      id: id,
      kind: NotificationKind.like,
      title: id,
      body: id,
      createdAt: at,
    );

    test('splits into Danas, Juče and Ranije, newest first', () {
      final now = DateTime(2026, 10, 22, 9, 30);
      final sections = groupNotificationsByDay([
        note('old', DateTime(2026, 10, 18, 20)),
        note('yesterday-late', DateTime(2026, 10, 21, 23, 59)),
        note('today', DateTime(2026, 10, 22, 0, 1)),
        note('yesterday-early', DateTime(2026, 10, 21, 0, 0)),
        note('today-later', DateTime(2026, 10, 22, 9)),
      ], now);

      expect(sections.map((s) => s.day), [
        NotificationDay.today,
        NotificationDay.yesterday,
        NotificationDay.earlier,
      ]);
      expect(sections[0].items.map((n) => n.id), ['today-later', 'today']);
      expect(sections[1].items.map((n) => n.id), [
        'yesterday-late',
        'yesterday-early',
      ]);
      expect(sections[2].items.map((n) => n.id), ['old']);
    });

    test('empty days are left out', () {
      final now = DateTime(2026, 10, 22, 9);
      final sections = groupNotificationsByDay([
        note('old', DateTime(2026, 9, 1)),
      ], now);
      expect(sections.single.day, NotificationDay.earlier);
    });
  });
}
