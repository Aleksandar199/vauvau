import '../../../core/geo/geo.dart';
import 'walk_tracking.dart';

/// Why GPS is not delivering points (shown in the walk panel).
enum WalkTrackingIssue {
  none,
  permissionDenied,
  servicesDisabled,
  unavailable,
  streamError,
}

class WalkSession {
  const WalkSession({
    required this.isActive,
    required this.now,
    this.id,
    this.startedAt,
    this.planned = const Duration(minutes: 30),
    this.statusMessage,
    this.isPaused = false,
    this.pausedAt,
    this.pausedTotal = Duration.zero,
    this.track = const WalkTrackState(),
    this.dogId = '',
    this.dogName = '',
    this.recovered = false,
    this.issue = WalkTrackingIssue.none,
  });

  final bool isActive;
  final DateTime now;

  /// Unique per walk; the reward ledger uses it so a walk is paid once.
  final String? id;
  final DateTime? startedAt;
  final Duration planned;
  final String? statusMessage;
  final bool isPaused;
  final DateTime? pausedAt;
  final Duration pausedTotal;

  /// GPS filter state: route, counted distance, signal.
  final WalkTrackState track;
  final String dogId;
  final String dogName;

  /// Restored after the app was killed (starts paused).
  final bool recovered;
  final WalkTrackingIssue issue;

  /// Counted (filtered) walking distance.
  double get distanceKm => track.distanceKm;

  /// Route points of every segment, flattened (for the start marker).
  List<GeoCoord> get path => [
        for (final segment in track.segments)
          for (final point in segment) point.coord,
      ];

  GpsSignal get signal => WalkTracker.signal(track, now: now);

  bool get distanceApproximate =>
      issue != WalkTrackingIssue.none ||
      WalkTracker.isApproximate(track, now: now);

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

  /// "1.24 km", or "≈ 1.2 km" while the signal is poor.
  String get distanceLabel => distanceApproximate
      ? '≈ ${distanceKm.toStringAsFixed(1)}'
      : distanceKm.toStringAsFixed(2);

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
    String? id,
    DateTime? startedAt,
    Duration? planned,
    String? statusMessage,
    bool clearStatus = false,
    bool? isPaused,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Duration? pausedTotal,
    WalkTrackState? track,
    String? dogId,
    String? dogName,
    bool? recovered,
    WalkTrackingIssue? issue,
  }) {
    return WalkSession(
      isActive: isActive ?? this.isActive,
      now: now ?? this.now,
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      planned: planned ?? this.planned,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      isPaused: isPaused ?? this.isPaused,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      pausedTotal: pausedTotal ?? this.pausedTotal,
      track: track ?? this.track,
      dogId: dogId ?? this.dogId,
      dogName: dogName ?? this.dogName,
      recovered: recovered ?? this.recovered,
      issue: issue ?? this.issue,
    );
  }

  /// Persisted after every change so a killed process can restore the walk.
  Map<String, Object?> toJson() => {
        'v': 1,
        'id': id,
        'startedAt': startedAt?.millisecondsSinceEpoch,
        'statusMessage': statusMessage,
        'isPaused': isPaused,
        'pausedAt': pausedAt?.millisecondsSinceEpoch,
        'pausedMs': pausedTotal.inMilliseconds,
        'dogId': dogId,
        'dogName': dogName,
        'savedAt': now.millisecondsSinceEpoch,
        'track': track.toJson(),
      };

  /// Null when the stored data is unusable.
  static ({WalkSession session, DateTime savedAt})? fromJson(
    Map<String, Object?> json,
  ) {
    final id = json['id'];
    final started = json['startedAt'];
    final saved = json['savedAt'];
    if (id is! String || id.isEmpty || started is! num || saved is! num) {
      return null;
    }
    final pausedAt = json['pausedAt'];
    final pausedMs = json['pausedMs'];
    final savedAt = DateTime.fromMillisecondsSinceEpoch(saved.toInt());
    return (
      session: WalkSession(
        isActive: true,
        now: savedAt,
        id: id,
        startedAt: DateTime.fromMillisecondsSinceEpoch(started.toInt()),
        statusMessage: json['statusMessage'] as String?,
        isPaused: json['isPaused'] == true,
        pausedAt: pausedAt is num
            ? DateTime.fromMillisecondsSinceEpoch(pausedAt.toInt())
            : null,
        pausedTotal: Duration(
          milliseconds: pausedMs is num ? pausedMs.toInt() : 0,
        ),
        dogId: json['dogId'] as String? ?? '',
        dogName: json['dogName'] as String? ?? '',
        track: WalkTrackState.fromJson(json['track']),
      ),
      savedAt: savedAt,
    );
  }
}
