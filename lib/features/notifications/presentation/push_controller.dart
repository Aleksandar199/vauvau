import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/profile_controller.dart';
import '../data/push_notification_gateway.dart';
import '../domain/app_notification.dart';
import '../domain/push_payload.dart';
import 'notification_controller.dart';
import 'notification_strings.dart';

class PushController extends Notifier<bool> {
  @override
  bool build() {
    final gateway = ref.watch(pushNotificationGatewayProvider);
    unawaited(gateway.initialize());
    final uid = ref.watch(fcmUidProvider);
    if (uid.isNotEmpty) {
      unawaited(gateway.syncToken(uid));
    }
    final foreground = gateway.foreground.listen(_ingest);
    final opened = gateway.opened.listen(_ingest);
    ref.onDispose(foreground.cancel);
    ref.onDispose(opened.cancel);
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
  }) {
    return _dispatch(
      PushPayload(
        kind: PushKind.message,
        title: NotificationStrings.pushMessageTitle,
        body: NotificationStrings.pushMessageBody(senderName, preview),
        dogId: dogId,
        peerUserId: peerUserId,
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

  Future<void> _dispatch(PushPayload payload, {bool local = true}) async {
    final settings = ref.read(appSettingsProvider);
    final enabled = switch (payload.kind) {
      PushKind.match => settings.notifyNewMatches,
      PushKind.message => settings.notifyMessages,
      PushKind.walk => settings.notifyWalkRequests,
    };
    if (!enabled) {
      return;
    }
    if (local) {
      _ingest(payload);
    }
    await _gateway.present(payload);
    final peer = payload.peerUserId;
    if (peer != null && peer.isNotEmpty) {
      await _gateway.queueForUser(peer, payload);
    }
  }

  Future<void> _ingestInitial(PushNotificationGateway gateway) async {
    final payload = await gateway.consumeInitial();
    if (payload != null) {
      _ingest(payload);
    }
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
          ),
        );
  }
}

final pushControllerProvider =
    NotifierProvider<PushController, bool>(PushController.new);
