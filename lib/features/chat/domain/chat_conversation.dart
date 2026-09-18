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
    if (messages.isEmpty) {
      return '';
    }
    final last = messages.last;
    if (last.isWalkInvite) {
      return last.walkLocationName == null || last.walkLocationName!.isEmpty
          ? last.text
          : last.text;
    }
    return last.text;
  }

  ChatConversation copyWith({
    List<String>? participantIds,
    List<String>? dogIds,
    String? peerUserId,
    List<ChatMessage>? messages,
    DateTime? lastActivityAt,
    bool? isNewMatch,
    int? unreadCount,
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
    );
  }
}
