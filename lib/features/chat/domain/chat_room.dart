class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.participantIds,
    required this.dogIds,
    this.lastMessage = '',
    this.lastMessageTimestamp,
    this.unreadCount = 0,
  });

  final String id;
  final List<String> participantIds;
  final List<String> dogIds;
  final String lastMessage;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;

  ChatRoom copyWith({
    List<String>? participantIds,
    List<String>? dogIds,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id,
      participantIds: participantIds ?? this.participantIds,
      dogIds: dogIds ?? this.dogIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
