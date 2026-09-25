import '../../../core/geo/geo.dart';
import '../../discover/domain/discover_profile.dart';

abstract class WalkPresenceRepository {
  Future<void> setWalking({
    required String userId,
    String? dogId,
    required bool isWalking,
    required GeoCoord location,
    String? statusMessage,
  });

  Future<void> updateLocation({
    required String userId,
    String? dogId,
    required GeoCoord location,
  });

  Stream<List<WalkingPresence>> watchWalking({required String excludeUserId});
}

class WalkingPresence {
  const WalkingPresence({
    required this.profile,
    required this.coord,
    required this.status,
  });

  final DiscoverProfile profile;
  final GeoCoord coord;
  final String status;
}
