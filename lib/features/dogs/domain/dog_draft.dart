import 'package:image_picker/image_picker.dart';

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
    this.cityId,
    this.neighborhoodId,
    this.photos = const [],
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
  final List<XFile> photos;

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
    List<XFile>? photos,
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
      photos: photos ?? this.photos,
    );
  }
}
