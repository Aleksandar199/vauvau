import '../../../core/geo/geo.dart';

class WalkSession {
  const WalkSession({
    required this.isActive,
    required this.now,
    this.startedAt,
    this.planned = const Duration(minutes: 30),
    this.statusMessage,
    this.isPaused = false,
    this.pausedAt,
    this.pausedTotal = Duration.zero,
    this.path = const [],
    this.distanceKm = 0,
  });

  final bool isActive;
  final DateTime now;
  final DateTime? startedAt;
  final Duration planned;
  final String? statusMessage;
  final bool isPaused;
  final DateTime? pausedAt;
  final Duration pausedTotal;
  final List<GeoCoord> path;
  final double distanceKm;

  Duration get elapsed {
    if (!isActive || startedAt == null) {
      return Duration.zero;
    }
    var paused = pausedTotal;
    if (isPaused && pausedAt != null) {
      paused += now.difference(pausedAt!);
    }
    final raw = now.difference(startedAt!);
    final active = raw - paused;
    return active.isNegative ? Duration.zero : active;
  }

  String get elapsedLabel {
    final total = elapsed.inSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Average speed in km/h based on moving time.
  double get speedKmh {
    final hours = elapsed.inMilliseconds / 3600000;
    if (hours <= 0) {
      return 0;
    }
    return distanceKm / hours;
  }

  /// Pace in minutes per km.
  double get paceMinPerKm {
    if (distanceKm < 0.01) {
      return 0;
    }
    return (elapsed.inSeconds / 60) / distanceKm;
  }

  /// Rough walking calorie estimate.
  int get caloriesEstimate => (distanceKm * 55).round();

  int get remainingMinutes {
    if (!isActive || startedAt == null) {
      return 0;
    }
    final left = planned - elapsed;
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
    bool? isPaused,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Duration? pausedTotal,
    List<GeoCoord>? path,
    double? distanceKm,
  }) {
    return WalkSession(
      isActive: isActive ?? this.isActive,
      now: now ?? this.now,
      startedAt: startedAt ?? this.startedAt,
      planned: planned ?? this.planned,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      isPaused: isPaused ?? this.isPaused,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      pausedTotal: pausedTotal ?? this.pausedTotal,
      path: path ?? this.path,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
