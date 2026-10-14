import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo.dart';
import '../data/geolocator_location_client.dart';
import '../domain/location_access.dart';
import '../domain/location_client.dart';
import '../domain/user_location.dart';
import 'home_city_provider.dart';

class LocationController extends Notifier<UserLocation> {
  /// Without GPS we stand in the center of the user's registered city.
  GeoCoord _fallbackCoord = UserLocation.noviSadFallback.coord;

  @override
  UserLocation build() {
    _fallbackCoord =
        ref.watch(homeCityProvider)?.coord ??
        UserLocation.noviSadFallback.coord;
    Future<void>.microtask(() => refresh(requestPermission: false));
    return UserLocation.noviSadFallback.copyWith(coord: _fallbackCoord);
  }

  LocationClient get _client => ref.read(locationClientProvider);

  Future<LocationAccess> refresh({required bool requestPermission}) async {
    final access = requestPermission
        ? await _client.requestPermission()
        : await _client.checkPermission();
    if (!access.canTrack) {
      state = UserLocation(
        coord: _fallbackCoord,
        access: access,
        isFallback: true,
      );
      return access;
    }
    final coord = await _client.currentPosition();
    if (coord == null) {
      state = UserLocation(
        coord: _fallbackCoord,
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
