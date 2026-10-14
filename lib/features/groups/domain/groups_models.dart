class BreedGroup {
  const BreedGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.memberIds,
    required this.memberCount,
    this.sortOrder = 0,
    this.lastMessage = '',
    this.lastMessageAt,
    this.isApproved = true,
    this.createdBy = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> memberIds;
  final int memberCount;
  final int sortOrder;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final bool isApproved;
  final String createdBy;
  final DateTime? createdAt;

  int get displayMemberCount =>
      memberCount >= memberIds.length ? memberCount : memberIds.length;

  bool isMember(String uid) => uid.isNotEmpty && memberIds.contains(uid);

  /// Safe Firestore/document map parser — returns null on malformed data.
  static BreedGroup? tryFromMap(String id, Map<String, dynamic>? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final memberIds = <String>[
        for (final value in _asList(raw['memberIds']))
          if (value is String && value.isNotEmpty) value,
      ];
      final memberCount = _asInt(raw['memberCount']) ??
          _asInt(raw['membersCount']) ??
          memberIds.length;
      final isApproved = raw['isApproved'];
      return BreedGroup(
        id: id,
        title: raw['title'] as String? ?? '',
        description: raw['description'] as String? ?? '',
        imageUrl: raw['imageUrl'] as String? ?? '',
        memberIds: memberIds,
        memberCount: memberCount,
        sortOrder: _asInt(raw['sortOrder']) ?? 0,
        lastMessage: raw['lastMessage'] as String? ?? '',
        lastMessageAt: _asDateTime(raw['lastMessageAt']),
        isApproved: isApproved is bool ? isApproved : true,
        createdBy: raw['createdBy'] as String? ?? '',
        createdAt: _asDateTime(raw['createdAt']),
      );
    } catch (_) {
      return null;
    }
  }

  static List<Object?> _asList(Object? value) {
    if (value is List) {
      return List<Object?>.from(value);
    }
    return const [];
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    // Timestamp is handled by callers that convert first; duck-type via toDate.
    try {
      final dynamic dynamicValue = value;
      if (dynamicValue != null && dynamicValue.toDate is Function) {
        final date = dynamicValue.toDate();
        if (date is DateTime) {
          return date;
        }
      }
    } catch (_) {}
    return null;
  }

  BreedGroup copyWith({
    List<String>? memberIds,
    int? memberCount,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? isApproved,
    String? createdBy,
    String? title,
    String? description,
    String? imageUrl,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return BreedGroup(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      sortOrder: sortOrder ?? this.sortOrder,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isApproved: isApproved ?? this.isApproved,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.isMine,
    this.replyToMessageId = '',
    this.replyToText = '',
    this.replyToSenderName = '',
    this.type = GroupMessageType.text,
    this.status,
    this.walkTime,
    this.walkLocationName,
    this.acceptedByUserIds = const [],
    this.declinedByUserIds = const [],
    this.likes = const [],
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final String imageUrl;
  final DateTime createdAt;
  final bool isMine;
  final String replyToMessageId;
  final String replyToText;
  final String replyToSenderName;
  final GroupMessageType type;
  final GroupWalkInviteStatus? status;
  final DateTime? walkTime;
  final String? walkLocationName;
  /// User ids that accepted this group walk invite (updates live on the message).
  final List<String> acceptedByUserIds;
  final List<String> declinedByUserIds;

  /// User ids that liked this message.
  final List<String> likes;

  int get likeCount => likes.length;

  bool isLikedBy(String uid) =>
      uid.isNotEmpty && likes.contains(uid);

  bool get hasImage => imageUrl.trim().isNotEmpty;

  bool get isWalkInvite => type == GroupMessageType.walkInvite;

  int get acceptedCount => acceptedByUserIds.length;

  bool get hasReply =>
      replyToMessageId.isNotEmpty || replyToText.trim().isNotEmpty;

  bool hasUserResponded(String userId) {
    if (userId.isEmpty) {
      return false;
    }
    return acceptedByUserIds.contains(userId) ||
        declinedByUserIds.contains(userId);
  }

  String get preview {
    if (isWalkInvite) {
      final place = (walkLocationName ?? '').trim();
      return place.isEmpty ? 'Poziv na šetnju' : 'Poziv na šetnju: $place';
    }
    if (text.trim().isNotEmpty) {
      return text.trim();
    }
    if (hasImage) {
      return '📷 Fotografija';
    }
    return '';
  }

  GroupMessage copyWith({
    GroupWalkInviteStatus? status,
    List<String>? acceptedByUserIds,
    List<String>? declinedByUserIds,
    List<String>? likes,
  }) {
    return GroupMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: text,
      imageUrl: imageUrl,
      createdAt: createdAt,
      isMine: isMine,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      type: type,
      status: status ?? this.status,
      walkTime: walkTime,
      walkLocationName: walkLocationName,
      acceptedByUserIds: acceptedByUserIds ?? this.acceptedByUserIds,
      declinedByUserIds: declinedByUserIds ?? this.declinedByUserIds,
      likes: likes ?? this.likes,
    );
  }
}

enum GroupMessageType { text, walkInvite }

enum GroupWalkInviteStatus { pending, accepted, declined }

class GroupInboxThread {
  const GroupInboxThread({
    required this.group,
    required this.lastMessage,
    required this.lastActivityAt,
    required this.unreadCount,
  });

  final BreedGroup group;
  final String lastMessage;
  final DateTime lastActivityAt;
  final int unreadCount;

  static GroupInboxThread fromMessages({
    required BreedGroup group,
    required List<GroupMessage> messages,
    DateTime? lastRead,
  }) {
    final last = messages.isEmpty ? null : messages.last;
    final cutoff = lastRead ?? DateTime.now();
    var unread = 0;
    for (final message in messages) {
      if (!message.isMine && message.createdAt.isAfter(cutoff)) {
        unread++;
      }
    }
    return GroupInboxThread(
      group: group,
      lastMessage: last?.preview ?? group.lastMessage,
      lastActivityAt: last?.createdAt ??
          group.lastMessageAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      unreadCount: unread,
    );
  }
}

abstract class GroupsRepository {
  Stream<List<BreedGroup>> watchGroups();

  Stream<List<BreedGroup>> watchPendingGroups();

  Stream<List<GroupMessage>> watchMessages(String groupId);

  Stream<DateTime?> watchLastRead(String groupId);

  Future<void> joinGroup(String groupId);

  Future<void> markRead(String groupId);

  Future<BreedGroup> createGroup({
    required String title,
    required String description,
    bool approveImmediately = false,
  });

  Future<void> approveGroup(String groupId);

  Future<void> deleteGroup(String groupId);

  Future<void> sendMessage({
    required String groupId,
    required String text,
    String imageUrl = '',
    GroupMessage? replyTo,
  });

  Future<void> sendPhoto({
    required String groupId,
    required String imageUrl,
    GroupMessage? replyTo,
  });

  Future<void> sendWalkInvite({
    required String groupId,
    required DateTime walkTime,
    required String walkLocationName,
  });

  Future<void> respondToWalkInvite({
    required String groupId,
    required String messageId,
    required GroupWalkInviteStatus status,
  });

  Future<void> toggleMessageLike({
    required String groupId,
    required String messageId,
  });
}
