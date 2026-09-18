import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_map_data.dart';
import '../domain/map_place.dart';
import '../domain/walk_session.dart';
import '../domain/walking_dog_pin.dart';

class WalkController extends Notifier<WalkSession> {
  Timer? _timer;

  @override
  WalkSession build() {
    ref.onDispose(() => _timer?.cancel());
    return WalkSession(isActive: false, now: DateTime.now());
  }

  void start({String? statusMessage}) {
    _timer?.cancel();
    final now = DateTime.now();
    state = WalkSession(
      isActive: true,
      now: now,
      startedAt: now,
      statusMessage: statusMessage,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(now: DateTime.now());
    });
  }

  void end() {
    _timer?.cancel();
    _timer = null;
    state = WalkSession(isActive: false, now: DateTime.now());
  }
}

final walkControllerProvider =
    NotifierProvider<WalkController, WalkSession>(WalkController.new);

final mapPlacesProvider = Provider<List<MapPlace>>((ref) => mockMapPlaces);

final walkingDogsProvider =
    Provider<List<WalkingDogPin>>((ref) => mockWalkingDogs);
