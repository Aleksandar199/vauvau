import '../../discover/data/mock_discover_profiles.dart';
import '../../discover/domain/discover_profile.dart';

class UserProfile {
  const UserProfile({
    required this.ownerName,
    required this.ownerBio,
    required this.dogs,
    required this.selectedDogId,
    this.ownerLocation = 'Novi Sad - Liman 3',
    this.phone = '+381 64 123 4567',
    this.joinedAt,
  });

  final String ownerName;
  final String ownerBio;
  final String ownerLocation;
  final String phone;
  final DateTime? joinedAt;
  final List<DiscoverProfile> dogs;
  final String selectedDogId;

  DiscoverProfile get dog {
    for (final item in dogs) {
      if (item.id == selectedDogId) {
        return item;
      }
    }
    return dogs.first;
  }

  List<String> get personalityTags => dog.traits;

  UserProfile copyWith({
    String? ownerName,
    String? ownerBio,
    String? ownerLocation,
    String? phone,
    DateTime? joinedAt,
    List<DiscoverProfile>? dogs,
    String? selectedDogId,
  }) {
    return UserProfile(
      ownerName: ownerName ?? this.ownerName,
      ownerBio: ownerBio ?? this.ownerBio,
      ownerLocation: ownerLocation ?? this.ownerLocation,
      phone: phone ?? this.phone,
      joinedAt: joinedAt ?? this.joinedAt,
      dogs: dogs ?? this.dogs,
      selectedDogId: selectedDogId ?? this.selectedDogId,
    );
  }
}

final UserProfile mockUserProfile = UserProfile(
  ownerName: 'Aleksandar',
  ownerBio: 'Šetač iz Limana. Tražim druženje za Lunu uz Dunav.',
  ownerLocation: 'Novi Sad - Liman 3',
  phone: '+381 64 123 4567',
  joinedAt: DateTime(2025, 4, 12),
  selectedDogId: mockMyDog.id,
  dogs: const [mockMyDog, mockSecondDog],
);
