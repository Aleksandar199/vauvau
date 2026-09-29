import '../domain/admin_feedback.dart';
import '../domain/support_repository.dart';

class LocalSupportRepository implements SupportRepository {
  final List<AdminFeedback> submitted = [];

  @override
  Future<void> submitFeedback(AdminFeedback feedback) async {
    submitted.add(feedback);
  }
}
