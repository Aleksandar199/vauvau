import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../app_update/domain/app_update.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../map/presentation/cities_controller.dart';
import '../data/batched_loader.dart';
import '../data/firestore_admin_repository.dart';
import '../data/local_admin_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final places = ref.watch(placesRepositoryProvider);
  if (isFirebaseReady) {
    return FirestoreAdminRepository(
      firestore: FirebaseFirestore.instance,
      placesRepository: places,
    );
  }
  final repo = LocalAdminRepository(placesRepository: places);
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

/// Dashboard numbers (count()/sum() queries); refresh = invalidate.
final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  if (!ref.watch(isAdminProvider)) return const AdminStats();
  return ref.watch(adminRepositoryProvider).loadStats();
});

final adminContentProvider = StreamProvider.autoDispose
    .family<List<AdminContentItem>, AdminContentKind>((ref, kind) {
  if (!ref.watch(isAdminProvider)) return Stream.value(const []);
  return ref.watch(adminRepositoryProvider).watchContent(kind);
});

final adminAppConfigProvider = FutureProvider.autoDispose<AppUpdateConfig?>((
  ref,
) {
  return ref.watch(adminRepositoryProvider).fetchAppConfig();
});

final adminUserDogsProvider = FutureProvider.autoDispose
    .family<List<AdminDogRef>, String>((ref, uid) {
  return ref.watch(adminRepositoryProvider).fetchUserDogs(uid);
});

/// Live entry of one user from the admin users list (detail screen).
final adminUserEntryProvider =
    Provider.autoDispose.family<AdminUserEntry?, String>((ref, uid) {
  final users = ref.watch(adminUsersProvider).value ?? const [];
  for (final user in users) {
    if (user.uid == uid) return user;
  }
  return null;
});

// --- AdminDirectory: names / previews instead of raw ids -------------------
// Every label on screen asks for its id; ids asked for in the same frame are
// fetched with one `whereIn` query and cached for the session.

final adminUserLoaderProvider = Provider<BatchedLoader<AdminUserRef>>((ref) {
  return BatchedLoader(ref.watch(adminRepositoryProvider).fetchUsers);
});

final adminDogLoaderProvider = Provider<BatchedLoader<AdminDogRef>>((ref) {
  return BatchedLoader(ref.watch(adminRepositoryProvider).fetchDogs);
});

final adminMomentLoaderProvider =
    Provider<BatchedLoader<AdminMomentRef>>((ref) {
  return BatchedLoader(ref.watch(adminRepositoryProvider).fetchMoments);
});

final adminUserRefProvider =
    FutureProvider.family<AdminUserRef, String>((ref, uid) async {
  if (uid.trim().isEmpty) return AdminUserRef.unknown(uid);
  try {
    return await ref.watch(adminUserLoaderProvider).load(uid);
  } catch (_) {
    return AdminUserRef.unknown(uid);
  }
});

final adminDogRefProvider =
    FutureProvider.family<AdminDogRef, String>((ref, id) async {
  if (id.trim().isEmpty) return AdminDogRef.unknown(id);
  try {
    return await ref.watch(adminDogLoaderProvider).load(id);
  } catch (_) {
    return AdminDogRef.unknown(id);
  }
});

final adminMomentRefProvider =
    FutureProvider.family<AdminMomentRef, String>((ref, id) async {
  if (id.trim().isEmpty) return AdminMomentRef.unknown(id);
  try {
    return await ref.watch(adminMomentLoaderProvider).load(id);
  } catch (_) {
    return AdminMomentRef.unknown(id);
  }
});

final adminMessageRefProvider = FutureProvider.autoDispose
    .family<AdminMessageRef, ({String chatId, String messageId})>((ref, key) {
  return ref
      .watch(adminRepositoryProvider)
      .fetchChatMessage(key.chatId, key.messageId);
});

/// Admin user actions; refreshes the cached name/role afterwards.
class AdminUserActions {
  AdminUserActions(this._ref);

  final Ref _ref;

  AdminRepository get _repo => _ref.read(adminRepositoryProvider);

  Future<void> setRole(String uid, String role, {String partnerId = ''}) async {
    await _repo.setUserRole(uid, role: role, partnerId: partnerId);
    _refresh(uid);
  }

  Future<void> setSuspended(
    String uid, {
    required bool suspended,
    String reason = '',
  }) async {
    await _repo.setUserSuspended(uid, suspended: suspended, reason: reason);
    _refresh(uid);
  }

  void _refresh(String uid) {
    _ref.read(adminUserLoaderProvider).invalidate(uid);
    _ref.invalidate(adminUserRefProvider(uid));
    _ref.invalidate(adminStatsProvider);
  }
}

final adminUserActionsProvider = Provider<AdminUserActions>(
  AdminUserActions.new,
);
