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
  return LocalReportRepository();
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
    required ReportContentType contentType,
    required String targetId,
    required String reason,
  }) {
    final uid =
        _ref.read(authStateProvider).asData?.value?.uid ?? 'local-user';
    return _ref.read(reportRepositoryProvider).submit(
          ContentReport(
            id: 'report-${DateTime.now().millisecondsSinceEpoch}',
            reportedByUserId: uid,
            contentType: contentType,
            targetId: targetId,
            reason: reason,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> resolve(String id) {
    return _ref.read(reportRepositoryProvider).updateStatus(
          id: id,
          status: ReportStatus.resolved,
        );
  }

  Future<void> dismiss(String id) {
    return _ref.read(reportRepositoryProvider).updateStatus(
          id: id,
          status: ReportStatus.dismissed,
        );
  }
}

final reportControllerProvider = Provider<ReportController>((ref) {
  return ReportController(ref);
});
