import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/map/data/kragujevac_dog_places_seed.dart';
import 'package:vauvau/features/map/data/poi_seed_data.dart';
import 'package:vauvau/features/map/domain/city_model.dart';
import 'package:vauvau/features/map/domain/map_city.dart';
import 'package:vauvau/features/map/domain/map_place.dart';
import 'package:vauvau/features/map/domain/models/poi_model.dart';
import 'package:vauvau/features/profile/domain/matching_filters.dart';

DiscoverProfile _profile(String id, String location) {
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
    distanceKm: 0,
  );
}

List<MapPlace> _kgPlaces() => PoiSeedData.allVerified
    .map(MapPlace.fromPoi)
    .where((p) => p.cityId == 'kragujevac')
    .toList();

void main() {
  test('Kragujevac is a selectable city with neighborhoods', () {
    final kg = SerbiaLocations.cityById(SerbiaLocations.kragujevacId);
    expect(kg, isNotNull);
    expect(kg!.name, 'Kragujevac');
    expect(kg.neighborhoods, isNotEmpty);
    expect(
      SerbiaLocations.neighborhoodsForAdoptionCity('Kragujevac'),
      isNotEmpty,
    );
  });

  test('Kragujevac default coordinates are used everywhere', () {
    expect(SeedCities.all.map((c) => c.id), contains('kragujevac'));
    expect(SeedCities.kragujevac.latitude, 44.0128);
    expect(SeedCities.kragujevac.longitude, 20.9114);
    expect(GeoCoord.forCityId('kragujevac'), GeoCoord.kragujevac);
    expect(GeoCoord.forCityName('Kragujevac, Centar'), GeoCoord.kragujevac);
    expect(MapCityX.fromCityId('kragujevac'), MapCity.kragujevac);
    expect(MapCity.kragujevac.cityId, 'kragujevac');
    expect(MapCity.kragujevac.camera?.latitude, 44.0128);
    expect(MapCity.kragujevac.camera?.longitude, 20.9114);
  });

  test('Firestore city list keeps built-in Kragujevac when missing remotely',
      () {
    final merged = SeedCities.mergeWith([SeedCities.noviSad]);
    expect(merged.map((c) => c.id), contains('kragujevac'));
  });

  test('city labels resolve Kragujevac with and without diacritics', () {
    expect(SerbiaLocations.cityIdForLabel('Kragujevac - Centar'), 'kragujevac');
    expect(SerbiaLocations.cityIdForLabel('KRAGUJEVAC'), 'kragujevac');
    expect(SerbiaLocations.resolveCityId('', 'Kragujevac'), 'kragujevac');
  });

  test('Discover filter by Kragujevac returns only Kragujevac dogs', () {
    final profiles = [
      _profile('ns', 'Novi Sad, Liman 1'),
      _profile('kg', 'Kragujevac, Centar'),
      _profile('nis', 'Niš - Medijana'),
    ];
    const filters = MatchingFilters(city: FilterCity.kragujevac);
    expect(filters.apply(profiles).map((p) => p.id), ['kg']);
    expect(filters.cityId, 'kragujevac');
  });

  test('Discover area for a Kragujevac user hides other cities', () {
    final area = DiscoverArea(
      origin: GeoCoord.kragujevac,
      radiusKm: 20,
      cityId: SerbiaLocations.kragujevacId,
    );
    final profiles = [
      _profile('bg', 'Beograd, Vračar'),
      _profile('kg', 'Kragujevac'),
    ];
    final visible = profiles.where(area.allows);
    expect(visible.map((p) => p.id), ['kg']);
  });

  test('seed ids are unique and merging is idempotent', () {
    final ids = KragujevacDogPlacesSeed.all.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);

    final all = PoiSeedData.allVerified.map((p) => p.id).toList();
    expect(all.toSet().length, all.length);

    final again = PoiSeedData.allVerified.map((p) => p.id).toList();
    expect(again, all);
  });

  test('every Kragujevac seed has a real cityId and coordinates in the city',
      () {
    final places = _kgPlaces();
    expect(places.length, KragujevacDogPlacesSeed.all.length);
    for (final place in places) {
      expect(place.city, MapCity.kragujevac, reason: place.name);
      expect(place.hasValidCoordinates, isTrue, reason: place.name);
      final km = haversineKm(
        GeoCoord.kragujevac,
        GeoCoord(place.latitude, place.longitude),
      );
      expect(km, lessThan(SeedCities.kragujevac.radiusKm), reason: place.name);
      final atCenter = place.latitude == SeedCities.kragujevac.latitude &&
          place.longitude == SeedCities.kragujevac.longitude;
      expect(atCenter, isFalse, reason: '${place.name} uses the city center');
    }
  });

  test('categories: parks, dog parks, vets, shops, groomers, cafes', () {
    final kgIds = _kgPlaces().map((p) => p.id).toSet();
    final places =
        PoiSeedData.allVerified.where((p) => kgIds.contains(p.id)).toList();
    List<String> namesOf(PoiCategory c) =>
        places.where((p) => p.category == c).map((p) => p.name).toList();
    expect(
      namesOf(PoiCategory.park),
      containsAll(['Veliki park', 'Pet park iza Gradske uprave']),
    );
    expect(namesOf(PoiCategory.vet), isNotEmpty);
    expect(namesOf(PoiCategory.petShop), isNotEmpty);
    expect(namesOf(PoiCategory.groomer), isNotEmpty);
    expect(namesOf(PoiCategory.cafe), isNotEmpty);
    expect(
      namesOf(PoiCategory.other),
      contains('Trg Radomira Putnika'),
    );
  });

  test('unconfirmed businesses and cafes are not marked verified', () {
    for (final poi in [
      ...KragujevacDogPlacesSeed.petShops,
      ...KragujevacDogPlacesSeed.vets,
      ...KragujevacDogPlacesSeed.grooming,
      ...KragujevacDogPlacesSeed.cafes,
    ]) {
      expect(poi.verificationStatus, PoiVerificationStatus.unknown,
          reason: poi.name);
    }
    for (final cafe in KragujevacDogPlacesSeed.cafes) {
      expect(cafe.petFriendly, isFalse, reason: cafe.name);
      expect(cafe.dogFriendlyIndoor, isNull, reason: cafe.name);
      expect(cafe.dogFriendlyOutdoor, isNull, reason: cafe.name);
    }
  });

  test('invalid coordinates are rejected', () {
    final base = KragujevacDogPlacesSeed.parks.first;
    expect(PoiSeedData.hasValidCoordinates(base), isTrue);
    expect(
      PoiSeedData.hasValidCoordinates(base.copyWith(latitude: 0, longitude: 0)),
      isFalse,
    );
    expect(
      PoiSeedData.hasValidCoordinates(base.copyWith(latitude: 95)),
      isFalse,
    );
    final place = MapPlace.fromPoi(base.copyWith(latitude: 0, longitude: 0));
    expect(place.hasValidCoordinates, isFalse);
  });

  test('missing optional fields do not break conversion', () {
    final minimal = PoiModel(
      id: 'kg-test-minimal',
      name: 'Test',
      category: PoiCategory.park,
      address: '',
      source: '',
      lastVerified: DateTime(2026, 10, 14),
      latitude: 44.01,
      longitude: 20.91,
      city: MapCity.kragujevac,
      cityId: 'kragujevac',
    );
    final place = MapPlace.fromPoi(minimal);
    expect(place.cityId, 'kragujevac');
    expect(place.city, MapCity.kragujevac);
  });

  test('switching cities changes camera and cityId', () {
    for (final city in [
      MapCity.noviSad,
      MapCity.belgrade,
      MapCity.nis,
      MapCity.kragujevac,
    ]) {
      expect(MapCityX.fromCityId(city.cityId), city);
    }
    expect(MapCity.kragujevac.camera, isNot(MapCity.nis.camera));
  });
}
