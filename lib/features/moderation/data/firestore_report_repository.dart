import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../domain/content_report.dart';

class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final Map<String, ReportStatus> _statusOverrides = {};
  final StreamController<void> _overrideTick =
      StreamController<void>.broadcast();

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<List<ContentReport>> watchAll() {
    return Stream.multi((controller) async {
      final user = await FirestoreAuthGuard.ensureReady();
      if (user == null) {
        controller.add(const []);
        await controller.close();
        return;
      }

      var fromReports = <ContentReport>[];
      var fromUsers = <ContentReport>[];

      void emit() {
        if (controller.isClosed) {
          return;
        }
        final byId = <String, ContentReport>{};
        for (final report in [...fromUsers, ...fromReports]) {
          byId[report.id] = report;
        }
        for (final entry in _statusOverrides.entries) {
          final existing = byId[entry.key];
          if (existing != null) {
            byId[entry.key] = existing.copyWith(status: entry.value);
          }
        }
        final list = byId.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        controller.add(list);
      }

      void onWatchError(Object error, StackTrace stack, String label) {
        if (FirestoreAuthGuard.isPermissionDenied(error)) {
          FirestoreAuthGuard.logPermissionDenied(error, stack, label: label);
        } else {
          debugPrint('$label watch failed: $error\n$stack');
        }
      }

      final reportsSub = _reports.snapshots().listen(
        (snapshot) {
          fromReports = snapshot.docs.map(_fromDoc).toList();
          emit();
        },
        onError: (Object error, StackTrace stack) {
          onWatchError(error, stack, 'reports');
          fromReports = [];
          emit();
        },
        cancelOnError: false,
      );

      final usersSub = _users.snapshots().listen(
        (snapshot) {
          fromUsers = _reportsFromUsers(snapshot);
          emit();
        },
        onError: (Object error, StackTrace stack) {
          onWatchError(error, stack, 'reports.users');
          fromUsers = [];
          emit();
        },
        cancelOnError: false,
      );

      final overrideSub = _overrideTick.stream.listen((_) => emit());

      controller.onCancel = () async {
        await reportsSub.cancel();
        await usersSub.cancel();
        await overrideSub.cancel();
      };
    });
  }

  @override
  Future<void> submit(ContentReport report) async {
    final uid = (FirebaseAuth.instance.currentUser?.uid ?? report.reporterId)
        .trim();
    if (uid.isEmpty) {
      throw StateError('Morate biti prijavljeni da biste poslali prijavu.');
    }

    final targetType = report.targetType == ReportContentType.dog
        ? 'dog_profile'
        : report.targetTypeKey;
    final details = report.details ?? '';
    final entry = <String, Object?>{
      'id': report.id,
      'reporterId': uid,
      'reportedBy': uid,
      'reportedByUserId': uid,
      'reportedUserId': report.reportedUserId,
      'targetType': targetType,
      'targetId': report.targetId,
      'reason': report.reason,
      'details': details,
      'status': report.statusKey,
      'createdAt': Timestamp.now(),
      'timestamp': Timestamp.now(),
    };

    // Fast path — return as soon as the reliable write succeeds.
    await _users.doc(uid).set(
      {
        'contentReports': FieldValue.arrayUnion([entry]),
      },
      SetOptions(merge: true),
    );
    debugPrint('Content report saved on users/$uid');

    // Best-effort mirrors — do not block the UI.
    unawaited(_mirrorReport(
      uid: uid,
      report: report,
      entry: entry,
      targetType: targetType,
      details: details,
    ));
  }

  Future<void> _mirrorReport({
    required String uid,
    required ContentReport report,
    required Map<String, Object?> entry,
    required String targetType,
    required String details,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'CONTENT_REPORT',
        'title': 'Prijava sadržaja',
        'message': '${report.reason} — ${report.targetId}',
        'body': details.isEmpty ? report.reason : details,
        'recipientId': uid,
        'toUserId': uid,
        'senderId': uid,
        'fromUserId': uid,
        'reportedByUserId': uid,
        'reportedUserId': report.reportedUserId,
        'targetType': targetType,
        'targetId': report.targetId,
        'reason': report.reason,
        'details': details,
        'reportId': report.id,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'status': 'pending',
      });
    } catch (error) {
      debugPrint('notifications mirror skipped: $error');
    }

    try {
      await _reports.doc(report.id).set({
        ...entry,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('reports mirror skipped: $error');
    }

    try {
      await _firestore.collection('admin_notifications').add({
        'type': 'REPORT_POST_OR_PROFILE',
        'targetId': report.targetId,
        'targetType': targetType,
        'reportedByUserId': uid,
        'reportedUserId': report.reportedUserId,
        'reason': report.reason,
        'details': details,
        'reportId': report.id,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (error) {
      debugPrint('admin_notifications mirror skipped: $error');
    }
  }

  @override
  Future<void> updateStatus({
    required String id,
    required ReportStatus status,
    String reporterId = '',
  }) async {
    // Optimistic UI — admin actions must feel instant even if a remote
    // collection is locked down by undeployed rules.
    _statusOverrides[id] = status;
    if (!_overrideTick.isClosed) {
      _overrideTick.add(null);
    }

    final statusKey = ContentReport.statusKeyOf(status);
    final reviewedAt = FieldValue.serverTimestamp();

    try {
      await _reports.doc(id).update({
        'status': statusKey,
        'reviewedAt': reviewedAt,
      });
      debugPrint('Report $id status → $statusKey (reports)');
    } catch (error) {
      debugPrint('reports status update skipped: $error');
    }

    var uid = reporterId.trim();
    if (uid.isEmpty) {
      uid = await _findReporterId(id) ?? '';
    }
    if (uid.isNotEmpty) {
      for (final field in const ['contentReports', 'placeChangeRequests']) {
        try {
          final patched = await _patchUserArrayStatus(
            userId: uid,
            field: field,
            reportId: id,
            status: statusKey,
          );
          if (patched) {
            debugPrint('Report $id status → $statusKey (users/$uid.$field)');
          }
        } catch (error) {
          debugPrint('users/$uid.$field status update skipped: $error');
        }
      }
    }
  }

  Future<String?> _findReporterId(String reportId) async {
    try {
      final snapshot = await _users.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        for (final field in const ['contentReports', 'placeChangeRequests']) {
          final raw = data[field];
          if (raw is! List) continue;
          for (final item in raw) {
            if (item is Map && (item['id'] as String? ?? '') == reportId) {
              return doc.id;
            }
          }
        }
      }
    } catch (error) {
      debugPrint('findReporterId failed: $error');
    }
    return null;
  }

  Future<bool> _patchUserArrayStatus({
    required String userId,
    required String field,
    required String reportId,
    required String status,
  }) async {
    final ref = _users.doc(userId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return false;
    final raw = data[field];
    if (raw is! List) return false;

    var changed = false;
    final next = <Map<String, Object?>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, Object?>.from(item);
      if ((map['id'] as String? ?? '') == reportId) {
        map['status'] = status;
        map['reviewedAt'] = Timestamp.now();
        changed = true;
      }
      next.add(map);
    }
    if (!changed) return false;
    await ref.set({field: next}, SetOptions(merge: true));
    return true;
  }

  List<ContentReport> _reportsFromUsers(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final items = <ContentReport>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      for (final field in const ['contentReports', 'placeChangeRequests']) {
        final raw = data[field];
        if (raw is! List) continue;
        for (final item in raw) {
          if (item is! Map) continue;
          final report = _fromMap(
            Map<String, dynamic>.from(item),
            fallbackReporterId: doc.id,
            fromPlaceChange: field == 'placeChangeRequests',
          );
          if (report != null) {
            items.add(report);
          }
        }
      }
    }
    return items;
  }

  ContentReport? _fromMap(
    Map<String, dynamic> data, {
    required String fallbackReporterId,
    bool fromPlaceChange = false,
  }) {
    final id = (data['id'] as String? ?? '').trim();
    if (id.isEmpty) return null;
    final raw = data['timestamp'] ?? data['createdAt'];
    final details = (data['details'] as String? ??
            data['description'] as String? ??
            '')
        .trim();
    final reason = (data['reason'] as String? ??
            data['changeType'] as String? ??
            '')
        .trim();
    final targetId = (data['targetId'] as String? ??
            data['placeId'] as String? ??
            '')
        .trim();
    return ContentReport(
      id: id,
      reporterId: data['reporterId'] as String? ??
          data['reportedByUserId'] as String? ??
          fallbackReporterId,
      reportedUserId: data['reportedUserId'] as String? ?? '',
      targetType: ContentReport.typeFromKey(
        data['targetType'] as String? ??
            (fromPlaceChange ? 'poi' : data['contentType'] as String?),
      ),
      targetId: targetId,
      targetName: (data['placeName'] as String? ??
              data['targetName'] as String? ??
              '')
          .trim(),
      reason: reason.isEmpty && fromPlaceChange ? 'Prijava promene' : reason,
      details: details.isEmpty ? null : details,
      timestamp: raw is Timestamp ? raw.toDate() : DateTime.now(),
      status: ContentReport.statusFromKey(data['status'] as String?),
    );
  }

  ContentReport _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _fromMap(doc.data(), fallbackReporterId: '') ??
        ContentReport(
          id: doc.id,
          reporterId: '',
          targetType: ReportContentType.poi,
          targetId: '',
          reason: '',
          timestamp: DateTime.now(),
        );
  }
}
