import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/push_notification_gateway.dart';
import '../domain/app_notification.dart';
import '../domain/push_payload.dart';
import 'notification_controller.dart';
import 'notification_strings.dart';
import 'push_navigation.dart';

class PushController extends Notifier<bool> {
  @override
  bool build() {
    final gateway = ref.watch(pushNotificationGatewayProvider);
    unawaited(gateway.initialize());
    final uid = ref.watch(fcmUidProvider);
    if (uid.isNotEmpty) {
      unawaited(gateway.syncToken(uid));
    }

    final notifications = ref.read(notificationServiceProvider);
    notifications.onNotificationTap = (raw) {
      final payload = pushPayloadFromNotificationJson(raw);
      if (payload != null) {
        unawaited(_handleOpened(payload));
      }
    };

    final foreground = gateway.foreground.listen(_handleForeground);
    final opened = gateway.opened.listen((payload) {
      unawaited(_handleOpened(payload));
    });
    ref.onDispose(foreground.cancel);
    ref.onDispose(opened.cancel);
    ref.onDispose(() => notifications.onNotificationTap = null);
    unawaited(_ingestInitial(gateway));
    return false;
  }

  PushNotificationGateway get _gateway =>
      ref.read(pushNotificationGatewayProvider);

  Future<bool> requestPermission() async {
    final granted = await _gateway.requestPermission();
    state = granted;
    final uid = ref.read(fcmUidProvider);
    if (granted && uid.isNotEmpty) {
      await _gateway.syncToken(uid);
    }
    return granted;
  }

  Future<void> notifyMatch({
    required String dogName,
    required String ownerName,
    String? dogId,
    String? peerUserId,
  }) {
    return _dispatch(
      PushPayload(
        kind: PushKind.match,
        title: NotificationStrings.pushMatchTitle,
        body: NotificationStrings.pushMatchBody(dogName, ownerName),
        dogId: dogId,
        peerUserId: peerUserId,
      ),
    );
  }

  Future<void> notifyMessage({
    required String senderName,
    required String preview,
    String? dogId,
    String? peerUserId,
    String? conversationId,
  }) {
    return _dispatch(
      PushPayload(
        kind: PushKind.message,
        title: NotificationStrings.pushMessageTitle,
        body: NotificationStrings.pushMessageBody(senderName, preview),
        dogId: dogId,
        peerUserId: peerUserId,
        conversationId: conversationId,
      ),
      local: false,
    );
  }

  Future<void> notifyGroupThread({
    required String groupTitle,
    required int count,
  }) {
    return _dispatch(
      PushPayload(
        kind: PushKind.message,
        title: groupTitle,
        body: NotificationStrings.pushGroupAlert(groupTitle, count),
      ),
    );
  }

  Future<void> notifyWalk({
    required String dogName,
    required String ownerName,
    String? dogId,
    String? peerUserId,
  }) {
    return _dispatch(
      PushPayload(
        kind: PushKind.walk,
        title: NotificationStrings.pushWalkTitle,
        body: NotificationStrings.pushWalkBody(dogName, ownerName),
        dogId: dogId,
        peerUserId: peerUserId,
      ),
    );
  }

  bool _isEnabled(PushKind kind) {
    final settings = ref.read(appSettingsProvider);
    return switch (kind) {
      PushKind.match => settings.notifyNewMatches,
      PushKind.message => settings.notifyMessages,
      PushKind.walk => settings.notifyWalkRequests,
    };
  }

  Future<void> _dispatch(PushPayload payload, {bool local = true}) async {
    if (_isEnabled(payload.kind)) {
      if (local) {
        _ingest(payload);
      }
      await _gateway.present(payload);
    }
    final peer = payload.peerUserId;
    if (peer != null && peer.isNotEmpty) {
      await _gateway.queueForUser(peer, payload);
    }
  }

  Future<void> _ingestInitial(PushNotificationGateway gateway) async {
    final payload = await gateway.consumeInitial();
    if (payload != null) {
      await _handleOpened(payload);
    }
  }

  Future<void> _handleForeground(PushPayload payload) async {
    if (!_isEnabled(payload.kind)) {
      return;
    }
    _ingest(payload);
    await _gateway.present(payload);
  }

  Future<void> _handleOpened(PushPayload payload) async {
    _ingest(payload);
    await openPushDestination(ref, payload);
  }

  void _ingest(PushPayload payload) {
    if (payload.title.isEmpty && payload.body.isEmpty) {
      return;
    }
    ref.read(notificationControllerProvider.notifier).prepend(
          AppNotification(
            id: 'push-${payload.kind.name}-${DateTime.now().microsecondsSinceEpoch}',
            kind: switch (payload.kind) {
              PushKind.match => NotificationKind.match,
              PushKind.message => NotificationKind.chatMessage,
              PushKind.walk => NotificationKind.walkRequest,
            },
            title: payload.title,
            body: payload.body,
            createdAt: DateTime.now(),
            dogId: payload.dogId,
            fromUserId: payload.peerUserId,
          ),
        );
  }
}

final pushControllerProvider =
    NotifierProvider<PushController, bool>(PushController.new);
