import 'dart:async';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../auth/domain/app_user.dart';
import '../domain/dog.dart';
import '../domain/dog_area.dart';
import '../domain/dog_draft.dart';
import '../domain/dog_enums.dart';
import '../domain/dogs_repository.dart';

Dog localDemoDog({String ownerId = 'local-user'}) {
  return Dog(
    id: 'local-luna',
    ownerId: ownerId,
    name: 'Luna',
    breed: 'Zlatni retriver',
    gender: DogGender.female,
    ageYears: 3,
    size: DogSize.large,
    energyLevel: DogEnergyLevel.high,
    temperament: const [DogTemperament.friendly, DogTemperament.playful],
    area: const DogArea(
      cityId: 'novi_sad',
      cityName: 'Novi Sad',
      neighborhoodId: 'liman_1',
      neighborhoodName: 'Liman 1',
    ),
    photoUrls: const [],
    likesTags: const ['Šetnje', 'Igru', 'Velike pse'],
    dislikesTags: const ['Gužvu'],
  );
}

class LocalDogsRepository implements DogsRepository {
  LocalDogsRepository({List<Dog>? dogs}) : _dogs = List<Dog>.from(dogs ?? []);

  final List<Dog> _dogs;
  final StreamController<List<Dog>> _controller =
      StreamController<List<Dog>>.broadcast();

  @override
  Stream<List<Dog>> watchByOwner(String ownerId) async* {
    yield _owned(ownerId);
    yield* _controller.stream.map((_) => _owned(ownerId));
  }

  @override
  Future<Dog> createFirstDog({
    required AppUser owner,
    required DogDraft draft,
  }) async {
    final id = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final photos = firestorePhotoFields(uniquePhotoUrls(draft.photos));
    final dog = Dog(
      id: id,
      ownerId: owner.uid,
      name: draft.name.trim(),
      breed: draft.breed.trim(),
      gender: draft.gender ?? DogGender.unknown,
      ageYears: draft.ageYears ?? 0,
      size: draft.size ?? DogSize.medium,
      weightKg: draft.weightKg,
      energyLevel: draft.energyLevel ?? DogEnergyLevel.moderate,
      temperament: draft.temperament,
      area: _areaFromOwner(owner, draft),
      photoUrls: List<String>.from(photos['photoUrls'] as List),
      bio: draft.bio.trim(),
      vaccinated: draft.vaccinated,
      chipped: draft.chipped,
      sterilized: draft.sterilized,
      likesTags: draft.likesTags,
      dislikesTags: draft.dislikesTags,
    );
    _dogs.add(dog);
    _controller.add(List<Dog>.from(_dogs));
    return dog;
  }

  @override
  Future<void> updateDog(Dog dog, {int ageMonths = 0}) async {
    final index = _dogs.indexWhere((item) => item.id == dog.id);
    if (index < 0) {
      _dogs.add(dog);
    } else {
      _dogs[index] = dog;
    }
    _controller.add(List<Dog>.from(_dogs));
  }

  @override
  Future<void> deleteDog(String dogId, {required String ownerId}) async {
    _dogs.removeWhere((dog) => dog.id == dogId);
    _controller.add(List<Dog>.from(_dogs));
  }

  DogArea _areaFromOwner(AppUser owner, DogDraft draft) {
    if (owner.cityId.isNotEmpty && owner.neighborhoodId.isNotEmpty) {
      return DogArea(
        cityId: owner.cityId,
        cityName: owner.cityName,
        neighborhoodId: owner.neighborhoodId,
        neighborhoodName: owner.neighborhoodName,
      );
    }
    return _areaFromDraft(draft);
  }

  DogArea _areaFromDraft(DogDraft draft) {
    final city = SerbiaLocations.cityById(draft.cityId ?? '');
    if (city == null) {
      return const DogArea(
        cityId: 'novi_sad',
        cityName: 'Novi Sad',
        neighborhoodId: 'liman_1',
        neighborhoodName: 'Liman 1',
      );
    }
    final neighborhoodId = draft.neighborhoodId;
    if (neighborhoodId != null && neighborhoodId.isNotEmpty) {
      final name = SerbiaLocations.resolveNeighborhoodName(
        cityId: city.id,
        neighborhoodId: neighborhoodId,
        customName: draft.customNeighborhoodName,
      );
      if (name.isNotEmpty) {
        final storedId = SerbiaLocations.usesCustomNeighborhood(
              city.id,
              neighborhoodId,
            )
            ? SerbiaLocations.customNeighborhoodId
            : neighborhoodId;
        return DogArea(
          cityId: city.id,
          cityName: city.name,
          neighborhoodId: storedId,
          neighborhoodName: name,
        );
      }
    }
    final first = city.neighborhoods.first;
    return DogArea(
      cityId: city.id,
      cityName: city.name,
      neighborhoodId: first.id,
      neighborhoodName: first.name,
    );
  }

  List<Dog> _owned(String ownerId) {
    return _dogs.where((dog) => dog.ownerId == ownerId).toList();
  }
}
