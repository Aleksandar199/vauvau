import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/geo/geo.dart';
import '../../auth/presentation/auth_providers.dart';

/// City the user picked at registration / in profile (e.g. Niš).
class HomeCity {
  const HomeCity({required this.id, required this.name, required this.coord});

  /// [SerbiaLocations] id: `novi_sad`, `beograd`, `nis`.
  final String id;
  final String name;
  final GeoCoord coord;

  /// Matching id in the map `cities` collection / [SeedCities].
  String get mapCityId => id.replaceAll('_', '-');

  @override
  bool operator ==(Object other) => other is HomeCity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final homeCityProvider = Provider<HomeCity?>((ref) {
  final (cityId, cityName) = ref.watch(
    authStateProvider.select((auth) {
      final user = auth.asData?.value;
      return (user?.cityId ?? '', user?.cityName ?? '');
    }),
  );
  final id = SerbiaLocations.resolveCityId(cityId, cityName);
  if (id == null) {
    return null;
  }
  return HomeCity(
    id: id,
    name: SerbiaLocations.cityById(id)?.name ?? cityName,
    coord: GeoCoord.forCityId(id),
  );
});
