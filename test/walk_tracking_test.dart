import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/location/domain/location_fix.dart';
import 'package:vauvau/features/map/domain/walk_tracking.dart';

/// ~1 m of latitude in degrees.
const double _m = 1 / 111195.0;
final DateTime _t0 = DateTime.utc(2026, 10, 16, 8);

LocationFix _fix(
  double northM,
  int second, {
  double? acc = 5,
  double? speed,
  bool mocked = false,
  double eastM = 0,
}) => LocationFix(
  latitude: 45.25 + northM * _m,
  longitude: 19.84 + eastM * _m * 1.42,
  timestamp: _t0.add(Duration(seconds: second)),
  accuracyM: acc,
  speedMps: speed,
  isMocked: mocked,
);

/// Feeds fixes with "now" = fix time + 1 s (fresh readings).
WalkTrackState _run(List<LocationFix> fixes, [WalkTrackState? start]) {
  var state = start ?? const WalkTrackState();
  for (final fix in fixes) {
    state = WalkTracker.step(
      state,
      fix,
      now: fix.timestamp.add(const Duration(seconds: 1)),
    );
  }
  return state;
}

void main() {
  group('rastojanje', () {
    test('računa se samo između prihvaćenih tačaka (hod ~4,3 km/h)', () {
      final state = _run([for (var i = 0; i <= 20; i++) _fix(i * 6.0, i * 5)]);
      expect(state.distanceM, closeTo(120, 1));
      expect(state.segments, hasLength(1));
      expect(state.segments.single, hasLength(21));
      expect(state.vehicleDetected, isFalse);
    });

    test('GPS šum ispod praga se ignoriše, ali se spori hod sabira', () {
      // Koraci od 2 m (prag je max(3 m, preciznost/2)).
      final state = _run([for (var i = 0; i <= 6; i++) _fix(i * 2.0, i * 5)]);
      expect(state.distanceM, closeTo(12, 1));
      expect(state.segments.single.length, lessThan(7));
    });

    test('neprecizne, bez preciznosti, zastarele, lažne i neuređene tačke', () {
      var state = _run([_fix(0, 0), _fix(10, 5)]);
      final before = state.distanceM;
      state = _run([
        _fix(30, 10, acc: 45),
        _fix(30, 15, acc: null),
        _fix(30, 20, mocked: true),
        _fix(30, 3), // starija od poslednje prihvaćene
      ], state);
      // Zastarela: stigla 40 s posle merenja.
      state = WalkTracker.step(
        state,
        _fix(40, 25),
        now: _t0.add(const Duration(seconds: 65)),
      );
      expect(state.distanceM, before);
      expect(state.rejectedFixes, 5);
      expect(state.mockDetected, isTrue);
      expect(state.lastVerdict, FixVerdict.stale);
    });
  });

  group('lažiranje', () {
    test('nagli skok (500 m za 5 s) se ne računa i počinje novi segment', () {
      final state = _run([
        _fix(0, 0),
        _fix(6, 5),
        _fix(506, 10),
        _fix(512, 15),
      ]);
      expect(state.distanceM, lessThan(15));
      // Skok uključuje i 60 s „vozila“, pa i tačka posle njega počinje segment.
      expect(state.segments.length, greaterThanOrEqualTo(2));
      expect(state.excludedM, greaterThan(490));
    });

    test('vožnja kolima (50 km/h) se ne računa ni sa crvenim svetlom', () {
      final fixes = <LocationFix>[
        for (var i = 0; i <= 4; i++) _fix(i * 6.0, i * 5), // hod 24 m
        for (var i = 1; i <= 24; i++)
          _fix(24 + i * 69.0, 20 + i * 5), // ~1,6 km
      ];
      var state = _run(fixes);
      expect(state.distanceM, closeTo(24, 1));
      expect(state.excludedM, greaterThan(1500));
      expect(state.vehicleDetected, isTrue);
      expect(state.lastVerdict, FixVerdict.vehicle);
      // Semafor odmah posle vožnje: spori pomaci u 60 s se ne računaju.
      final lastM = 24 + 24 * 69.0;
      state = _run([
        for (var i = 1; i <= 6; i++) _fix(lastM + i * 5.0, 140 + i * 5),
      ], state);
      expect(state.distanceM, closeTo(24, 1));
      // Posle 60 s hoda opet se računa.
      state = _run([
        for (var i = 1; i <= 6; i++) _fix(lastM + 30 + i * 6.0, 200 + i * 5),
      ], state);
      expect(state.distanceM, greaterThan(50));
    });

    test('brzina koju javlja uređaj (> 15 km/h) uključuje režim vozila', () {
      final state = _run([_fix(0, 0), _fix(6, 5, speed: 8.0)]);
      expect(state.distanceM, 0);
      expect(state.lastVerdict, FixVerdict.vehicle);
    });

    test('trčanje brže od 9 km/h se ne računa kao šetnja', () {
      final state = _run([for (var i = 0; i <= 5; i++) _fix(i * 14.0, i * 5)]);
      expect(state.distanceM, 0);
      expect(state.lastVerdict, FixVerdict.tooFast);
    });
  });

  group('signal', () {
    test('posle gubitka signala daleki skok se ne računa, kratak korak da', () {
      var state = _run([_fix(0, 0), _fix(6, 5)]);
      state = _run([_fix(406, 125)], state); // 2 min tišine, 400 m
      expect(state.lastVerdict, FixVerdict.gap);
      expect(state.distanceM, closeTo(6, 0.5));
      state = _run([_fix(456, 245)], state); // 2 min, 50 m
      expect(state.lastVerdict, FixVerdict.accepted);
      expect(state.distanceM, closeTo(56, 1));
    });

    test('pauza prekida segment: pomeranje dok je pauzirano se ne računa', () {
      var state = _run([_fix(0, 0), _fix(6, 5)]);
      state = WalkTracker.breakSegment(state);
      state = _run([_fix(306, 300), _fix(312, 305)], state);
      expect(state.distanceM, closeTo(12, 1));
      expect(state.segments, hasLength(2));
    });

    test('stanje signala: traženje, dobar, slab, izgubljen', () {
      const empty = WalkTrackState();
      expect(WalkTracker.signal(empty, now: _t0), GpsSignal.searching);
      final good = _run([_fix(0, 0)]);
      final now = _t0.add(const Duration(seconds: 2));
      expect(WalkTracker.signal(good, now: now), GpsSignal.good);
      expect(WalkTracker.isApproximate(good, now: now), isFalse);
      final weak = _run([_fix(0, 0, acc: 25)]);
      expect(WalkTracker.signal(weak, now: now), GpsSignal.weak);
      expect(WalkTracker.isApproximate(weak, now: now), isTrue);
      expect(
        WalkTracker.signal(good, now: _t0.add(const Duration(seconds: 45))),
        GpsSignal.lost,
      );
    });

    test('mnogo odbijenih tačaka → kilometraža je približna', () {
      final state = _run([
        _fix(0, 0),
        for (var i = 1; i <= 6; i++) _fix(i * 6.0, i * 5, acc: 60),
        _fix(42, 35),
      ]);
      expect(
        WalkTracker.isApproximate(
          state,
          now: _t0.add(const Duration(seconds: 36)),
        ),
        isTrue,
      );
    });
  });

  group('čuvanje', () {
    test('JSON zadržava rutu, rastojanje i oznake', () {
      final state = _run([
        for (var i = 0; i <= 10; i++) _fix(i * 6.0, i * 5),
        _fix(600, 60, mocked: true),
      ]);
      final restored = WalkTrackState.fromJson(state.toJson());
      expect(restored.distanceM, state.distanceM);
      expect(restored.pointCount, state.pointCount);
      expect(restored.mockDetected, isTrue);
      expect(
        restored.anchor!.timestamp.isAtSameMomentAs(state.anchor!.timestamp),
        isTrue,
      );
    });

    test('proređivanje rute zadržava krajeve segmenata', () {
      final segment = [
        for (var i = 0; i < 2000; i++)
          RoutePoint(
            latitude: i * _m,
            longitude: 0,
            timestamp: _t0.add(Duration(seconds: i)),
          ),
      ];
      final thinned = thinSegments([segment]);
      expect(thinned.single.length, lessThanOrEqualTo(600));
      expect(thinned.single.first, same(segment.first));
      expect(thinned.single.last, same(segment.last));
    });
  });
}
