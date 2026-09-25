import 'discover_profile.dart';
import 'geo_query.dart';

abstract class DiscoverRepository {
  Stream<List<DiscoverProfile>> watchProfiles({
    required String excludeOwnerId,
    GeoQuery? geo,
  });

  Future<bool> swipe({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    required String action,
  });
}
