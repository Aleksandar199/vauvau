import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/app_notification.dart';

class NotificationController extends Notifier<List<AppNotification>> {
  List<AppNotification> _local = const [];
  List<AppNotification> _remote = const [];

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('notifications');

  @override
  List<AppNotification> build() {
    final uid = ref.watch(
      authStateProvider.select((auth) => auth.asData?.value?.uid ?? ''),
    );
    final authReady =
        ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
    _remote = const [];
    _local = const [];
    if (!isFirebaseReady || uid.isEmpty || !authReady) {
      return const [];
    }
    final sub = FirestoreAuthGuard.guardedStream<List<AppNotification>>(
      label: 'notifications',
      empty: const [],
      create: () => _collection
          .where('toUserId', isEqualTo: uid)
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => [for (final doc in snapshot.docs) _fromDoc(doc)],
          ),
    ).listen((remote) {
      _remote = remote;
      state = _merged();
    });
    ref.onDispose(sub.cancel);
    return const [];
  }

  AppNotification _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final created = data['timestamp'] ?? data['createdAt'];
    return AppNotification(
      id: doc.id,
      kind: _kindFromKey(
        data['type'] as String? ?? data['kind'] as String?,
      ),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? data['message'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      dogId: _string(data['senderDogId']) ??
          _string(data['fromDogId']) ??
          _string(data['dogId']) ??
          _string(data['toDogId']),
      fromUserId: _string(data['fromUserId']) ??
          _string(data['senderUserId']) ??
          _string(data['senderId']) ??
          _string(data['peerUserId']),
      conversationId: _string(data['conversationId']) ??
          _string(data['chatId']) ??
          _string(data['matchId']),
      groupId: _string(data['groupId']),
      eventId: _string(data['eventId']),
    );
  }

  String? _string(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  NotificationKind _kindFromKey(String? key) {
    switch (key) {
      case 'match':
        return NotificationKind.match;
      case 'walk':
        return NotificationKind.walkRequest;
      case 'message':
        return NotificationKind.chatMessage;
      case 'group':
        return NotificationKind.groupMessage;
      case 'event':
        return NotificationKind.eventMessage;
      case 'SUPER_LIKE':
      case 'superLike':
      case 'super_like':
        return NotificationKind.superLike;
      case 'like':
        return NotificationKind.like;
      default:
        return NotificationKind.like;
    }
  }

  List<AppNotification> _merged() {
    return [..._local, ..._remote]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void addWalkRequest({required String dogName, required String ownerName}) {
    prepend(
      AppNotification(
        id: 'walk-${DateTime.now().microsecondsSinceEpoch}',
        kind: NotificationKind.walkRequest,
        title: 'Zahtev za šetnju',
        body: 'Poziv za šetnju sa $dogName je poslat vlasniku $ownerName.',
        createdAt: DateTime.now(),
      ),
    );
  }

  void prepend(AppNotification item) {
    _local = [item, ..._local];
    state = _merged();
  }

  void markRead(String id) {
    AppNotification? matched;
    for (final item in [..._local, ..._remote]) {
      if (item.id == id) {
        matched = item;
        break;
      }
    }
    final isRemote = _remote.any((item) => item.id == id);
    _local = [
      for (final item in _local)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    _remote = [
      for (final item in _remote)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    state = _merged();
    if (isRemote) {
      unawaited(
        _collection.doc(id).update({'isRead': true}).catchError(
          (Object error) => debugPrint('Obaveštenje nije označeno: $error'),
        ),
      );
    }
    // Clear the OS pull-down shade entry for this notification.
    unawaited(
      ref.read(notificationServiceProvider).dismissTrayAlerts(
            conversationId: matched?.conversationId,
            groupId: matched?.groupId,
            eventId: matched?.eventId,
            allAlerts: matched == null ||
                ((matched.conversationId ?? '').isEmpty &&
                    (matched.groupId ?? '').isEmpty &&
                    (matched.eventId ?? '').isEmpty),
          ),
    );
  }

  /// When the user opens a DM and reads it, drop related "new message"
  /// notifications (badge + list) — they've already seen the chat.
  void markChatMessagesRead({
    required String conversationId,
    String? peerUserId,
  }) {
    final roomId = conversationId.trim();
    final peer = (peerUserId ?? '').trim();
    if (roomId.isEmpty && peer.isEmpty) {
      return;
    }

    bool matches(AppNotification item) {
      if (item.kind != NotificationKind.chatMessage) {
        return false;
      }
      final cid = (item.conversationId ?? '').trim();
      if (roomId.isNotEmpty && cid == roomId) {
        return true;
      }
      // Older docs may lack conversationId — match by sender.
      final from = (item.fromUserId ?? '').trim();
      return peer.isNotEmpty && from == peer;
    }

    final remoteIds = [
      for (final item in _remote)
        if (matches(item)) item.id,
    ];
    final touchedLocal = _local.any(matches);
    if (remoteIds.isEmpty && !touchedLocal) {
      return;
    }

    // Remove entirely so the notifications screen doesn't show them after
    // the user already read the conversation elsewhere.
    _local = [for (final item in _local) if (!matches(item)) item];
    _remote = [for (final item in _remote) if (!matches(item)) item];
    state = _merged();

    if (remoteIds.isEmpty) {
      return;
    }
    final batch = FirebaseFirestore.instance.batch();
    for (final id in remoteIds) {
      batch.delete(_collection.doc(id));
    }
    unawaited(
      batch.commit().catchError(
        (Object error) =>
            debugPrint('Chat obaveštenja nisu obrisana: $error'),
      ),
    );
    // Drop shade entries for this chat; also clear other alert-channel
    // leftovers (legacy random ids) so pull-down doesn't keep "read" ones.
    unawaited(
      ref.read(notificationServiceProvider).dismissTrayAlerts(
            conversationId: roomId.isEmpty ? null : roomId,
            allAlerts: true,
          ),
    );
  }

  void markAllRead() {
    final unreadRemote = [
      for (final item in _remote)
        if (!item.isRead) item.id,
    ];
    _local = [for (final item in _local) item.copyWith(isRead: true)];
    _remote = [for (final item in _remote) item.copyWith(isRead: true)];
    state = _merged();
    unawaited(
      ref.read(notificationServiceProvider).dismissTrayAlerts(allAlerts: true),
    );
    if (unreadRemote.isEmpty) {
      return;
    }
    final batch = FirebaseFirestore.instance.batch();
    for (final id in unreadRemote) {
      batch.update(_collection.doc(id), {'isRead': true});
    }
    unawaited(
      batch.commit().catchError(
        (Object error) => debugPrint('Obaveštenja nisu označena: $error'),
      ),
    );
  }
}

final notificationControllerProvider =
    NotifierProvider<NotificationController, List<AppNotification>>(
  NotificationController.new,
);

final notificationUnreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationControllerProvider)
      .where((item) => !item.isRead)
      .length;
});
