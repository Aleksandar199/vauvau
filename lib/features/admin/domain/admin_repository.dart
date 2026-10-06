import '../../map/data/places_repository.dart';
import '../../map/domain/models/poi_model.dart';
import 'admin_models.dart';

abstract class AdminRepository {
  Stream<List<FeedbackEntry>> watchFeedback();

  Stream<List<AdminUserEntry>> watchUsers();

  Future<void> resolveFeedback(String feedbackId);

  Future<void> deleteFeedback(String feedbackId);

  /// Official places: `places` is source of truth; writes are batched with `pois`.
  Future<String> createPlace(PlaceDraft draft);

  Future<void> updatePlace(PoiModel poi);

  Future<void> deletePlace(String placeId);
}
