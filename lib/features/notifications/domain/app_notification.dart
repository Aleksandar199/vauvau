enum NotificationKind { match, walkRequest, chatMessage, like, superLike }

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
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? dogId;
  final String? fromUserId;

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
    );
  }
}
