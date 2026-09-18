import '../domain/discover_profile.dart';

DiscoverProfile discoverProfileFromMap(
  String id,
  Map<String, dynamic> data,
) {
  final gallery = _stringList(data['galleryUrls']);
  final photos = _stringList(data['photoUrls']);
  final photoUrl = data['photoUrl'] as String? ?? '';
  final urls = <String>[
    if (photoUrl.isNotEmpty) photoUrl,
    ...gallery,
    ...photos,
  ];
  final unique = <String>[];
  for (final url in urls) {
    if (url.isNotEmpty && !unique.contains(url)) {
      unique.add(url);
    }
  }
  final area = data['area'] as Map<String, dynamic>?;
  final location = data['location'] as String? ??
      '${area?['cityName'] ?? ''} - ${area?['neighborhoodName'] ?? ''}'.trim();

  return DiscoverProfile(
    id: id,
    ownerId: data['ownerId'] as String? ?? '',
    name: data['name'] as String? ?? '',
    ownerName: data['ownerName'] as String? ?? 'Vlasnik',
    breed: data['breed'] as String? ?? '',
    ageYears: (data['ageYears'] as num?)?.toInt() ??
        (data['age'] as num?)?.toInt() ??
        0,
    gender: _gender(data['gender'] as String?),
    size: _size(data['size'] as String?),
    location: location.isEmpty ? 'Srbija' : location,
    bio: data['bio'] as String? ?? '',
    photoUrls: unique,
    energyLevel: _energy(data['energyLevel'] as String?),
    vaccinated: data['isVaccinated'] as bool? ?? true,
    chipped: data['isMicrochipped'] as bool? ?? true,
    sterilized: data['isSterilized'] as bool? ?? false,
    traits: _stringList(data['temperament']),
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
      return 'gigantski';
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
