import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/push_payload.dart';
import 'push_platform.dart';

abstract class PushNotificationGateway {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> syncToken(String uid);

  Future<void> present(PushPayload payload);

  Future<void> queueForUser(String userId, PushPayload payload);

  Stream<PushPayload> get foreground;

  Stream<PushPayload> get opened;

  Future<PushPayload?> consumeInitial();
}

class NoopPushNotificationGateway implements PushNotificationGateway {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> syncToken(String uid) async {}

  @override
  Future<void> present(PushPayload payload) async {}

  @override
  Future<void> queueForUser(String userId, PushPayload payload) async {}

  @override
  Stream<PushPayload> get foreground => const Stream.empty();

  @override
  Stream<PushPayload> get opened => const Stream.empty();

  @override
  Future<PushPayload?> consumeInitial() async => null;
}

class FcmPushNotificationGateway implements PushNotificationGateway {
  FcmPushNotificationGateway(
    this._firestore, {
    NotificationService? notifications,
  }) : _notifications = notifications ?? NotificationService();

  final FirebaseFirestore _firestore;
  final NotificationService _notifications;
  var _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  Future<void> initialize() async {
    if (_initialized || !isFirebaseReady || !isPushPlatform) {
      return;
    }
    try {
      await _notifications.initialize();
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _initialized = true;
    } catch (_) {}
  }

  @override
  Future<bool> requestPermission() async {
    if (!isFirebaseReady || !isPushPlatform) {
      return false;
    }
    try {
      final localGranted = await _notifications.requestPermissions();
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final fcmGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      return localGranted || fcmGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> syncToken(String uid) async {
    if (uid.isEmpty || !isFirebaseReady || !isPushPlatform) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _writeToken(uid, token);
      }
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((value) {
        unawaited(_writeToken(uid, value));
      });
    } catch (_) {}
  }

  Future<void> _writeToken(String uid, String token) {
    return _firestore.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> present(PushPayload payload) async {
    debugPrint('VauVau push: ${payload.title} — ${payload.body}');
    await _notifications.showPushAlert(
      title: payload.title,
      body: payload.body,
      data: payload.data,
    );
  }

  @override
  Future<void> queueForUser(String userId, PushPayload payload) async {
    if (userId.isEmpty || !isFirebaseReady) {
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmInbox')
          .add({
        'type': payload.typeName,
        'title': payload.title,
        'body': payload.body,
        'dogId': payload.dogId,
        'conversationId': payload.conversationId,
        'createdAt': FieldValue.serverTimestamp(),
        'data': payload.data,
      });
    } catch (_) {}
  }

  @override
  Stream<PushPayload> get foreground {
    if (!isFirebaseReady || !isPushPlatform) {
      return const Stream.empty();
    }
    try {
      return FirebaseMessaging.onMessage.map(_fromMessage);
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Stream<PushPayload> get opened {
    if (!isFirebaseReady || !isPushPlatform) {
      return const Stream.empty();
    }
    try {
      return FirebaseMessaging.onMessageOpenedApp.map(_fromMessage);
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<PushPayload?> consumeInitial() async {
    if (!isFirebaseReady || !isPushPlatform) {
      return null;
    }
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message == null) {
        return null;
      }
      return _fromMessage(message);
    } catch (_) {
      return null;
    }
  }

  PushPayload _fromMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);
    if (notification?.title != null) {
      data.putIfAbsent('title', () => notification!.title);
    }
    if (notification?.body != null) {
      data.putIfAbsent('body', () => notification!.body);
    }
    return PushPayload.fromData(data);
  }
}

PushPayload? pushPayloadFromNotificationJson(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return PushPayload.fromData(
      decoded.map((key, value) => MapEntry('$key', value)),
    );
  } catch (_) {
    return null;
  }
}

final pushNotificationGatewayProvider = Provider<PushNotificationGateway>((ref) {
  if (!isFirebaseReady || !isPushPlatform) {
    return NoopPushNotificationGateway();
  }
  return FcmPushNotificationGateway(
    FirebaseFirestore.instance,
    notifications: ref.watch(notificationServiceProvider),
  );
});

final fcmUidProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid ?? '';
});
