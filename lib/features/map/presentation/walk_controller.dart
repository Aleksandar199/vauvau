import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/domain/geo_query.dart';
import '../../home/presentation/home_tab.dart';
import '../../location/domain/location_access.dart';
import '../../location/domain/location_fix.dart';
import '../../location/presentation/location_controller.dart';
import '../../moderation/presentation/report_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../rewards/domain/reward_rules.dart';
import '../../rewards/domain/rewards_models.dart';
import '../../rewards/presentation/rewards_controller.dart';
import '../data/firestore_walk_presence_repository.dart';
import '../data/local_walk_presence_repository.dart';
import '../data/mock_map_data.dart';
import '../data/walk_session_store.dart';
import '../domain/completed_walk.dart';
import '../domain/map_place.dart';
import '../domain/models/poi_model.dart';
import '../domain/walk_presence_repository.dart';
import '../domain/walk_session.dart';
import '../domain/walk_tracking.dart';
import '../domain/walking_dog_pin.dart';
import 'cities_controller.dart';
import 'poi_report_controller.dart';
import 'user_poi_controller.dart';

final walkSessionStoreProvider = Provider<WalkSessionStore>(
  (ref) => const PrefsWalkSessionStore(),
);

/// Injectable clock for the walk timer and GPS filter (tests).
final walkClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

enum WalkStartResult { started, alreadyActive }

/// Notice for the map after a walk could not be restored.
enum WalkRecoveryNotice { none, restoredPaused, discardedTooOld }

class WalkController extends Notifier<WalkSession> {
  Timer? _timer;
  StreamSubscription<LocationFix>? _fixSub;
  Timer? _persistTimer;
  var _recoveryChecked = false;

  void _notice(WalkRecoveryNotice notice) =>
      ref.read(walkRecoveryNoticeProvider.notifier).show(notice);

  DateTime _now() => ref.read(walkClockProvider)();

  @override
  WalkSession build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _fixSub?.cancel();
      _fixSub = null;
      _persistTimer?.cancel();
    });
    ref.listen<bool>(
      appSettingsProvider.select((settings) => settings.showLocationOnMap),
      (previous, share) {
        if (previous == share || !state.isActive) {
          return;
        }
        unawaited(
          ref.read(walkPresenceRepositoryProvider).setWalking(
                userId: _userId,
                dogId: _dogId,
                isWalking: share,
                location: ref.read(userLocationProvider).coord,
                statusMessage: state.statusMessage,
              ),
        );
      },
    );
    if (!_recoveryChecked) {
      _recoveryChecked = true;
      Future<void>.microtask(recover);
    }
    return WalkSession(isActive: false, now: _now());
  }

  bool get _shareLocation => ref.read(appSettingsProvider).showLocationOnMap;

  /// Restores a walk saved before the process was killed. It comes back
  /// PAUSED (the time while the app was dead counts as a pause, nothing
  /// walked meanwhile is counted); the user resumes or ends it.
  Future<void> recover() async {
    if (state.isActive) return;
    final json = await ref.read(walkSessionStoreProvider).load();
    if (json == null || state.isActive) return;
    final restored = WalkSession.fromJson(json);
    final store = ref.read(walkSessionStoreProvider);
    if (restored == null) {
      await store.clear();
      return;
    }
    final now = _now();
    final session = restored.session;
    if (now.difference(restored.savedAt) > RewardRules.maxRecoveryAge) {
      // Abandoned long ago: an unfinished walk is never rewarded.
      _notice(WalkRecoveryNotice.discardedTooOld);
      await store.clear();
      return;
    }
    final pausedAt = session.isPaused
        ? (session.pausedAt ?? restored.savedAt)
        : restored.savedAt;
    state = session.copyWith(
      now: now,
      isPaused: true,
      pausedAt: pausedAt,
      recovered: true,
      track: WalkTracker.breakSegment(session.track),
    );
    _notice(WalkRecoveryNotice.restoredPaused);
    _startTimer();
    _persistNow();
  }

  /// Starts a walk; a second simultaneous walk is refused.
  WalkStartResult start({
    String? statusMessage,
    String? dogId,
    String? dogName,
  }) {
    if (state.isActive) {
      return WalkStartResult.alreadyActive;
    }
    final now = _now();
    final startCoord = ref.read(userLocationProvider).coord;
    final dog = ref.read(currentDiscoverDogProvider);
    // Not `1 << 32`: on web that is 0 and nextInt(0) throws.
    final rand = math.Random().nextInt(0x7fffffff).toRadixString(36);
    state = WalkSession(
      isActive: true,
      now: now,
      id: 'walk-${now.millisecondsSinceEpoch}-$rand',
      startedAt: now,
      statusMessage: statusMessage,
      dogId: dogId ?? dog.id,
      dogName: dogName ?? dog.name,
      issue: _issueFor(ref.read(userLocationProvider).access),
    );
    _notice(WalkRecoveryNotice.none);
    _startTimer();
    _persistNow();
    // Always publish walk + status to dog/user docs so Discover cards
    // show "U šetnji / Odmaram / Tražim društvo". Map pin sharing stays
    // gated by showLocationOnMap for live location updates.
    unawaited(
      ref.read(walkPresenceRepositoryProvider).setWalking(
            userId: _userId,
            dogId: state.dogId,
            isWalking: true,
            location: startCoord,
            statusMessage: statusMessage,
          ),
    );
    _listenToGps();
    return WalkStartResult.started;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isActive) {
        return;
      }
      state = state.copyWith(now: _now());
    });
  }

  void _listenToGps() {
    _fixSub?.cancel();
    _fixSub = ref.read(locationClientProvider).watchWalkFixes().listen(
          onFix,
          onError: (Object error) {
            debugPrint('Walk GPS stream error: $error');
            if (state.isActive) {
              state = state.copyWith(issue: WalkTrackingIssue.streamError);
            }
          },
          onDone: () {
            _fixSub = null;
            if (state.isActive && !state.isPaused) {
              state = state.copyWith(issue: WalkTrackingIssue.streamError);
            }
          },
        );
  }

  /// GPS switched back on / permission granted during a walk.
  void retryGps() {
    if (!state.isActive) return;
    state = state.copyWith(issue: WalkTrackingIssue.none);
    _listenToGps();
  }

  /// One GPS reading (public for tests).
  void onFix(LocationFix fix) {
    if (!state.isActive || state.isPaused) {
      return;
    }
    final now = _now();
    final track = WalkTracker.step(state.track, fix, now: now);
    final verdict = track.lastVerdict;
    final moved = verdict == FixVerdict.accepted ||
        verdict == FixVerdict.anchored;
    state = state.copyWith(
      track: track,
      now: now,
      issue: WalkTrackingIssue.none,
    );
    _schedulePersist();
    if (!moved && verdict != FixVerdict.tooFast &&
        verdict != FixVerdict.vehicle && verdict != FixVerdict.gap) {
      return;
    }
    final coord = fix.coord;
    ref.read(userLocationProvider.notifier).setCoord(coord);
    if (_shareLocation) {
      unawaited(
        ref.read(walkPresenceRepositoryProvider).updateLocation(
              userId: _userId,
              dogId: state.dogId,
              location: coord,
            ),
      );
    }
  }

  void pause() {
    if (!state.isActive || state.isPaused) {
      return;
    }
    final now = _now();
    state = state.copyWith(
      isPaused: true,
      pausedAt: now,
      now: now,
      track: WalkTracker.breakSegment(state.track),
    );
    _persistNow();
  }

  void resume() {
    if (!state.isActive || !state.isPaused) {
      return;
    }
    final now = _now();
    final pausedAt = state.pausedAt;
    var total = state.pausedTotal;
    if (pausedAt != null) {
      total += now.difference(pausedAt);
    }
    state = state.copyWith(
      isPaused: false,
      pausedTotal: total,
      clearPausedAt: true,
      now: now,
      track: WalkTracker.breakSegment(state.track),
    );
    _persistNow();
    // After a process kill the GPS stream is not running yet.
    if (_fixSub == null) {
      _listenToGps();
    }
  }

  /// Stops GPS + clears Firestore `isWalking` before Auth sign-out.
  /// Must run while the current uid is still available. The walk is
  /// dropped (an interrupted walk is not rewarded).
  Future<void> stopForSignOut() async {
    final userId = _userId;
    final dogId = state.dogId.isEmpty ? _dogId : state.dogId;
    _stopTracking();
    state = WalkSession(isActive: false, now: _now());
    await ref.read(walkSessionStoreProvider).clear();
    if (userId.isEmpty || userId == 'local-user') {
      return;
    }
    try {
      await ref.read(walkPresenceRepositoryProvider).setWalking(
            userId: userId,
            dogId: dogId,
            isWalking: false,
            location: ref.read(userLocationProvider).coord,
          );
    } catch (error) {
      debugPrint('stopForSignOut presence clear failed: $error');
    }
  }

  /// Ends the walk (state resets immediately) and saves it; the future
  /// says what was saved and rewarded. Null for an accidental tap.
  Future<WalkSaveResult?> end() {
    final session = state;
    final startedAt = session.startedAt;
    final userId = _userId;
    final dogId = session.dogId.isEmpty ? _dogId : session.dogId;
    final endedAt = _now();

    _stopTracking();
    state = WalkSession(isActive: false, now: endedAt);
    unawaited(ref.read(walkSessionStoreProvider).clear());
    unawaited(
      ref.read(walkPresenceRepositoryProvider).setWalking(
            userId: userId,
            dogId: dogId,
            isWalking: false,
            location: ref.read(userLocationProvider).coord,
          ),
    );

    if (!session.isActive || startedAt == null || session.id == null) {
      return Future.value();
    }
    final track = session.track;
    final walk = CompletedWalk(
      id: session.id!,
      userId: userId,
      dogId: dogId,
      dogName: session.dogName,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: session.copyWith(now: endedAt).elapsed.inSeconds,
      recognizedMeters: track.distanceM.floor(),
      excludedMeters: track.excludedM.floor(),
      segments: track.segments,
      statusMessage: (session.statusMessage ?? '').trim(),
      mockDetected: track.mockDetected,
      vehicleDetected: track.vehicleDetected,
      approximate: session.distanceApproximate,
      recovered: session.recovered,
      acceptedFixes: track.acceptedFixes,
      rejectedFixes: track.rejectedFixes,
    );
    if (!walk.worthSaving || userId.isEmpty) {
      return Future.value();
    }
    return ref.read(walkRewardsServiceProvider).saveCompletedWalk(walk);
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    // Cancelling the stream stops Android's location foreground service.
    _fixSub?.cancel();
    _fixSub = null;
    _persistTimer?.cancel();
    _persistTimer = null;
  }

  /// GPS fixes arrive every few seconds; write to disk at most every 5 s.
  void _schedulePersist() {
    if (_persistTimer?.isActive ?? false) return;
    _persistTimer = Timer(const Duration(seconds: 5), _persistNow);
  }

  void _persistNow() {
    _persistTimer?.cancel();
    _persistTimer = null;
    if (!state.isActive) return;
    unawaited(ref.read(walkSessionStoreProvider).save(state.toJson()));
  }

  WalkTrackingIssue _issueFor(LocationAccess access) => switch (access) {
        LocationAccess.granted => WalkTrackingIssue.none,
        LocationAccess.denied ||
        LocationAccess.permanentlyDenied =>
          WalkTrackingIssue.permissionDenied,
        LocationAccess.servicesDisabled => WalkTrackingIssue.servicesDisabled,
        LocationAccess.unavailable => WalkTrackingIssue.unavailable,
      };

  String get _userId =>
      ref.read(authStateProvider).asData?.value?.uid ?? 'local-user';

  String get _dogId => ref.read(currentDiscoverDogProvider).id;
}

final walkControllerProvider =
    NotifierProvider<WalkController, WalkSession>(WalkController.new);

final mapPlacesProvider = Provider<List<MapPlace>>((ref) {
  final reported = ref.watch(poiReportsProvider);
  final confirmed = ref.watch(poiConfirmationsProvider);
  final submitted = ref.watch(userPoiSubmissionsProvider);
  final adminPlaces =
      ref.watch(livePlacesProvider).value ?? const <MapPlace>[];
  final hidden = ref.watch(hiddenContentProvider);
  MapPlace applyCommunityFlags(MapPlace place) {
    if (confirmed.contains(place.id)) {
      return place.copyWith(
        verificationStatus: PoiVerificationStatus.verified,
        lastVerified: DateTime.now(),
      );
    }
    if (reported.contains(place.id)) {
      return place.copyWith(
        verificationStatus: PoiVerificationStatus.reported,
        petFriendly: false,
      );
    }
    return place;
  }

  // Merge by id. Priority (last wins): seed < community pois < places (SoT).
  // Seed stays as catalog baseline until Firestore is fully populated; live
  // docs with the same id overwrite seed entries without leaving the map empty.
  final byId = <String, MapPlace>{};
  void put(MapPlace place) {
    if (place.verificationStatus == PoiVerificationStatus.rejected ||
        hidden.contains(place.id) ||
        !place.hasValidCoordinates) {
      return;
    }
    byId[place.id] = place;
  }

  for (final place in mockMapPlaces.map(applyCommunityFlags)) {
    put(place);
  }
  for (final place in submitted.map(MapPlace.fromPoi).map(applyCommunityFlags)) {
    put(place);
  }
  for (final place in adminPlaces.map(applyCommunityFlags)) {
    put(place);
  }
  return byId.values.toList();
});

final walkPresenceRepositoryProvider = Provider<WalkPresenceRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreWalkPresenceRepository(FirebaseFirestore.instance);
  }
  return const LocalWalkPresenceRepository();
});

final liveWalkingDogsProvider =
    StreamProvider.autoDispose<List<WalkingDogPin>>((ref) {
  // IndexedStack keeps MapScreen mounted — only subscribe on the Map tab.
  final onMapTab = ref.watch(homeTabIndexProvider.select((tab) => tab == 1));
  final authReady =
      ref.watch(firestoreAuthReadyProvider).asData?.value ?? false;
  if (!onMapTab || !authReady) {
    return const Stream<List<WalkingDogPin>>.empty();
  }
  // Only the uid: watching the whole AppUser re-subscribed this stream on
  // every users/{uid} snapshot, so walker pins vanished and came back.
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.asData?.value?.uid ?? ''),
  );
  return ref
      .watch(walkPresenceRepositoryProvider)
      .watchWalking(excludeUserId: uid)
      .map(
        (items) => [
          for (final item in items)
            WalkingDogPin(
              profile: item.profile,
              latitude: item.coord.latitude,
              longitude: item.coord.longitude,
              status: item.status,
            ),
        ],
      );
});

final walkingDogsProvider = Provider<List<WalkingDogPin>>((ref) {
  final origin = ref.watch(userLocationProvider.select((l) => l.coord));
  final radius =
      ref.watch(matchingFiltersProvider.select((filters) => filters.radiusKm));
  final geo = GeoQuery(origin: origin, radiusKm: radius);
  // `.value` keeps the last list while the stream reconnects (asData was
  // briefly null and cleared every walker pin).
  final source = isFirebaseReady
      ? (ref.watch(liveWalkingDogsProvider).value ?? const [])
      : mockWalkingDogs;
  return [
    for (final pin in source)
      if (geo.withinRadius(
        pin.profile.copyWith(
          latitude: pin.latitude,
          longitude: pin.longitude,
        ),
      ))
        pin,
  ];
});

class WalkRecoveryNoticeController extends Notifier<WalkRecoveryNotice> {
  @override
  WalkRecoveryNotice build() => WalkRecoveryNotice.none;

  void show(WalkRecoveryNotice notice) => state = notice;
}

/// Shown once on the map after a walk was restored or dropped.
final walkRecoveryNoticeProvider =
    NotifierProvider<WalkRecoveryNoticeController, WalkRecoveryNotice>(
  WalkRecoveryNoticeController.new,
);
