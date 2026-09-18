import '../domain/app_notification.dart';

List<AppNotification> seedNotifications(DateTime now) {
  return [
    AppNotification(
      id: 'n-match',
      kind: NotificationKind.match,
      title: 'Novi VauVau Match!',
      body: 'Rex i Luna žele da se upoznaju.',
      createdAt: now.subtract(const Duration(minutes: 8)),
      dogId: 'rex',
    ),
    AppNotification(
      id: 'n-walk',
      kind: NotificationKind.walkRequest,
      title: 'Zahtev za šetnju',
      body: 'Miloš te je pozvao u šetnju u Limanskom parku.',
      createdAt: now.subtract(const Duration(minutes: 25)),
    ),
    AppNotification(
      id: 'n-chat',
      kind: NotificationKind.chatMessage,
      title: 'Nova poruka',
      body: 'Nova poruka od Ane.',
      createdAt: now.subtract(const Duration(hours: 2)),
      isRead: true,
      dogId: 'maza',
    ),
  ];
}
