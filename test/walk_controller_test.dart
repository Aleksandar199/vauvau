import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/location/domain/location_access.dart';
import 'package:vauvau/features/location/domain/location_client.dart';
import 'package:vauvau/features/location/domain/location_fix.dart';
import 'package:vauvau/features/location/presentation/location_controller.dart';
import 'package:vauvau/features/map/data/walk_session_store.dart';
import 'package:vauvau/features/map/domain/walk_session.dart';
import 'package:vauvau/features/map/domain/walk_tracking.dart';
import 'package:vauvau/features/map/presentation/walk_controller.dart';
import 'package:vauvau/features/rewards/data/local_rewards_repository.dart';
import 'package:vauvau/features/rewards/domain/rewards_models.dart';
import 'package:vauvau/features/rewards/presentation/rewards_controller.dart';

const double _m = 1 / 111195.0;

class _FakeGps implements LocationClient {
  LocationAccess access = LocationAccess.granted;
  StreamController<LocationFix> fixes = StreamController.broadcast();
  int listens = 0;

  @override
  Future<LocationAccess> checkPermission() async => access;

  @override
  Future<LocationAccess> requestPermission() async => access;

  @override
  Future<bool> isServiceEnabled() async =>
      access != LocationAccess.servicesDisabled;

  @override
  Future<GeoCoord?> currentPosition() async => null;

  @override
  Stream<GeoCoord> watchPosition() => const Stream.empty();

  @override
  Stream<GeoCoord> watchWalkPosition() => const Stream.empty();

  @override
  Stream<LocationFix> watchWalkFixes() {
    listens++;
    return fixes.stream;
  }

  @override
  Future<void> openAppSettings() async {}
}

class _Harness {
  _Harness() {
    _rewards = LocalRewardsRepository(challenges: const []);
  }

  DateTime now = DateTime.utc(2026, 10, 16, 8);
  final gps = _FakeGps();
  final store = MemoryWalkSessionStore();
  late final LocalRewardsRepository _rewards;
  final List<ProviderContainer> _containers = [];

  LocalRewardsRepository get rewards => _rewards;

  /// A fresh container = a fresh app process (same disk store).
  ProviderContainer boot() {
    final container = ProviderContainer(
      overrides: [
        locationClientProvider.overrideWithValue(gps),
        walkClockProvider.overrideWithValue(() => now),
        rewardsClockProvider.overrideWithValue(() => now),
        walkSessionStoreProvider.overrideWithValue(store),
        rewardsRepositoryProvider.overrideWithValue(_rewards),
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AppUser(uid: 'u1', displayName: 'Ana')),
        ),
      ],
    );
    _containers.add(container);
    return container;
  }

  void dispose() {
    for (final c in _containers) {
      c.dispose();
    }
  }

  /// Walks [meters] north at ~4.3 km/h, one fix per 5 s.
  void walk(WalkController walk, double fromM, double meters) {
    final steps = (meters / 6).round();
    for (var i = 1; i <= steps; i++) {
      now = now.add(const Duration(seconds: 5));
      walk.onFix(fix(fromM + i * 6));
    }
  }

  LocationFix fix(double northM, {double acc = 5}) => LocationFix(
    latitude: 45.25 + northM * _m,
    longitude: 19.84,
    timestamp: now,
    accuracyM: acc,
  );
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<ProviderContainer> _ready(_Harness h) async {
  final c = h.boot();
  // Riverpod 3 pauses providers nobody listens to.
  c.listen(authStateProvider, (_, _) {});
  c.listen(userLocationProvider, (_, _) {});
  c.listen(walkControllerProvider, (_, _) {});
  c.listen(walkRecoveryNoticeProvider, (_, _) {});
  await c.read(authStateProvider.future);
  await _settle();
  return c;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'pauza, nastavak i kraj: pauza se ne računa, šetnja se nagradi jednom',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      final c = await _ready(h);
      final walk = c.read(walkControllerProvider.notifier);

      expect(walk.start(statusMessage: 'U šetnji'), WalkStartResult.started);
      // Druga istovremena šetnja je zabranjena.
      expect(walk.start(), WalkStartResult.alreadyActive);
      final id = c.read(walkControllerProvider).id;

      walk.onFix(h.fix(0));
      h.walk(walk, 0, 600);
      expect(c.read(walkControllerProvider).distanceKm, closeTo(0.6, 0.01));

      walk.pause();
      // Dok je pauzirano: 10 min i 800 m se ne računaju.
      h.now = h.now.add(const Duration(minutes: 10));
      walk.onFix(h.fix(1400));
      expect(c.read(walkControllerProvider).distanceKm, closeTo(0.6, 0.01));

      walk.resume();
      walk.onFix(h.fix(1400)); // nova tačka sidra, bez rastojanja
      h.walk(walk, 1400, 600);
      final session = c.read(walkControllerProvider);
      expect(session.id, id);
      expect(session.distanceKm, closeTo(1.2, 0.02));
      expect(session.track.segments, hasLength(2));
      // ~200 fiksova × 5 s ≈ 16,7 min aktivno (bez 10 min pauze).
      expect(session.elapsed.inMinutes, inInclusiveRange(16, 17));

      final result = await walk.end();
      expect(c.read(walkControllerProvider).isActive, isFalse);
      expect(result, isNotNull);
      expect(result!.saved, isTrue);
      expect(result.points, 5);
      expect(result.xp, 5);
      expect(h.store.stored, isNull);
      expect(h.rewards.walksOf('u1').keys, [id]);
      expect(h.rewards.summaryOf('u1'), const RewardSummary(xp: 5, points: 5));
    },
  );

  test('oporavak posle prekida procesa: šetnja se vraća pauzirana', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final first = await _ready(h);
    final walk = first.read(walkControllerProvider.notifier);
    walk.start();
    walk.onFix(h.fix(0));
    h.walk(walk, 0, 900);
    walk.pause(); // upis na disk odmah
    walk.resume();
    h.walk(walk, 900, 60);
    await _settle();
    final before = first.read(walkControllerProvider);

    // Proces ubijen; aplikacija ponovo pokrenuta 3 minuta kasnije.
    first.dispose();
    h.now = h.now.add(const Duration(minutes: 3));
    final second = await _ready(h);
    final restored = second.read(walkControllerProvider);
    expect(restored.isActive, isTrue);
    expect(restored.isPaused, isTrue);
    expect(restored.recovered, isTrue);
    expect(restored.id, before.id);
    expect(restored.distanceKm, greaterThan(0.85));
    expect(
      second.read(walkRecoveryNoticeProvider),
      WalkRecoveryNotice.restoredPaused,
    );

    // Nastavak: GPS se ponovo pokreće, put dok je app bio ugašen se ne računa.
    final listensBefore = h.gps.listens;
    final again = second.read(walkControllerProvider.notifier);
    again.resume();
    expect(h.gps.listens, listensBefore + 1);
    again.onFix(h.fix(2000));
    expect(
      second.read(walkControllerProvider).distanceKm,
      closeTo(restored.distanceKm, 0.001),
    );
    // Vreme dok je app bio ugašen je pauza.
    expect(
      second.read(walkControllerProvider).elapsed,
      lessThan(before.copyWith(now: h.now).elapsed),
    );
  });

  test('prestara prekinuta šetnja se odbacuje i ne nagrađuje', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final first = await _ready(h);
    final walk = first.read(walkControllerProvider.notifier);
    walk.start();
    walk.onFix(h.fix(0));
    h.walk(walk, 0, 1500);
    walk.pause();
    await _settle();
    first.dispose();

    h.now = h.now.add(const Duration(hours: 7));
    final second = await _ready(h);
    expect(second.read(walkControllerProvider).isActive, isFalse);
    expect(
      second.read(walkRecoveryNoticeProvider),
      WalkRecoveryNotice.discardedTooOld,
    );
    expect(h.store.stored, isNull);
    expect(h.rewards.summaryOf('u1'), RewardSummary.empty);
  });

  test('odjava prekida šetnju bez nagrade', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final c = await _ready(h);
    final walk = c.read(walkControllerProvider.notifier);
    walk.start();
    walk.onFix(h.fix(0));
    h.walk(walk, 0, 1500);
    await walk.stopForSignOut();
    expect(c.read(walkControllerProvider).isActive, isFalse);
    expect(h.store.stored, isNull);
    expect(h.rewards.walksOf('u1'), isEmpty);
    expect(h.rewards.summaryOf('u1'), RewardSummary.empty);
  });

  test(
    'odbijena dozvola i greška GPS-a: kilometraža nije „precizna“',
    () async {
      final h = _Harness()..gps.access = LocationAccess.denied;
      addTearDown(h.dispose);
      final c = await _ready(h);
      final walk = c.read(walkControllerProvider.notifier);
      walk.start();
      var session = c.read(walkControllerProvider);
      expect(session.issue, WalkTrackingIssue.permissionDenied);
      expect(session.distanceApproximate, isTrue);
      expect(session.distanceLabel, startsWith('≈'));

      // GPS isključen usred šetnje → greška toka.
      h.gps.fixes.addError(Exception('Location services disabled'));
      await _settle();
      expect(
        c.read(walkControllerProvider).issue,
        WalkTrackingIssue.streamError,
      );

      h.gps.access = LocationAccess.granted;
      walk.retryGps();
      expect(c.read(walkControllerProvider).issue, WalkTrackingIssue.none);
      h.gps.fixes.add(h.fix(0));
      await _settle();
      session = c.read(walkControllerProvider);
      expect(session.track.acceptedFixes, 1);
      expect(session.issue, WalkTrackingIssue.none);
    },
  );

  test('gubitak signala: posle 30 s bez tačaka signal je izgubljen', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final c = await _ready(h);
    final walk = c.read(walkControllerProvider.notifier);
    walk.start();
    walk.onFix(h.fix(0));
    expect(c.read(walkControllerProvider).signal, GpsSignal.good);
    h.now = h.now.add(const Duration(seconds: 40));
    final later = c.read(walkControllerProvider).copyWith(now: h.now);
    expect(later.signal, GpsSignal.lost);
    expect(later.distanceApproximate, isTrue);
  });

  test('slučajan dodir (bez kretanja) se ne čuva', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final c = await _ready(h);
    final walk = c.read(walkControllerProvider.notifier);
    walk.start();
    expect(await walk.end(), isNull);
    expect(h.rewards.walksOf('u1'), isEmpty);
  });
}
