import '../../../core/geo/geo.dart';
import 'location_access.dart';

abstract class LocationClient {
  Future<bool> isServiceEnabled();

  Future<LocationAccess> checkPermission();

  Future<LocationAccess> requestPermission();

  Future<GeoCoord?> currentPosition();

  Stream<GeoCoord> watchPosition();

  Future<void> openAppSettings();
}
