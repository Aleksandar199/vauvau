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
    this.senderName = '',
    this.senderAvatarUrl = '',
    this.imageUrl = '',
    this.isRead = false,
    this.type = ChatMessageType.text,
    this.status,
    this.walkTime,
    this.walkLocationName,
    this.replyToMessageId = '',
    this.replyToText = '',
    this.replyToSenderName = '',
    this.likes = const [],
    this.storyId = '',
    this.storyAuthorId = '',
    this.storyCaption = '',
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final String imageUrl;
  final DateTime sentAt;
  final bool isRead;
  final bool isMine;
  final ChatMessageType type;
  final WalkInviteStatus? status;
  final DateTime? walkTime;
  final String? walkLocationName;
  final String replyToMessageId;
  final String replyToText;
  final String replyToSenderName;

  /// User ids that liked this message.
  final List<String> likes;

  /// Set when the message replies to a story (see StoryReference).
  final String storyId;
  final String storyAuthorId;
  final String storyCaption;

  bool get isStoryReply => storyId.isNotEmpty;

  DateTime get timestamp => sentAt;

  bool get hasImage => imageUrl.trim().isNotEmpty;

  bool get hasReply =>
      replyToMessageId.isNotEmpty || replyToText.trim().isNotEmpty;

  int get likeCount => likes.length;

  bool isLikedBy(String uid) =>
      uid.isNotEmpty && likes.contains(uid);

  /// Inbox / reply preview when the body is a photo with no caption.
  String get previewText {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    if (hasImage) {
      return '📷 Fotografija';
    }
    return '';
  }

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
    String? senderAvatarUrl,
    String? imageUrl,
    List<String>? likes,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      text: text,
      imageUrl: imageUrl ?? this.imageUrl,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      isMine: isMine,
      type: type,
      status: status ?? this.status,
      walkTime: walkTime,
      walkLocationName: walkLocationName,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      likes: likes ?? this.likes,
      storyId: storyId,
      storyAuthorId: storyAuthorId,
      storyCaption: storyCaption,
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

  static String clipReplyText(String raw, [int max = 120]) {
    final text = raw.trim();
    if (text.length <= max) {
      return text;
    }
    return '${text.substring(0, max).trimRight()}…';
  }

  static List<String> likesFrom(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item != null && '$item'.trim().isNotEmpty) '$item',
    ];
  }
}
