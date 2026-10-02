import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/firestore_lost_dog_repository.dart';
import '../data/local_lost_dog_repository.dart';
import '../domain/lost_dog.dart';
import '../domain/lost_dog_repository.dart';

class LostDogsController extends Notifier<AsyncValue<List<LostDog>>> {
  @override
  AsyncValue<List<LostDog>> build() {
    final repo = ref.watch(lostDogRepositoryProvider);
    final sub = repo.watchLostDogs().listen(
      (dogs) => state = AsyncValue.data(dogs),
      onError: (Object error, StackTrace stack) {
        debugPrint('Lost dogs stream: $error');
        // Keep previous listings visible on transient stream errors.
        if (!state.hasValue) {
          state = AsyncValue.error(error, stack);
        }
      },
    );
    ref.onDispose(sub.cancel);
    return const AsyncValue.loading();
  }

  void reload() => ref.invalidateSelf();

  Future<bool> report({
    required String dogName,
    required String city,
    required String neighborhood,
    required DateTime eventDate,
    required String description,
    required String contactPhone,
    required String type,
    required String breed,
    XFile? photo,
  }) async {
    try {
      await ref.read(lostDogRepositoryProvider).reportLostDog(
            LostDog(
              id: '',
              dogName: dogName,
              breed: breed,
              type: type,
              city: city,
              neighborhood: neighborhood,
              lostDate: eventDate,
              foundDate: type == LostDogType.found ? eventDate : null,
              description: description,
              imageUrl: '',
              contactPhone: contactPhone,
              uploaderUserId: '',
              status: LostDogStatus.active,
              createdAt: DateTime.now(),
            ),
            photo: photo,
          );
      return true;
    } catch (e, stack) {
      // ignore: avoid_print
      print(e.toString());
      debugPrint('$stack');
      return false;
    }
  }

  Future<void> addComment(String dogId, String text) {
    final name = ref.read(authStateProvider).asData?.value?.displayName ?? '';
    return ref.read(lostDogRepositoryProvider).addComment(
          dogId,
          text,
          authorName: name,
        );
  }

  Future<void> markFound(String id) {
    return ref.read(lostDogRepositoryProvider).markFound(id);
  }

  Future<void> deleteLostDog(String id) {
    return ref.read(lostDogRepositoryProvider).deleteLostDog(id);
  }
}

final lostDogRepositoryProvider = Provider<LostDogRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreLostDogRepository(firestore: FirebaseFirestore.instance);
  }
  final repo = LocalLostDogRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final lostDogsControllerProvider =
    NotifierProvider<LostDogsController, AsyncValue<List<LostDog>>>(
  LostDogsController.new,
);

List<LostDog> _dogsOf(AsyncValue<List<LostDog>> value) {
  return value.asData?.value ?? const [];
}

final activeLostDogsProvider = Provider<List<LostDog>>((ref) {
  return [
    for (final dog in _dogsOf(ref.watch(lostDogsControllerProvider)))
      if (dog.isMissing) dog,
  ];
});

final missingLostDogsProvider = activeLostDogsProvider;

final activeFoundDogsProvider = Provider<List<LostDog>>((ref) {
  return [
    for (final dog in _dogsOf(ref.watch(lostDogsControllerProvider)))
      if (dog.isFoundListing && dog.isActive) dog,
  ];
});

final recentMissingLostDogsProvider = Provider<List<LostDog>>((ref) {
  final cutoff = DateTime.now().subtract(const Duration(hours: 24));
  return [
    for (final dog in ref.watch(activeLostDogsProvider))
      if (dog.createdAt.isAfter(cutoff)) dog,
  ];
});

final lostDogReporterIdProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid ?? '';
});

final lostDogCommentsProvider =
    StreamProvider.family<List<LostDogComment>, String>((ref, dogId) {
  return ref.watch(lostDogRepositoryProvider).watchComments(dogId);
});
