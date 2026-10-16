import 'walk_tracking.dart';

/// A walk the user ended, ready to be saved (and maybe rewarded).
class CompletedWalk {
  const CompletedWalk({
    required this.id,
    required this.userId,
    required this.dogId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.recognizedMeters,
    this.dogName = '',
    this.excludedMeters = 0,
    this.segments = const [],
    this.statusMessage = '',
    this.mockDetected = false,
    this.vehicleDetected = false,
    this.approximate = false,
    this.recovered = false,
    this.acceptedFixes = 0,
    this.rejectedFixes = 0,
  });

  /// Stable per session (survives pause/recovery) → one reward per walk.
  final String id;
  final String userId;
  final String dogId;
  final String dogName;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Active time (pauses excluded).
  final int durationSeconds;

  /// Walking distance that passed the GPS filter, whole meters (floored).
  final int recognizedMeters;
  final int excludedMeters;
  final List<List<RoutePoint>> segments;
  final String statusMessage;
  final bool mockDetected;
  final bool vehicleDetected;
  final bool approximate;

  /// Walk was restored after the app process was killed.
  final bool recovered;
  final int acceptedFixes;
  final int rejectedFixes;

  double get recognizedKm => recognizedMeters / 1000;

  /// Old flow saved only real walks, not accidental taps.
  bool get worthSaving => durationSeconds >= 30 || recognizedMeters >= 50;
}
