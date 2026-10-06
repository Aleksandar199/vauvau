import '../../../core/geo/firestore_geo.dart';
import '../../../core/geo/geo.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_dog_profile.dart';
import '../../dogs/domain/dog.dart';
import '../../dogs/domain/dog_area.dart';
import '../../dogs/domain/dog_enums.dart';
import '../domain/discover_profile.dart';

DiscoverProfile discoverProfileFromMap(String id, Map<String, dynamic> data) {
  final unique = collectPhotoUrls(data);
  final area = data['area'] as Map<String, dynamic>?;
  final location =
      data['location'] as String? ??
      '${area?['cityName'] ?? ''} - ${area?['neighborhoodName'] ?? ''}'.trim();

  final coord = geoCoordFromMap(data) ?? GeoCoord.forCityName(location);

  return DiscoverProfile(
    id: id,
    ownerId: data['ownerId'] as String? ?? '',
    name: data['name'] as String? ?? '',
    ownerName: data['ownerName'] as String? ?? 'Vlasnik',
    breed: data['breed'] as String? ?? '',
    ageYears:
        (data['ageYears'] as num?)?.toInt() ??
        (data['age'] as num?)?.toInt() ??
        0,
    ageMonths: (data['ageMonths'] as num?)?.toInt() ?? 0,
    gender: _gender(data['gender'] as String?),
    size: _size(data['size'] as String?),
    location: location.isEmpty ? '' : location,
    bio: data['bio'] as String? ?? '',
    photoUrls: unique,
    energyLevel: _energy(data['energyLevel'] as String?),
    vaccinated:
        data['isVaccinated'] as bool? ?? data['vaccinated'] as bool? ?? false,
    chipped:
        data['isMicrochipped'] as bool? ?? data['chipped'] as bool? ?? false,
    sterilized:
        data['isSterilized'] as bool? ?? data['sterilized'] as bool? ?? false,
    traits: _stringList(data['temperament'] ?? data['traits']),
    weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0,
    walking: data['isWalking'] as bool? ?? false,
    activityStatus: (data['walkStatus'] as String? ??
            data['activityStatus'] as String? ??
            '')
        .trim(),
    latitude: coord.latitude,
    longitude: coord.longitude,
    goodWithDogs:
        data['goodWithDogs'] as bool? ??
        data['friendlyWithDogs'] as bool? ??
        false,
    goodWithCats:
        data['goodWithCats'] as bool? ??
        data['friendlyWithCats'] as bool? ??
        false,
    goodWithKids:
        data['goodWithKids'] as bool? ??
        data['friendlyWithKids'] as bool? ??
        false,
    likesTags: _stringList(data['likesTags']),
    dislikesTags: _stringList(data['dislikesTags']),
  );
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString()).toList();
}

String _gender(String? raw) {
  switch (raw) {
    case 'male':
    case 'mužjak':
      return 'mužjak';
    case 'female':
    case 'ženka':
      return 'ženka';
    default:
      return raw ?? '';
  }
}

String _size(String? raw) {
  switch (raw) {
    case 'small':
    case 'mali':
      return 'mali';
    case 'medium':
    case 'srednji':
      return 'srednji';
    case 'xlarge':
    case 'gigantski':
      return 'veliki';
    case 'large':
    case 'veliki':
      return 'veliki';
    default:
      return raw ?? 'srednji';
  }
}

String _energy(String? raw) {
  switch (raw) {
    case 'low':
    case 'niska':
      return 'niska';
    case 'high':
    case 'visoka':
      return 'visoka';
    default:
      return 'umerena';
  }
}

DiscoverProfile discoverProfileFromDog(Dog dog, {String ownerName = ''}) {
  return DiscoverProfile(
    id: dog.id,
    ownerId: dog.ownerId,
    name: dog.name,
    ownerName: ownerName.isEmpty ? dog.ownerId : ownerName,
    breed: dog.breed,
    ageYears: dog.ageYears,
    gender: _gender(dog.gender.firestoreValue),
    size: _size(dog.size.firestoreValue),
    location: dog.location,
    bio: dog.bio,
    photoUrls: uniquePhotoUrls(dog.photoUrls),
    energyLevel: _energy(dog.energyLevel.firestoreValue),
    vaccinated: dog.vaccinated,
    chipped: dog.chipped,
    sterilized: dog.sterilized,
    traits: dog.temperament.map((tag) => tag.firestoreValue).toList(),
    weightKg: dog.weightKg ?? 0,
    likesTags: dog.likesTags,
    dislikesTags: dog.dislikesTags,
  );
}

DiscoverProfile discoverProfileFromUserDog(AppUser user) {
  final dog = user.dog;
  return DiscoverProfile(
    id: dog.id.isEmpty ? 'user-dog' : dog.id,
    ownerId: user.uid,
    name: dog.name,
    ownerName: user.displayName ?? '',
    breed: dog.breed,
    ageYears: dog.age,
    gender: _gender(dog.gender),
    size: _size(dog.size),
    location: user.locationLabel,
    bio: dog.bio,
    photoUrls: uniquePhotoUrls(dog.photoUrls),
    traits: dog.temperament,
    likesTags: dog.likesTags,
    dislikesTags: dog.dislikesTags,
  );
}

Dog dogFromDiscover(
  DiscoverProfile profile, {
  required String ownerId,
  required DogArea area,
}) {
  return Dog(
    id: profile.id,
    ownerId: ownerId,
    name: profile.name,
    breed: profile.breed,
    gender: _genderEnum(profile.gender),
    ageYears: profile.ageYears,
    size: _sizeEnum(profile.size),
    weightKg: profile.weightKg > 0 ? profile.weightKg : null,
    energyLevel: _energyEnum(profile.energyLevel),
    temperament: temperamentFromStored(profile.traits),
    area: area,
    photoUrls: uniquePhotoUrls(profile.photoUrls),
    bio: profile.bio,
    vaccinated: profile.vaccinated,
    chipped: profile.chipped,
    sterilized: profile.sterilized,
    likesTags: profile.likesTags,
    dislikesTags: profile.dislikesTags,
  );
}

List<DogTemperament> temperamentFromStored(Iterable<String> raw) {
  final tags = <DogTemperament>[];
  for (final value in raw) {
    final mapped = _temperamentFromLabel(value);
    if (mapped != null && !tags.contains(mapped)) {
      tags.add(mapped);
    }
  }
  return tags;
}

DogTemperament? _temperamentFromLabel(String raw) {
  final key = raw.trim().toLowerCase();
  for (final value in DogTemperament.values) {
    if (value.firestoreValue == key) {
      return value;
    }
    if (DiscoverProfile.localizeTrait(value.firestoreValue).toLowerCase() ==
        key) {
      return value;
    }
    if (DiscoverProfile.localizeTrait(raw) ==
        DiscoverProfile.localizeTrait(value.firestoreValue)) {
      return value;
    }
  }
  return null;
}

DogGender _genderEnum(String raw) {
  switch (raw) {
    case 'male':
    case 'mužjak':
      return DogGender.male;
    case 'female':
    case 'ženka':
      return DogGender.female;
    default:
      return DogGender.unknown;
  }
}

DogSize _sizeEnum(String raw) {
  switch (raw) {
    case 'small':
    case 'mali':
      return DogSize.small;
    case 'medium':
    case 'srednji':
      return DogSize.medium;
    case 'large':
    case 'xlarge':
    case 'veliki':
      return DogSize.large;
    default:
      return DogSize.medium;
  }
}

DogEnergyLevel _energyEnum(String raw) {
  switch (raw) {
    case 'low':
    case 'niska':
      return DogEnergyLevel.low;
    case 'high':
    case 'visoka':
      return DogEnergyLevel.high;
    default:
      return DogEnergyLevel.moderate;
  }
}

UserDogProfile userDogFromDiscover(DiscoverProfile profile) {
  return UserDogProfile(
    id: profile.id,
    name: profile.name,
    breed: profile.breed,
    age: profile.ageYears,
    gender: profile.gender,
    bio: profile.bio,
    photoUrls: profile.photoUrls,
    size: profile.size,
    temperament: temperamentFromStored(
      profile.traits,
    ).map((tag) => tag.firestoreValue).toList(),
    likesTags: profile.likesTags,
    dislikesTags: profile.dislikesTags,
  );
}
