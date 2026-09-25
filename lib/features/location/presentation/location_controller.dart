import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo.dart';
import '../data/geolocator_location_client.dart';
import '../domain/location_access.dart';
import '../domain/location_client.dart';
import '../domain/user_location.dart';

class LocationController extends Notifier<UserLocation> {
  @override
  UserLocation build() {
    Future<void>.microtask(() => refresh(requestPermission: false));
    return UserLocation.noviSadFallback;
  }

  LocationClient get _client => ref.read(locationClientProvider);

  Future<LocationAccess> refresh({required bool requestPermission}) async {
    final access = requestPermission
        ? await _client.requestPermission()
        : await _client.checkPermission();
    if (!access.canTrack) {
      state = UserLocation(
        coord: UserLocation.noviSadFallback.coord,
        access: access,
        isFallback: true,
      );
      return access;
    }
    final coord = await _client.currentPosition();
    if (coord == null) {
      state = UserLocation(
        coord: UserLocation.noviSadFallback.coord,
        access: access,
        isFallback: true,
      );
      return access;
    }
    state = UserLocation(coord: coord, access: access);
    return access;
  }

  Future<LocationAccess> requestPermission() {
    return refresh(requestPermission: true);
  }

  void setCoord(GeoCoord coord) {
    state = UserLocation(
      coord: coord,
      access: LocationAccess.granted,
    );
  }
}

final locationClientProvider = Provider<LocationClient>((ref) {
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return GeolocatorLocationClient();
  }
  return const FallbackLocationClient();
});

final userLocationProvider =
    NotifierProvider<LocationController, UserLocation>(LocationController.new);
