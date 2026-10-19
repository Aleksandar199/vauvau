import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/services/message_sound_player.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/chat/data/firestore_chat_repository.dart';
import 'package:vauvau/features/chat/domain/chat_conversation.dart';
import 'package:vauvau/features/chat/domain/chat_message.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/chat/presentation/incoming_message_sound.dart';
import 'package:vauvau/features/chat/presentation/open_chats.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/events/presentation/events_controller.dart';
import 'package:vauvau/features/groups/presentation/groups_controller.dart';
import 'package:vauvau/features/notifications/data/conversation_notifications.dart';
import 'package:vauvau/features/notifications/data/push_notification_gateway.dart';
import 'package:vauvau/features/notifications/domain/app_notification.dart';
import 'package:vauvau/features/notifications/domain/push_payload.dart';
import 'package:vauvau/features/notifications/presentation/notification_controller.dart';
import 'package:vauvau/features/notifications/presentation/push_controller.dart';
import 'package:vauvau/features/profile/domain/app_settings.dart';
import 'package:vauvau/features/profile/domain/user_profile.dart';
import 'package:vauvau/features/profile/presentation/profile_controller.dart';

class _RecordingGateway extends NoopPushNotificationGateway {
  final queued = <({String userId, PushPayload payload})>[];
  final presented = <PushPayload>[];

  @override
  Future<void> queueForUser(String userId, PushPayload payload) async {
    queued.add((userId: userId, payload: payload));
  }

  @override
  Future<void> present(PushPayload payload) async => presented.add(payload);
}

class _Settings extends AppSettingsController {
  @override
  AppSettings build() => const AppSettings();
}

class _Profile extends ProfileController {
  @override
  UserProfile build() => UserProfile(
        ownerName: 'Marko',
        ownerBio: '',
        dogs: [_dog(id: 'rex', name: 'Rex', owner: 'Marko', ownerId: 'me')],
        selectedDogId: 'rex',
      );
}

class _SilentSound implements MessageSoundPlayer {
  int plays = 0;

  @override
  Future<void> play() async => plays++;

  @override
  void dispose() {}
}

DiscoverProfile _dog({
  required String id,
  required String name,
  required String owner,
  required String ownerId,
}) {
  return DiscoverProfile(
    id: id,
    ownerId: ownerId,
    name: name,
    ownerName: owner,
    breed: 'Bigl',
    ageYears: 3,
    gender: 'muški',
    size: 'srednji',
    location: 'Novi Sad',
    bio: '',
    photoUrls: const [],
  );
}

/// Conversation as I (Marko, uid `me`) see it: the peer is Nina with Lola.
ChatConversation _ninaChat({int unread = 0, DateTime? at}) {
  return ChatConversation(
    id: 'me_nina',
    dogId: 'lola',
    dogName: 'Lola',
    ownerName: 'Nina',
    breed: 'Labrador',
    location: 'Novi Sad',
    photoUrl: '',
    peerUserId: 'nina',
    participantIds: const ['me', 'nina'],
    messages: const [],
    lastActivityAt: at ?? DateTime.now(),
    isNewMatch: false,
    unreadCount: unread,
    lastMessagePreview: 'Ćao!',
  );
}

ProviderContainer _container(
  _RecordingGateway gateway, {
  List<ChatConversation> seed = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(const AppUser(uid: 'me')),
      ),
      pushNotificationGatewayProvider.overrideWithValue(gateway),
      appSettingsProvider.overrideWith(_Settings.new),
      profileControllerProvider.overrideWith(_Profile.new),
      chatSeedProvider.overrideWith((ref) => seed),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _ChatList extends Notifier<List<ChatConversation>> {
  @override
  List<ChatConversation> build() => const [];

  void set(List<ChatConversation> value) => state = value;
}

final _chats = NotifierProvider<_ChatList, List<ChatConversation>>(
  _ChatList.new,
);

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  // The chat alert reads the app lifecycle from WidgetsBinding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sender of chat notifications (bug 1)', () {
    test('walk invite names me and my dog, not the peer', () async {
      final gateway = _RecordingGateway();
      final container = _container(gateway, seed: [_ninaChat()]);
      container.read(authStateProvider);
      await _tick();

      await container.read(chatInboxProvider.notifier).sendWalkInvite(
            conversationId: 'me_nina',
            walkTime: DateTime.now().add(const Duration(hours: 2)),
            walkLocationName: 'Dunavski park',
          );
      await _tick();

      final walk = gateway.queued.single;
      expect(walk.userId, 'nina');
      expect(walk.payload.kind, PushKind.walk);
      expect(walk.payload.body, contains('Marko'));
      expect(walk.payload.body, contains('Rex'));
      expect(walk.payload.body, isNot(contains('Nina')));
      expect(walk.payload.body, isNot(contains('Lola')));
      expect(walk.payload.dogId, 'rex');
      expect(walk.payload.conversationId, 'me_nina');
    });

    test('text and location messages are sent under my name', () async {
      final gateway = _RecordingGateway();
      final container = _container(gateway, seed: [_ninaChat()]);
      container.read(authStateProvider);
      await _tick();

      final inbox = container.read(chatInboxProvider.notifier);
      await inbox.sendMessage('me_nina', 'Vidimo se');
      await inbox.sendLocationPin(
        conversationId: 'me_nina',
        locationName: 'Limanski park',
      );
      await _tick();

      expect(gateway.queued, hasLength(2));
      for (final item in gateway.queued) {
        expect(item.userId, 'nina');
        expect(item.payload.kind, PushKind.message);
        expect(item.payload.body, startsWith('Marko: '));
        expect(item.payload.dogId, 'rex');
      }
      expect(gateway.queued.last.payload.body, contains('Limanski park'));
    });

    test('stored notification points back to the sender', () async {
      final firestore = FakeFirebaseFirestore();
      await writeQueuedNotification(
        firestore,
        userId: 'nina',
        senderId: 'me',
        payload: const PushPayload(
          kind: PushKind.walk,
          title: 'Poziv na šetnju',
          body: 'Marko vas poziva u šetnju sa Rex.',
          dogId: 'rex',
          // Sender-side payload: the peer is the recipient.
          peerUserId: 'nina',
          conversationId: 'me_nina',
        ),
      );

      final doc =
          (await firestore.collection('notifications').get()).docs.single;
      expect(doc['fromUserId'], 'me');
      expect(doc['toUserId'], 'nina');
      // Read back on Nina's phone, the peer is me (not Nina herself).
      final parsed = PushPayload.fromData(Map.of(doc.data()));
      expect(parsed.peerUserId, 'me');
    });
  });

  group('chat messages are push only (bug 3)', () {
    test('a new message goes to fcmInbox, not to notifications', () async {
      final firestore = FakeFirebaseFirestore();
      await writeQueuedNotification(
        firestore,
        userId: 'nina',
        senderId: 'me',
        payload: const PushPayload(
          kind: PushKind.message,
          title: 'Nova poruka',
          body: 'Marko: Ćao',
          peerUserId: 'nina',
          conversationId: 'me_nina',
        ),
      );

      final inbox = await firestore
          .collection('users')
          .doc('nina')
          .collection('fcmInbox')
          .get();
      expect(inbox.docs, hasLength(1));
      expect(inbox.docs.single['type'], 'message');
      expect((await firestore.collection('notifications').get()).docs, isEmpty);
    });

    test('walk invites keep their in-app notification', () async {
      final firestore = FakeFirebaseFirestore();
      await writeQueuedNotification(
        firestore,
        userId: 'nina',
        senderId: 'me',
        payload: const PushPayload(
          kind: PushKind.walk,
          title: 'Poziv na šetnju',
          body: 'Marko vas poziva u šetnju.',
          conversationId: 'me_nina',
        ),
      );
      expect((await firestore.collection('notifications').get()).docs,
          hasLength(1));
    });

    test('group and incoming chat alerts reach the phone, not the list',
        () async {
      final gateway = _RecordingGateway();
      final container = _container(gateway);
      final push = container.read(pushControllerProvider.notifier);

      await push.notifyGroupThread(groupTitle: 'Bigl', count: 2, groupId: 'g');
      await push.alertIncomingMessage(
        senderName: 'Nina',
        preview: 'Ćao',
        senderUserId: 'nina',
        conversationId: 'me_nina',
      );

      expect(gateway.presented, hasLength(2));
      expect(gateway.presented.last.body, 'Nina: Ćao');
      expect(container.read(notificationControllerProvider), isEmpty);
    });

    test('incoming 1:1 message alerts the phone unless that chat is open',
        () async {
      final sound = _SilentSound();
      final alerts = <String>[];
      final container = ProviderContainer(
        overrides: [
          messageSoundPlayerProvider.overrideWithValue(sound),
          appSettingsProvider.overrideWith(_Settings.new),
          systemMessageAlertsAudibleProvider.overrideWithValue(true),
          incomingChatAlertProvider
              .overrideWithValue((chat) => alerts.add(chat.id)),
          visibleConversationsProvider.overrideWith((ref) => ref.watch(_chats)),
          joinedGroupThreadsProvider.overrideWith((ref) => const []),
          joinedEventThreadsProvider.overrideWith((ref) => const []),
        ],
      );
      addTearDown(container.dispose);
      container.listen(incomingMessageSoundProvider, (_, _) {});
      void deliver(List<ChatConversation> next) =>
          container.read(_chats.notifier).set(next);

      deliver([_ninaChat()]);
      await _tick();
      deliver([_ninaChat(unread: 1)]);
      await _tick();
      expect(alerts, ['me_nina']);
      // The OS notification sounds; no extra chime.
      expect(sound.plays, 0);

      container.read(openChatsProvider.notifier).open('me_nina');
      deliver([_ninaChat(unread: 2)]);
      await _tick();
      expect(alerts, ['me_nina'], reason: 'open chat needs no alert');
      expect(sound.plays, 1);
    });
  });

  group('reading a chat reads its notifications (bug 2)', () {
    AppNotification item(
      String id,
      NotificationKind kind, {
      String? conversationId,
      String? fromUserId,
    }) {
      return AppNotification(
        id: id,
        kind: kind,
        title: id,
        body: id,
        createdAt: DateTime(2026, 10, 15),
        conversationId: conversationId,
        fromUserId: fromUserId,
      );
    }

    test('matches this chat by conversationId or legacy sender', () {
      bool belongs(AppNotification n) => notificationBelongsToChat(
            n,
            conversationId: 'me_nina',
            peerUserId: 'nina',
          );
      expect(
        belongs(item('w', NotificationKind.walkRequest,
            conversationId: 'me_nina')),
        isTrue,
      );
      expect(
        belongs(item('m', NotificationKind.chatMessage, fromUserId: 'nina')),
        isTrue,
      );
      expect(
        belongs(item('o', NotificationKind.chatMessage,
            conversationId: 'me_ana', fromUserId: 'nina')),
        isFalse,
      );
      expect(belongs(item('l', NotificationKind.like, fromUserId: 'nina')),
          isFalse);
    });

    test('Firestore docs of the chat get isRead: true, others stay',
        () async {
      final firestore = FakeFirebaseFirestore();
      final notifications = firestore.collection('notifications');
      Future<void> add(String id, Map<String, dynamic> data) =>
          notifications.doc(id).set({'isRead': false, ...data});
      await add('walk', {'toUserId': 'me', 'conversationId': 'me_nina'});
      await add('msg', {'toUserId': 'me', 'conversationId': 'me_nina'});
      await add('legacy', {'toUserId': 'me', 'fromUserId': 'nina'});
      await add('other-chat', {'toUserId': 'me', 'conversationId': 'me_ana'});
      await add('not-mine', {'toUserId': 'ana', 'conversationId': 'me_nina'});

      final updated = await markConversationNotificationsRead(
        firestore,
        uid: 'me',
        conversationId: 'me_nina',
        alsoIds: const ['legacy'],
      );

      expect(updated.toSet(), {'walk', 'msg', 'legacy'});
      Future<bool> isRead(String id) async =>
          (await notifications.doc(id).get())['isRead'] as bool;
      expect(await isRead('walk'), isTrue);
      expect(await isRead('msg'), isTrue);
      expect(await isRead('legacy'), isTrue);
      expect(await isRead('other-chat'), isFalse);
      expect(await isRead('not-mine'), isFalse);
    });

    test('opening the chat clears its unread badge and notifications',
        () async {
      final gateway = _RecordingGateway();
      final container = _container(gateway, seed: [_ninaChat(unread: 2)]);
      container.read(authStateProvider);
      await _tick();
      final notifications =
          container.read(notificationControllerProvider.notifier);
      notifications
        ..prepend(item('walk', NotificationKind.walkRequest,
            conversationId: 'me_nina'))
        ..prepend(item('like', NotificationKind.like, fromUserId: 'nina'));
      expect(container.read(notificationUnreadCountProvider), 2);

      container.read(chatInboxProvider.notifier).markRead('me_nina');

      final chat = container.read(chatInboxProvider.notifier).byId('me_nina');
      expect(chat!.unreadCount, 0);
      final list = container.read(notificationControllerProvider);
      expect(list.firstWhere((n) => n.id == 'walk').isRead, isTrue);
      expect(list.firstWhere((n) => n.id == 'like').isRead, isFalse);
      expect(container.read(notificationUnreadCountProvider), 1);
    });
  });

  group('message likes (bug 4, now reactions)', () {
    test('Firestore likes reach the open conversation', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = FirestoreChatRepository(
        firestore: firestore,
        currentUserId: 'me',
      );
      addTearDown(repo.dispose);
      final roomId = repo.openFromMatch(
        profile: _dog(id: 'lola', name: 'Lola', owner: 'Nina', ownerId: 'nina'),
        myUserId: 'me',
        myDogId: 'rex',
      );
      final messages =
          firestore.collection('chats').doc(roomId).collection('messages');
      await messages.doc('hers').set({
        'senderId': 'nina',
        'text': 'Ćao',
        'timestamp': DateTime(2026, 10, 15, 10),
      });
      await messages.doc('mine').set({
        'senderId': 'me',
        'text': 'Zdravo',
        'timestamp': DateTime(2026, 10, 15, 11),
      });
      repo.attachRoom(roomId);
      await _tick();

      ChatMessage message(String id) => repo.currentInbox
          .firstWhere((chat) => chat.id == roomId)
          .messages
          .firstWhere((m) => m.id == id);

      await repo.toggleMessageLike(conversationId: roomId, messageId: 'hers');
      await _tick();
      expect(message('hers').likes, ['me']);
      expect((await messages.doc('hers').get())['likes'], ['me']);

      // The peer likes my message: it shows up on my side.
      await messages.doc('mine').update({'likes': ['nina']});
      await _tick();
      expect(message('mine').likeCount, 1);

      await repo.toggleMessageLike(conversationId: roomId, messageId: 'hers');
      await _tick();
      expect(message('hers').likes, isEmpty);
    });
  });

  group('Pridruži se šetnji (mapa)', () {
    test('prva poruka čeka da se soba napravi', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = FirestoreChatRepository(
        firestore: firestore,
        currentUserId: 'me',
      );
      addTearDown(repo.dispose);
      final roomId = repo.openFromMatch(
        profile: _dog(id: 'lola', name: 'Lola', owner: 'Nina', ownerId: 'nina'),
        myUserId: 'me',
        myDogId: 'rex',
      );
      // Odmah posle otvaranja, kao dugme na mapi.
      await repo.sendMessage(roomId, 'Mogu li da vam se pridružim?');
      final room = await firestore.collection('chats').doc(roomId).get();
      expect(room.exists, isTrue);
      expect(room['participantIds'], containsAll(['me', 'nina']));
      final messages = await firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .get();
      expect(messages.docs.single['text'], 'Mogu li da vam se pridružim?');
    });

    test('šalje pravu poruku u čet i obaveštenje šetaču', () async {
      final gateway = _RecordingGateway();
      final container = _container(gateway);
      container.listen(chatInboxProvider, (_, _) {});
      await container.read(authStateProvider.future);
      final lola =
          _dog(id: 'lola', name: 'Lola', owner: 'Nina', ownerId: 'nina');

      final chatId =
          await container.read(chatInboxProvider.notifier).requestJoinWalk(lola);
      await _tick();

      final chat = container
          .read(chatInboxProvider)
          .firstWhere((c) => c.id == chatId);
      expect(chat.messages.last.text, contains('pridružim'));
      expect(chat.messages.last.text, contains('Rex'));
      expect(
        gateway.queued.where(
          (q) => q.userId == 'nina' && q.payload.kind == PushKind.walk,
        ),
        hasLength(1),
      );
    });

    test('šetač bez vlasnika: greška, ništa se ne šalje', () async {
      final gateway = _RecordingGateway();
      final container = _container(gateway);
      final noOwner = _dog(id: 'x', name: 'X', owner: '', ownerId: '');
      await expectLater(
        container.read(chatInboxProvider.notifier).requestJoinWalk(noOwner),
        throwsA(isA<StateError>()),
      );
      expect(gateway.queued, isEmpty);
    });
  });
}
