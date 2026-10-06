import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/walk_history_repository.dart';
import '../domain/walk_record.dart';

final walkHistoryRepositoryProvider = Provider<WalkHistoryRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreWalkHistoryRepository(FirebaseFirestore.instance);
  }
  return LocalWalkHistoryRepository();
});

final walkHistoryProvider = FutureProvider.autoDispose<List<WalkRecord>>((
  ref,
) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return const [];
  return ref.read(walkHistoryRepositoryProvider).fetchRecent(userId: uid);
});
