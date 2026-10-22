import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/geo/geo.dart';
import '../domain/location_access.dart';
import '../domain/location_client.dart';
import '../domain/location_fix.dart';

class GeolocatorLocationClient implements LocationClient {
  static const _walkNotification = ForegroundNotificationConfig(
    notificationTitle: 'VauVau Šetnja u toku',
    notificationText:
        'Vaša lokacija se prati u pozadini radi preciznog merenja rute.',
    notificationIcon: AndroidResource(name: 'launch_background'),
    enableWakeLock: true,
    setOngoing: true,
    notificationChannelName: 'VauVau šetnja',
  );

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
    return _watch(_foregroundSettings());
  }

  @override
  Stream<GeoCoord> watchWalkPosition() {
    return _watch(_walkSettings());
  }

  @override
  Stream<LocationFix> watchWalkFixes() {
    try {
      return Geolocator.getPositionStream(locationSettings: _walkSettings())
          .map(
            (position) => LocationFix(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: position.timestamp,
              accuracyM: position.accuracy,
              speedMps: position.speed,
              altitudeM: position.altitude,
              isMocked: position.isMocked,
            ),
          );
    } catch (_) {
      return const Stream.empty();
    }
  }

  Stream<GeoCoord> _watch(LocationSettings settings) {
    try {
      return Geolocator.getPositionStream(locationSettings: settings).map(
        (position) => GeoCoord(position.latitude, position.longitude),
      );
    } catch (_) {
      return const Stream.empty();
    }
  }

  LocationSettings _foregroundSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 12,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 12,
        intervalDuration: const Duration(seconds: 5),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 12,
        activityType: ActivityType.otherNavigation,
        pauseLocationUpdatesAutomatically: true,
        allowBackgroundLocationUpdates: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 12,
    );
  }

  LocationSettings _walkSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: _walkNotification,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
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
  Stream<GeoCoord> watchWalkPosition() => const Stream.empty();

  @override
  Stream<LocationFix> watchWalkFixes() => const Stream.empty();

  @override
  Future<void> openAppSettings() async {}
}
