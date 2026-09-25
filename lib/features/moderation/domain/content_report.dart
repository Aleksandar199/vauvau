enum ReportContentType { dog, poi, chat }

enum ReportStatus { pending, resolved, dismissed }

class ContentReport {
  const ContentReport({
    required this.id,
    required this.reportedByUserId,
    required this.contentType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.status = ReportStatus.pending,
  });

  final String id;
  final String reportedByUserId;
  final ReportContentType contentType;
  final String targetId;
  final String reason;
  final DateTime createdAt;
  final ReportStatus status;

  bool get isActive => status == ReportStatus.pending;

  ContentReport copyWith({ReportStatus? status}) {
    return ContentReport(
      id: id,
      reportedByUserId: reportedByUserId,
      contentType: contentType,
      targetId: targetId,
      reason: reason,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  String get contentTypeKey => contentType.name;

  String get statusKey => status.name;

  static ReportContentType typeFromKey(String? value) {
    return switch (value) {
      'poi' => ReportContentType.poi,
      'chat' => ReportContentType.chat,
      _ => ReportContentType.dog,
    };
  }

  static ReportStatus statusFromKey(String? value) {
    return switch (value) {
      'resolved' => ReportStatus.resolved,
      'dismissed' => ReportStatus.dismissed,
      _ => ReportStatus.pending,
    };
  }
}

abstract class ReportRepository {
  Stream<List<ContentReport>> watchAll();

  Future<void> submit(ContentReport report);

  Future<void> updateStatus({
    required String id,
    required ReportStatus status,
  });
}
