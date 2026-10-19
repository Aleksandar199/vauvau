enum ReportContentType { user, moment, message, dog, poi, chat }

enum ReportStatus { pending, reviewed, actionTaken, dismissed }

class ContentReport {
  const ContentReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.timestamp,
    this.reportedUserId = '',
    this.targetName = '',
    this.contextId = '',
    this.details,
    this.status = ReportStatus.pending,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportContentType targetType;
  final String targetId;
  /// Human-readable place/profile name when available (e.g. POI placeName).
  final String targetName;
  /// Where the target lives: chat id for a reported 1:1 message.
  final String contextId;
  final String reason;
  final String? details;
  final DateTime timestamp;
  final ReportStatus status;

  bool get isActive => status == ReportStatus.pending;

  ContentReport copyWith({ReportStatus? status, String? targetName}) {
    return ContentReport(
      id: id,
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName ?? this.targetName,
      contextId: contextId,
      reason: reason,
      details: details,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  String get targetTypeKey => targetType.name;

  String get statusKey => statusKeyOf(status);

  static String statusKeyOf(ReportStatus status) {
    return switch (status) {
      ReportStatus.actionTaken => 'action_taken',
      ReportStatus.pending => 'pending',
      ReportStatus.reviewed => 'reviewed',
      ReportStatus.dismissed => 'dismissed',
    };
  }

  static ReportContentType typeFromKey(String? value) {
    return switch (value) {
      'user' => ReportContentType.user,
      'moment' => ReportContentType.moment,
      'message' => ReportContentType.message,
      'poi' => ReportContentType.poi,
      'chat' => ReportContentType.chat,
      'dog' || 'dog_profile' => ReportContentType.dog,
      _ => ReportContentType.dog,
    };
  }

  /// Older documents stored `resolved` before the review states existed.
  static ReportStatus statusFromKey(String? value) {
    return switch (value) {
      'reviewed' || 'resolved' => ReportStatus.reviewed,
      'action_taken' => ReportStatus.actionTaken,
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
    String reporterId = '',
  });
}
