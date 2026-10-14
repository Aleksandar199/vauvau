import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/data/load_discover_profile.dart';
import '../../discover/domain/discover_profile.dart';
import '../../profile/presentation/profile_controller.dart';
import 'chat_inbox.dart';

class IncomingLike {
  const IncomingLike({
    required this.fromUserId,
    required this.profile,
    required this.createdAt,
  });

  final String fromUserId;
  final DiscoverProfile profile;
  final DateTime createdAt;
}

final rawIncomingLikesProvider = StreamProvider<List<IncomingLike>>((ref) {
  if (!isFirebaseReady) {
    return Stream.value(const []);
  }
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.asData?.value?.uid ?? ''),
  );
  final authReady = ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
  final myDogId = ref.watch(currentDiscoverDogProvider).id;
  if (!authReady ||
      uid.isEmpty ||
      myDogId.isEmpty ||
      myDogId == 'local-luna') {
    return Stream.value(const []);
  }

  return FirestoreAuthGuard.guardedStream<List<IncomingLike>>(
    label: 'swipes.incomingLikes',
    empty: const [],
    create: () => FirebaseFirestore.instance
        .collection('swipes')
        .where('toDogId', isEqualTo: myDogId)
        .snapshots()
        .asyncMap((snapshot) async {
    final docs = [
      for (final doc in snapshot.docs)
        if ((doc.data()['type'] as String? ?? 'like') == 'like') doc,
    ]..sort((a, b) {
        return _swipeTime(b.data()).compareTo(_swipeTime(a.data()));
      });
    final likes = <IncomingLike>[];
    final seen = <String>{};
    for (final doc in docs) {
      final data = doc.data();
      final fromUserId = data['fromUserId'] as String? ?? '';
      if (fromUserId.isEmpty || fromUserId == uid || !seen.add(fromUserId)) {
        continue;
      }
      final dogId = data['fromDogId'] as String? ??
          data['senderDogId'] as String? ??
          '';
      try {
        final profile = await loadDiscoverProfile(
          dogId: dogId,
          ownerId: fromUserId,
        );
        if (profile == null) {
          continue;
        }
        likes.add(
          IncomingLike(
            fromUserId: fromUserId,
            profile: profile,
            createdAt: _swipeTime(data),
          ),
        );
      } catch (error) {
        debugPrint('Incoming like load failed: $error');
      }
    }
    return likes;
  }),
  );
});

final incomingLikesProvider = Provider<List<IncomingLike>>((ref) {
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.asData?.value?.uid ?? ''),
  );
  final chats = ref.watch(chatInboxProvider);
  final chattingWith = <String>{};
  for (final chat in chats) {
    if (chat.peerUserId.isNotEmpty) {
      chattingWith.add(chat.peerUserId);
    }
    for (final id in chat.participantIds) {
      if (id.isNotEmpty && id != uid) {
        chattingWith.add(id);
      }
    }
  }
  final likes = ref.watch(rawIncomingLikesProvider).asData?.value ?? const [];
  return [
    for (final like in likes)
      if (!chattingWith.contains(like.fromUserId)) like,
  ];
});

DateTime _swipeTime(Map<String, dynamic> data) {
  final raw = data['createdAt'] ?? data['timestamp'];
  if (raw is Timestamp) {
    return raw.toDate();
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
