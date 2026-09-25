import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/firestore_poi_repository.dart';
import '../domain/models/poi_model.dart';
import '../domain/poi_repository.dart';

final poiRepositoryProvider = Provider<PoiRepository>((ref) {
  if (isFirebaseReady) {
    return FirestorePoiRepository(FirebaseFirestore.instance);
  }
  return LocalPoiRepository();
});

final livePoisProvider = StreamProvider<List<PoiModel>>((ref) {
  return ref.watch(poiRepositoryProvider).watchAll();
});

class UserPoiSubmissions extends Notifier<List<PoiModel>> {
  @override
  List<PoiModel> build() {
    if (!isFirebaseReady) {
      return const [];
    }
    return ref.watch(livePoisProvider).asData?.value ?? const [];
  }

  Future<void> add(PoiModel poi) async {
    _assertCanWrite(requireAdmin: false);
    if (isFirebaseReady) {
      await ref.read(poiRepositoryProvider).upsert(poi);
      return;
    }
    state = [...state.where((item) => item.id != poi.id), poi];
  }

  Future<void> updatePoi(PoiModel poi) async {
    _assertCanWrite(requireAdmin: true);
    if (isFirebaseReady) {
      await ref.read(poiRepositoryProvider).upsert(poi);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == poi.id) poi else item,
    ];
  }

  Future<void> approve(String id) async {
    final current = _byId(id);
    if (current == null) {
      return;
    }
    await updatePoi(
      current.copyWith(
        verificationStatus: PoiVerificationStatus.verified,
        lastVerified: DateTime.now(),
      ),
    );
  }

  Future<void> reject(String id) async {
    _assertCanWrite(requireAdmin: true);
    final current = _byId(id);
    if (current == null) {
      return;
    }
    final rejected = current.copyWith(
      verificationStatus: PoiVerificationStatus.rejected,
    );
    if (isFirebaseReady) {
      await ref.read(poiRepositoryProvider).upsert(rejected);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == id) rejected else item,
    ];
  }

  PoiModel? _byId(String id) {
    for (final item in state) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  void _assertCanWrite({required bool requireAdmin}) {
    if (!requireAdmin) {
      return;
    }
    if (!(ref.read(isAdminProvider))) {
      throw StateError('Admin only');
    }
  }
}

final userPoiSubmissionsProvider =
    NotifierProvider<UserPoiSubmissions, List<PoiModel>>(
  UserPoiSubmissions.new,
);

final pendingPoisProvider = Provider<List<PoiModel>>((ref) {
  return ref
      .watch(userPoiSubmissionsProvider)
      .where((poi) => poi.verificationStatus.isAwaitingReview)
      .toList();
});
