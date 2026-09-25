import '../../../core/geo/geo.dart';
import 'location_access.dart';

class UserLocation {
  const UserLocation({
    required this.coord,
    required this.access,
    this.isFallback = false,
  });

  final GeoCoord coord;
  final LocationAccess access;
  final bool isFallback;

  double get latitude => coord.latitude;
  double get longitude => coord.longitude;

  static const noviSadFallback = UserLocation(
    coord: GeoCoord.noviSad,
    access: LocationAccess.unavailable,
    isFallback: true,
  );

  UserLocation copyWith({
    GeoCoord? coord,
    LocationAccess? access,
    bool? isFallback,
  }) {
    return UserLocation(
      coord: coord ?? this.coord,
      access: access ?? this.access,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}
