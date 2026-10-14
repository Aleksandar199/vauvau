import '../../../core/constants/serbia_locations.dart';
import 'dog_enums.dart';

class DogDraft {
  const DogDraft({
    this.name = '',
    this.breed = '',
    this.gender,
    this.ageYears,
    this.size,
    this.weightKg,
    this.energyLevel,
    this.temperament = const [],
    this.cityId = SerbiaLocations.noviSadId,
    this.neighborhoodId,
    this.customNeighborhoodName = '',
    this.photos = const [],
    this.vaccinated = false,
    this.chipped = false,
    this.sterilized = false,
    this.bio = '',
    this.likesTags = const [],
    this.dislikesTags = const [],
  });

  final String name;
  final String breed;
  final DogGender? gender;
  final int? ageYears;
  final DogSize? size;
  final double? weightKg;
  final DogEnergyLevel? energyLevel;
  final List<DogTemperament> temperament;
  final String? cityId;
  final String? neighborhoodId;
  final String customNeighborhoodName;
  final List<String> photos;
  final bool vaccinated;
  final bool chipped;
  final bool sterilized;
  final String bio;
  final List<String> likesTags;
  final List<String> dislikesTags;

  DogDraft copyWith({
    String? name,
    String? breed,
    DogGender? gender,
    int? ageYears,
    DogSize? size,
    double? weightKg,
    bool clearWeight = false,
    DogEnergyLevel? energyLevel,
    List<DogTemperament>? temperament,
    String? cityId,
    bool clearNeighborhood = false,
    String? neighborhoodId,
    String? customNeighborhoodName,
    List<String>? photos,
    bool? vaccinated,
    bool? chipped,
    bool? sterilized,
    String? bio,
    List<String>? likesTags,
    List<String>? dislikesTags,
  }) {
    return DogDraft(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      ageYears: ageYears ?? this.ageYears,
      size: size ?? this.size,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      energyLevel: energyLevel ?? this.energyLevel,
      temperament: temperament ?? this.temperament,
      cityId: cityId ?? this.cityId,
      neighborhoodId:
          clearNeighborhood ? null : (neighborhoodId ?? this.neighborhoodId),
      customNeighborhoodName: clearNeighborhood
          ? ''
          : (customNeighborhoodName ?? this.customNeighborhoodName),
      photos: photos ?? this.photos,
      vaccinated: vaccinated ?? this.vaccinated,
      chipped: chipped ?? this.chipped,
      sterilized: sterilized ?? this.sterilized,
      bio: bio ?? this.bio,
      likesTags: likesTags ?? this.likesTags,
      dislikesTags: dislikesTags ?? this.dislikesTags,
    );
  }
}
