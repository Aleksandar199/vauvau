class WalkRecord {
  const WalkRecord({
    required this.id,
    required this.userId,
    required this.dogId,
    required this.distanceKm,
    required this.durationSeconds,
    required this.startedAt,
    required this.endedAt,
    this.statusMessage = '',
  });

  final String id;
  final String userId;
  final String dogId;
  final double distanceKm;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime endedAt;
  final String statusMessage;

  Duration get duration => Duration(seconds: durationSeconds);

  String get durationLabel {
    final total = durationSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  String get distanceLabel => '${distanceKm.toStringAsFixed(2)} km';
}
