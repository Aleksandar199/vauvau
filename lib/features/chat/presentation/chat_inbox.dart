import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/domain/discover_profile.dart';
import '../../dogs/domain/dogs_exception.dart';
import '../../events/presentation/events_controller.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../moderation/presentation/block_controller.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../notifications/presentation/push_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/firestore_chat_repository.dart';
import '../data/local_chat_repository.dart';
import '../data/mock_conversations.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/scheduled_walk.dart';

class ChatInboxController extends Notifier<List<ChatConversation>> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  List<ChatConversation> build() {
    final repo = ref.watch(chatRepositoryProvider);
    final sub = repo.watchInbox().listen((value) => state = value);
    ref.onDispose(sub.cancel);
    return repo.currentInbox;
  }

  List<ChatConversation> get newMatches =>
      state.where((chat) => chat.isNewMatch).toList();

  List<ChatConversation> get threads {
    final open = state.where((chat) => !chat.isNewMatch).toList()
      ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    return open;
  }

  ChatConversation? byId(String id) {
    for (final chat in state) {
      if (chat.id == id) {
        return chat;
      }
    }
    return null;
  }

  String openFromMatch(DiscoverProfile profile) {
    final id = _repo.openFromMatch(
      profile: profile,
      myUserId: ref.read(chatUserIdProvider),
      myDogId: ref.read(currentDiscoverDogProvider).id,
    );
    state = _repo.currentInbox;
    return id;
  }

  void markRead(String conversationId) {
    _repo.markRead(conversationId);
    state = _repo.currentInbox;
    final chat = byId(conversationId);
    ref.read(notificationControllerProvider.notifier).markChatMessagesRead(
          conversationId: conversationId,
          peerUserId: chat?.peerUserId,
        );
  }

  void attachRoom(String conversationId) {
    _repo.attachRoom(conversationId);
    state = _repo.currentInbox;
  }

  void detachRoom(String conversationId) {
    _repo.detachRoom(conversationId);
    state = _repo.currentInbox;
  }

  Future<void> sendMessage(
    String conversationId,
    String rawText, {
    ChatMessage? replyTo,
  }) async {
    await _repo.sendMessage(conversationId, rawText, replyTo: replyTo);
    state = _repo.currentInbox;
    final preview = rawText.trim();
    if (preview.isEmpty) {
      return;
    }
    _notifyPeerOfMessage(conversationId, preview);
  }

  /// My name as the peer should see it. Never `chat.ownerName`: that is the
  /// peer's own name (the bug where invites read "Nina vas poziva…" to Nina).
  String get _myName {
    final auth =
        (ref.read(authStateProvider).asData?.value?.displayName ?? '').trim();
    if (auth.isNotEmpty) {
      return auth;
    }
    final owner = ref.read(profileControllerProvider).ownerName.trim();
    return owner.isEmpty ? 'Neko' : owner;
  }

  /// My selected dog, or null while my profile has no real dog yet.
  DiscoverProfile? get _myDog {
    final profile = ref.read(profileControllerProvider);
    return profile.dogs.isEmpty ? null : profile.dog;
  }

  /// Phone push to the peer (fcmInbox only: no in-app notification).
  void _notifyPeerOfMessage(String conversationId, String preview) {
    final chat = byId(conversationId);
    if (chat == null) {
      return;
    }
    unawaited(
      ref.read(pushControllerProvider.notifier).notifyMessage(
            senderName: _myName,
            preview: preview,
            dogId: _myDog?.id,
            peerUserId: chat.peerUserId,
            conversationId: conversationId,
          ),
    );
  }

  Future<void> sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  }) async {
    if (!walkTime.isAfter(DateTime.now())) {
      return;
    }
    await _repo.sendWalkInvite(
      conversationId: conversationId,
      walkTime: walkTime,
      walkLocationName: walkLocationName,
    );
    state = _repo.currentInbox;
    final chat = byId(conversationId);
    if (chat != null) {
      notifyWalkRequest(
        peerUserId: chat.peerUserId,
        conversationId: conversationId,
      );
    }
  }

  /// Tells [peerUserId] that I invited them for a walk. The invite comes from
  /// me: my name and my dog, not the peer's.
  void notifyWalkRequest({required String peerUserId, String? conversationId}) {
    final myDog = _myDog;
    unawaited(
      ref.read(pushControllerProvider.notifier).notifyWalk(
            dogName: myDog?.name ?? '',
            ownerName: _myName,
            dogId: myDog?.id,
            peerUserId: peerUserId,
            conversationId: conversationId,
          ),
    );
  }

  Future<void> sendLocationPin({
    required String conversationId,
    required String locationName,
  }) async {
    await _repo.sendLocationPin(
      conversationId: conversationId,
      locationName: locationName,
    );
    state = _repo.currentInbox;
    _notifyPeerOfMessage(conversationId, '📍 $locationName');
  }

  Future<void> sendPhoto(
    String conversationId,
    XFile file, {
    ChatMessage? replyTo,
  }) async {
    final error = await ContentValidationService.validateImage(file);
    if (error != null) {
      throw DogsException(error);
    }
    final url = await ImageUploadService.uploadFile(
      file,
      folderName: 'chats',
    );
    await _repo.sendPhoto(
      conversationId: conversationId,
      imageUrl: url,
      replyTo: replyTo,
    );
    state = _repo.currentInbox;
    _notifyPeerOfMessage(conversationId, '📷 Fotografija');
  }

  Future<void> respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  }) async {
    await _repo.respondToWalkInvite(
      conversationId: conversationId,
      messageId: messageId,
      status: status,
    );
    state = _repo.currentInbox;
  }

  Future<void> toggleMessageLike({
    required String conversationId,
    required String messageId,
  }) async {
    await _repo.toggleMessageLike(
      conversationId: conversationId,
      messageId: messageId,
    );
    state = _repo.currentInbox;
  }

  Future<void> setMessageReaction({
    required String conversationId,
    required String messageId,
    String? emoji,
  }) async {
    await _repo.setMessageReaction(
      conversationId: conversationId,
      messageId: messageId,
      emoji: emoji,
    );
    state = _repo.currentInbox;
  }
}

final chatSeedProvider = Provider<List<ChatConversation>>((ref) {
  return seedChatConversations(DateTime.now());
});

final chatUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  return user?.uid ?? 'local-user';
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  final uid = user?.uid ?? '';
  final name = (user?.displayName ?? '').trim().isEmpty
      ? 'Ti'
      : user!.displayName!.trim();
  final avatar = user?.ownerAvatarUrl ?? '';
  // Do not open Firestore chat listeners until Auth has a real user.
  // (authState still loading → asData null → previously queried as 'local-user')
  final authReady = ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
  if (isFirebaseReady && user != null && uid.isNotEmpty && authReady) {
    final repo = FirestoreChatRepository(
      firestore: FirebaseFirestore.instance,
      currentUserId: uid,
      currentUserName: name,
      currentUserAvatarUrl: avatar,
    );
    repo.start();
    ref.onDispose(repo.dispose);
    return repo;
  }
  final repo = LocalChatRepository(
    seed: isFirebaseReady ? const [] : ref.watch(chatSeedProvider),
    currentUserId: uid.isEmpty ? 'local-user' : uid,
    currentUserName: name,
    currentUserAvatarUrl: avatar,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final chatInboxProvider =
    NotifierProvider<ChatInboxController, List<ChatConversation>>(
  ChatInboxController.new,
);

/// False until the chat repository has a first usable inbox snapshot.
final chatInboxLoadedProvider = Provider<bool>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  // Keep Riverpod subscribed so UI rebuilds when bootstrap completes.
  ref.watch(_chatInboxLoadedStreamProvider);
  return repo.hasLoadedInbox;
});

final _chatInboxLoadedStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(chatRepositoryProvider).watchInboxLoaded();
});

/// Inbox without threads from blocked users.
final visibleConversationsProvider = Provider<List<ChatConversation>>((ref) {
  final blocked = ref.watch(blockedUserIdsProvider);
  final inbox = ref.watch(chatInboxProvider);
  if (blocked.isEmpty) {
    return inbox;
  }
  return [
    for (final chat in inbox)
      if (!blocked.contains(chat.peerUserId)) chat,
  ];
});

final chatNowProvider = Provider<DateTime>((ref) => DateTime.now());

/// Ticks so scheduled-walk banners drop items once their time has passed.
final scheduledWalksClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(
    const Duration(hours: 1),
    (_) => DateTime.now(),
  );
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  return ref.watch(chatRepositoryProvider).watchMessages(roomId);
});

/// Walk invites for every conversation, independent of which chat is open.
class ChatWalkInvitesController
    extends Notifier<Map<String, List<ChatMessage>>> {
  @override
  Map<String, List<ChatMessage>> build() {
    final repo = ref.watch(chatRepositoryProvider);
    final sub = repo.watchWalkInvites().listen((value) => state = value);
    ref.onDispose(sub.cancel);
    return repo.currentWalkInvites;
  }
}

final chatWalkInvitesProvider = NotifierProvider<ChatWalkInvitesController,
    Map<String, List<ChatMessage>>>(ChatWalkInvitesController.new);

final scheduledWalksProvider = Provider<List<ScheduledWalk>>((ref) {
  ref.watch(scheduledWalksClockProvider);
  final inbox = ref.watch(chatInboxProvider);
  final invites = ref.watch(chatWalkInvitesProvider);
  final now = DateTime.now();
  final walks = <ScheduledWalk>[];
  for (final chat in inbox) {
    // Open rooms carry fresher (optimistic) copies of the same invites.
    final byId = <String, ChatMessage>{
      for (final message in invites[chat.id] ?? const <ChatMessage>[])
        message.id: message,
      for (final message in chat.messages)
        if (message.isWalkInvite) message.id: message,
    };
    for (final message in byId.values) {
      final walkTime = message.walkTime;
      if (message.isWalkInvite &&
          message.status == WalkInviteStatus.accepted &&
          walkTime != null &&
          walkTime.isAfter(now)) {
        walks.add(
          ScheduledWalk(
            id: message.id,
            conversationId: chat.id,
            dogName: chat.dogName,
            ownerName: chat.ownerName,
            locationName: message.walkLocationName ?? chat.location,
            walkTime: walkTime,
          ),
        );
      }
    }
  }
  walks.sort((a, b) => a.walkTime.compareTo(b.walkTime));
  return walks;
});



final totalUnreadChatCountProvider = Provider<int>((ref) {
  var threads = 0;
  for (final chat in ref.watch(visibleConversationsProvider)) {
    if (chat.unreadCount > 0) {
      threads++;
    }
  }
  for (final group in ref.watch(joinedGroupThreadsProvider)) {
    if (group.unreadCount > 0) {
      threads++;
    }
  }
  for (final event in ref.watch(joinedEventThreadsProvider)) {
    if (event.unreadCount > 0) {
      threads++;
    }
  }
  return threads;
});