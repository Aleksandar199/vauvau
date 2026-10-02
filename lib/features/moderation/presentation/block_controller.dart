import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/firestore_blocked_users_repository.dart';
import '../data/local_blocked_users_repository.dart';
import '../domain/blocked_users_repository.dart';

final blockedUsersRepositoryProvider = Provider<BlockedUsersRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreBlockedUsersRepository(
      FirebaseFirestore.instance,
      ref.watch(authStateProvider).asData?.value?.uid ?? '',
    );
  }
  final repo = LocalBlockedUsersRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final blockedUsersStreamProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(blockedUsersRepositoryProvider).watchBlocked();
});

/// Synchronous view of the block list so feeds can filter without juggling
/// another [AsyncValue].
final blockedUserIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(blockedUsersStreamProvider).asData?.value ??
      const <String>{};
});

class BlockController {
  BlockController(this._ref);

  final Ref _ref;

  bool isBlocked(String userId) {
    return userId.isNotEmpty &&
        _ref.read(blockedUserIdsProvider).contains(userId);
  }

  Future<void> block(String userId) {
    return _ref.read(blockedUsersRepositoryProvider).block(userId);
  }

  Future<void> unblock(String userId) {
    return _ref.read(blockedUsersRepositoryProvider).unblock(userId);
  }
}

final blockControllerProvider = Provider<BlockController>((ref) {
  return BlockController(ref);
});
