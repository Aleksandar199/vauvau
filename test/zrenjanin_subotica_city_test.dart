import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/events/data/seed_events.dart';
import 'package:vauvau/features/location/presentation/home_city_provider.dart';
import 'package:vauvau/features/map/data/kragujevac_dog_places_seed.dart';
import 'package:vauvau/features/map/data/nis_dog_places_seed.dart';
import 'package:vauvau/features/map/data/places_repository.dart';
import 'package:vauvau/features/map/data/poi_seed_data.dart';
import 'package:vauvau/features/map/data/subotica_dog_places_seed.dart';
import 'package:vauvau/features/map/data/zrenjanin_dog_places_seed.dart';
import 'package:vauvau/features/map/domain/city_model.dart';
import 'package:vauvau/features/map/domain/map_city.dart';
import 'package:vauvau/features/map/domain/map_place.dart';
import 'package:vauvau/features/map/domain/models/poi_model.dart';
import 'package:vauvau/features/map/domain/place_duplicates.dart';
import 'package:vauvau/features/map/presentation/cities_controller.dart';
import 'package:vauvau/features/map/presentation/user_poi_controller.dart';
import 'package:vauvau/features/map/presentation/walk_controller.dart';
import 'package:vauvau/features/moments/presentation/create_moment_sheet.dart';
import 'package:vauvau/features/moments/presentation/moments_strings.dart';
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

List<MapPlace> get _allPlaces =>
    [for (final poi in PoiSeedData.allVerified) MapPlace.fromPoi(poi)];

List<MapPlace> _placesOf(String cityId) =>
    _allPlaces.where((p) => p.cityId == cityId).toList();

PoiModel _poi({
  String id = 'x',
  String name = 'Pet Shop',
  String address = 'Bajnatska 25, Subotica',
  String cityId = 'subotica',
  double latitude = 46.0851,
  double longitude = 19.6783,
}) {
  return PoiModel(
    id: id,
    name: name,
    category: PoiCategory.petShop,
    address: address,
    latitude: latitude,
    longitude: longitude,
    source: 'test',
    lastVerified: DateTime(2026, 10, 19),
    city: MapCityX.fromCityId(cityId),
    cityId: cityId,
  );
}

const _newCities = [
  (SerbiaLocations.zrenjaninId, 'Zrenjanin', MapCity.zrenjanin),
  (SerbiaLocations.suboticaId, 'Subotica', MapCity.subotica),
];

void main() {
  group('gradovi i kvartovi', () {
    test('Zrenjanin i Subotica su u svim listama gradova', () {
      for (final (id, name, mapCity) in _newCities) {
        final city = SerbiaLocations.cityById(id);
        expect(city, isNotNull, reason: id);
        expect(city!.name, name);
        expect(city.neighborhoods.length, greaterThan(15), reason: id);
        final ids = city.neighborhoods.map((h) => h.id).toList();
        expect(ids.toSet().length, ids.length, reason: '$id: unique ids');
        expect(SerbiaLocations.adoptionCities, contains(name));
        final adoption = SerbiaLocations.neighborhoodsForAdoptionCity(name);
        expect(adoption, contains('Ostalo'), reason: 'ručni unos');
        expect(adoption.length, city.neighborhoods.length + 1);
        expect(SeedCities.all.map((c) => c.id), contains(mapCity.cityId));
      }
    });

    test('kvartovi su gradski, ne okolna sela', () {
      final zr = SerbiaLocations.cityById(SerbiaLocations.zrenjaninId)!
          .neighborhoods
          .map((h) => h.name);
      final su = SerbiaLocations.cityById(SerbiaLocations.suboticaId)!
          .neighborhoods
          .map((h) => h.name);
      expect(zr, containsAll(['Centar', 'Bagljaš', 'Mala Amerika', 'Berbersko']));
      expect(zr, isNot(contains('Elemir')));
      expect(zr, isNot(contains('Ečka')));
      expect(su, containsAll(['Dudova šuma', 'Prozivka', 'Kertvaroš', 'Zorka']));
      expect(su, isNot(contains('Palić')));
      expect(su, isNot(contains('Bajmok')));
    });

    test('postojeći gradovi su netaknuti i redosled je isti', () {
      expect(
        SerbiaLocations.cities.map((c) => c.id).take(4),
        ['novi_sad', 'beograd', 'nis', 'kragujevac'],
      );
      expect(SeedCities.all.map((c) => c.id).take(4),
          ['novi-sad', 'beograd', 'nis', 'kragujevac']);
      expect(SeedCities.kragujevac.latitude, 44.0128);
      expect(GeoCoord.forCityId('nis'), GeoCoord.nis);
      expect(GeoCoord.forCityName('Beograd, Vračar'), GeoCoord.belgrade);
      expect(GeoCoord.forCityName('nepoznato'), GeoCoord.noviSad);
    });
  });

  group('centri mape', () {
    test('centri su usklađeni u svim modelima i blizu očekivanih', () {
      final expected = {
        'zrenjanin': (const GeoCoord(45.383, 20.381), GeoCoord.zrenjanin),
        'subotica': (const GeoCoord(46.100, 19.667), GeoCoord.subotica),
      };
      for (final (id, _, mapCity) in _newCities) {
        final seed = SeedCities.byId(id)!;
        final (approx, coord) = expected[id]!;
        expect(GeoCoord.forCityId(id), coord);
        expect(seed.latitude, coord.latitude);
        expect(seed.longitude, coord.longitude);
        expect(mapCity.camera?.latitude, coord.latitude);
        expect(mapCity.camera?.longitude, coord.longitude);
        expect(MapCityX.fromCityId(id), mapCity);
        expect(mapCity.cityId, id);
        expect(haversineKm(approx, coord), lessThan(2), reason: id);
      }
      expect(MapCity.zrenjanin.camera, isNot(MapCity.subotica.camera));
    });

    test('Firestore lista gradova zadržava ugrađene nove gradove', () {
      final merged = SeedCities.mergeWith([SeedCities.noviSad]);
      expect(merged.map((c) => c.id), containsAll(['zrenjanin', 'subotica']));
      expect(merged.last.id, 'subotica');
    });

    test('korisnik iz Zrenjanina dobija Zrenjanin na mapi', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(uid: 'u1', city: 'Zrenjanin', cityId: 'zrenjanin'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authStateProvider, (_, _) {});
      await container.read(authStateProvider.future);
      expect(container.read(homeCityProvider)?.coord, GeoCoord.zrenjanin);
      final region = container.read(mapRegionProvider);
      expect(region.cityId, 'zrenjanin');

      container.read(mapRegionProvider.notifier).selectCity(SeedCities.subotica);
      expect(container.read(mapRegionProvider).cityId, 'subotica');
      expect(
        mapRegionCenter(container.read(mapRegionProvider), GeoCoord.noviSad),
        GeoCoord.subotica,
      );
    });

    test('stari profil samo sa imenom grada (ćirilica) se učitava', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AppUser(uid: 'u2', city: 'Суботица')),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authStateProvider, (_, _) {});
      await container.read(authStateProvider.future);
      expect(container.read(homeCityProvider)?.id, 'subotica');
    });
  });

  group('normalizacija', () {
    test('grad bez obzira na dijakritiku, velika slova, ćirilicu i mađarski',
        () {
      expect(SerbiaLocations.cityIdForLabel('ZRENJANIN'), 'zrenjanin');
      expect(SerbiaLocations.cityIdForLabel('Zrenjanin - Bagljaš'), 'zrenjanin');
      expect(SerbiaLocations.cityIdForLabel('Зрењанин, Багљаш'), 'zrenjanin');
      expect(SerbiaLocations.cityIdForLabel('Nagybecskerek'), 'zrenjanin');
      expect(SerbiaLocations.cityIdForLabel('subotica, prozivka'), 'subotica');
      expect(SerbiaLocations.cityIdForLabel('Суботица'), 'subotica');
      expect(SerbiaLocations.cityIdForLabel('Szabadka'), 'subotica');
      expect(SerbiaLocations.resolveCityId('', 'Subotica'), 'subotica');
      expect(SerbiaLocations.resolveCityId('Zrenjanin', ''), 'zrenjanin');
      expect(SerbiaLocations.cityIdForLabel('Нови Сад'), 'novi_sad');
      expect(SerbiaLocations.cityIdForLabel('Ниш - Медијана'), 'nis');
      expect(SerbiaLocations.cityIdForLabel('Kragujevac'), 'kragujevac');
      expect(SerbiaLocations.cityIdForLabel('Palić'), isNull);
      expect(GeoCoord.forCityName('Зрењанин'), GeoCoord.zrenjanin);
      expect(GeoCoord.forCityName('Subotica, Centar I'), GeoCoord.subotica);
    });

    test('kvart po imenu bez obzira na pisanje; nepoznat ostaje ručni', () {
      expect(
        SerbiaLocations.neighborhoodIdForLabel('zrenjanin', 'Багљаш'),
        'zr_bagljas',
      );
      expect(
        SerbiaLocations.neighborhoodIdForLabel('zrenjanin', 'ruza sulman'),
        'zr_ruza_sulman',
      );
      expect(
        SerbiaLocations.neighborhoodIdForLabel('subotica', 'DUDOVA SUMA'),
        'su_dudova_suma',
      );
      expect(
        SerbiaLocations.neighborhoodIdForLabel('subotica', 'Moj sokak'),
        isNull,
      );
      expect(
        SerbiaLocations.usesCustomNeighborhood('subotica', 'nepoznat'),
        isTrue,
      );
      expect(
        SerbiaLocations.resolveNeighborhoodName(
          cityId: 'zrenjanin',
          neighborhoodId: SerbiaLocations.customNeighborhoodId,
          customName: 'Moj kraj',
        ),
        'Moj kraj',
      );
      expect(
        SerbiaLocations.formatPlace('Subotica', 'Prozivka'),
        'Subotica, Prozivka',
      );
    });
  });

  group('Otkrij', () {
    test('filter grada vraća samo pse iz tog grada', () {
      final profiles = [
        _profile('ns', 'Novi Sad, Liman 1'),
        _profile('zr', 'Zrenjanin, Bagljaš'),
        _profile('su', 'Subotica, Prozivka'),
      ];
      expect(
        const MatchingFilters(city: FilterCity.zrenjanin)
            .apply(profiles)
            .map((p) => p.id),
        ['zr'],
      );
      const su = MatchingFilters(city: FilterCity.subotica);
      expect(su.apply(profiles).map((p) => p.id), ['su']);
      expect(su.cityId, 'subotica');
    });

    test('oblast za korisnika iz Subotice krije druge gradove', () {
      const area = DiscoverArea(
        origin: GeoCoord.subotica,
        radiusKm: 20,
        cityId: SerbiaLocations.suboticaId,
      );
      final visible = [
        _profile('zr', 'Zrenjanin'),
        _profile('su', 'Subotica'),
      ].where(area.allows);
      expect(visible.map((p) => p.id), ['su']);
    });
  });

  group('seed mesta', () {
    test('id-jevi su jedinstveni, sa prefiksom grada, spajanje je idempotentno',
        () {
      for (final (seed, prefix) in [
        (ZrenjaninDogPlacesSeed.all, 'zr-'),
        (SuboticaDogPlacesSeed.all, 'su-'),
      ]) {
        final ids = seed.map((p) => p.id).toList();
        expect(ids.toSet().length, ids.length);
        expect(ids.every((id) => id.startsWith(prefix)), isTrue);
      }
      final all = PoiSeedData.allVerified.map((p) => p.id).toList();
      expect(all.toSet().length, all.length);
      expect(PoiSeedData.allVerified.map((p) => p.id).toList(), all);
      expect(
        all,
        containsAll([
          ...ZrenjaninDogPlacesSeed.all.map((p) => p.id),
          ...SuboticaDogPlacesSeed.all.map((p) => p.id),
          ...KragujevacDogPlacesSeed.all.map((p) => p.id),
          ...NisDogPlacesSeed.all.map((p) => p.id),
        ]),
      );
    });

    test('svako mesto ima grad i stvarne koordinate u tom gradu', () {
      for (final (id, _, mapCity) in _newCities) {
        final city = SeedCities.byId(id)!;
        final places = _placesOf(id);
        expect(places, isNotEmpty, reason: id);
        for (final place in places) {
          expect(place.city, mapCity, reason: place.name);
          expect(place.hasValidCoordinates, isTrue, reason: place.name);
          final km = haversineKm(
            GeoCoord(city.latitude, city.longitude),
            GeoCoord(place.latitude, place.longitude),
          );
          expect(km, lessThan(city.radiusKm), reason: place.name);
          final atCenter = place.latitude == city.latitude &&
              place.longitude == city.longitude;
          expect(atCenter, isFalse, reason: '${place.name} = centar grada');
          expect(place.neighborhood, contains(city.name), reason: place.name);
        }
      }
    });

    test('nema starih markera: mesta drugih gradova su van novih gradova', () {
      for (final (id, _, _) in _newCities) {
        final city = SeedCities.byId(id)!;
        final center = GeoCoord(city.latitude, city.longitude);
        for (final place in _allPlaces.where((p) => p.cityId != id)) {
          final km = haversineKm(
            center,
            GeoCoord(place.latitude, place.longitude),
          );
          expect(km, greaterThan(city.radiusKm),
              reason: '${place.name} (${place.cityId}) u $id');
        }
      }
    });

    test('kategorije: parkovi, parkovi za pse, veterinari, prodavnice', () {
      List<String> namesOf(List<PoiModel> seed, PoiCategory c) =>
          seed.where((p) => p.category == c).map((p) => p.name).toList();
      final zr = PoiSeedData.verifiedZrenjanin;
      final su = PoiSeedData.verifiedSubotica;
      expect(namesOf(zr, PoiCategory.park), contains('Karađorđev park'));
      expect(namesOf(zr, PoiCategory.vet), contains('Veterina Dimić'));
      expect(namesOf(zr, PoiCategory.petShop), contains('Aristo Pets'));
      expect(namesOf(su, PoiCategory.park), contains('Dudova šuma'));
      expect(namesOf(su, PoiCategory.vet), contains('Panvet'));
      expect(namesOf(su, PoiCategory.petShop), contains('Pet Centar Subotica'));
      expect(namesOf(su, PoiCategory.groomer), contains('Anastazija Grooming'));
      expect(namesOf(su, PoiCategory.shelter), isNotEmpty);
      // Nijedan lokal nije potvrđen kao dog-friendly.
      expect(namesOf(zr, PoiCategory.cafe), isEmpty);
      expect(namesOf(su, PoiCategory.cafe), isEmpty);
      // Samo jedna filijala Pet Centra u Subotici.
      expect(
        su.where((p) => p.name.startsWith('Pet Centar')).length,
        1,
      );
    });

    test('parkovi za pse su označeni, obični parkovi nisu', () {
      for (final p in [
        ...ZrenjaninDogPlacesSeed.dogParks,
        ...SuboticaDogPlacesSeed.dogParks,
      ]) {
        expect(p.isDogPark, isTrue, reason: p.name);
        expect(p.sourceUrl, isNotEmpty, reason: p.name);
      }
      for (final p in [
        ...ZrenjaninDogPlacesSeed.parks,
        ...SuboticaDogPlacesSeed.parks,
      ]) {
        expect(p.isDogPark, isFalse, reason: p.name);
      }
    });

    test('neprovereno nije verified i nema telefon, sajt ni radno vreme', () {
      final seeds = [
        ...ZrenjaninDogPlacesSeed.all,
        ...SuboticaDogPlacesSeed.all,
      ];
      for (final poi in seeds) {
        expect(poi.is24_7, isFalse, reason: poi.name);
        expect(poi.isEmergencyService, isFalse, reason: poi.name);
        expect(poi.lastVerified, DateTime(2026, 10, 19));
        if (poi.verificationStatus == PoiVerificationStatus.unknown) {
          expect(poi.phone, isEmpty, reason: poi.name);
          expect(poi.website, isNull, reason: poi.name);
          expect(poi.openingHours, isEmpty, reason: poi.name);
        } else {
          expect(poi.verificationStatus, PoiVerificationStatus.verified);
          expect(poi.sourceUrl, startsWith('http'), reason: poi.name);
        }
        final isBusiness = poi.category != PoiCategory.park;
        if (isBusiness &&
            poi.verificationStatus == PoiVerificationStatus.verified) {
          expect(poi.phone, isNotEmpty, reason: poi.name);
          expect(poi.source, ZrenjaninDogPlacesSeed.officialSource);
        }
      }
      expect(
        ZrenjaninDogPlacesSeed.all
            .firstWhere((p) => p.id == 'zr-vet-ultimate-vet')
            .verificationStatus,
        PoiVerificationStatus.unknown,
      );
    });

    test('loše koordinate ne postaju marker', () {
      final base = SuboticaDogPlacesSeed.parks.first;
      expect(PoiSeedData.hasValidCoordinates(base), isTrue);
      expect(
        PoiSeedData.hasValidCoordinates(
          base.copyWith(latitude: 0, longitude: 0),
        ),
        isFalse,
      );
      expect(
        PoiSeedData.hasValidCoordinates(base.copyWith(longitude: 200)),
        isFalse,
      );
      expect(
        MapPlace.fromPoi(base.copyWith(latitude: 0, longitude: 0))
            .hasValidCoordinates,
        isFalse,
      );
    });

    test('mesta za šetnje i događaje po gradu', () {
      final zr = EventVenues.forCity(SerbiaLocations.zrenjaninId, _allPlaces);
      expect(zr, contains('Karađorđev park'));
      expect(zr, isNot(contains('Dudova šuma')));
      expect(zr.last, EventVenues.customOption);
      final su = EventVenues.forCity(SerbiaLocations.suboticaId, _allPlaces);
      expect(su, contains('Dudova šuma'));
      expect(su, isNot(contains('Limanski park')));
    });
  });

  group('duplikati', () {
    test('isto ime i adresa (različito pisanje) je duplikat', () {
      final a = PlaceIdentity.ofPoi(
        _poi(id: 'a', name: 'Veterinar', address: 'Trg Paje Kujundžića 2/a, Subotica'),
      );
      final b = PlaceIdentity.ofPoi(
        _poi(
          id: 'b',
          name: 'VETERINAR',
          address: 'trg paje kujundzica 2a',
          latitude: 46.2,
        ),
      );
      expect(PlaceDuplicates.isDuplicate(a, b), isTrue);
    });

    test('isto ime i pin u blizini je duplikat', () {
      final a = PlaceIdentity.ofPoi(_poi(id: 'a', address: 'Bajnatska 25'));
      final b = PlaceIdentity.ofPoi(
        _poi(id: 'b', address: 'Bajnatska bb', latitude: 46.0853),
      );
      expect(PlaceDuplicates.isDuplicate(a, b), isTrue);
    });

    test('različite firme na istoj adresi i isto ime u drugom gradu nisu', () {
      final shop = PlaceIdentity.ofPoi(_poi(id: 'a', name: 'Pet Centar'));
      final vet = PlaceIdentity.ofPoi(_poi(id: 'b', name: 'Panvet'));
      expect(PlaceDuplicates.isDuplicate(shop, vet), isFalse);
      final otherCity = PlaceIdentity.ofPoi(
        _poi(id: 'c', name: 'Pet Centar', cityId: 'zrenjanin'),
      );
      expect(PlaceDuplicates.isDuplicate(shop, otherCity), isFalse);
      final farAway = PlaceIdentity.ofPoi(
        _poi(
          id: 'd',
          name: 'Pet Centar',
          address: 'Somborski put 35',
          latitude: 46.0944,
          longitude: 19.6535,
        ),
      );
      expect(PlaceDuplicates.isDuplicate(shop, farAway), isFalse);
    });

    test('dedupe zadržava prvi unos i postojeći id; ponovni prolaz ništa ne menja',
        () {
      final list = [
        _poi(id: 'first'),
        _poi(id: 'copy', name: 'pet shop', address: 'Bajnatska 25'),
        _poi(id: 'other', name: 'Drugi shop'),
      ];
      final once = PlaceDuplicates.dedupe(list);
      expect(once.map((p) => p.id), ['first', 'other']);
      expect(PlaceDuplicates.dedupe(once).map((p) => p.id), ['first', 'other']);
    });

    test('seed novih gradova nema duplikata', () {
      for (final seed in [
        ZrenjaninDogPlacesSeed.all,
        SuboticaDogPlacesSeed.all,
      ]) {
        expect(PlaceDuplicates.dedupe(seed).length, seed.length);
      }
      expect(
        PoiSeedData.verifiedSubotica.length,
        SuboticaDogPlacesSeed.all.length,
      );
    });

    test('admin upozorenje: novo mesto sa istim imenom na mapi', () {
      final existing = _placesOf('subotica').map(PlaceIdentity.ofPlace);
      final hit = PlaceDuplicates.findDuplicate(
        const PlaceIdentity(
          id: '',
          name: 'Panvet',
          address: 'Koste Racina 5',
          cityId: 'subotica',
          latitude: 46.1077,
          longitude: 19.6657,
        ),
        existing,
      );
      expect(hit?.id, 'su-vet-panvet');
      final none = PlaceDuplicates.findDuplicate(
        const PlaceIdentity(
          id: '',
          name: 'Panvet',
          address: 'Koste Racina 5',
          cityId: 'zrenjanin',
          latitude: 45.38,
          longitude: 20.39,
        ),
        existing,
      );
      expect(none, isNull);
    });
  });

  group('places → pois', () {
    test('admin mesto u Zrenjaninu se upisuje u places i pois atomski',
        () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestorePlacesRepository(db);
      final id = await repo.createPlace(
        const PlaceDraft(
          name: 'Test park',
          category: 'park',
          cityId: 'zrenjanin',
          cityName: 'Zrenjanin',
          address: 'Test 1, Zrenjanin',
          latitude: 45.38,
          longitude: 20.39,
          createdBy: 'admin',
        ),
      );
      final place = await db.collection('places').doc(id).get();
      final poi = await db.collection('pois').doc(id).get();
      expect(place.data()?['cityId'], 'zrenjanin');
      expect(poi.data()?['cityId'], 'zrenjanin');
      expect(poi.data()?['city'], 'zrenjanin');

      // `pois.city` is the MapCity enum name the map reads back.
      expect(MapCity.values.byName(poi.data()!['city'] as String),
          MapCity.zrenjanin);
    });

    test('admin verifikacija seed mesta piše isti id u obe kolekcije',
        () async {
      final db = FakeFirebaseFirestore();
      final seed = SuboticaDogPlacesSeed.vets
          .firstWhere((p) => p.id == 'su-vet-animed');
      expect(seed.verificationStatus, PoiVerificationStatus.unknown);
      await FirestorePlacesRepository(db).updatePlace(
        seed.copyWith(verificationStatus: PoiVerificationStatus.verified),
      );
      final place = await db.collection('places').doc(seed.id).get();
      final poi = await db.collection('pois').doc(seed.id).get();
      expect(place.data()?['verificationStatus'], 'verified');
      expect(place.data()?['cityId'], 'subotica');
      expect(poi.data()?['verificationStatus'], 'verified');
      expect(poi.data()?['city'], 'subotica');
      expect(
        (await db.collection('pois').get()).docs.length,
        1,
        reason: 'jedan dokument po mestu',
      );
    });
  });

  test('admin „Potvrdi“ na seed mestu ga označava kao verified', () async {
    final container = ProviderContainer(
      overrides: [isAdminProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);
    final submissions = container.read(userPoiSubmissionsProvider.notifier);
    expect(submissions.findById('su-vet-animed'), isNotNull);

    await submissions.approve('su-vet-animed');

    final approved = container
        .read(userPoiSubmissionsProvider)
        .singleWhere((p) => p.id == 'su-vet-animed');
    expect(approved.verificationStatus, PoiVerificationStatus.verified);
    expect(approved.cityId, 'subotica');
    expect(approved.city, MapCity.subotica);
  });

  testWidgets('forma objave nudi mesta izabranog novog grada', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeCityProvider.overrideWithValue(
            const HomeCity(
              id: SerbiaLocations.zrenjaninId,
              name: 'Zrenjanin',
              coord: GeoCoord.zrenjanin,
            ),
          ),
          mapPlacesProvider.overrideWithValue(_allPlaces),
        ],
        child: const MaterialApp(home: Scaffold(body: CreateMomentSheet())),
      ),
    );
    await tester.pump();

    final zrFirst =
        EventVenues.forCity(SerbiaLocations.zrenjaninId, _allPlaces).first;
    // Location is optional and starts empty; its list has the city's places.
    expect(find.text(zrFirst), findsNothing);
    await tester.tap(find.text(MomentsStrings.noLocation));
    await tester.pumpAndSettle();
    await tester.tap(find.text(zrFirst).last);
    await tester.pumpAndSettle();
    expect(find.text(zrFirst), findsOneWidget);

    await tester.tap(find.text('Zrenjanin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subotica').last);
    await tester.pumpAndSettle();

    final suFirst =
        EventVenues.forCity(SerbiaLocations.suboticaId, _allPlaces).first;
    expect(find.text(zrFirst), findsNothing);
    await tester.tap(find.text(MomentsStrings.noLocation));
    await tester.pumpAndSettle();
    expect(find.text(suFirst), findsWidgets);
    expect(find.text(zrFirst), findsNothing);
  });
}
