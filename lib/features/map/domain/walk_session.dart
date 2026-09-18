class WalkSession {
  const WalkSession({
    required this.isActive,
    required this.now,
    this.startedAt,
    this.planned = const Duration(minutes: 30),
    this.statusMessage,
  });

  final bool isActive;
  final DateTime now;
  final DateTime? startedAt;
  final Duration planned;
  final String? statusMessage;

  int get remainingMinutes {
    if (!isActive || startedAt == null) {
      return 0;
    }
    final left = planned - now.difference(startedAt!);
    if (left.isNegative) {
      return 0;
    }
    return left.inMinutes;
  }

  WalkSession copyWith({
    bool? isActive,
    DateTime? now,
    DateTime? startedAt,
    Duration? planned,
    String? statusMessage,
    bool clearStatus = false,
  }) {
    return WalkSession(
      isActive: isActive ?? this.isActive,
      now: now ?? this.now,
      startedAt: startedAt ?? this.startedAt,
      planned: planned ?? this.planned,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }
}
