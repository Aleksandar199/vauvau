import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/domain/discover_profile.dart';
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
  }

  void sendMessage(String conversationId, String rawText) {
    _repo.sendMessage(conversationId, rawText);
    state = _repo.currentInbox;
  }

  void sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  }) {
    _repo.sendWalkInvite(
      conversationId: conversationId,
      walkTime: walkTime,
      walkLocationName: walkLocationName,
    );
    state = _repo.currentInbox;
  }

  void sendLocationPin({
    required String conversationId,
    required String locationName,
  }) {
    _repo.sendLocationPin(
      conversationId: conversationId,
      locationName: locationName,
    );
    state = _repo.currentInbox;
  }

  void respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  }) {
    _repo.respondToWalkInvite(
      conversationId: conversationId,
      messageId: messageId,
      status: status,
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
  if (isFirebaseReady) {
    final repo = FirestoreChatRepository(
      firestore: FirebaseFirestore.instance,
      currentUserId: ref.watch(chatUserIdProvider),
    );
    repo.start();
    ref.onDispose(repo.dispose);
    return repo;
  }
  final repo = LocalChatRepository(
    seed: ref.watch(chatSeedProvider),
    currentUserId: ref.watch(chatUserIdProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final chatInboxProvider =
    NotifierProvider<ChatInboxController, List<ChatConversation>>(
  ChatInboxController.new,
);

final chatNowProvider = Provider<DateTime>((ref) => DateTime.now());

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  return ref.watch(chatRepositoryProvider).watchMessages(roomId);
});

final scheduledWalksProvider = Provider<List<ScheduledWalk>>((ref) {
  final inbox = ref.watch(chatInboxProvider);
  final walks = <ScheduledWalk>[];
  for (final chat in inbox) {
    for (final message in chat.messages) {
      if (message.isWalkInvite &&
          message.status == WalkInviteStatus.accepted &&
          message.walkTime != null) {
        walks.add(
          ScheduledWalk(
            id: message.id,
            conversationId: chat.id,
            dogName: chat.dogName,
            ownerName: chat.ownerName,
            locationName: message.walkLocationName ?? chat.location,
            walkTime: message.walkTime!,
          ),
        );
      }
    }
  }
  walks.sort((a, b) => a.walkTime.compareTo(b.walkTime));
  return walks;
});
