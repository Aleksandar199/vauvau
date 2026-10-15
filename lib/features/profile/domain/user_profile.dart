import '../../discover/data/mock_discover_profiles.dart';
import '../../auth/domain/owner_details.dart';
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
    this.ownerNeighborhoodName = '',
    this.ownerDetails = const OwnerDetails(),
  });

  final String ownerName;
  final String ownerEmail;
  final String ownerBio;
  final String ownerLocation;
  final String ownerCityId;
  final String ownerNeighborhoodId;
  final String ownerNeighborhoodName;
  final OwnerDetails ownerDetails;
  final List<DiscoverProfile> dogs;
  final String selectedDogId;

  DiscoverProfile get dog {
    if (dogs.isEmpty) {
      return mockMyDog;
    }
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
    String? ownerNeighborhoodName,
    OwnerDetails? ownerDetails,
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
      ownerNeighborhoodName:
          ownerNeighborhoodName ?? this.ownerNeighborhoodName,
      ownerDetails: ownerDetails ?? this.ownerDetails,
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
  ownerNeighborhoodName: 'Liman 3',
  selectedDogId: mockMyDog.id,
  dogs: const [mockMyDog, mockSecondDog],
);
