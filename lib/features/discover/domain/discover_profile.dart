import '../../../core/geo/geo.dart';
import '../../../core/l10n/l10n.dart';
import '../../dogs/domain/dog_preference_tags.dart';
import '../presentation/discover_strings.dart';

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
    this.likesTags = const [],
    this.dislikesTags = const [],
    this.createdAt,
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
  final List<String> likesTags;
  final List<String> dislikesTags;
  /// When the dog profile was created (Firestore `createdAt`).
  final DateTime? createdAt;

  /// Default Discover order: newest first, then closer by distance.
  static int compareFeedOrder(DiscoverProfile a, DiscoverProfile b) {
    final aMs = a.createdAt?.millisecondsSinceEpoch ?? 0;
    final bMs = b.createdAt?.millisecondsSinceEpoch ?? 0;
    final byCreated = bMs.compareTo(aMs);
    if (byCreated != 0) {
      return byCreated;
    }
    return a.distanceKm.compareTo(b.distanceKm);
  }

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
    final raw = activityStatus.trim();
    if (raw.isNotEmpty) {
      return decorateWalkStatus(raw);
    }
    return walking
        ? DiscoverStrings.walkingBadge
        : DiscoverStrings.restingBadge;
  }

  /// Normalizes walk/status labels for Discover cards.
  static String decorateWalkStatus(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    final walking = lower.contains('šetnj') || lower.contains('walk');
    final looking = lower.contains('tražim') ||
        lower.contains('looking') ||
        lower.contains('play');
    final resting = lower.contains('odmar') || lower.contains('rest');
    if (walking) {
      return DiscoverStrings.walkingBadge;
    }
    if (looking) {
      return DiscoverStrings.lookingForPlayBadge;
    }
    if (resting) {
      return DiscoverStrings.restingBadge;
    }
    return value;
  }

  String get ageLabel {
    if (ageYears <= 0 && ageMonths > 0) {
      return L10n.isEnglish
          ? _countEn(ageMonths, 'month', 'months')
          : _count(ageMonths, 'mesec', 'meseca', 'meseci');
    }
    final years = ageYears <= 0 ? 1 : ageYears;
    return L10n.isEnglish
        ? _countEn(years, 'year', 'years')
        : _count(years, 'godina', 'godine', 'godina');
  }

  String get genderLabel {
    switch (gender) {
      case 'male':
      case 'mužjak':
        return DiscoverStrings.genderMale;
      case 'female':
      case 'ženka':
        return DiscoverStrings.genderFemale;
      default:
        return gender.isEmpty
            ? L10n.tr('Nije navedeno', 'Not specified')
            : gender;
    }
  }

  String get sizeLabel {
    switch (size) {
      case 'small':
      case 'mali':
        return DiscoverStrings.sizeSmall;
      case 'medium':
      case 'srednji':
        return DiscoverStrings.sizeMid;
      case 'large':
      case 'xlarge':
      case 'veliki':
        return DiscoverStrings.sizeBig;
      default:
        return size.isEmpty ? DiscoverStrings.sizeMid : size;
    }
  }

  String get energyLabel {
    switch (energyLevel) {
      case 'visoka':
      case 'high':
        return DiscoverStrings.energyHigh;
      case 'niska':
      case 'low':
        return DiscoverStrings.energyLow;
      default:
        return DiscoverStrings.energyMid;
    }
  }

  List<String> get traitLabels => [
        for (final tag in traits) localizeTrait(tag),
      ];

  List<String> get getsAlongLabels => [
        if (goodWithDogs) L10n.tr('Psi 🐕', 'Dogs 🐕'),
        if (goodWithCats) L10n.tr('Mačke 🐈', 'Cats 🐈'),
        if (goodWithKids) L10n.tr('Deca 👶', 'Kids 👶'),
      ];

  List<String> get likeLabels => [
        for (final tag in likesTags) DogPreferenceTags.localize(tag),
      ];

  List<String> get dislikeLabels => [
        for (final tag in dislikesTags) DogPreferenceTags.localize(tag),
      ];

  static String localizeTrait(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'friendly':
      case 'druželjubiv':
      case 'social': // legacy duplicate of friendly
      case 'društven':
        return L10n.tr('Društven', 'Friendly');
      case 'playful':
      case 'igračka':
      case 'razigran':
      case 'voli loptice':
      case 'voli lopticu':
        return L10n.tr('Razigran', 'Playful');
      case 'energetic':
      case 'energičan':
        return L10n.tr('Energičan', 'Energetic');
      case 'calm':
      case 'miran':
      case 'mirna':
        return L10n.tr('Miran', 'Calm');
      case 'shy':
      case 'sramežljiv':
        return L10n.tr('Sramežljiv', 'Shy');
      case 'radoznala':
      case 'radoznao':
      case 'curious':
        return L10n.tr('Radoznao', 'Curious');
      case 'protective':
      case 'zaštitnički':
        return L10n.tr('Zaštitnički', 'Protective');
      case 'poslušan':
      case 'obedient':
        return L10n.tr('Poslušan', 'Obedient');
      case 'nežna':
      case 'nežan':
      case 'gentle':
        return L10n.tr('Nežan', 'Gentle');
      case 'plivač':
      case 'swimmer':
        return L10n.tr('Plivač', 'Swimmer');
      case 'mazna':
      case 'mazan':
      case 'cuddly':
        return L10n.tr('Mazan', 'Cuddly');
      case 'avanturista':
      case 'adventurous':
        return L10n.tr('Avanturista', 'Adventurous');
      case 'kafićar':
        return L10n.tr('Kafićar', 'Café buddy');
      case 'voli grickalice':
        return L10n.tr('Voli grickalice', 'Loves treats');
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

  static String _countEn(int value, String one, String many) {
    final n = value.abs();
    return n == 1 ? '$n $one' : '$n $many';
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
    List<String>? likesTags,
    List<String>? dislikesTags,
    DateTime? createdAt,
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
      likesTags: likesTags ?? this.likesTags,
      dislikesTags: dislikesTags ?? this.dislikesTags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
