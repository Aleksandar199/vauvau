import 'dart:async';

import '../../../core/images/dog_photo_urls.dart';
import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/chat_room.dart';

class LocalChatRepository implements ChatRepository {
  LocalChatRepository({
    required List<ChatConversation> seed,
    required this.currentUserId,
    this.currentUserName = 'Ti',
    this.currentUserAvatarUrl = '',
  }) : _inbox = List<ChatConversation>.from(seed);

  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;
  List<ChatConversation> _inbox;
  int _messageSeq = 0;
  final StreamController<List<ChatConversation>> _inboxController =
      StreamController<List<ChatConversation>>.broadcast();

  @override
  List<ChatConversation> get currentInbox =>
      List<ChatConversation>.from(_inbox);

  @override
  bool get hasLoadedInbox => true;

  @override
  Map<String, List<ChatMessage>> get currentWalkInvites =>
      _walkInvitesOf(_inbox);

  @override
  Stream<Map<String, List<ChatMessage>>> watchWalkInvites() =>
      watchInbox().map(_walkInvitesOf);

  static Map<String, List<ChatMessage>> _walkInvitesOf(
    List<ChatConversation> inbox,
  ) {
    return {
      for (final chat in inbox)
        chat.id: [
          for (final message in chat.messages)
            if (message.isWalkInvite) message,
        ],
    };
  }

  @override
  Stream<List<ChatConversation>> watchInbox() async* {
    yield currentInbox;
    yield* _inboxController.stream;
  }

  @override
  Stream<bool> watchInboxLoaded() async* {
    yield true;
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
          final messages = chat.messages;
          if (messages.length <= 30) {
            return messages;
          }
          return messages.sublist(messages.length - 30);
        }
      }
      return const <ChatMessage>[];
    });
  }

  @override
  void attachRoom(String roomId) {}

  @override
  void detachRoom(String roomId) {}

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
      photoUrl: resolvedDogPhotoUrl(profile.photoUrls),
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
  Future<void> sendMessage(
    String conversationId,
    String rawText, {
    ChatMessage? replyTo,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      return;
    }
    final replyName = replyTo == null
        ? ''
        : (replyTo.senderName.trim().isNotEmpty
            ? replyTo.senderName.trim()
            : (replyTo.isMine ? currentUserName : 'Korisnik'));
    _append(
      conversationId,
      ChatMessage(
        id: _nextId(),
        senderId: currentUserId,
        receiverId: _peer(conversationId),
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
        text: text,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        replyToMessageId: replyTo?.id ?? '',
        replyToText: replyTo == null
            ? ''
            : ChatMessage.clipReplyText(replyTo.previewText),
        replyToSenderName: replyName,
      ),
    );
  }

  @override
  Future<void> sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  }) async {
    _append(
      conversationId,
      ChatMessage(
        id: _nextId(),
        senderId: currentUserId,
        receiverId: _peer(conversationId),
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
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
  Future<void> sendLocationPin({
    required String conversationId,
    required String locationName,
  }) async {
    _append(
      conversationId,
      ChatMessage(
        id: _nextId(),
        senderId: currentUserId,
        receiverId: _peer(conversationId),
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
        text: locationName,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        type: ChatMessageType.locationPin,
      ),
    );
  }

  @override
  Future<void> sendPhoto({
    required String conversationId,
    required String imageUrl,
    ChatMessage? replyTo,
  }) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return;
    }
    final replyName = replyTo == null
        ? ''
        : (replyTo.senderName.trim().isNotEmpty
            ? replyTo.senderName.trim()
            : (replyTo.isMine ? currentUserName : 'Korisnik'));
    _append(
      conversationId,
      ChatMessage(
        id: _nextId(),
        senderId: currentUserId,
        receiverId: _peer(conversationId),
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
        text: '',
        imageUrl: url,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        replyToMessageId: replyTo?.id ?? '',
        replyToText:
            replyTo == null ? '' : ChatMessage.clipReplyText(replyTo.previewText),
        replyToSenderName: replyName,
      ),
    );
  }

  @override
  Future<void> respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  }) async {
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
  Future<void> toggleMessageLike({
    required String conversationId,
    required String messageId,
  }) async {
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            messages: [
              for (final message in chat.messages)
                if (message.id == messageId)
                  message.copyWith(
                    likes: message.isLikedBy(currentUserId)
                        ? [
                            for (final id in message.likes)
                              if (id != currentUserId) id,
                          ]
                        : [...message.likes, currentUserId],
                  )
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
