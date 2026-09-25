import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
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
  FcmPushNotificationGateway(this._firestore);

  final FirebaseFirestore _firestore;
  var _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized || !isFirebaseReady || !isPushPlatform) {
      return;
    }
    try {
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
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
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
      if (token == null || token.isEmpty) {
        return;
      }
      await _firestore.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      FirebaseMessaging.instance.onTokenRefresh.listen((value) {
        _firestore.collection('users').doc(uid).set(
          {
            'fcmToken': value,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (_) {}
  }

  @override
  Future<void> present(PushPayload payload) async {
    debugPrint('VauVau push: ${payload.title} — ${payload.body}');
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
    final data = message.data;
    return PushPayload(
      kind: PushPayload.kindFrom(data['type']?.toString()),
      title: notification?.title ?? data['title']?.toString() ?? '',
      body: notification?.body ?? data['body']?.toString() ?? '',
      dogId: data['dogId']?.toString(),
    );
  }
}

final pushNotificationGatewayProvider = Provider<PushNotificationGateway>((ref) {
  if (!isFirebaseReady || !isPushPlatform) {
    return NoopPushNotificationGateway();
  }
  return FcmPushNotificationGateway(FirebaseFirestore.instance);
});

final fcmUidProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid ?? '';
});
