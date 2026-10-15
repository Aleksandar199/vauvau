import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/chat/data/local_chat_repository.dart';
import 'package:vauvau/features/chat/domain/chat_conversation.dart';
import 'package:vauvau/features/chat/domain/chat_message.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';

/// Mirrors Firestore: inbox rooms carry no hydrated messages unless a chat is
/// open, while walk invites are streamed separately for every room.
class _LazyInboxRepository extends LocalChatRepository {
  _LazyInboxRepository({required super.seed, required this.invites})
      : super(currentUserId: 'me');

  final Map<String, List<ChatMessage>> invites;
  final _controller =
      StreamController<Map<String, List<ChatMessage>>>.broadcast();

  void push(Map<String, List<ChatMessage>> next) {
    invites
      ..clear()
      ..addAll(next);
    _controller.add(Map.of(invites));
  }

  @override
  Map<String, List<ChatMessage>> get currentWalkInvites => Map.of(invites);

  @override
  Stream<Map<String, List<ChatMessage>>> watchWalkInvites() async* {
    yield currentWalkInvites;
    yield* _controller.stream;
  }
}

ChatConversation _room(String id, {List<ChatMessage> messages = const []}) {
  return ChatConversation(
    id: id,
    dogId: 'dog-$id',
    dogName: 'Lola',
    ownerName: 'Jelena',
    breed: 'Labrador',
    location: 'Novi Sad - Liman',
    photoUrl: '',
    messages: messages,
    lastActivityAt: DateTime.now(),
    isNewMatch: false,
    unreadCount: 0,
  );
}

ChatMessage _invite(
  String id, {
  required WalkInviteStatus status,
  required DateTime walkTime,
}) {
  return ChatMessage(
    id: id,
    text: 'Poziv na Å¡etnju',
    sentAt: DateTime.now(),
    isMine: false,
    type: ChatMessageType.walkInvite,
    status: status,
    walkTime: walkTime,
    walkLocationName: 'Limanski park',
  );
}

void main() {
  test('accepted walks show even when no chat room is open', () async {
    final future = DateTime.now().add(const Duration(days: 1));
    final repo = _LazyInboxRepository(
      seed: [_room('room-1')],
      invites: {
        'room-1': [
          _invite('w-accepted', status: WalkInviteStatus.accepted, walkTime: future),
          _invite('w-pending', status: WalkInviteStatus.pending, walkTime: future),
          _invite(
            'w-past',
            status: WalkInviteStatus.accepted,
            walkTime: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      },
    );
    addTearDown(repo.dispose);
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(scheduledWalksProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);

    final walks = container.read(scheduledWalksProvider);
    expect(walks.map((w) => w.id), ['w-accepted']);
    expect(walks.single.locationName, 'Limanski park');
    expect(walks.single.dogName, 'Lola');
  });

  test('walks stay listed after an open chat drops its messages', () async {
    final future = DateTime.now().add(const Duration(days: 2));
    final accepted =
        _invite('w-1', status: WalkInviteStatus.accepted, walkTime: future);
    final repo = _LazyInboxRepository(
      seed: [_room('room-1', messages: [accepted])],
      invites: {
        'room-1': [accepted],
      },
    );
    addTearDown(repo.dispose);
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(scheduledWalksProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(scheduledWalksProvider), hasLength(1));

    // Leaving the chat clears hydrated messages (detachRoom in Firestore).
    container.read(chatInboxProvider.notifier).state = [_room('room-1')];
    await Future<void>.delayed(Duration.zero);
    expect(container.read(scheduledWalksProvider).map((w) => w.id), ['w-1']);
  });

  test('newly accepted invite appears without opening the chat', () async {
    final future = DateTime.now().add(const Duration(days: 3));
    final repo = _LazyInboxRepository(
      seed: [_room('room-1')],
      invites: {
        'room-1': [
          _invite('w-1', status: WalkInviteStatus.pending, walkTime: future),
        ],
      },
    );
    addTearDown(repo.dispose);
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(scheduledWalksProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(scheduledWalksProvider), isEmpty);
    repo.push({
      'room-1': [
        _invite('w-1', status: WalkInviteStatus.accepted, walkTime: future),
      ],
    });
    await Future<void>.delayed(Duration.zero);
    expect(container.read(scheduledWalksProvider).map((w) => w.id), ['w-1']);
  });
}
