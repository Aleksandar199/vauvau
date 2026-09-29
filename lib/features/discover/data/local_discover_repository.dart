import '../domain/discover_profile.dart';
import '../domain/discover_repository.dart';
import '../domain/geo_query.dart';
import 'mock_discover_profiles.dart';

class LocalDiscoverRepository implements DiscoverRepository {
  LocalDiscoverRepository({List<DiscoverProfile>? seed})
      : _profiles = seed ?? mockDiscoverProfiles;

  final List<DiscoverProfile> _profiles;
  final Set<String> _likes = {};

  @override
  Stream<List<DiscoverProfile>> watchProfiles({
    required String excludeOwnerId,
    GeoQuery? geo,
  }) {
    final filtered = List<DiscoverProfile>.from(_profiles);
    return Stream.value(geo == null ? filtered : geo.apply(filtered));
  }

  @override
  Future<bool> swipe({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    required String action,
    String likerName = '',
  }) async {
    if (action != 'like' && action != 'superLike') {
      return false;
    }
    _likes.add('$userId:${target.id}');
    // ignore: avoid_print
    print('DOG LIKE SUCCESS for: ${target.id}');
    return false;
  }

  @override
  Future<bool> hasLiked({
    required String userId,
    required String dogId,
  }) async {
    return _likes.contains('$userId:$dogId');
  }
}
