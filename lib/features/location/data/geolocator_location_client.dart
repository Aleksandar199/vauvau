import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/geo/geo.dart';
import '../domain/location_access.dart';
import '../domain/location_client.dart';

class GeolocatorLocationClient implements LocationClient {
  @override
  Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<LocationAccess> checkPermission() async {
    try {
      if (!await isServiceEnabled()) {
        return LocationAccess.servicesDisabled;
      }
      return _map(await Geolocator.checkPermission());
    } catch (_) {
      return LocationAccess.unavailable;
    }
  }

  @override
  Future<LocationAccess> requestPermission() async {
    try {
      if (!await isServiceEnabled()) {
        return LocationAccess.servicesDisabled;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return _map(permission);
    } catch (_) {
      return LocationAccess.unavailable;
    }
  }

  @override
  Future<GeoCoord?> currentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return GeoCoord(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<GeoCoord> watchPosition() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 12,
        ),
      ).map((position) => GeoCoord(position.latitude, position.longitude));
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  LocationAccess _map(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccess.granted;
      case LocationPermission.deniedForever:
        return LocationAccess.permanentlyDenied;
      case LocationPermission.denied:
        return LocationAccess.denied;
      case LocationPermission.unableToDetermine:
        return kIsWeb ? LocationAccess.denied : LocationAccess.unavailable;
    }
  }
}

class FallbackLocationClient implements LocationClient {
  const FallbackLocationClient();

  @override
  Future<bool> isServiceEnabled() async => false;

  @override
  Future<LocationAccess> checkPermission() async => LocationAccess.unavailable;

  @override
  Future<LocationAccess> requestPermission() async =>
      LocationAccess.unavailable;

  @override
  Future<GeoCoord?> currentPosition() async => null;

  @override
  Stream<GeoCoord> watchPosition() => const Stream.empty();

  @override
  Future<void> openAppSettings() async {}
}
