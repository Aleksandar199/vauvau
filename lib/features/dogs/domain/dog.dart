import 'dog_area.dart';
import 'dog_enums.dart';

class Dog {
  const Dog({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.gender,
    required this.ageYears,
    required this.size,
    required this.energyLevel,
    required this.temperament,
    required this.area,
    required this.photoUrls,
    this.weightKg,
    this.bio = '',
    this.vaccinated = true,
    this.chipped = true,
    this.sterilized = false,
  });

  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final DogGender gender;
  final int ageYears;
  final DogSize size;
  final double? weightKg;
  final DogEnergyLevel energyLevel;
  final List<DogTemperament> temperament;
  final DogArea area;
  final List<String> photoUrls;
  final String bio;
  final bool vaccinated;
  final bool chipped;
  final bool sterilized;

  String get location => '${area.cityName} - ${area.neighborhoodName}';

  String get photoUrl => photoUrls.isEmpty ? '' : photoUrls.first;
}
