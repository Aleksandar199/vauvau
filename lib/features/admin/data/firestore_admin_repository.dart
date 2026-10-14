import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../map/data/places_repository.dart';
import '../../map/domain/models/poi_model.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository({
    required this.firestore,
    PlacesRepository? placesRepository,
  }) : _places = placesRepository ?? FirestorePlacesRepository(firestore);

  final FirebaseFirestore firestore;
  final PlacesRepository _places;

  CollectionReference<Map<String, dynamic>> get _feedback =>
      firestore.collection('admin_feedback');

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  @override
  Stream<List<FeedbackEntry>> watchFeedback() {
    return FirestoreAuthGuard.guardedStream<List<FeedbackEntry>>(
      label: 'admin.feedback',
      empty: const [],
      create: () => _feedback
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final entries = snapshot.docs.map(_feedbackFromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return entries;
      }),
    );
  }

  @override
  Stream<List<AdminUserEntry>> watchUsers() {
    return FirestoreAuthGuard.guardedStream<List<AdminUserEntry>>(
      label: 'admin.users',
      empty: const [],
      create: () => _users.snapshots().map((snapshot) {
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
      }),
    );
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

  @override
  Future<String> createPlace(PlaceDraft draft) => _places.createPlace(draft);

  @override
  Future<void> updatePlace(PoiModel poi) => _places.updatePlace(poi);

  @override
  Future<void> deletePlace(String placeId) => _places.deletePlace(placeId);

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
