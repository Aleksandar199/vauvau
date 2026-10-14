import '../domain/app_notification.dart';

/// Kept for offline/dev fallbacks — production inbox is Firestore-only.
List<AppNotification> seedNotifications(DateTime now) => const [];
