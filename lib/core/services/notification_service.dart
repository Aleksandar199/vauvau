import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the local reminders used by the dog health record.
///
/// Every method is a no-op on platforms without a local notification
/// implementation (web, desktop, widget tests), so callers never have to guard.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Reminders always fire at 09:00 local time on the due date.
  static const int reminderHour = 9;

  static const String channelId = 'vauvau_health';
  static const String channelName = 'Zdravlje i podsetnici';
  static const String channelDescription =
      'Podsetnici za vakcine i zaštitu od parazita.';

  final FlutterLocalNotificationsPlugin _plugin;
  var _initialized = false;

  bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized || !isSupported) {
      return;
    }
    try {
      ensureTimeZonesReady();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (error) {
      debugPrint('Notification timezone fallback: $error');
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (error, stack) {
      debugPrint('Notification init failed: $error');
      debugPrint('$stack');
    }
  }

  /// Asks for the Android 13+ notification permission and the iOS alert
  /// permission. Returns false when the platform has no local notifications.
  Future<bool> requestPermissions() async {
    if (!isSupported) {
      return false;
    }
    await initialize();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } catch (error) {
      debugPrint('Notification permission failed: $error');
      return false;
    }
  }

  /// Schedules a reminder at 09:00 on the day of [scheduledDate].
  ///
  /// Returns false when the platform is unsupported or the resulting time has
  /// already passed, in which case nothing is scheduled.
  Future<bool> scheduleHealthReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!isSupported) {
      return false;
    }
    await initialize();
    if (!_initialized) {
      return false;
    }
    final when = reminderInstant(scheduledDate);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) {
      return false;
    }
    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: when,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      return true;
    } catch (error, stack) {
      debugPrint('Notification schedule failed: $error');
      debugPrint('$stack');
      return false;
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    if (!isSupported) {
      return;
    }
    try {
      await _plugin.cancel(id: notificationId);
    } catch (error) {
      debugPrint('Notification cancel failed: $error');
    }
  }

  /// Loads the tz database if needed. `tz.local` throws before the database is
  /// initialized, and `initializeTimeZones` defaults the local zone to UTC.
  static void ensureTimeZonesReady() {
    if (!tz.timeZoneDatabase.isInitialized) {
      tz_data.initializeTimeZones();
    }
  }

  static tz.TZDateTime reminderInstant(DateTime date) {
    ensureTimeZonesReady();
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      reminderHour,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
