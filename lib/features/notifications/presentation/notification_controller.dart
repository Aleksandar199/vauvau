import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/mock_notifications.dart';
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
    _remote = const [];
    if (!isFirebaseReady) {
      _local = seedNotifications(DateTime.now());
      return _local;
    }
    _local = const [];
    if (uid.isNotEmpty) {
      final sub = _collection
          .where('toUserId', isEqualTo: uid)
          .limit(100)
          .snapshots()
          .listen(
        (snapshot) {
          _remote = [for (final doc in snapshot.docs) _fromDoc(doc)];
          state = _merged();
        },
        onError: (Object error) => debugPrint('Obaveštenja: $error'),
      );
      ref.onDispose(sub.cancel);
    }
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
      dogId: data['senderDogId'] as String? ??
          data['fromDogId'] as String? ??
          data['dogId'] as String? ??
          data['toDogId'] as String?,
      fromUserId: data['fromUserId'] as String? ??
          data['senderUserId'] as String?,
    );
  }

  NotificationKind _kindFromKey(String? key) {
    switch (key) {
      case 'match':
        return NotificationKind.match;
      case 'walk':
        return NotificationKind.walkRequest;
      case 'message':
        return NotificationKind.chatMessage;
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
  }

  void markAllRead() {
    final unreadRemote = [
      for (final item in _remote)
        if (!item.isRead) item.id,
    ];
    _local = [for (final item in _local) item.copyWith(isRead: true)];
    _remote = [for (final item in _remote) item.copyWith(isRead: true)];
    state = _merged();
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
  return ref.watch(notificationControllerProvider).where((item) => !item.isRead).length;
});