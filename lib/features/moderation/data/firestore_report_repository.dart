import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/content_report.dart';

class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  /// Sorted client-side so reports written before the `timestamp` field
  /// existed are still listed instead of dropped by an `orderBy` filter.
  @override
  Stream<List<ContentReport>> watchAll() {
    return _reports.snapshots().map((snapshot) {
      final reports = snapshot.docs.map(_fromDoc).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  @override
  Future<void> submit(ContentReport report) async {
    await _reports.doc(report.id).set({
      'id': report.id,
      'reporterId': report.reporterId,
      'reportedBy': report.reporterId,
      'reportedByUserId': report.reporterId,
      'reportedUserId': report.reportedUserId,
      'targetType': report.targetType == ReportContentType.dog
          ? 'dog_profile'
          : report.targetTypeKey,
      'targetId': report.targetId,
      'reason': report.reason,
      'details': report.details ?? '',
      'status': report.statusKey,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('admin_notifications').add({
      'type': 'REPORT_POST_OR_PROFILE',
      'targetId': report.targetId,
      'targetType': report.targetType == ReportContentType.dog
          ? 'dog_profile'
          : report.targetTypeKey,
      'reportedByUserId': report.reporterId,
      'reportedUserId': report.reportedUserId,
      'reason': report.reason,
      'details': report.details ?? '',
      'reportId': report.id,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  @override
  Future<void> updateStatus({
    required String id,
    required ReportStatus status,
  }) {
    return _reports.doc(id).update({
      'status': ContentReport.statusKeyOf(status),
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  ContentReport _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final raw = data['timestamp'] ?? data['createdAt'];
    final details = (data['details'] as String? ?? '').trim();
    return ContentReport(
      id: data['id'] as String? ?? doc.id,
      reporterId: data['reporterId'] as String? ??
          data['reportedByUserId'] as String? ??
          '',
      reportedUserId: data['reportedUserId'] as String? ?? '',
      targetType: ContentReport.typeFromKey(
        data['targetType'] as String? ?? data['contentType'] as String?,
      ),
      targetId: data['targetId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      details: details.isEmpty ? null : details,
      timestamp: raw is Timestamp ? raw.toDate() : DateTime.now(),
      status: ContentReport.statusFromKey(data['status'] as String?),
    );
  }
}
