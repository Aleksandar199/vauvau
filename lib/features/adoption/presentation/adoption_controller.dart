import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/firestore_adoption_repository.dart';
import '../data/local_adoption_repository.dart';
import '../domain/adoption_dog.dart';
import '../domain/adoption_repository.dart';

class AdoptionController extends Notifier<AsyncValue<List<AdoptionDog>>> {
  @override
  AsyncValue<List<AdoptionDog>> build() {
    final repo = ref.watch(adoptionRepositoryProvider);
    final sub = repo.watchAdoptionDogs().listen(
      (dogs) => state = AsyncValue.data(dogs),
      onError: (Object error, StackTrace stack) {
        debugPrint('Adoption stream: $error');
        state = AsyncValue.error(error, stack);
      },
    );
    ref.onDispose(sub.cancel);
    return const AsyncValue.loading();
  }

  void reload() => ref.invalidateSelf();

  Future<bool> publish({
    required String name,
    required String breed,
    required String age,
    required String gender,
    required String size,
    required String city,
    required String neighborhood,
    required String description,
    required String contactPhone,
    required bool isVaccinated,
    required bool isSterilized,
    required List<XFile> photos,
  }) async {
    final profile = ref.read(profileControllerProvider);
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    final location =
        neighborhood.isEmpty ? city : '$city, $neighborhood';
    try {
      await ref.read(adoptionRepositoryProvider).addAdoptionDog(
            AdoptionDog(
              id: '',
              name: name,
              breed: breed,
              age: age,
              gender: gender,
              size: size,
              location: location,
              description: description,
              imageUrls: const [],
              contactPhone: contactPhone,
              uploaderUserId: uid,
              uploaderName: profile.ownerName,
              isVaccinated: isVaccinated,
              isSterilized: isSterilized,
              createdAt: DateTime.now(),
            ),
            photos: photos,
            city: city,
            neighborhood: neighborhood,
          );
      return true;
    } catch (e, stack) {
      // ignore: avoid_print
      print(e.toString());
      debugPrint('$stack');
      return false;
    }
  }

  Future<void> markAdopted(String id) {
    return ref.read(adoptionRepositoryProvider).markAdopted(id);
  }
}

final adoptionRepositoryProvider = Provider<AdoptionRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreAdoptionRepository(
      firestore: FirebaseFirestore.instance,
    );
  }
  final repo = LocalAdoptionRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final adoptionControllerProvider =
    NotifierProvider<AdoptionController, AsyncValue<List<AdoptionDog>>>(
  AdoptionController.new,
);
