import 'discover_profile.dart';

abstract class DiscoverRepository {
  Stream<List<DiscoverProfile>> watchProfiles({required String excludeOwnerId});

  Future<bool> swipe({
    required String userId,
    required String myDogId,
    required DiscoverProfile target,
    required String action,
  });
}
