import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notifications/data/social_notifications.dart';
import '../data/firestore_follow_repository.dart';
import '../data/local_follow_repository.dart';
import '../domain/follow_repository.dart';
import 'follows_strings.dart';

/// Signed-in uid ('local-user' without Firebase, like chat / moments).
final socialUserIdProvider = Provider<String>((ref) {
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.value?.uid ?? ''),
  );
  if (uid.isNotEmpty) {
    return uid;
  }
  return isFirebaseReady ? '' : 'local-user';
});

/// Name shown to others in follow / story notifications (never the email).
final socialUserNameProvider = Provider<String>((ref) {
  final name = ref.watch(
    authStateProvider.select((auth) => auth.value?.displayName?.trim() ?? ''),
  );
  return name.isEmpty ? 'Neko' : name;
});

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreFollowRepository(FirebaseFirestore.instance);
  }
  final repo = LocalFollowRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Owners I follow.
final followingIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(socialUserIdProvider);
  return ref.watch(followRepositoryProvider).watchFollowing(uid);
});

/// Owners who follow me.
final followerIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(socialUserIdProvider);
  return ref.watch(followRepositoryProvider).watchFollowers(uid);
});

/// Follow / unfollow with optimistic state. [state] holds the wanted value
/// per owner while a write is in flight; afterwards the stream is the truth.
class FollowController extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  bool isBusy(String ownerId) => state.containsKey(ownerId);

  Future<void> follow(String ownerId) => _set(ownerId, true);

  Future<void> unfollow(String ownerId) => _set(ownerId, false);

  Future<void> _set(String ownerId, bool wanted) async {
    final me = ref.read(socialUserIdProvider);
    if (ownerId.isEmpty || me.isEmpty) {
      throw const FollowException('Morate biti prijavljeni.');
    }
    if (ownerId == me) {
      throw const FollowException('Ne možete pratiti sebe.');
    }
    if (isBusy(ownerId)) {
      return;
    }
    state = {...state, ownerId: wanted};
    final repo = ref.read(followRepositoryProvider);
    try {
      if (wanted) {
        final created = await repo.follow(
          followerUserId: me,
          followedUserId: ownerId,
        );
        if (created) {
          final name = ref.read(socialUserNameProvider);
          await ref.read(socialNotificationWriterProvider).send(
                SocialNotification(
                  id: 'follow_${FollowRepository.docId(me, ownerId)}',
                  type: SocialNotificationType.follow,
                  fromUserId: me,
                  toUserId: ownerId,
                  title: FollowsStrings.newFollowerTitle,
                  body: FollowsStrings.newFollowerBody(name),
                ),
              );
        }
      } else {
        await repo.unfollow(followerUserId: me, followedUserId: ownerId);
      }
    } finally {
      if (ref.mounted) {
        state = {...state}..remove(ownerId);
      }
    }
  }
}

final followControllerProvider =
    NotifierProvider<FollowController, Map<String, bool>>(
      FollowController.new,
    );

/// Whether I follow [ownerId], including an in-flight optimistic change.
final isFollowingProvider = Provider.family<bool, String>((ref, ownerId) {
  final pending = ref.watch(
    followControllerProvider.select((pending) => pending[ownerId]),
  );
  if (pending != null) {
    return pending;
  }
  final following =
      ref.watch(followingIdsProvider).value ?? const <String>{};
  return following.contains(ownerId);
});
