import '../../../core/constants/serbia_locations.dart';
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
    this.vaccinated = false,
    this.chipped = false,
    this.sterilized = false,
    this.likesTags = const [],
    this.dislikesTags = const [],
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
  final List<String> likesTags;
  final List<String> dislikesTags;

  String get location =>
      SerbiaLocations.formatPlace(area.cityName, area.neighborhoodName);

  String get photoUrl => photoUrls.isEmpty ? '' : photoUrls.first;

  Dog copyWith({
    String? name,
    String? breed,
    DogGender? gender,
    int? ageYears,
    DogSize? size,
    double? weightKg,
    bool clearWeight = false,
    DogEnergyLevel? energyLevel,
    List<DogTemperament>? temperament,
    DogArea? area,
    List<String>? photoUrls,
    String? bio,
    bool? vaccinated,
    bool? chipped,
    bool? sterilized,
    List<String>? likesTags,
    List<String>? dislikesTags,
  }) {
    return Dog(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      ageYears: ageYears ?? this.ageYears,
      size: size ?? this.size,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      energyLevel: energyLevel ?? this.energyLevel,
      temperament: temperament ?? this.temperament,
      area: area ?? this.area,
      photoUrls: photoUrls ?? this.photoUrls,
      bio: bio ?? this.bio,
      vaccinated: vaccinated ?? this.vaccinated,
      chipped: chipped ?? this.chipped,
      sterilized: sterilized ?? this.sterilized,
      likesTags: likesTags ?? this.likesTags,
      dislikesTags: dislikesTags ?? this.dislikesTags,
    );
  }
}
