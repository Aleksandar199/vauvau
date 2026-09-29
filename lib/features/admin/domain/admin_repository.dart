import 'admin_models.dart';

abstract class AdminRepository {
  Stream<List<FeedbackEntry>> watchFeedback();

  Stream<List<AdminUserEntry>> watchUsers();

  Future<void> resolveFeedback(String feedbackId);

  Future<void> deleteFeedback(String feedbackId);
}
