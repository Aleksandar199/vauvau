import '../../../core/geo/geo.dart';
import 'location_access.dart';
import 'location_fix.dart';

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

  /// Same stream as [watchWalkPosition] with time, accuracy, speed and the
  /// mock-location flag, which the walk filter needs.
  Stream<LocationFix> watchWalkFixes();

  Future<void> openAppSettings();
}
