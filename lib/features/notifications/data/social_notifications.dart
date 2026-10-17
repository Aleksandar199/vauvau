import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';

/// In-app notification types for follows and stories (`notifications.type`).
abstract final class SocialNotificationType {
  static const follow = 'FOLLOW';
  static const storyLike = 'STORY_LIKE';
  static const storyReply = 'STORY_REPLY';
}

/// One notification to write. [id] is deterministic per action, so a retry
/// (or a re-follow / re-like) never creates a second document: rules allow
/// only `create`, and an existing id is left as is.
class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    required this.title,
    required this.body,
    this.storyId = '',
    this.conversationId = '',
  });

  final String id;
  final String type;
  final String fromUserId;
  final String toUserId;
  final String title;
  final String body;
  final String storyId;
  final String conversationId;

  /// Never notify yourself (or nobody).
  bool get isDeliverable =>
      fromUserId.isNotEmpty && toUserId.isNotEmpty && fromUserId != toUserId;
}

abstract class SocialNotificationWriter {
  /// Best effort: never throws. Returns true when a new document was written.
  Future<bool> send(SocialNotification notification);
}

class FirestoreSocialNotificationWriter implements SocialNotificationWriter {
  FirestoreSocialNotificationWriter(this._firestore);

  final FirebaseFirestore _firestore;

  static String _clip(String value, int max) {
    final text = value.trim();
    return text.length <= max ? text : '${text.substring(0, max - 1)}…';
  }

  @override
  Future<bool> send(SocialNotification n) async {
    if (!n.isDeliverable || n.id.isEmpty) {
      return false;
    }
    try {
      await _firestore.collection('notifications').doc(n.id).set({
        'type': n.type,
        'fromUserId': n.fromUserId,
        'senderUserId': n.fromUserId,
        'toUserId': n.toUserId,
        'recipientId': n.toUserId,
        'title': _clip(n.title, 200),
        'body': _clip(n.body, 200),
        if (n.storyId.isNotEmpty) 'storyId': n.storyId,
        if (n.conversationId.isNotEmpty) 'conversationId': n.conversationId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      // Already sent (rules deny rewriting it), blocked by the recipient or
      // offline: the action itself already succeeded, so just log.
      debugPrint('Social notification ${n.id} not written: $error');
      return false;
    }
  }
}

/// Records notifications in memory (tests / offline demo).
class LocalSocialNotificationWriter implements SocialNotificationWriter {
  final Map<String, SocialNotification> sent = {};

  @override
  Future<bool> send(SocialNotification n) async {
    if (!n.isDeliverable || n.id.isEmpty || sent.containsKey(n.id)) {
      return false;
    }
    sent[n.id] = n;
    return true;
  }
}

final socialNotificationWriterProvider = Provider<SocialNotificationWriter>((
  ref,
) {
  if (isFirebaseReady) {
    return FirestoreSocialNotificationWriter(FirebaseFirestore.instance);
  }
  return LocalSocialNotificationWriter();
});
