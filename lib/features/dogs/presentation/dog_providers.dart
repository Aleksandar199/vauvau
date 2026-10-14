import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/dogs_repository_impl.dart';
import '../data/local_dogs_repository.dart';
import '../domain/dog.dart';
import '../domain/dogs_repository.dart';

final dogsRepositoryProvider = Provider<DogsRepository>((ref) {
  if (!isFirebaseReady) {
    return LocalDogsRepository(dogs: [localDemoDog()]);
  }
  return DogsRepositoryImpl(
    firestore: FirebaseFirestore.instance,
  );
});

class LocalOwnerDogs extends Notifier<List<Dog>> {
  @override
  List<Dog> build() => const [];

  void replace(List<Dog> dogs) {
    state = dogs;
  }

  void upsert(Dog dog) {
    state = [
      for (final item in state)
        if (item.id != dog.id) item,
      dog,
    ];
  }

  void remove(String dogId) {
    state = [
      for (final item in state)
        if (item.id != dogId) item,
    ];
  }
}

final localOwnerDogsProvider =
    NotifierProvider<LocalOwnerDogs, List<Dog>>(LocalOwnerDogs.new);

final ownerDogsProvider = StreamProvider<List<Dog>>((ref) {
  final auth = ref.watch(authStateProvider);
  final local = ref.watch(localOwnerDogsProvider);
  final authReady =
      ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
  return auth.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const <Dog>[]);
      }
      final localForOwner =
          local.where((dog) => dog.ownerId == user.uid).toList();
      // Wait for ID token before dogs query (rules require isAuthenticated).
      if (isFirebaseReady && !authReady) {
        return Stream.value(localForOwner);
      }
      return _mergeOwnerDogs(
        remote: ref.watch(dogsRepositoryProvider).watchByOwner(user.uid),
        local: localForOwner,
      );
    },
    loading: () => Stream.value(local),
    error: (_, _) => Stream.value(local),
  );
});

/// Keeps optimistic edits (from [localOwnerDogsProvider]) until Firestore
/// snapshots catch up — otherwise a stale remote emit wipes gender/size/etc.
Stream<List<Dog>> _mergeOwnerDogs({
  required Stream<List<Dog>> remote,
  required List<Dog> local,
}) async* {
  List<Dog> merge(List<Dog> remoteList) {
    if (local.isEmpty) {
      return remoteList;
    }
    if (remoteList.isEmpty) {
      return local;
    }
    final byId = <String, Dog>{for (final dog in remoteList) dog.id: dog};
    for (final overlay in local) {
      final current = byId[overlay.id];
      if (current == null || _preferLocalOverlay(current, overlay)) {
        byId[overlay.id] = overlay;
      }
    }
    final result = <Dog>[];
    final seen = <String>{};
    for (final dog in remoteList) {
      result.add(byId[dog.id]!);
      seen.add(dog.id);
    }
    for (final dog in local) {
      if (!seen.contains(dog.id)) {
        result.add(dog);
      }
    }
    return result;
  }

  if (local.isNotEmpty) {
    yield merge(const []);
  }
  await for (final list in remote) {
    yield merge(list);
  }
}

bool _preferLocalOverlay(Dog remote, Dog local) {
  if (remote.name != local.name) return true;
  if (remote.breed != local.breed) return true;
  if (remote.gender != local.gender) return true;
  if (remote.size != local.size) return true;
  if (remote.ageYears != local.ageYears) return true;
  if (remote.ageMonths != local.ageMonths) return true;
  if (remote.bio != local.bio) return true;
  if (remote.weightKg != local.weightKg) return true;
  if (remote.vaccinated != local.vaccinated) return true;
  if (remote.chipped != local.chipped) return true;
  if (remote.sterilized != local.sterilized) return true;
  if (remote.energyLevel != local.energyLevel) return true;
  if (!_sameStringList(remote.photoUrls, local.photoUrls)) return true;
  if (!_sameStringList(remote.likesTags, local.likesTags)) return true;
  if (!_sameStringList(remote.dislikesTags, local.dislikesTags)) return true;
  if (remote.temperament.length != local.temperament.length) return true;
  for (var i = 0; i < remote.temperament.length; i++) {
    if (remote.temperament[i] != local.temperament[i]) return true;
  }
  return false;
}

bool _sameStringList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
