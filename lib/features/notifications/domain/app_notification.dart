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

enum NotificationDay { today, yesterday, earlier }

typedef NotificationSection = ({
  NotificationDay day,
  List<AppNotification> items,
});

/// Splits [items] into Danas / Juče / Ranije by the device's calendar day
/// (newest first inside each section; empty sections are left out).
List<NotificationSection> groupNotificationsByDay(
  List<AppNotification> items,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final byDay = <NotificationDay, List<AppNotification>>{
    for (final day in NotificationDay.values) day: <AppNotification>[],
  };
  final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final item in sorted) {
    final at = item.createdAt;
    final day = !at.isBefore(today)
        ? NotificationDay.today
        : !at.isBefore(yesterday)
        ? NotificationDay.yesterday
        : NotificationDay.earlier;
    byDay[day]!.add(item);
  }
  return [
    for (final day in NotificationDay.values)
      if (byDay[day]!.isNotEmpty) (day: day, items: byDay[day]!),
  ];
}
