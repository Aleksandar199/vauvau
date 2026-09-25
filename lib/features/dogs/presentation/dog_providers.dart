import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
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
}

final localOwnerDogsProvider =
    NotifierProvider<LocalOwnerDogs, List<Dog>>(LocalOwnerDogs.new);

final ownerDogsProvider = StreamProvider<List<Dog>>((ref) {
  final auth = ref.watch(authStateProvider);
  final local = ref.watch(localOwnerDogsProvider);
  return auth.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const <Dog>[]);
      }
      final localForOwner =
          local.where((dog) => dog.ownerId == user.uid).toList();
      return _mergeOwnerDogs(
        remote: ref.watch(dogsRepositoryProvider).watchByOwner(user.uid),
        local: localForOwner,
      );
    },
    loading: () => Stream.value(local),
    error: (_, _) => Stream.value(local),
  );
});

Stream<List<Dog>> _mergeOwnerDogs({
  required Stream<List<Dog>> remote,
  required List<Dog> local,
}) async* {
  if (local.isNotEmpty) {
    yield local;
  }
  await for (final list in remote) {
    yield list.isNotEmpty ? list : local;
  }
}
