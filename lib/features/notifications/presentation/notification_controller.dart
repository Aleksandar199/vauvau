import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../chat/presentation/open_chats.dart';
import '../data/conversation_notifications.dart';
import '../data/social_notifications.dart';
import '../domain/app_notification.dart';

class NotificationController extends Notifier<List<AppNotification>> {
  List<AppNotification> _local = const [];
  List<AppNotification> _remote = const [];
  String _uid = '';

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
    _uid = uid;
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
      _readArrivalsForOpenChats();
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
      storyId: _string(data['storyId']),
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
      case SocialNotificationType.follow:
        return NotificationKind.follow;
      case SocialNotificationType.storyLike:
        return NotificationKind.storyLike;
      case SocialNotificationType.storyReply:
        return NotificationKind.storyReply;
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

  /// The user opened and read a 1:1 chat: its notifications (old "new
  /// message" docs, walk invites…) become read in the list, in Firestore and
  /// in the phone tray.
  ///
  /// Previously this only touched `chatMessage` docs already in [_remote]
  /// and deleted them; walk invites and docs that arrived a moment later
  /// (e.g. when the chat was opened straight from a push) stayed unread.
  void markChatMessagesRead({
    required String conversationId,
    String? peerUserId,
  }) {
    final roomId = conversationId.trim();
    final peer = (peerUserId ?? '').trim();
    if (roomId.isEmpty && peer.isEmpty) {
      return;
    }

    bool matches(AppNotification item) => notificationBelongsToChat(
          item,
          conversationId: roomId,
          peerUserId: peer,
        );

    final remoteIds = [
      for (final item in _remote)
        if (!item.isRead && matches(item)) item.id,
    ];
    if (_local.any((item) => !item.isRead && matches(item)) ||
        remoteIds.isNotEmpty) {
      _local = [
        for (final item in _local)
          if (matches(item)) item.copyWith(isRead: true) else item,
      ];
      _remote = [
        for (final item in _remote)
          if (matches(item)) item.copyWith(isRead: true) else item,
      ];
      state = _merged();
    }

    if (isFirebaseReady && _uid.isNotEmpty) {
      unawaited(
        markConversationNotificationsRead(
          FirebaseFirestore.instance,
          uid: _uid,
          conversationId: roomId,
          alsoIds: remoteIds,
        ).catchError((Object error) {
          debugPrint('Chat obaveštenja nisu označena: $error');
          return const <String>[];
        }),
      );
    }
    // Only this chat's tray entries; other chats' alerts stay.
    unawaited(
      ref.read(notificationServiceProvider).dismissTrayAlerts(
            conversationId: roomId.isEmpty ? null : roomId,
          ),
    );
  }

  /// Notifications that arrive for a chat the user is looking at right now
  /// are read on arrival.
  void _readArrivalsForOpenChats() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return;
    }
    final open = ref.read(openChatsProvider);
    if (open.isEmpty) {
      return;
    }
    final rooms = <String>{
      for (final item in _remote)
        if (!item.isRead && open.contains(item.conversationId))
          item.conversationId!,
    };
    for (final roomId in rooms) {
      markChatMessagesRead(conversationId: roomId);
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
