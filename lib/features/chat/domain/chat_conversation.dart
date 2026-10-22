import 'chat_message.dart';
import 'chat_room.dart';

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.dogId,
    required this.dogName,
    required this.ownerName,
    required this.breed,
    required this.location,
    required this.photoUrl,
    required this.messages,
    required this.lastActivityAt,
    this.participantIds = const [],
    this.dogIds = const [],
    this.peerUserId = '',
    this.isNewMatch = false,
    this.unreadCount = 0,
    this.lastMessagePreview = '',
    this.peerUnreadCount,
  });

  final String id;
  final String dogId;
  final String dogName;
  final String ownerName;
  final String breed;
  final String location;
  final String photoUrl;
  final List<String> participantIds;
  final List<String> dogIds;
  final String peerUserId;
  final List<ChatMessage> messages;
  final DateTime lastActivityAt;
  final bool isNewMatch;
  final int unreadCount;

  /// From the room document (`lastMessage`) — used when messages are not hydrated.
  final String lastMessagePreview;

  /// Messages the peer has not read yet (`unreadByUser[peer]`); null when
  /// unknown (older rooms, local data). 0 = the peer saw everything I sent.
  final int? peerUnreadCount;

  /// "Viđeno" for my latest message: it is the newest one, it is saved on
  /// the server (not an optimistic local copy) and the peer has read it.
  bool get lastMessageSeenByPeer {
    if (peerUnreadCount != 0 || messages.isEmpty) {
      return false;
    }
    final last = messages.last;
    return last.isMine &&
        !last.id.startsWith('local-') &&
        !lastActivityAt.isBefore(last.sentAt);
  }

  String get title => '$dogName ($ownerName)';

  ChatRoom get room => ChatRoom(
        id: id,
        participantIds: participantIds,
        dogIds: dogIds.isEmpty ? [dogId] : dogIds,
        lastMessage: lastSnippet,
        lastMessageTimestamp: lastActivityAt,
        unreadCount: unreadCount,
      );

  String get lastSnippet {
    if (messages.isNotEmpty) {
      final last = messages.last;
      if (last.isWalkInvite) {
        return last.walkLocationName == null || last.walkLocationName!.isEmpty
            ? last.text
            : last.text;
      }
      return last.previewText;
    }
    return lastMessagePreview;
  }

  ChatConversation copyWith({
    List<String>? participantIds,
    List<String>? dogIds,
    String? peerUserId,
    List<ChatMessage>? messages,
    DateTime? lastActivityAt,
    bool? isNewMatch,
    int? unreadCount,
    String? lastMessagePreview,
    int? peerUnreadCount,
  }) {
    return ChatConversation(
      id: id,
      dogId: dogId,
      dogName: dogName,
      ownerName: ownerName,
      breed: breed,
      location: location,
      photoUrl: photoUrl,
      participantIds: participantIds ?? this.participantIds,
      dogIds: dogIds ?? this.dogIds,
      peerUserId: peerUserId ?? this.peerUserId,
      messages: messages ?? this.messages,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isNewMatch: isNewMatch ?? this.isNewMatch,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      peerUnreadCount: peerUnreadCount ?? this.peerUnreadCount,
    );
  }
}
