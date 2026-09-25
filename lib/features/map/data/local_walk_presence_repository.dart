import '../../../core/geo/geo.dart';
import '../domain/walk_presence_repository.dart';

class LocalWalkPresenceRepository implements WalkPresenceRepository {
  const LocalWalkPresenceRepository();

  @override
  Future<void> setWalking({
    required String userId,
    String? dogId,
    required bool isWalking,
    required GeoCoord location,
    String? statusMessage,
  }) async {}

  @override
  Future<void> updateLocation({
    required String userId,
    String? dogId,
    required GeoCoord location,
  }) async {}

  @override
  Stream<List<WalkingPresence>> watchWalking({required String excludeUserId}) {
    return Stream.value(const []);
  }
}
