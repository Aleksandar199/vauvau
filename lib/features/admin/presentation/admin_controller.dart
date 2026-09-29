import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/firestore_admin_repository.dart';
import '../data/local_admin_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreAdminRepository(firestore: FirebaseFirestore.instance);
  }
  final repo = LocalAdminRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Only admins may read `admin_feedback` and list `users`, so the streams stay
/// closed for everyone else instead of triggering permission errors.
final adminFeedbackProvider =
    StreamProvider<List<FeedbackEntry>>((ref) async* {
  if (!ref.watch(isAdminProvider)) {
    yield const [];
    return;
  }
  yield* ref.watch(adminRepositoryProvider).watchFeedback();
});

final adminUsersProvider = StreamProvider<List<AdminUserEntry>>((ref) async* {
  if (!ref.watch(isAdminProvider)) {
    yield const [];
    return;
  }
  yield* ref.watch(adminRepositoryProvider).watchUsers();
});

final newFeedbackCountProvider = Provider<int>((ref) {
  final feedback = ref.watch(adminFeedbackProvider).asData?.value ?? const [];
  return feedback.where((entry) => !entry.isResolved).length;
});
