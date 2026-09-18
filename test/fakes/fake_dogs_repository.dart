import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/dogs/domain/dog.dart';
import 'package:vauvau/features/dogs/domain/dog_area.dart';
import 'package:vauvau/features/dogs/domain/dog_draft.dart';
import 'package:vauvau/features/dogs/domain/dog_enums.dart';
import 'package:vauvau/features/dogs/domain/dogs_repository.dart';

class FakeDogsRepository implements DogsRepository {
  FakeDogsRepository({List<Dog>? dogs}) : dogs = dogs ?? [];

  final List<Dog> dogs;

  @override
  Stream<List<Dog>> watchByOwner(String ownerId) => Stream.value(dogs);

  @override
  Future<Dog> createFirstDog({
    required AppUser owner,
    required DogDraft draft,
  }) async {
    final dog = Dog(
      id: 'dog-1',
      ownerId: owner.uid,
      name: draft.name,
      breed: draft.breed,
      gender: draft.gender ?? DogGender.unknown,
      ageYears: draft.ageYears ?? 0,
      size: draft.size ?? DogSize.medium,
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
    dogs.add(dog);
    return dog;
  }
}

Dog fakeDog({String ownerId = '1'}) {
  return Dog(
    id: 'dog-1',
    ownerId: ownerId,
    name: 'Luna',
    breed: 'Golden Retriever',
    gender: DogGender.female,
    ageYears: 3,
    size: DogSize.large,
    energyLevel: DogEnergyLevel.high,
    temperament: const [DogTemperament.friendly],
    area: const DogArea(
      cityId: 'novi_sad',
      cityName: 'Novi Sad',
      neighborhoodId: 'liman',
      neighborhoodName: 'Liman',
    ),
    photoUrls: const ['https://example.com/luna.jpg'],
  );
}
