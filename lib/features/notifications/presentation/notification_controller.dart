import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_notifications.dart';
import '../domain/app_notification.dart';

class NotificationController extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    return seedNotifications(DateTime.now());
  }

  int get unreadCount => state.where((item) => !item.isRead).length;

  void markRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  void markAllRead() {
    state = [for (final item in state) item.copyWith(isRead: true)];
  }
}

final notificationControllerProvider =
    NotifierProvider<NotificationController, List<AppNotification>>(
  NotificationController.new,
);

final notificationUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationControllerProvider).where((item) => !item.isRead).length;
});
