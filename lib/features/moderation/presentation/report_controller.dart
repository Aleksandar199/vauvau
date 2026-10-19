import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/firestore_report_repository.dart';
import '../data/local_report_repository.dart';
import '../domain/content_report.dart';

class HiddenContent extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void hide(String id) {
    state = {...state, id};
  }
}

final hiddenContentProvider =
    NotifierProvider<HiddenContent, Set<String>>(HiddenContent.new);

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreReportRepository(FirebaseFirestore.instance);
  }
  final repo = LocalReportRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final contentReportsProvider = StreamProvider<List<ContentReport>>((ref) {
  return ref.watch(reportRepositoryProvider).watchAll();
});

final activeReportsProvider = Provider<List<ContentReport>>((ref) {
  final reports = ref.watch(contentReportsProvider).asData?.value ?? const [];
  return reports.where((report) => report.isActive).toList();
});

class ReportController {
  ReportController(this._ref);

  final Ref _ref;

  Future<void> submit({
    required ReportContentType targetType,
    required String targetId,
    required String reason,
    String reportedUserId = '',
    String targetName = '',
    String contextId = '',
    String? details,
  }) {
    final uid =
        _ref.read(authStateProvider).asData?.value?.uid ?? 'local-user';
    final trimmed = (details ?? '').trim();
    return _ref.read(reportRepositoryProvider).submit(
          ContentReport(
            id: 'report-${DateTime.now().millisecondsSinceEpoch}',
            reporterId: uid,
            reportedUserId: reportedUserId,
            targetName: targetName.length > 200
                ? targetName.substring(0, 200)
                : targetName,
            contextId: contextId,
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            details: trimmed.isEmpty ? null : trimmed,
            timestamp: DateTime.now(),
          ),
        );
  }

  Future<void> markReviewed(String id, {String reporterId = ''}) {
    return _ref.read(reportRepositoryProvider).updateStatus(
          id: id,
          status: ReportStatus.reviewed,
          reporterId: reporterId,
        );
  }

  Future<void> markActionTaken(String id, {String reporterId = ''}) {
    return _ref.read(reportRepositoryProvider).updateStatus(
          id: id,
          status: ReportStatus.actionTaken,
          reporterId: reporterId,
        );
  }

  Future<void> dismiss(String id, {String reporterId = ''}) {
    return _ref.read(reportRepositoryProvider).updateStatus(
          id: id,
          status: ReportStatus.dismissed,
          reporterId: reporterId,
        );
  }
}

final reportControllerProvider = Provider<ReportController>((ref) {
  return ReportController(ref);
});
