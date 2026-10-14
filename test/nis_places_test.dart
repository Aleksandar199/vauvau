import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/map/data/nis_dog_places_seed.dart';
import 'package:vauvau/features/map/data/poi_seed_data.dart';
import 'package:vauvau/features/map/domain/city_model.dart';
import 'package:vauvau/features/map/domain/map_city.dart';
import 'package:vauvau/features/map/domain/map_place.dart';
import 'package:vauvau/features/map/domain/map_place_type.dart';
import 'package:vauvau/features/map/domain/models/poi_model.dart';
import 'package:vauvau/features/map/presentation/cities_controller.dart';
import 'package:vauvau/features/map/presentation/map_screen.dart';
import 'package:vauvau/features/map/presentation/map_strings.dart';
import 'package:vauvau/features/map/presentation/walk_controller.dart';
import 'package:vauvau/features/map/presentation/widgets/place_sheet.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const _nisUser = AppUser(uid: 'u-nis', city: 'Niš', cityId: 'nis');

List<PoiModel> _nisSeeds() => PoiSeedData.allVerified
    .where((p) => p.resolvedCityId == SerbiaLocations.nisId)
    .toList();

PoiModel _seed(String id) => NisDogPlacesSeed.all.firstWhere((p) => p.id == id);

MapPlace _livePlace(String id, String name, double lat, double lng) {
  return MapPlace(
    id: id,
    name: name,
    type: MapPlaceType.vet,
    neighborhood: 'Admin adresa',
    latitude: lat,
    longitude: lng,
    city: MapCity.nis,
    cityId: 'nis',
    verificationStatus: PoiVerificationStatus.verified,
  );
}

void main() {
  group('city', () {
    test('Niš and Nis resolve to the same city id everywhere', () {
      expect(SerbiaLocations.cityIdForLabel('Niš'), 'nis');
      expect(SerbiaLocations.cityIdForLabel('NIS, Pantelej'), 'nis');
      expect(MapCityX.fromCityId('nis'), MapCity.nis);
      expect(MapCityX.fromCityId('niš'), MapCity.nis);
      expect(MapCity.nis.cityId, 'nis');
      expect(SeedCities.nis.id, 'nis');
      expect(
        SeedCities.all.where((c) => c.id == 'nis' || c.name == 'Niš').length,
        1,
      );
    });

    test('default map center is 43.3209 / 21.8958', () {
      expect(SeedCities.nis.latitude, 43.3209);
      expect(SeedCities.nis.longitude, 21.8958);
      expect(MapCity.nis.camera?.latitude, 43.3209);
      expect(MapCity.nis.camera?.longitude, 21.8958);
    });
  });

  group('seed data', () {
    test('every Niš seed uses cityId nis and a real, distinct coordinate', () {
      final seeds = _nisSeeds();
      expect(seeds.length, NisDogPlacesSeed.all.length);
      final coords = <String>{};
      for (final poi in seeds) {
        expect(poi.cityId, 'nis', reason: poi.id);
        expect(poi.city, MapCity.nis, reason: poi.id);
        expect(PoiSeedData.hasValidCoordinates(poi), isTrue, reason: poi.id);
        final km = haversineKm(
          GeoCoord.nis,
          GeoCoord(poi.latitude, poi.longitude),
        );
        expect(km, lessThan(SeedCities.nis.radiusKm), reason: poi.id);
        final atCenter = poi.latitude == SeedCities.nis.latitude &&
            poi.longitude == SeedCities.nis.longitude;
        expect(atCenter, isFalse, reason: '${poi.id} uses the city center');
        expect(
          coords.add('${poi.latitude},${poi.longitude}'),
          isTrue,
          reason: '${poi.id} shares coordinates with another place',
        );
      }
    });

    test('ids are unique, stable and the merge is idempotent', () {
      final ids = NisDogPlacesSeed.all.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.every((id) => id.startsWith('nis-')), isTrue);

      final first = PoiSeedData.allVerified.map((p) => p.id).toList();
      final second = PoiSeedData.allVerified.map((p) => p.id).toList();
      expect(second, first);
      expect(first.toSet().length, first.length);
    });

    test('unverifiable legacy cafes are gone, located ones are downgraded', () {
      final ids = NisDogPlacesSeed.all.map((p) => p.id).toSet();
      expect(ids, isNot(contains('nis-cafe-julijan-djupon')));
      expect(ids, isNot(contains('nis-cafe-ministry-of-beer')));
      for (final id in ['nis-cafe-hush-hush', 'nis-cafe-tramvaj']) {
        final cafe = _seed(id);
        expect(cafe.verificationStatus, PoiVerificationStatus.unknown);
        expect(cafe.petFriendly, isFalse);
        expect(cafe.dogFriendlyIndoor, isNull);
        expect(cafe.dogFriendlyOutdoor, isNull);
      }
    });

    test('pet policies follow the venue sources', () {
      final off = _seed('nis-cafe-off');
      expect(off.verificationStatus, PoiVerificationStatus.verified);
      expect(off.dogFriendlyOutdoor, isTrue);
      expect(off.dogFriendlyIndoor, isNull);

      final laVie = _seed('nis-restaurant-la-vie');
      expect(laVie.category, PoiCategory.restaurant);
      expect(laVie.petFriendly, isTrue);

      final retro = _seed('nis-cafe-retro-bar');
      expect(retro.description, contains('mali'));
      expect(retro.dogFriendlyIndoor, isNull);
    });

    test('only the fenced Čair area is an official dog park', () {
      final official = NisDogPlacesSeed.all
          .map(MapPlace.fromPoi)
          .where((p) => p.isOfficialDogPark)
          .map((p) => p.id)
          .toList();
      expect(official, ['nis-dogpark-cair']);
      expect(MapPlace.fromPoi(_seed('nis-park-cair')).isOfficialDogPark,
          isFalse);
    });

    test('no Niš vet is marked emergency or 24/7 without evidence', () {
      for (final vet in NisDogPlacesSeed.vets) {
        expect(vet.is24_7, isFalse, reason: vet.id);
        expect(vet.isEmergencyService, isFalse, reason: vet.id);
        expect(vet.verificationStatus, PoiVerificationStatus.unknown);
      }
    });

    test('pet shop branches stay separate markers', () {
      final branches = NisDogPlacesSeed.petShops
          .where((p) => p.name.startsWith('Pet Centar'))
          .toList();
      expect(branches.length, 2);
      expect(branches.map((p) => p.address).toSet().length, 2);
    });

    test('legacy "Park za pse" records keep the dog-park badge', () {
      const legacy = MapPlace(
        id: 'park-legacy',
        name: 'Park za pse — Ive Andrića',
        type: MapPlaceType.park,
        neighborhood: '',
        latitude: 45.2389,
        longitude: 19.8324,
      );
      expect(legacy.isOfficialDogPark, isTrue);
      const explicitNo = MapPlace(
        id: 'park-x',
        name: 'Park za pse X',
        type: MapPlaceType.park,
        neighborhood: '',
        latitude: 45.2,
        longitude: 19.8,
        isDogPark: false,
      );
      expect(explicitNo.isOfficialDogPark, isFalse);
    });
  });

  group('merge with Firestore', () {
    ProviderContainer containerWith(List<MapPlace> live) {
      final container = ProviderContainer(
        overrides: [
          livePlacesProvider.overrideWith((ref) => Stream.value(live)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('admin place with the same id replaces the seed (no duplicate)',
        () async {
      final container = containerWith([
        _livePlace('nis-vet-nova', 'Nova (admin)', 43.3285, 21.9089),
      ]);
      container.listen(livePlacesProvider, (_, _) {});
      await container.read(livePlacesProvider.future);
      final matches = container
          .read(mapPlacesProvider)
          .where((p) => p.id == 'nis-vet-nova')
          .toList();
      expect(matches.length, 1);
      expect(matches.single.name, 'Nova (admin)');
    });

    test('a 0,0 Firestore place never becomes a marker', () async {
      final container = containerWith([
        _livePlace('nis-broken-geocode', 'Broken', 0, 0),
      ]);
      container.listen(livePlacesProvider, (_, _) {});
      await container.read(livePlacesProvider.future);
      expect(
        container.read(mapPlacesProvider).map((p) => p.id),
        isNot(contains('nis-broken-geocode')),
      );
    });

    test('missing optional fields do not break conversion', () {
      final minimal = PoiModel(
        id: 'nis-minimal',
        name: 'Bez detalja',
        category: PoiCategory.vet,
        address: '',
        latitude: 43.32,
        longitude: 21.9,
        cityId: 'nis',
        city: MapCity.nis,
        lastVerified: DateTime(2026, 10, 14),
        source: '',
      );
      final place = MapPlace.fromPoi(minimal);
      expect(place.phone, isEmpty);
      expect(place.website, isNull);
      expect(place.openingHours, isEmpty);
      expect(place.isOfficialDogPark, isFalse);
    });
  });

  group('map screen', () {
    Future<ProviderContainer> pumpNisMap(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_nisUser)),
          discoverImageFactoryProvider.overrideWith((ref) {
            return (_) => MemoryImage(_transparentPng);
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authStateProvider, (_, _) {});
      await container.read(authStateProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: MapScreen())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      return container;
    }

    testWidgets('Niš user sees Niš markers and no Novi Sad markers',
        (tester) async {
      final container = await pumpNisMap(tester);
      expect(container.read(mapRegionProvider).cityId, 'nis');
      expect(find.byKey(const Key('place-nis-dogpark-cair')), findsOneWidget);
      expect(find.byKey(const Key('place-nis-park-cair')), findsOneWidget);
      expect(find.byKey(const Key('place-cafe-gabby')), findsNothing);
    });

    testWidgets('marker details show name, address and correct badge',
        (tester) async {
      await pumpNisMap(tester);
      final pin = tester.widget<PlacePin>(
        find.byWidgetPredicate(
          (w) => w is PlacePin && w.place.id == 'nis-park-svetog-save',
        ),
      );
      pin.onTap();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Park Svetog Save'), findsWidgets);
      expect(find.textContaining('Park Svetog Save, Niš'), findsWidgets);
      expect(find.text(MapStrings.publicParkBadge), findsOneWidget);
      expect(find.text(MapStrings.dogParkBadge), findsNothing);
    });

    testWidgets('switching to Belgrade drops all Niš markers', (tester) async {
      final container = await pumpNisMap(tester);
      container
          .read(mapRegionProvider.notifier)
          .selectCity(SeedCities.belgrade);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('place-nis-dogpark-cair')), findsNothing);
      expect(find.byKey(const Key('place-nis-park-cair')), findsNothing);
    });
  });
}
