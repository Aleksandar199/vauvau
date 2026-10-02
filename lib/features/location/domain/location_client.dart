import '../../../core/geo/geo.dart';
import 'location_access.dart';

abstract class LocationClient {
  Future<bool> isServiceEnabled();

  Future<LocationAccess> checkPermission();

  Future<LocationAccess> requestPermission();

  Future<GeoCoord?> currentPosition();

  /// Lightweight position updates for map centering while the app is open.
  Stream<GeoCoord> watchPosition();

  /// High-priority stream used during an active walk. On Android this starts a
  /// location foreground service so the OS is less likely to kill tracking.
  Stream<GeoCoord> watchWalkPosition();

  Future<void> openAppSettings();
}
