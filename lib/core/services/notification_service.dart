import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationTapHandler = void Function(String? payload);

/// Schedules health reminders and presents FCM alerts while the app is open.
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

  static const String alertsChannelId = 'vauvau_alerts';
  static const String alertsChannelName = 'VauVau obaveštenja';
  static const String alertsChannelDescription =
      'Mečevi, poruke i zahtevi za šetnju.';

  final FlutterLocalNotificationsPlugin _plugin;
  var _initialized = false;
  NotificationTapHandler? onNotificationTap;

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
        onDidReceiveNotificationResponse: (response) {
          onNotificationTap?.call(response.payload);
        },
      );
      await _ensureAlertsChannel();
      _initialized = true;
    } catch (error, stack) {
      debugPrint('Notification init failed: $error');
      debugPrint('$stack');
    }
  }

  Future<void> _ensureAlertsChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        alertsChannelId,
        alertsChannelName,
        description: alertsChannelDescription,
        importance: Importance.high,
      ),
    );
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

  /// Stable id so we can dismiss the tray entry when the user reads in-app.
  static int alertIdFor(Map<String, String>? data) {
    final key = (data?['conversationId'] ??
            data?['chatId'] ??
            data?['groupId'] ??
            data?['eventId'] ??
            data?['type'] ??
            'alert')
        .trim();
    return key.hashCode & 0x7fffffff;
  }

  static String alertTagFor(Map<String, String>? data) {
    final type = (data?['type'] ?? 'alert').trim();
    final id = (data?['conversationId'] ??
            data?['chatId'] ??
            data?['groupId'] ??
            data?['eventId'] ??
            '')
        .trim();
    if (id.isNotEmpty) {
      return 'vauvau_${type}_$id';
    }
    return 'vauvau_$type';
  }

  /// Shows an immediate heads-up notification for a foreground FCM message.
  Future<void> showPushAlert({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (!isSupported || (title.isEmpty && body.isEmpty)) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }
    final payload = data == null || data.isEmpty ? null : jsonEncode(data);
    final tag = alertTagFor(data);
    try {
      await _plugin.show(
        id: alertIdFor(data),
        title: title.isEmpty ? 'VauVau' : title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            alertsChannelId,
            alertsChannelName,
            channelDescription: alertsChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            tag: tag,
            groupKey: 'vauvau_alerts_group',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (error, stack) {
      debugPrint('Push alert failed: $error');
      debugPrint('$stack');
    }
  }

  /// Clears matching entries from the OS notification shade (pull-down tray).
  Future<void> dismissTrayAlerts({
    String? conversationId,
    String? groupId,
    String? eventId,
    bool allAlerts = false,
  }) async {
    if (!isSupported) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }
    try {
      if (conversationId != null && conversationId.trim().isNotEmpty) {
        final id = conversationId.trim();
        final data = {'type': 'message', 'conversationId': id};
        await _plugin.cancel(id: alertIdFor(data), tag: alertTagFor(data));
        await _plugin.cancel(id: alertIdFor(data));
      }
      if (groupId != null && groupId.trim().isNotEmpty) {
        final id = groupId.trim();
        final data = {'type': 'group', 'groupId': id};
        await _plugin.cancel(id: alertIdFor(data), tag: alertTagFor(data));
      }
      if (eventId != null && eventId.trim().isNotEmpty) {
        final id = eventId.trim();
        final data = {'type': 'event', 'eventId': id};
        await _plugin.cancel(id: alertIdFor(data), tag: alertTagFor(data));
      }

      // Also sweep active tray items on the alerts channel (covers older
      // random-id notifications and FCM-presented ones we can see).
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final active = await android?.getActiveNotifications() ?? const [];
        for (final item in active) {
          final channel = item.channelId ?? '';
          final tag = item.tag ?? '';
          final nid = item.id;
          if (nid == null) {
            continue;
          }
          if (channel.isNotEmpty && channel != alertsChannelId) {
            continue;
          }
          if (allAlerts) {
            await _plugin.cancel(id: nid, tag: tag.isEmpty ? null : tag);
            continue;
          }
          final conv = conversationId?.trim() ?? '';
          final group = groupId?.trim() ?? '';
          final event = eventId?.trim() ?? '';
          final matchConv = conv.isNotEmpty && tag.contains(conv);
          final matchGroup = group.isNotEmpty && tag.contains(group);
          final matchEvent = event.isNotEmpty && tag.contains(event);
          if (matchConv || matchGroup || matchEvent) {
            await _plugin.cancel(id: nid, tag: tag.isEmpty ? null : tag);
          }
        }
      }
    } catch (error) {
      debugPrint('Dismiss tray alerts failed: $error');
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
