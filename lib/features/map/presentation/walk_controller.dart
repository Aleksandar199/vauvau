import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/geo/geo.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../discover/domain/geo_query.dart';
import '../../location/presentation/location_controller.dart';
import '../../moderation/presentation/report_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/firestore_walk_presence_repository.dart';
import '../data/local_walk_presence_repository.dart';
import '../data/mock_map_data.dart';
import '../domain/map_place.dart';
import '../domain/models/poi_model.dart';
import '../domain/walk_presence_repository.dart';
import '../domain/walk_record.dart';
import '../domain/walk_session.dart';
import '../domain/walking_dog_pin.dart';
import 'cities_controller.dart';
import 'poi_report_controller.dart';
import 'user_poi_controller.dart';
import 'walk_history_controller.dart';

class WalkController extends Notifier<WalkSession> {
  Timer? _timer;
  StreamSubscription<GeoCoord>? _positionSub;

  @override
  WalkSession build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _positionSub?.cancel();
      _positionSub = null;
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
    return WalkSession(isActive: false, now: DateTime.now());
  }

  bool get _shareLocation => ref.read(appSettingsProvider).showLocationOnMap;

  void start({String? statusMessage}) {
    _timer?.cancel();
    _positionSub?.cancel();
    final now = DateTime.now();
    final startCoord = ref.read(userLocationProvider).coord;
    state = WalkSession(
      isActive: true,
      now: now,
      startedAt: now,
      statusMessage: statusMessage,
      path: [startCoord],
      distanceKm: 0,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isPaused) {
        state = state.copyWith(now: DateTime.now());
      } else {
        state = state.copyWith(now: DateTime.now());
      }
    });
    // Always publish walk + status to dog/user docs so Discover cards
    // show "U šetnji / Odmaram / Tražim društvo". Map pin sharing stays
    // gated by showLocationOnMap for live location updates.
    unawaited(
      ref.read(walkPresenceRepositoryProvider).setWalking(
            userId: _userId,
            dogId: _dogId,
            isWalking: true,
            location: startCoord,
            statusMessage: statusMessage,
          ),
    );
    _positionSub =
        ref.read(locationClientProvider).watchWalkPosition().listen((coord) {
      ref.read(userLocationProvider.notifier).setCoord(coord);
      _appendPoint(coord);
      if (!_shareLocation) {
        return;
      }
      unawaited(
        ref.read(walkPresenceRepositoryProvider).updateLocation(
              userId: _userId,
              dogId: _dogId,
              location: coord,
            ),
      );
    }, onError: (_) {});
  }

  void pause() {
    if (!state.isActive || state.isPaused) {
      return;
    }
    state = state.copyWith(
      isPaused: true,
      pausedAt: DateTime.now(),
      now: DateTime.now(),
    );
  }

  void resume() {
    if (!state.isActive || !state.isPaused) {
      return;
    }
    final pausedAt = state.pausedAt;
    var total = state.pausedTotal;
    if (pausedAt != null) {
      total += DateTime.now().difference(pausedAt);
    }
    state = state.copyWith(
      isPaused: false,
      pausedTotal: total,
      clearPausedAt: true,
      now: DateTime.now(),
    );
  }

  void end() {
    final session = state;
    final startedAt = session.startedAt;
    final durationSeconds = session.elapsed.inSeconds;
    final distanceKm = session.distanceKm;
    final statusMessage = (session.statusMessage ?? '').trim();
    final userId = _userId;
    final dogId = _dogId;

    _timer?.cancel();
    _timer = null;
    // Cancelling the stream stops Android's location foreground service.
    _positionSub?.cancel();
    _positionSub = null;
    state = WalkSession(isActive: false, now: DateTime.now());
    unawaited(
      ref.read(walkPresenceRepositoryProvider).setWalking(
            userId: userId,
            dogId: dogId,
            isWalking: false,
            location: ref.read(userLocationProvider).coord,
          ),
    );

    // Persist completed walks (skip tiny accidental taps).
    if (startedAt != null &&
        userId.isNotEmpty &&
        userId != 'local-user' &&
        (durationSeconds >= 30 || distanceKm >= 0.05)) {
      final endedAt = DateTime.now();
      unawaited(
        ref
            .read(walkHistoryRepositoryProvider)
            .save(
              WalkRecord(
                id: 'walk-${endedAt.millisecondsSinceEpoch}',
                userId: userId,
                dogId: dogId,
                distanceKm: distanceKm,
                durationSeconds: durationSeconds,
                startedAt: startedAt,
                endedAt: endedAt,
                statusMessage: statusMessage,
              ),
            )
            .then((_) {
          ref.invalidate(walkHistoryProvider);
        }).catchError((Object error) {
          debugPrint('Walk history save failed: $error');
        }),
      );
    }
  }

  void _appendPoint(GeoCoord coord) {
    if (!state.isActive || state.isPaused) {
      return;
    }
    final path = [...state.path];
    var distance = state.distanceKm;
    if (path.isNotEmpty) {
      final last = path.last;
      final step = haversineKm(last, coord);
      // Ignore GPS jitter under ~4 meters.
      if (step < 0.004) {
        return;
      }
      distance += step;
    }
    path.add(coord);
    state = state.copyWith(
      path: path,
      distanceKm: distance,
      now: DateTime.now(),
    );
  }

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
      ref.watch(livePlacesProvider).asData?.value ?? const <MapPlace>[];
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
  // When Firebase is live, skip seed so we don't show duplicate pins that
  // already exist under different Firestore ids in `places` / `pois`.
  final byId = <String, MapPlace>{};
  void put(MapPlace place) {
    if (place.verificationStatus == PoiVerificationStatus.rejected ||
        hidden.contains(place.id)) {
      return;
    }
    byId[place.id] = place;
  }

  if (!isFirebaseReady) {
    for (final place in mockMapPlaces.map(applyCommunityFlags)) {
      put(place);
    }
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

final liveWalkingDogsProvider = StreamProvider<List<WalkingDogPin>>((ref) {
  return ref
      .watch(walkPresenceRepositoryProvider)
      .watchWalking(
        excludeUserId: ref.watch(authStateProvider).asData?.value?.uid ?? '',
      )
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
  final location = ref.watch(userLocationProvider);
  final radius = ref.watch(matchingFiltersProvider).radiusKm;
  final geo = GeoQuery(origin: location.coord, radiusKm: radius);
  final source = isFirebaseReady
      ? (ref.watch(liveWalkingDogsProvider).asData?.value ?? const [])
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
