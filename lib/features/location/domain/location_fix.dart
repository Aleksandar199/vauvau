import '../../../core/geo/geo.dart';

/// One raw GPS reading with the metadata the walk filter needs.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyM,
    this.speedMps,
    this.altitudeM,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;

  /// When the device took the reading (not when it reached Dart).
  final DateTime timestamp;

  /// Horizontal accuracy radius in meters; null = unknown (treated as bad).
  final double? accuracyM;

  /// Device-reported ground speed; null or negative = unknown.
  final double? speedMps;

  /// Altitude in meters; null or exactly 0 = the device did not report one
  /// (Android sends 0.0 then), so it is never used as evidence.
  final double? altitudeM;

  /// Android mock-location provider (fake GPS apps).
  final bool isMocked;

  GeoCoord get coord => GeoCoord(latitude, longitude);
}
