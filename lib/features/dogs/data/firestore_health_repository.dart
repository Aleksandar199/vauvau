import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/health_record.dart';
import '../domain/health_repository.dart';

class FirestoreHealthRepository implements HealthRepository {
  FirestoreHealthRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _col(String dogId) {
    return firestore.collection('dogs').doc(dogId).collection('health_records');
  }

  @override
  Stream<List<HealthRecord>> watchRecords(String dogId) {
    if (dogId.isEmpty) {
      return Stream.value(const []);
    }
    return _col(dogId).snapshots().map((snapshot) {
      final records = [
        for (final doc in snapshot.docs) _fromDoc(dogId, doc),
      ]..sort((a, b) => b.administeredDate.compareTo(a.administeredDate));
      return records;
    });
  }

  @override
  Future<String> saveRecord(HealthRecord record) async {
    final ref = record.id.isEmpty
        ? _col(record.dogId).doc()
        : _col(record.dogId).doc(record.id);
    final due = record.nextDueDate;
    try {
      await ref.set({
        'id': ref.id,
        'dogId': record.dogId,
        'category': record.category.firestoreValue,
        'title': record.title.trim(),
        'administeredDate': Timestamp.fromDate(record.administeredDate),
        'nextDueDate': due == null ? null : Timestamp.fromDate(due),
        'notes': record.notes?.trim() ?? '',
        'notificationId': record.notificationId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return ref.id;
    } catch (error, stack) {
      debugPrint('Health record save FAILED: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  @override
  Future<void> deleteRecord({
    required String dogId,
    required String recordId,
  }) {
    return _col(dogId).doc(recordId).delete();
  }

  HealthRecord _fromDoc(
    String dogId,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final notes = (data['notes'] as String? ?? '').trim();
    return HealthRecord(
      id: doc.id,
      dogId: data['dogId'] as String? ?? dogId,
      category: HealthCategoryX.fromString(data['category'] as String?) ??
          HealthCategory.vaccineRabies,
      title: (data['title'] as String? ?? '').trim(),
      administeredDate: _date(data['administeredDate']) ?? DateTime.now(),
      nextDueDate: _date(data['nextDueDate']),
      notes: notes.isEmpty ? null : notes,
      notificationId: (data['notificationId'] as num?)?.toInt(),
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
