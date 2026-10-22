import 'dart:math' as math;

import '../../../core/geo/geo.dart';
import '../../location/domain/location_fix.dart';

/// All GPS filter thresholds in one place (see [WalkTracker]).
abstract final class WalkTrackingRules {
  /// Fixes with a worse (larger) accuracy radius are dropped.
  static const double maxAccuracyM = 30;

  /// Above this the signal is shown as weak and km as approximate.
  static const double weakAccuracyM = 20;

  /// Fixes older than this when they arrive are stale (cached/buffered).
  static const Duration maxFixAge = Duration(seconds: 20);

  /// Smallest counted step; the real minimum is max(this, accuracy / 2).
  static const double minStepM = 3;

  /// Faster segments are not walking: not counted, route restarts there.
  static const double maxWalkKmh = 9;

  /// Segment or device speed above this starts "vehicle" mode.
  static const double vehicleKmh = 15;

  /// After a vehicle-speed segment nothing counts for this long (traffic
  /// lights, slow traffic after driving).
  static const Duration vehicleHold = Duration(seconds: 60);

  /// A longer silence between fixes is a signal gap.
  static const Duration maxGap = Duration(seconds: 60);

  /// Across a gap only a short, walking-speed step is counted.
  static const double maxGapStepM = 150;

  /// No fix for this long = signal lost.
  static const Duration lostSignalAfter = Duration(seconds: 30);

  /// More rejected fixes than this share = distance shown as approximate.
  static const double approximateRejectShare = 0.3;

  /// Route points kept for storage (older points are thinned out).
  static const int maxStoredPoints = 600;

  // --- Synthetic-GPS suspicion (see [FixStats]) -------------------------
  // Real GNSS readings vary; many spoofers do not. A walk is flagged only
  // when at least [suspicionSignals] independent signals fire, each over
  // enough samples, so one odd phone does not lose an honest walk.

  /// Fixes needed before accuracy / altitude constancy counts.
  static const int suspicionMinFixes = 40;

  /// Counted steps needed before "no device speed" counts.
  static const int suspicionMinMoving = 30;

  /// Share of counted steps without a device speed that fires the signal.
  static const double suspicionSpeedlessShare = 0.9;

  /// Device speed below this (m/s) counts as "not reported" while moving.
  static const double suspicionMinSpeedMps = 0.2;

  /// Signals (of 3) that make a walk suspicious.
  static const int suspicionSignals = 2;
}

/// What the filter did with one fix.
enum FixVerdict {
  /// First fix (or first after pause/gap): starts a route segment.
  anchored,

  /// Counted: distance added.
  accepted,

  /// Too close to the last point (GPS noise) – ignored.
  jitter,
  inaccurate,
  stale,
  outOfOrder,
  mocked,

  /// Faster than walking – segment not counted.
  tooFast,

  /// Inside vehicle mode – segment not counted.
  vehicle,

  /// Long silence and a big jump – segment not counted.
  gap,
}

enum GpsSignal { searching, good, weak, lost }

/// A stored route point (time + accuracy kept for later review).
class RoutePoint {
  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyM,
  });

  factory RoutePoint.fromFix(LocationFix fix) => RoutePoint(
    latitude: fix.latitude,
    longitude: fix.longitude,
    timestamp: fix.timestamp,
    accuracyM: fix.accuracyM,
  );

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracyM;

  GeoCoord get coord => GeoCoord(latitude, longitude);

  Map<String, Object?> toJson() => {
    'lat': latitude,
    'lng': longitude,
    't': timestamp.millisecondsSinceEpoch,
    if (accuracyM != null) 'acc': double.parse(accuracyM!.toStringAsFixed(1)),
  };

  static RoutePoint? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final lat = raw['lat'];
    final lng = raw['lng'];
    final t = raw['t'];
    if (lat is! num || lng is! num || t is! num) return null;
    final acc = raw['acc'];
    return RoutePoint(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(t.toInt()),
      accuracyM: acc is num ? acc.toDouble() : null,
    );
  }
}

/// Immutable filter state for one walk. Serializable so a walk survives a
/// process kill.
class WalkTrackState {
  const WalkTrackState({
    this.segments = const [],
    this.anchor,
    this.distanceM = 0,
    this.excludedM = 0,
    this.acceptedFixes = 0,
    this.rejectedFixes = 0,
    this.mockDetected = false,
    this.vehicleUntil,
    this.vehicleTime = Duration.zero,
    this.lastFixAt,
    this.lastAccuracyM,
    this.lastVerdict,
    this.stats = const FixStats(),
  });

  /// Route split where counting stopped (pause, vehicle, gap).
  final List<List<RoutePoint>> segments;

  /// Last point distance is measured from.
  final RoutePoint? anchor;

  /// Recognized (counted) walking distance.
  final double distanceM;

  /// Distance moved but not counted (vehicle / too fast / gaps).
  final double excludedM;
  final int acceptedFixes;
  final int rejectedFixes;
  final bool mockDetected;
  final DateTime? vehicleUntil;
  final Duration vehicleTime;

  /// When the last fix of any kind arrived (signal monitoring).
  final DateTime? lastFixAt;
  final double? lastAccuracyM;
  final FixVerdict? lastVerdict;

  /// Evidence for synthetic GPS that is not flagged as a mock provider.
  final FixStats stats;

  double get distanceKm => distanceM / 1000;

  bool get vehicleDetected => vehicleTime > Duration.zero || excludedM >= 200;

  /// Several independent signals say the GPS data is synthetic.
  bool get suspicious => stats.suspicious;

  int get pointCount =>
      segments.fold(0, (sum, segment) => sum + segment.length);

  List<GeoCoord> get lastSegmentCoords =>
      segments.isEmpty ? const [] : [for (final p in segments.last) p.coord];

  WalkTrackState copyWith({
    List<List<RoutePoint>>? segments,
    RoutePoint? anchor,
    bool clearAnchor = false,
    double? distanceM,
    double? excludedM,
    int? acceptedFixes,
    int? rejectedFixes,
    bool? mockDetected,
    DateTime? vehicleUntil,
    Duration? vehicleTime,
    DateTime? lastFixAt,
    double? lastAccuracyM,
    FixVerdict? lastVerdict,
    FixStats? stats,
  }) {
    return WalkTrackState(
      segments: segments ?? this.segments,
      anchor: clearAnchor ? null : (anchor ?? this.anchor),
      distanceM: distanceM ?? this.distanceM,
      excludedM: excludedM ?? this.excludedM,
      acceptedFixes: acceptedFixes ?? this.acceptedFixes,
      rejectedFixes: rejectedFixes ?? this.rejectedFixes,
      mockDetected: mockDetected ?? this.mockDetected,
      vehicleUntil: vehicleUntil ?? this.vehicleUntil,
      vehicleTime: vehicleTime ?? this.vehicleTime,
      lastFixAt: lastFixAt ?? this.lastFixAt,
      lastAccuracyM: lastAccuracyM ?? this.lastAccuracyM,
      lastVerdict: lastVerdict ?? this.lastVerdict,
      stats: stats ?? this.stats,
    );
  }

  Map<String, Object?> toJson() => {
    'segments': [
      for (final segment in thinSegments(segments))
        [for (final p in segment) p.toJson()],
    ],
    if (anchor != null) 'anchor': anchor!.toJson(),
    'distanceM': distanceM,
    'excludedM': excludedM,
    'acceptedFixes': acceptedFixes,
    'rejectedFixes': rejectedFixes,
    'mockDetected': mockDetected,
    if (vehicleUntil != null)
      'vehicleUntil': vehicleUntil!.millisecondsSinceEpoch,
    'vehicleMs': vehicleTime.inMilliseconds,
    'stats': stats.toJson(),
  };

  static WalkTrackState fromJson(Object? raw) {
    if (raw is! Map) return const WalkTrackState();
    final segments = <List<RoutePoint>>[];
    final rawSegments = raw['segments'];
    if (rawSegments is List) {
      for (final rawSegment in rawSegments) {
        if (rawSegment is! List) continue;
        final points = [for (final p in rawSegment) ?RoutePoint.fromJson(p)];
        if (points.isNotEmpty) segments.add(points);
      }
    }
    num n(String key) => raw[key] is num ? raw[key] as num : 0;
    final vehicleUntil = raw['vehicleUntil'];
    return WalkTrackState(
      segments: segments,
      anchor: RoutePoint.fromJson(raw['anchor']),
      distanceM: n('distanceM').toDouble(),
      excludedM: n('excludedM').toDouble(),
      acceptedFixes: n('acceptedFixes').toInt(),
      rejectedFixes: n('rejectedFixes').toInt(),
      mockDetected: raw['mockDetected'] == true,
      vehicleUntil: vehicleUntil is num
          ? DateTime.fromMillisecondsSinceEpoch(vehicleUntil.toInt())
          : null,
      vehicleTime: Duration(milliseconds: n('vehicleMs').toInt()),
      stats: FixStats.fromJson(raw['stats']),
    );
  }
}

/// Pure GPS filter: decides which fixes count as walking distance.
///
/// This is client-side validation – it keeps honest users' numbers clean
/// (noise, driving, tunnels), it is NOT protection against a modified app.
abstract final class WalkTracker {
  static WalkTrackState step(
    WalkTrackState state,
    LocationFix fix, {
    required DateTime now,
  }) {
    final next = _filter(state, fix, now: now);
    const rejected = {
      FixVerdict.mocked,
      FixVerdict.stale,
      FixVerdict.inaccurate,
      FixVerdict.outOfOrder,
    };
    final verdict = next.lastVerdict;
    if (verdict == null || rejected.contains(verdict)) {
      return next;
    }
    return next.copyWith(
      stats: next.stats.add(fix, moved: verdict == FixVerdict.accepted),
    );
  }

  static WalkTrackState _filter(
    WalkTrackState state,
    LocationFix fix, {
    required DateTime now,
  }) {
    final seen = state.copyWith(lastFixAt: now, lastAccuracyM: fix.accuracyM);

    WalkTrackState reject(FixVerdict verdict, {bool mocked = false}) =>
        seen.copyWith(
          rejectedFixes: state.rejectedFixes + 1,
          lastVerdict: verdict,
          mockDetected: mocked ? true : null,
        );

    if (fix.isMocked) {
      return reject(FixVerdict.mocked, mocked: true);
    }
    final age = now.difference(fix.timestamp);
    if (age > WalkTrackingRules.maxFixAge ||
        age < const Duration(seconds: -10)) {
      return reject(FixVerdict.stale);
    }
    final accuracy = fix.accuracyM;
    if (accuracy == null ||
        accuracy.isNaN ||
        accuracy > WalkTrackingRules.maxAccuracyM) {
      return reject(FixVerdict.inaccurate);
    }

    final point = RoutePoint.fromFix(fix);
    final anchor = state.anchor;
    if (anchor == null) {
      return seen.copyWith(
        anchor: point,
        segments: [
          ...state.segments,
          [point],
        ],
        acceptedFixes: state.acceptedFixes + 1,
        lastVerdict: FixVerdict.anchored,
      );
    }
    if (!fix.timestamp.isAfter(anchor.timestamp)) {
      return reject(FixVerdict.outOfOrder);
    }

    final dtSeconds =
        fix.timestamp.difference(anchor.timestamp).inMilliseconds / 1000;
    final stepM = haversineKm(anchor.coord, point.coord) * 1000;
    final speedKmh = stepM / dtSeconds * 3.6;
    final speed = fix.speedMps;
    final deviceKmh = speed != null && speed >= 0 ? speed * 3.6 : null;

    // Restart the route at this point without counting the step.
    WalkTrackState reanchor(FixVerdict verdict, {DateTime? vehicleUntil}) {
      final inVehicle =
          verdict == FixVerdict.vehicle || verdict == FixVerdict.tooFast;
      return seen.copyWith(
        anchor: point,
        segments: [
          ...state.segments,
          [point],
        ],
        excludedM: state.excludedM + stepM,
        vehicleTime: inVehicle
            ? state.vehicleTime +
                  Duration(milliseconds: (dtSeconds * 1000).round())
            : null,
        vehicleUntil: vehicleUntil,
        acceptedFixes: state.acceptedFixes + 1,
        lastVerdict: verdict,
      );
    }

    final isGap = dtSeconds > WalkTrackingRules.maxGap.inSeconds;
    if (isGap &&
        (stepM > WalkTrackingRules.maxGapStepM ||
            speedKmh > WalkTrackingRules.maxWalkKmh)) {
      return reanchor(FixVerdict.gap);
    }

    final minStep = math.max(WalkTrackingRules.minStepM, accuracy / 2);
    final vehicleSpeed =
        speedKmh > WalkTrackingRules.vehicleKmh ||
        (deviceKmh != null && deviceKmh > WalkTrackingRules.vehicleKmh);
    if (stepM < minStep && !vehicleSpeed) {
      // Keep the anchor so slow walking still adds up over several fixes.
      return seen.copyWith(lastVerdict: FixVerdict.jitter);
    }

    if (vehicleSpeed) {
      return reanchor(
        FixVerdict.vehicle,
        vehicleUntil: fix.timestamp.add(WalkTrackingRules.vehicleHold),
      );
    }
    final holdUntil = state.vehicleUntil;
    if (holdUntil != null && fix.timestamp.isBefore(holdUntil)) {
      return reanchor(FixVerdict.vehicle);
    }
    if (speedKmh > WalkTrackingRules.maxWalkKmh) {
      return reanchor(FixVerdict.tooFast);
    }

    final segments = [...state.segments];
    segments[segments.length - 1] = [...segments.last, point];
    return seen.copyWith(
      anchor: point,
      segments: segments,
      distanceM: state.distanceM + stepM,
      acceptedFixes: state.acceptedFixes + 1,
      lastVerdict: FixVerdict.accepted,
    );
  }

  /// Pause / resume / recovery: the next fix starts a new segment, so the
  /// distance covered while not tracking is never counted.
  static WalkTrackState breakSegment(WalkTrackState state) =>
      state.copyWith(clearAnchor: true);

  static GpsSignal signal(WalkTrackState state, {required DateTime now}) {
    final last = state.lastFixAt;
    if (last == null) return GpsSignal.searching;
    if (now.difference(last) > WalkTrackingRules.lostSignalAfter) {
      return GpsSignal.lost;
    }
    final accuracy = state.lastAccuracyM;
    if (accuracy == null ||
        accuracy > WalkTrackingRules.weakAccuracyM ||
        state.lastVerdict == FixVerdict.inaccurate ||
        state.lastVerdict == FixVerdict.stale) {
      return GpsSignal.weak;
    }
    return GpsSignal.good;
  }

  /// True when km should be shown as "≈" instead of a precise value.
  static bool isApproximate(WalkTrackState state, {required DateTime now}) {
    if (signal(state, now: now) != GpsSignal.good) return true;
    final total = state.acceptedFixes + state.rejectedFixes;
    if (total < 5) return false;
    return state.rejectedFixes / total >
        WalkTrackingRules.approximateRejectShare;
  }
}

/// Keeps at most [WalkTrackingRules.maxStoredPoints] points by dropping
/// every other inner point; segment ends always stay.
List<List<RoutePoint>> thinSegments(
  List<List<RoutePoint>> segments, {
  int maxPoints = WalkTrackingRules.maxStoredPoints,
}) {
  var result = segments;
  int count() => result.fold(0, (sum, s) => sum + s.length);
  while (count() > maxPoints) {
    final before = count();
    result = [
      for (final segment in result)
        if (segment.length <= 2)
          segment
        else
          [
            for (var i = 0; i < segment.length; i++)
              if (i == 0 || i == segment.length - 1 || i.isEven) segment[i],
          ],
    ];
    if (count() == before) break;
  }
  return result;
}

/// Counters for spotting synthetic GPS that is NOT flagged as a mock
/// provider (rooted phones that hide it, emulators). Three independent
/// signals; a walk is suspicious when [WalkTrackingRules.suspicionSignals]
/// of them fire:
/// 1. accuracy is exactly the same value for every fix,
/// 2. a real, non-zero altitude never changes,
/// 3. the device reports no speed although the position keeps moving.
///
/// Client-side only (a modified app can skip it) and thresholds are
/// conservative; they still need calibration on real walks.
class FixStats {
  const FixStats({
    this.samples = 0,
    this.accuracyKeys = const [],
    this.altitudeSamples = 0,
    this.altitudeKeys = const [],
    this.movingSamples = 0,
    this.speedlessMoving = 0,
  });

  /// Fixes that passed the basic checks (not mocked / stale / inaccurate).
  final int samples;

  /// Up to two distinct accuracy values (×10) – we only need "1 or more".
  final List<int> accuracyKeys;
  final int altitudeSamples;
  final List<int> altitudeKeys;

  /// Fixes that added walking distance.
  final int movingSamples;

  /// Of those, fixes where the device reported (almost) no speed.
  final int speedlessMoving;

  FixStats add(LocationFix fix, {required bool moved}) {
    final accuracy = fix.accuracyM;
    final altitude = fix.altitudeM;
    final hasAltitude = altitude != null && altitude != 0 && altitude.isFinite;
    final speed = fix.speedMps;
    final speedless =
        speed == null || speed < WalkTrackingRules.suspicionMinSpeedMps;
    return FixStats(
      samples: samples + 1,
      accuracyKeys: accuracy == null
          ? accuracyKeys
          : _withKey(accuracyKeys, (accuracy * 10).round()),
      altitudeSamples: altitudeSamples + (hasAltitude ? 1 : 0),
      altitudeKeys: hasAltitude
          ? _withKey(altitudeKeys, (altitude * 10).round())
          : altitudeKeys,
      movingSamples: movingSamples + (moved ? 1 : 0),
      speedlessMoving: speedlessMoving + (moved && speedless ? 1 : 0),
    );
  }

  static List<int> _withKey(List<int> keys, int key) {
    if (keys.length >= 2 || keys.contains(key)) return keys;
    return [...keys, key];
  }

  bool get constantAccuracy =>
      samples >= WalkTrackingRules.suspicionMinFixes &&
      accuracyKeys.length <= 1;

  bool get constantAltitude =>
      altitudeSamples >= WalkTrackingRules.suspicionMinFixes &&
      altitudeKeys.length <= 1;

  bool get missingSpeed =>
      movingSamples >= WalkTrackingRules.suspicionMinMoving &&
      speedlessMoving / movingSamples >=
          WalkTrackingRules.suspicionSpeedlessShare;

  int get signals => [
    constantAccuracy,
    constantAltitude,
    missingSpeed,
  ].where((fired) => fired).length;

  bool get suspicious => signals >= WalkTrackingRules.suspicionSignals;

  Map<String, Object?> toJson() => {
    'n': samples,
    'acc': accuracyKeys,
    'altN': altitudeSamples,
    'alt': altitudeKeys,
    'mov': movingSamples,
    'nospeed': speedlessMoving,
  };

  static FixStats fromJson(Object? raw) {
    if (raw is! Map) return const FixStats();
    int n(String key) => raw[key] is num ? (raw[key] as num).toInt() : 0;
    List<int> keys(String key) => raw[key] is List
        ? [
            for (final v in raw[key] as List)
              if (v is num) v.toInt(),
          ].take(2).toList()
        : const [];
    return FixStats(
      samples: n('n'),
      accuracyKeys: keys('acc'),
      altitudeSamples: n('altN'),
      altitudeKeys: keys('alt'),
      movingSamples: n('mov'),
      speedlessMoving: n('nospeed'),
    );
  }
}
