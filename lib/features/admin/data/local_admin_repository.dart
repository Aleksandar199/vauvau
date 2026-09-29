import 'dart:async';

import '../../support/domain/admin_feedback.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

/// In-memory admin data used when Firebase is not configured (local dev runs
/// and widget tests).
class LocalAdminRepository implements AdminRepository {
  LocalAdminRepository({
    List<FeedbackEntry>? feedback,
    List<AdminUserEntry>? users,
  })  : _feedback = List<FeedbackEntry>.from(feedback ?? _seedFeedback()),
        _users = List<AdminUserEntry>.from(users ?? _seedUsers());

  final List<FeedbackEntry> _feedback;
  final List<AdminUserEntry> _users;
  final StreamController<List<FeedbackEntry>> _feedbackController =
      StreamController<List<FeedbackEntry>>.broadcast();

  void dispose() {
    _feedbackController.close();
  }

  @override
  Stream<List<FeedbackEntry>> watchFeedback() async* {
    yield _sortedFeedback();
    yield* _feedbackController.stream;
  }

  @override
  Stream<List<AdminUserEntry>> watchUsers() async* {
    yield List<AdminUserEntry>.from(_users);
  }

  @override
  Future<void> resolveFeedback(String feedbackId) async {
    for (var i = 0; i < _feedback.length; i++) {
      if (_feedback[i].id == feedbackId) {
        _feedback[i] = _feedback[i].copyWith(
          status: FeedbackEntry.statusResolved,
        );
      }
    }
    _feedbackController.add(_sortedFeedback());
  }

  @override
  Future<void> deleteFeedback(String feedbackId) async {
    _feedback.removeWhere((entry) => entry.id == feedbackId);
    _feedbackController.add(_sortedFeedback());
  }

  List<FeedbackEntry> _sortedFeedback() {
    return List<FeedbackEntry>.from(_feedback)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<FeedbackEntry> _seedFeedback() {
    return [
      FeedbackEntry(
        id: 'feedback-1',
        userId: 'local-user',
        userName: 'Milica',
        userEmail: 'milica@example.com',
        category: AdminFeedback.categories[1],
        subject: 'Mapa se sporo učitava',
        message: 'Kada otvorim mapu na mobilnom podatku, pinovi kasne.',
        status: FeedbackEntry.statusNew,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      FeedbackEntry(
        id: 'feedback-2',
        userId: 'seed-nikola',
        userName: 'Nikola',
        userEmail: 'nikola@example.com',
        category: AdminFeedback.categories.first,
        subject: 'Predlog za nove parkove',
        message: 'Dodajte Futoški park u listu lokacija za šetnje.',
        status: FeedbackEntry.statusResolved,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<AdminUserEntry> _seedUsers() {
    return [
      AdminUserEntry(
        uid: 'local-user',
        name: 'Milica',
        email: 'milica@example.com',
        role: 'user',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      AdminUserEntry(
        uid: 'seed-nikola',
        name: 'Nikola',
        email: 'nikola@example.com',
        role: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      ),
    ];
  }
}
