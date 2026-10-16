import '../../../core/geo/geo.dart';

/// One raw GPS reading with the metadata the walk filter needs.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyM,
    this.speedMps,
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

  /// Android mock-location provider (fake GPS apps).
  final bool isMocked;

  GeoCoord get coord => GeoCoord(latitude, longitude);
}
