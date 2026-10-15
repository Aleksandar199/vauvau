import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_notification.dart';

/// True when [item] announces something in the 1:1 chat [conversationId]
/// (new message, walk invite…). Older docs without `conversationId` are
/// matched by sender [peerUserId] for message / walk kinds only.
bool notificationBelongsToChat(
  AppNotification item, {
  required String conversationId,
  String? peerUserId,
}) {
  final roomId = conversationId.trim();
  final cid = (item.conversationId ?? '').trim();
  if (cid.isNotEmpty) {
    return roomId.isNotEmpty && cid == roomId;
  }
  final peer = (peerUserId ?? '').trim();
  if (peer.isEmpty) {
    return false;
  }
  return (item.kind == NotificationKind.chatMessage ||
          item.kind == NotificationKind.walkRequest) &&
      (item.fromUserId ?? '').trim() == peer;
}

/// Sets `isRead: true` on [uid]'s `notifications` docs for [conversationId]
/// (queried on the server, so docs not yet in the local list are covered too)
/// plus [alsoIds]. Returns the ids that were updated.
Future<List<String>> markConversationNotificationsRead(
  FirebaseFirestore firestore, {
  required String uid,
  required String conversationId,
  Iterable<String> alsoIds = const [],
}) async {
  final collection = firestore.collection('notifications');
  final ids = <String>{...alsoIds};
  final roomId = conversationId.trim();
  if (uid.isNotEmpty && roomId.isNotEmpty) {
    // Equality filters only: served by single-field indexes.
    final snapshot = await collection
        .where('toUserId', isEqualTo: uid)
        .where('conversationId', isEqualTo: roomId)
        .get();
    for (final doc in snapshot.docs) {
      if (doc.data()['isRead'] != true) {
        ids.add(doc.id);
      }
    }
  }
  if (ids.isEmpty) {
    return const [];
  }
  final batch = firestore.batch();
  for (final id in ids) {
    batch.update(collection.doc(id), {'isRead': true});
  }
  await batch.commit();
  return ids.toList();
}
