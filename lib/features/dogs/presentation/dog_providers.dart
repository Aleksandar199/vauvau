import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/dog_photo_storage.dart';
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
    photoStorage: DogPhotoStorage(FirebaseStorage.instance),
  );
});

final ownerDogsProvider = StreamProvider<List<Dog>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const <Dog>[]);
      }
      return ref.watch(dogsRepositoryProvider).watchByOwner(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => Stream.value(const <Dog>[]),
  );
});
