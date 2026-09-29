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

  int get displayMemberCount =>
      memberCount >= memberIds.length ? memberCount : memberIds.length;

  bool isMember(String uid) => uid.isNotEmpty && memberIds.contains(uid);

  BreedGroup copyWith({
    List<String>? memberIds,
    int? memberCount,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return BreedGroup(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      sortOrder: sortOrder,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
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
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final String imageUrl;
  final DateTime createdAt;
  final bool isMine;

  bool get hasImage => imageUrl.trim().isNotEmpty;

  String get preview {
    if (text.trim().isNotEmpty) {
      return text.trim();
    }
    if (hasImage) {
      return '📷 Fotografija';
    }
    return '';
  }
}

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

  Stream<List<GroupMessage>> watchMessages(String groupId);

  Stream<DateTime?> watchLastRead(String groupId);

  Future<void> joinGroup(String groupId);

  Future<void> markRead(String groupId);

  Future<void> sendMessage({
    required String groupId,
    required String text,
    String imageUrl = '',
  });

  Future<void> sendPhoto({
    required String groupId,
    required String imageUrl,
  });
}
