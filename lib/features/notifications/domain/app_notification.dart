enum NotificationKind {
  match,
  walkRequest,
  chatMessage,
  like,
  superLike,
  groupMessage,
  eventMessage,
  follow,
  storyLike,
  storyReply,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.dogId,
    this.fromUserId,
    this.conversationId,
    this.groupId,
    this.eventId,
    this.storyId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? dogId;
  final String? fromUserId;
  final String? conversationId;
  final String? groupId;
  final String? eventId;
  final String? storyId;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      dogId: dogId,
      fromUserId: fromUserId,
      conversationId: conversationId,
      groupId: groupId,
      eventId: eventId,
      storyId: storyId,
    );
  }
}
