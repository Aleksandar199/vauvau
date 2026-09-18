import '../../discover/domain/discover_profile.dart';

class WalkingDogPin {
  const WalkingDogPin({
    required this.profile,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  final DiscoverProfile profile;
  final double latitude;
  final double longitude;
  final String status;
}
