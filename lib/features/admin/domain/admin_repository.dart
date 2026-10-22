import '../../app_update/domain/app_update.dart';
import '../../rewards/domain/birthday_reward.dart';
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

  // --- Lookups (batched by AdminDirectory; missing ids → `.unknown`) ---

  Future<Map<String, AdminUserRef>> fetchUsers(Set<String> uids);

  Future<Map<String, AdminDogRef>> fetchDogs(Set<String> dogIds);

  Future<Map<String, AdminMomentRef>> fetchMoments(Set<String> momentIds);

  Future<AdminMessageRef> fetchChatMessage(String chatId, String messageId);

  Future<List<AdminDogRef>> fetchUserDogs(String uid);

  // --- Dashboard ---

  Future<AdminStats> loadStats();

  // --- Users ---

  /// Only `user` ⇄ `partner` (admin role stays a Console-only change).
  Future<void> setUserRole(
    String uid, {
    required String role,
    String partnerId = '',
  });

  Future<void> setUserSuspended(
    String uid, {
    required bool suspended,
    String reason = '',
  });

  // --- Moderation actions ---

  Future<void> deleteDog(String dogId);

  Future<void> deleteChatMessage(String chatId, String messageId);

  // --- Listings: lost dogs, adoption, events, groups ---

  Stream<List<AdminContentItem>> watchContent(AdminContentKind kind);

  /// lost dog → resolved, adoption → adopted, group → approved.
  Future<void> closeContent(AdminContentKind kind, String id);

  Future<void> deleteContent(AdminContentKind kind, String id);

  // --- app_config/android ---

  Future<AppUpdateConfig?> fetchAppConfig();

  Future<void> saveAppConfig(AppUpdateConfig config);

  // --- app_config/birthday (rođendanski poklon) ---

  Future<BirthdayRewardConfig> fetchBirthdayReward();

  Future<void> saveBirthdayReward(BirthdayRewardConfig config);
}
