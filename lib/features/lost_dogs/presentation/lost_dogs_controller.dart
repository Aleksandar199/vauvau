import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../location/presentation/home_city_provider.dart';
import '../data/firestore_lost_dog_repository.dart';
import '../data/local_lost_dog_repository.dart';
import '../domain/lost_dog.dart';
import '../domain/lost_dog_city.dart';
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
    String cityId = '',
    required String neighborhood,
    required DateTime eventDate,
    required String description,
    required String contactPhone,
    required String type,
    required String breed,
    XFile? photo,
  }) async {
    try {
      await ref
          .read(lostDogRepositoryProvider)
          .reportLostDog(
            LostDog(
              id: '',
              dogName: dogName,
              breed: breed,
              type: type,
              city: city,
              cityId: cityId,
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
    return ref
        .read(lostDogRepositoryProvider)
        .addComment(dogId, text, authorName: name);
  }

  Future<void> toggleCommentLike(String dogId, String commentId) {
    return ref
        .read(lostDogRepositoryProvider)
        .toggleCommentLike(dogId, commentId);
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

/// Recent missing dogs that may alert this user: only their own city
/// (see [LostDogCity.alertsUser]; users without a city get every city).
final emergencyLostDogsProvider = Provider<List<LostDog>>((ref) {
  final homeCityId = ref.watch(homeCityProvider.select((city) => city?.id));
  return [
    for (final dog in ref.watch(recentMissingLostDogsProvider))
      if (LostDogCity.alertsUser(dog, homeCityId)) dog,
  ];
});

/// City picked on the lost-dogs screen: [LostDogCity.all], [LostDogCity.other]
/// or a [SerbiaLocations] city id. Starts at the user's city.
class LostDogCityFilterController extends Notifier<String> {
  @override
  String build() {
    final homeCityId = ref.watch(homeCityProvider.select((city) => city?.id));
    return LostDogCity.defaultFilter(homeCityId);
  }

  void select(String filter) => state = filter;
}

final lostDogCityFilterProvider =
    NotifierProvider<LostDogCityFilterController, String>(
      LostDogCityFilterController.new,
    );

/// Listings stored with `cityId` – reaches older listings of one city that
/// fall outside the newest-first catalog.
final lostDogsInCityProvider = StreamProvider.family<List<LostDog>, String>((
  ref,
  cityId,
) {
  return ref.watch(lostDogRepositoryProvider).watchLostDogsInCity(cityId);
});

/// Catalog for the selected city: newest listings (incl. old ones without
/// `cityId`, mapped by name) merged with the city query, newest first.
final cityLostDogsProvider = Provider<List<LostDog>>((ref) {
  final filter = ref.watch(lostDogCityFilterProvider);
  final catalog = _dogsOf(ref.watch(lostDogsControllerProvider));
  final byId = <String, LostDog>{for (final dog in catalog) dog.id: dog};
  if (filter != LostDogCity.all && filter != LostDogCity.other) {
    for (final dog
        in ref.watch(lostDogsInCityProvider(filter)).value ?? const []) {
      byId.putIfAbsent(dog.id, () => dog);
    }
  }
  final dogs = LostDogCity.filter(byId.values.toList(), filter)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return dogs;
});

final cityMissingDogsProvider = Provider<List<LostDog>>((ref) {
  return [
    for (final dog in ref.watch(cityLostDogsProvider))
      if (dog.isMissing) dog,
  ];
});

final cityFoundDogsProvider = Provider<List<LostDog>>((ref) {
  return [
    for (final dog in ref.watch(cityLostDogsProvider))
      if (dog.isFoundListing && dog.isActive) dog,
  ];
});

final lostDogReporterIdProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid ?? '';
});

final lostDogCommentsProvider =
    StreamProvider.family<List<LostDogComment>, String>((ref, dogId) {
      return ref.watch(lostDogRepositoryProvider).watchComments(dogId);
    });
