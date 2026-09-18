enum ChatMessageType {
  text,
  walkInvite,
  locationPin,
}

enum WalkInviteStatus { pending, accepted, declined }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.senderId = '',
    this.receiverId = '',
    this.isRead = false,
    this.type = ChatMessageType.text,
    this.status,
    this.walkTime,
    this.walkLocationName,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final bool isMine;
  final ChatMessageType type;
  final WalkInviteStatus? status;
  final DateTime? walkTime;
  final String? walkLocationName;

  DateTime get timestamp => sentAt;

  String get typeKey => switch (type) {
        ChatMessageType.text => 'text',
        ChatMessageType.walkInvite => 'walk_invite',
        ChatMessageType.locationPin => 'location_pin',
      };

  String? get statusKey => switch (status) {
        WalkInviteStatus.pending => 'pending',
        WalkInviteStatus.accepted => 'accepted',
        WalkInviteStatus.declined => 'declined',
        null => null,
      };

  bool get isWalkInvite => type == ChatMessageType.walkInvite;

  bool get isLocationPin => type == ChatMessageType.locationPin;

  ChatMessage copyWith({
    bool? isRead,
    WalkInviteStatus? status,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      isMine: isMine,
      type: type,
      status: status ?? this.status,
      walkTime: walkTime,
      walkLocationName: walkLocationName,
    );
  }

  static ChatMessageType typeFromKey(String? value) {
    return switch (value) {
      'walk_invite' => ChatMessageType.walkInvite,
      'location_pin' => ChatMessageType.locationPin,
      _ => ChatMessageType.text,
    };
  }

  static WalkInviteStatus? statusFromKey(String? value) {
    return switch (value) {
      'pending' => WalkInviteStatus.pending,
      'accepted' => WalkInviteStatus.accepted,
      'declined' => WalkInviteStatus.declined,
      _ => null,
    };
  }
}
