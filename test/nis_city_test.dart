import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/map/data/nis_dog_places_seed.dart';
import 'package:vauvau/features/map/data/poi_seed_data.dart';
import 'package:vauvau/features/map/domain/city_model.dart';
import 'package:vauvau/features/map/domain/map_city.dart';
import 'package:vauvau/features/map/domain/map_place.dart';
import 'package:vauvau/features/profile/domain/matching_filters.dart';

DiscoverProfile _profile(String id, String location, double distanceKm) {
  return DiscoverProfile(
    id: id,
    name: id,
    ownerName: 'Owner',
    breed: 'Mešanac',
    ageYears: 3,
    gender: 'mužjak',
    size: 'srednji',
    location: location,
    bio: '',
    photoUrls: const [],
    distanceKm: distanceKm,
  );
}

void main() {
  test('Niš is a selectable city with neighborhoods', () {
    final nis = SerbiaLocations.cityById(SerbiaLocations.nisId);
    expect(nis, isNotNull);
    expect(nis!.name, 'Niš');
    expect(nis.neighborhoods, isNotEmpty);
    expect(SerbiaLocations.neighborhoodsForAdoptionCity('Niš'), contains('Medijana'));
  });

  test('Niš center coordinates are used for map and geo defaults', () {
    expect(SeedCities.all.map((c) => c.id), contains('nis'));
    expect(SeedCities.nis.latitude, 43.3209);
    expect(SeedCities.nis.longitude, 21.8958);
    expect(GeoCoord.forCityName('Niš, Medijana'), GeoCoord.nis);
    expect(GeoCoord.forCityName('Nis'), GeoCoord.nis);
    expect(GeoCoord.forCityId('nis'), GeoCoord.nis);
  });

  test('Firestore city list keeps built-in Niš when missing remotely', () {
    final merged = SeedCities.mergeWith([SeedCities.noviSad, SeedCities.belgrade]);
    expect(merged.map((c) => c.id), containsAll(['novi-sad', 'beograd', 'nis']));
  });

  test('Niš seed POIs resolve to the nis city and lie near the center', () {
    final nisPlaces = PoiSeedData.allVerified
        .map(MapPlace.fromPoi)
        .where((p) => p.cityId == 'nis')
        .toList();
    expect(nisPlaces.length, NisDogPlacesSeed.all.length);
    for (final place in nisPlaces) {
      expect(place.city, MapCity.nis);
      final km = haversineKm(
        GeoCoord.nis,
        GeoCoord(place.latitude, place.longitude),
      );
      expect(km, lessThan(SeedCities.nis.radiusKm), reason: place.name);
    }
    expect(
      nisPlaces.map((p) => p.name),
      containsAll(['Park Čair', 'Niška tvrđava', 'Park za pse u Čairu']),
    );
  });

  test('Discover filter by Niš returns only Niš dogs, ignoring radius', () {
    final profiles = [
      _profile('ns', 'Novi Sad, Liman 1', 2),
      _profile('bg', 'Beograd, Vračar', 80),
      _profile('nis1', 'Niš, Medijana', 230),
      _profile('nis2', 'Nis', 231),
    ];
    const filters = MatchingFilters(city: FilterCity.nis);
    expect(filters.apply(profiles).map((p) => p.id), ['nis1', 'nis2']);

    const anyCity = MatchingFilters();
    expect(anyCity.apply(profiles).map((p) => p.id), ['ns']);
  });

  test('city labels resolve with and without diacritics', () {
    expect(SerbiaLocations.cityIdForLabel('Niš - Medijana'), 'nis');
    expect(SerbiaLocations.cityIdForLabel('Nis, Pantelej'), 'nis');
    expect(SerbiaLocations.cityIdForLabel('Novi Sad, Liman 1'), 'novi_sad');
    expect(SerbiaLocations.cityIdForLabel('Beograd - Vračar'), 'beograd');
    expect(SerbiaLocations.cityIdForLabel('Nisava'), isNull);
    expect(SerbiaLocations.resolveCityId('', 'Niš'), 'nis');
    expect(SerbiaLocations.resolveCityId('nis', ''), 'nis');
  });

  test('Discover area for a Niš user hides Novi Sad and Beograd dogs', () {
    final area = DiscoverArea(
      origin: GeoCoord.nis,
      radiusKm: 20,
      cityId: SerbiaLocations.nisId,
    );
    // A legacy Belgrade dog stored with Novi Sad coordinates.
    final profiles = [
      _profile('ns', 'Novi Sad, Liman 1', 0),
      _profile('bg', 'Beograd, Vračar', 0),
      _profile('nis', 'Niš - Medijana', 0),
    ];
    final visible = area.geo.apply(profiles).where(area.allows);
    expect(visible.map((p) => p.id), ['nis']);
  });
}
