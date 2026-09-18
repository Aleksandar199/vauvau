import 'dart:async';

import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/chat_room.dart';

class LocalChatRepository implements ChatRepository {
  LocalChatRepository({
    required List<ChatConversation> seed,
    required this.currentUserId,
  }) : _inbox = List<ChatConversation>.from(seed);

  final String currentUserId;
  List<ChatConversation> _inbox;
  int _messageSeq = 0;
  final StreamController<List<ChatConversation>> _inboxController =
      StreamController<List<ChatConversation>>.broadcast();

  @override
  List<ChatConversation> get currentInbox =>
      List<ChatConversation>.from(_inbox);

  @override
  Stream<List<ChatConversation>> watchInbox() async* {
    yield currentInbox;
    yield* _inboxController.stream;
  }

  @override
  Stream<List<ChatRoom>> watchRooms() {
    return watchInbox().map(
      (conversations) => conversations.map((chat) => chat.room).toList(),
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return watchInbox().map((conversations) {
      for (final chat in conversations) {
        if (chat.id == roomId) {
          return chat.messages;
        }
      }
      return const <ChatMessage>[];
    });
  }

  @override
  String openFromMatch({
    required DiscoverProfile profile,
    required String myUserId,
    required String myDogId,
  }) {
    for (final chat in _inbox) {
      if (chat.dogId == profile.id) {
        return chat.id;
      }
    }
    final chat = ChatConversation(
      id: 'chat-${profile.id}',
      dogId: profile.id,
      dogName: profile.name,
      ownerName: profile.ownerName,
      breed: profile.breed,
      location: profile.location,
      photoUrl: profile.photoUrls.isEmpty ? '' : profile.photoUrls.first,
      participantIds: [myUserId, 'owner-${profile.id}'],
      dogIds: [myDogId, profile.id],
      peerUserId: 'owner-${profile.id}',
      messages: const [],
      lastActivityAt: DateTime.now(),
      isNewMatch: true,
    );
    _inbox = [chat, ..._inbox];
    _emit();
    return chat.id;
  }

  @override
  void markRead(String conversationId) {
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            unreadCount: 0,
            messages: [
              for (final message in chat.messages) message.copyWith(isRead: true),
            ],
          )
        else
          chat,
    ];
    _emit();
  }

  @override
  void sendMessage(String conversationId, String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return;
    }
    _append(
      conversationId,
      ChatMessage(
        id: _nextId(),
        senderId: currentUserId,
        receiverId: _peer(conversationId),
        text: text,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
      ),
    );
  }

  @override
  void sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  }) {
    _append(
      conversationId,
      ChatMessage(
        id: _nextId(),
        senderId: currentUserId,
        receiverId: _peer(conversationId),
        text: 'Poziv na šetnju: $walkLocationName',
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        type: ChatMessageType.walkInvite,
        status: WalkInviteStatus.pending,
        walkTime: walkTime,
        walkLocationName: walkLocationName,
      ),
    );
  }

  @override
  void sendLocationPin({
    required String conversationId,
    required String locationName,
  }) {
    _append(
      conversationId,
      ChatMessage(
        id: _nextId(),
        senderId: currentUserId,
        receiverId: _peer(conversationId),
        text: locationName,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        type: ChatMessageType.locationPin,
      ),
    );
  }

  @override
  void respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  }) {
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            messages: [
              for (final message in chat.messages)
                if (message.id == messageId)
                  message.copyWith(status: status)
                else
                  message,
            ],
          )
        else
          chat,
    ];
    _emit();
  }

  @override
  void dispose() {
    _inboxController.close();
  }

  void _append(String conversationId, ChatMessage message) {
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            messages: [...chat.messages, message],
            lastActivityAt: message.sentAt,
            isNewMatch: false,
            unreadCount: 0,
          )
        else
          chat,
    ];
    _emit();
  }

  String _peer(String conversationId) {
    for (final chat in _inbox) {
      if (chat.id == conversationId) {
        return chat.peerUserId;
      }
    }
    return '';
  }

  String _nextId() {
    _messageSeq += 1;
    return 'local-$_messageSeq';
  }

  void _emit() {
    if (!_inboxController.isClosed) {
      _inboxController.add(currentInbox);
    }
  }
}
