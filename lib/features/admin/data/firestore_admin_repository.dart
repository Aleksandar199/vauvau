import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _feedback =>
      firestore.collection('admin_feedback');

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  @override
  Stream<List<FeedbackEntry>> watchFeedback() {
    return _feedback
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs.map(_feedbackFromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    });
  }

  @override
  Stream<List<AdminUserEntry>> watchUsers() {
    return _users.snapshots().map((snapshot) {
      final users = snapshot.docs.map(_userFromDoc).toList()
        ..sort((a, b) {
          final left = a.createdAt;
          final right = b.createdAt;
          if (left == null || right == null) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          return right.compareTo(left);
        });
      return users;
    });
  }

  @override
  Future<void> resolveFeedback(String feedbackId) {
    return _feedback.doc(feedbackId).update({
      'status': FeedbackEntry.statusResolved,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteFeedback(String feedbackId) {
    return _feedback.doc(feedbackId).delete();
  }

  FeedbackEntry _feedbackFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['userName'] as String? ?? '').trim();
    final status = (data['status'] as String? ?? '').trim();
    return FeedbackEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: name.isEmpty ? 'Korisnik' : name,
      userEmail: data['userEmail'] as String? ?? '',
      category: data['category'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: status.isEmpty ? FeedbackEntry.statusNew : status,
      createdAt: doc.metadata.hasPendingWrites
          ? DateTime.now()
          : _date(data['createdAt']) ?? DateTime.now(),
    );
  }

  AdminUserEntry _userFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String? ?? '').trim();
    return AdminUserEntry(
      uid: data['uid'] as String? ?? doc.id,
      name: name.isEmpty ? 'Korisnik' : name,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      createdAt: _date(data['createdAt']),
    );
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
