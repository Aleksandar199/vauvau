import '../../discover/data/mock_discover_profiles.dart';
import '../../discover/domain/discover_profile.dart';

class UserProfile {
  const UserProfile({
    required this.ownerName,
    required this.ownerBio,
    required this.dogs,
    required this.selectedDogId,
    this.ownerEmail = '',
    this.ownerLocation = '',
    this.ownerCityId = '',
    this.ownerNeighborhoodId = '',
  });

  final String ownerName;
  final String ownerEmail;
  final String ownerBio;
  final String ownerLocation;
  final String ownerCityId;
  final String ownerNeighborhoodId;
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
    String? ownerEmail,
    String? ownerBio,
    String? ownerLocation,
    String? ownerCityId,
    String? ownerNeighborhoodId,
    List<DiscoverProfile>? dogs,
    String? selectedDogId,
  }) {
    return UserProfile(
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerBio: ownerBio ?? this.ownerBio,
      ownerLocation: ownerLocation ?? this.ownerLocation,
      ownerCityId: ownerCityId ?? this.ownerCityId,
      ownerNeighborhoodId: ownerNeighborhoodId ?? this.ownerNeighborhoodId,
      dogs: dogs ?? this.dogs,
      selectedDogId: selectedDogId ?? this.selectedDogId,
    );
  }
}

final UserProfile mockUserProfile = UserProfile(
  ownerName: 'Aleksandar',
  ownerEmail: 'aleksandar@vauvau.local',
  ownerBio: 'Šetač iz Limana. Tražim druženje za Lunu uz Dunav.',
  ownerLocation: 'Novi Sad · Liman 3',
  ownerCityId: 'novi_sad',
  ownerNeighborhoodId: 'liman_3',
  selectedDogId: mockMyDog.id,
  dogs: const [mockMyDog, mockSecondDog],
);
