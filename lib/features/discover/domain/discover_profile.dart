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
    this.distanceKm = 1.2,
    this.weightKg = 22,
    this.walking = false,
    this.ownerId = '',
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
  final String ownerId;

  String get headline => '$name, $ageYears god.';

  String get subtitle {
    final city = location.split(' - ').first;
    return '$breed • $city';
  }

  String get conversationTitle => '$name ($ownerName)';

  String get cityName => location.split(' - ').first;

  String get neighborhoodName {
    final parts = location.split(' - ');
    return parts.length > 1 ? parts[1] : '';
  }

  String get distanceLabel {
    final area = neighborhoodName.isEmpty ? cityName : neighborhoodName;
    return '$area, ${distanceKm.toStringAsFixed(1)} km';
  }

  String get energyLabel {
    switch (energyLevel) {
      case 'visoka':
        return 'Visoka';
      case 'niska':
        return 'Niska';
      default:
        return 'Umerena';
    }
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
    String? ownerId,
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
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
