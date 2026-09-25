import '../../../core/geo/geo.dart';

class DiscoverProfile {
  const DiscoverProfile({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.breed,
    required this.ageYears,
    required this.gender,
    required this.size,
    required this.location,
    required this.bio,
    required this.photoUrls,
    this.energyLevel = 'umerena',
    this.vaccinated = true,
    this.chipped = true,
    this.sterilized = false,
    this.ageMonths = 0,
    this.traits = const [],
    this.distanceKm = 0,
    this.weightKg = 0,
    this.walking = false,
    this.activityStatus = '',
    this.ownerId = '',
    this.latitude,
    this.longitude,
    this.goodWithDogs = false,
    this.goodWithCats = false,
    this.goodWithKids = false,
  });

  final String id;
  final String name;
  final String ownerName;
  final String breed;
  final int ageYears;
  final String gender;
  final String size;
  final String location;
  final String bio;
  final List<String> photoUrls;
  final String energyLevel;
  final bool vaccinated;
  final bool chipped;
  final bool sterilized;
  final int ageMonths;
  final List<String> traits;
  final double distanceKm;
  final double weightKg;
  final bool walking;
  final String activityStatus;
  final String ownerId;
  final double? latitude;
  final double? longitude;
  final bool goodWithDogs;
  final bool goodWithCats;
  final bool goodWithKids;

  String get imageUrl => photoUrls.isEmpty ? '' : photoUrls.first;

  String get photoUrl => imageUrl;

  List<String> get photos => photoUrls;

  String get headline => '$name, $ageLabel';

  String get subtitle {
    final city = cityName;
    return '$breed • $city';
  }

  String get conversationTitle => '$name ($ownerName)';

  List<String> get _placeParts {
    if (location.contains(' · ')) {
      return location.split(' · ');
    }
    return location.split(' - ');
  }

  String get cityName => _placeParts.first;

  String get neighborhoodName {
    final parts = _placeParts;
    return parts.length > 1 ? parts.sublist(1).join(' · ') : '';
  }

  String get distanceLabel {
    if (neighborhoodName.isNotEmpty) {
      return neighborhoodName;
    }
    return cityName;
  }

  String get statusBadge {
    if (activityStatus.isNotEmpty) {
      return activityStatus;
    }
    return walking ? '🟢 U šetnji' : 'Odmaram';
  }

  String get ageLabel {
    if (ageYears <= 0 && ageMonths > 0) {
      return _count(ageMonths, 'mesec', 'meseca', 'meseci');
    }
    return _count(ageYears <= 0 ? 1 : ageYears, 'godina', 'godine', 'godina');
  }

  String get genderLabel {
    switch (gender) {
      case 'male':
      case 'mužjak':
        return 'Mužjak';
      case 'female':
      case 'ženka':
        return 'Ženka';
      default:
        return gender.isEmpty ? 'Nije navedeno' : gender;
    }
  }

  String get sizeLabel {
    switch (size) {
      case 'small':
      case 'mali':
        return 'Mali';
      case 'medium':
      case 'srednji':
        return 'Srednji';
      case 'large':
      case 'xlarge':
      case 'veliki':
        return 'Veliki';
      default:
        return size.isEmpty ? 'Srednji' : size;
    }
  }

  String get energyLabel {
    switch (energyLevel) {
      case 'visoka':
      case 'high':
        return 'Visok';
      case 'niska':
      case 'low':
        return 'Nizak';
      default:
        return 'Umeren';
    }
  }

  List<String> get traitLabels => [
        for (final tag in traits) localizeTrait(tag),
      ];

  List<String> get getsAlongLabels => [
        if (goodWithDogs) 'Psi 🐕',
        if (goodWithCats) 'Mačke 🐈',
        if (goodWithKids) 'Deca 👶',
      ];

  static String localizeTrait(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'friendly':
      case 'druželjubiv':
        return 'Društven';
      case 'playful':
      case 'igračka':
      case 'razigran':
        return 'Razigran';
      case 'energetic':
      case 'energičan':
        return 'Energičan';
      case 'calm':
      case 'miran':
      case 'mirna':
        return 'Miran';
      case 'shy':
      case 'sramežljiv':
        return 'Sramežljiv';
      case 'protective':
      case 'zaštitnički':
        return 'Zaštitnički';
      case 'social':
      case 'društven':
        return 'Društven';
      default:
        return raw;
    }
  }

  static String _count(int value, String one, String few, String many) {
    final n = value.abs();
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (n == 1) {
      return '$n $one';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$n $few';
    }
    return '$n $many';
  }

  GeoCoord? get coord {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) {
      return null;
    }
    return GeoCoord(lat, lng);
  }

  DiscoverProfile copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? breed,
    int? ageYears,
    String? gender,
    String? size,
    String? location,
    String? bio,
    List<String>? photoUrls,
    String? energyLevel,
    bool? vaccinated,
    bool? chipped,
    bool? sterilized,
    int? ageMonths,
    List<String>? traits,
    double? distanceKm,
    double? weightKg,
    bool? walking,
    String? activityStatus,
    String? ownerId,
    double? latitude,
    double? longitude,
    bool? goodWithDogs,
    bool? goodWithCats,
    bool? goodWithKids,
  }) {
    return DiscoverProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      breed: breed ?? this.breed,
      ageYears: ageYears ?? this.ageYears,
      gender: gender ?? this.gender,
      size: size ?? this.size,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      photoUrls: photoUrls ?? this.photoUrls,
      energyLevel: energyLevel ?? this.energyLevel,
      vaccinated: vaccinated ?? this.vaccinated,
      chipped: chipped ?? this.chipped,
      sterilized: sterilized ?? this.sterilized,
      ageMonths: ageMonths ?? this.ageMonths,
      traits: traits ?? this.traits,
      distanceKm: distanceKm ?? this.distanceKm,
      weightKg: weightKg ?? this.weightKg,
      walking: walking ?? this.walking,
      activityStatus: activityStatus ?? this.activityStatus,
      ownerId: ownerId ?? this.ownerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      goodWithDogs: goodWithDogs ?? this.goodWithDogs,
      goodWithCats: goodWithCats ?? this.goodWithCats,
      goodWithKids: goodWithKids ?? this.goodWithKids,
    );
  }
}
