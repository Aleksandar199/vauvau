import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/location/domain/location_fix.dart';
import 'package:vauvau/features/map/domain/completed_walk.dart';
import 'package:vauvau/features/map/domain/walk_session.dart';
import 'package:vauvau/features/map/domain/walk_tracking.dart';
import 'package:vauvau/features/map/presentation/map_strings.dart';
import 'package:vauvau/features/map/presentation/widgets/walk_stats_panel.dart';
import 'package:vauvau/features/rewards/data/local_rewards_repository.dart';
import 'package:vauvau/features/rewards/data/reward_payloads.dart';
import 'package:vauvau/features/rewards/domain/earner_stats.dart';
import 'package:vauvau/features/rewards/domain/reward_rules.dart';
import 'package:vauvau/features/rewards/domain/rewards_models.dart';

const double _m = 1 / 111195.0;
final DateTime _t0 = DateTime.utc(2026, 10, 22, 8);

LocationFix _fix(
  int i, {
  double? acc,
  double? alt,
  double? speed,
  bool mocked = false,
}) => LocationFix(
  latitude: 45.25 + i * 6.0 * _m,
  longitude: 19.84,
  timestamp: _t0.add(Duration(seconds: i * 5)),
  accuracyM: acc,
  altitudeM: alt,
  speedMps: speed,
  isMocked: mocked,
);

/// [count] fixes, one every 5 s, 6 m apart (≈ 4.3 km/h).
WalkTrackState _walk(
  int count,
  LocationFix Function(int i) make, [
  WalkTrackState? from,
]) {
  var state = from ?? const WalkTrackState();
  for (var i = 0; i < count; i++) {
    final fix = make(i);
    state = WalkTracker.step(
      state,
      fix,
      now: fix.timestamp.add(const Duration(seconds: 1)),
    );
  }
  return state;
}

/// What a real phone sends: accuracy, altitude and speed all fluctuate.
LocationFix _natural(int i) => _fix(
  i,
  acc: 4 + (i * 7 % 9) * 0.6,
  alt: 84 + (i * 5 % 11) * 0.4,
  speed: 1.0 + (i % 4) * 0.1,
);

final DateTime _now = DateTime.utc(2026, 10, 22, 10);

CompletedWalk _completed({
  bool suspicious = false,
  bool mock = false,
  int meters = 2500,
}) => CompletedWalk(
  id: 'w1',
  userId: 'u1',
  dogId: 'd',
  startedAt: _now.subtract(const Duration(minutes: 31)),
  endedAt: _now.subtract(const Duration(minutes: 1)),
  durationSeconds: 1800,
  recognizedMeters: meters,
  suspiciousGps: suspicious,
  mockDetected: mock,
);

LedgerEntry _walkEntry(
  String uid,
  int points,
  int dayKey, {
  int km = 6,
  DateTime? at,
}) => LedgerEntry(
  id: 'walk_${uid}_$dayKey$points',
  type: LedgerType.walk,
  xp: points,
  points: points,
  reason: 'Šetnja',
  createdAt: at ?? _now.subtract(const Duration(hours: 5)),
  periodKey: dayKey,
  km: km,
  userId: uid,
);

void main() {
  group('Sumnjiv GPS (FixStats)', () {
    test(
      'sintetički signal: ista preciznost, visina i bez brzine → sumnjivo',
      () {
        final state = _walk(60, (i) => _fix(i, acc: 5.0, alt: 85.0, speed: 0));
        expect(state.stats.constantAccuracy, isTrue);
        expect(state.stats.constantAltitude, isTrue);
        expect(state.stats.missingSpeed, isTrue);
        expect(state.suspicious, isTrue);
        // Distanca se i dalje računa – odluka o nagradi je na pravilima.
        expect(state.distanceKm, greaterThan(0.3));
      },
    );

    test('prirodan signal (promenljivo sve) nije sumnjiv', () {
      final state = _walk(80, _natural);
      expect(state.stats.signals, 0);
      expect(state.suspicious, isFalse);
    });

    test('jedan signal nije dovoljan (telefon sa konstantnom preciznošću)', () {
      final state = _walk(
        80,
        (i) => _fix(i, acc: 5.0, alt: 84 + (i % 7) * 0.5, speed: 1.1),
      );
      expect(state.stats.constantAccuracy, isTrue);
      expect(state.stats.signals, 1);
      expect(state.suspicious, isFalse);
    });

    test('prekratka šetnja se ne ocenjuje (premalo tačaka)', () {
      final state = _walk(25, (i) => _fix(i, acc: 5.0, alt: 85.0, speed: 0));
      expect(state.stats.signals, 0);
      expect(state.suspicious, isFalse);
    });

    test('visina 0 ili nepoznata nikad nije dokaz', () {
      final zero = _walk(
        60,
        (i) => _fix(i, acc: 4 + (i % 5) * 0.7, alt: 0, speed: 1.1),
      );
      final unknown = _walk(
        60,
        (i) => _fix(i, acc: 4 + (i % 5) * 0.7, speed: 1.1),
      );
      expect(zero.stats.constantAltitude, isFalse);
      expect(unknown.stats.constantAltitude, isFalse);
      expect(zero.suspicious, isFalse);
    });

    test('mock tačke ne ulaze u statistiku, ali označavaju šetnju', () {
      final state = _walk(50, (i) => _fix(i, acc: 5.0, speed: 0, mocked: true));
      expect(state.mockDetected, isTrue);
      expect(state.stats.samples, 0);
    });

    test('statistika se čuva u JSON-u (oporavak posle prekida procesa)', () {
      final state = _walk(60, (i) => _fix(i, acc: 5.0, alt: 85.0, speed: 0));
      final restored = WalkTrackState.fromJson(state.toJson());
      expect(restored.stats.samples, state.stats.samples);
      expect(restored.suspicious, isTrue);
      // Dalje praćenje nastavlja gde je stalo.
      final more = _walk(
        5,
        (i) => _fix(60 + i, acc: 8.0, alt: 90.0, speed: 1.2),
        restored,
      );
      expect(more.stats.accuracyKeys.length, 2);
      expect(more.stats.constantAccuracy, isFalse);
    });
  });

  group('Pravila nagrade za sumnjiv GPS i platformu', () {
    test('sumnjiv GPS i lažna lokacija ne donose poene', () {
      expect(
        RewardRules.ineligibleReason(_completed(suspicious: true)),
        WalkIneligibleReason.suspiciousGps,
      );
      expect(
        RewardRules.ineligibleReason(_completed(mock: true, suspicious: true)),
        WalkIneligibleReason.mockLocation,
      );
      expect(
        RewardRules.countsTowardChallenges(_completed(suspicious: true)),
        isFalse,
      );
      expect(RewardRules.ineligibleReason(_completed()), isNull);
    });

    test('web (osim debug) ne donosi poene; telefon da', () {
      expect(
        RewardRules.ineligibleReason(_completed(), platformAllowed: false),
        WalkIneligibleReason.unsupportedPlatform,
      );
      expect(
        RewardRules.ineligibleReason(_completed(), platformAllowed: true),
        isNull,
      );
      // U testu (Dart VM, nije web) platforma je dozvoljena.
      expect(RewardRules.platformCanEarn, isTrue);
    });

    test('sumnjiva šetnja se čuva, ali saldo ostaje 0', () async {
      final repo = LocalRewardsRepository(challenges: const []);
      final result = await repo.saveWalk(
        _completed(suspicious: true),
        now: _now,
      );
      expect(result.saved, isTrue);
      expect(result.points, 0);
      expect(result.ineligibleReason, WalkIneligibleReason.suspiciousGps);
      expect(repo.summaryOf('u1'), RewardSummary.empty);
    });

    test('oznaka se čita iz sačuvane šetnje (ponovni obračun)', () {
      final walk = completedWalkFromDoc('u1', 'w1', {
        'startedAt': _now.subtract(const Duration(minutes: 40)),
        'endedAt': _now.subtract(const Duration(minutes: 10)),
        'recognizedMeters': 3000,
        'durationSeconds': 1800,
        'flags': {'suspicious': true},
      });
      expect(walk?.suspiciousGps, isTrue);
    });
  });

  group('Admin: najveća zarada', () {
    test(
      'sabira poene po korisniku i prepoznaje dnevni limit skoro svaki dan',
      () {
        final entries = [
          // Varalica: limit (30) svih 6 dana.
          for (var d = 0; d < 6; d++)
            _walkEntry(
              'cheat',
              30,
              20261016 + d,
              at: _now.subtract(Duration(days: d, hours: 1)),
            ),
          // Običan korisnik: 2 šetnje.
          _walkEntry('ana', 10, 20261021, km: 2),
          _walkEntry('ana', 5, 20261022, km: 1),
          // Staro (van 7 dana) i ne-šetnja se ne računaju.
          _walkEntry(
            'old',
            30,
            20261001,
            at: _now.subtract(const Duration(days: 20)),
          ),
          LedgerEntry(
            id: 'ch',
            type: LedgerType.challenge,
            xp: 10,
            points: 10,
            reason: 'Izazov',
            createdAt: _now,
            userId: 'ana',
          ),
        ];
        final top = EarnerStats.top(entries, now: _now);
        expect(top.map((e) => e.userId), ['cheat', 'ana']);
        expect(top.first.points, 180);
        expect(top.first.daysAtCap, 6);
        expect(top.first.looksSuspicious, isTrue);
        expect(top.last.points, 15);
        expect(top.last.looksSuspicious, isFalse);
      },
    );

    test('prazna lista i unosi bez korisnika', () {
      expect(EarnerStats.top(const [], now: _now), isEmpty);
      expect(EarnerStats.top([_walkEntry('', 10, 1)], now: _now), isEmpty);
    });
  });

  testWidgets('tokom šetnje piše da je lažna lokacija otkrivena', (
    tester,
  ) async {
    Future<void> pump(WalkTrackState track) => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WalkTrackingStatus(
              walk: WalkSession(
                isActive: true,
                now: DateTime.now(),
                track: track,
              ),
            ),
          ),
        ),
      ),
    );
    await pump(const WalkTrackState(mockDetected: true));
    expect(find.text(MapStrings.mockLocationWarning), findsOneWidget);
    await pump(const WalkTrackState());
    expect(find.text(MapStrings.mockLocationWarning), findsNothing);
  });
}
