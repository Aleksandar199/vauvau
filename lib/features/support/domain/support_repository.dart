import 'admin_feedback.dart';

abstract class SupportRepository {
  Future<void> submitFeedback(AdminFeedback feedback);
}
