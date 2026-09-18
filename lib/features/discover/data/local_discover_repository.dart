import '../domain/discover_profile.dart';
import '../domain/discover_repository.dart';
import 'mock_discover_profiles.dart';

class LocalDiscoverRepository implements DiscoverRepository {
  LocalDiscoverRepository({List<DiscoverProfile>? seed})
      : _profiles = seed ?? mockDiscoverProfiles;

  final List<DiscoverProfile> _profiles;
  final Set<String> _likes = {};

  @override
  Stream<List<DiscoverProfile>> watchProfiles({required String excludeOwnerId}) {
    return Stream.value(
      _profiles.where((profile) => profile.ownerId != excludeOwnerId).toList(),
    );
  }

  @override
  Future<bool> swipe({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    required String action,
  }) async {
    if (action != 'like') {
      return false;
    }
    _likes.add('$userId:${target.id}');
    return false;
  }
}
