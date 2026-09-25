import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/content_report.dart';

class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  @override
  Stream<List<ContentReport>> watchAll() {
    return _reports.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(_fromDoc).toList(),
        );
  }

  @override
  Future<void> submit(ContentReport report) {
    return _reports.doc(report.id).set({
      'id': report.id,
      'reportedByUserId': report.reportedByUserId,
      'contentType': report.contentTypeKey,
      'targetId': report.targetId,
      'reason': report.reason,
      'status': report.statusKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateStatus({
    required String id,
    required ReportStatus status,
  }) {
    return _reports.doc(id).update({'status': status.name});
  }

  ContentReport _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final created = data['createdAt'];
    return ContentReport(
      id: data['id'] as String? ?? doc.id,
      reportedByUserId: data['reportedByUserId'] as String? ?? '',
      contentType: ContentReport.typeFromKey(data['contentType'] as String?),
      targetId: data['targetId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      status: ContentReport.statusFromKey(data['status'] as String?),
    );
  }
}
