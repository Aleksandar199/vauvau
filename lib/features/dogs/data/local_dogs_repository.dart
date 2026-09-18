import 'dart:async';

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
      neighborhoodId: 'liman',
      neighborhoodName: 'Liman',
    ),
    photoUrls: const [
      'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80',
    ],
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
    final dog = Dog(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: owner.uid,
      name: draft.name.trim(),
      breed: draft.breed.trim(),
      gender: draft.gender ?? DogGender.unknown,
      ageYears: draft.ageYears ?? 0,
      size: draft.size ?? DogSize.medium,
      weightKg: draft.weightKg,
      energyLevel: draft.energyLevel ?? DogEnergyLevel.moderate,
      temperament: draft.temperament,
      area: const DogArea(
        cityId: 'novi_sad',
        cityName: 'Novi Sad',
        neighborhoodId: 'liman',
        neighborhoodName: 'Liman',
      ),
      photoUrls: const [],
    );
    _dogs
      ..removeWhere((item) => item.ownerId == owner.uid)
      ..add(dog);
    _controller.add(List<Dog>.from(_dogs));
    return dog;
  }

  List<Dog> _owned(String ownerId) {
    return _dogs.where((dog) => dog.ownerId == ownerId).toList();
  }
}
