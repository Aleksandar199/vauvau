import '../../../core/geo/geo.dart';
import 'discover_profile.dart';

class GeoQuery {
  const GeoQuery({
    required this.origin,
    required this.radiusKm,
  });

  final GeoCoord origin;
  final double radiusKm;

  DiscoverProfile locate(DiscoverProfile profile) {
    final point = profile.coord;
    if (point == null) {
      return profile;
    }
    return profile.copyWith(distanceKm: haversineKm(origin, point));
  }

  bool withinRadius(DiscoverProfile profile) {
    return locate(profile).distanceKm <= radiusKm;
  }

  List<DiscoverProfile> apply(List<DiscoverProfile> source) {
    return [
      for (final profile in source)
        if (withinRadius(profile)) locate(profile),
    ];
  }
}

