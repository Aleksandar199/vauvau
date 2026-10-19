import '../domain/map_city.dart';
import '../domain/models/poi_model.dart';
import '../domain/place_duplicates.dart';
import 'belgrade_dog_places_seed.dart';
import 'kragujevac_dog_places_seed.dart';
import 'nis_dog_places_seed.dart';
import 'subotica_dog_places_seed.dart';
import 'zrenjanin_dog_places_seed.dart';

abstract final class PoiSeedData {
  static const String source = 'PetZone / VauVau Baza';
  static final DateTime lastVerified = DateTime(2026, 8, 12);

  static List<PoiModel> get verifiedNoviSad => [
        ...verifiedCafes,
        ...verifiedDogParks,
        ...emergencyVets,
        ...dogHotels,
        ...petSitters,
      ];

  static List<PoiModel> get verifiedBelgrade {
    final byId = <String, PoiModel>{
      for (final poi in belgradeEmergencyVets) poi.id: poi,
      for (final poi in belgradeLegacyExtras) poi.id: poi,
      // Newer geocoded Belgrade corpus wins on id collisions.
      for (final poi in BelgradeDogPlacesSeed.all) poi.id: poi,
    };
    return byId.values.toList();
  }

  static List<PoiModel> get allVerified {
    final byId = <String, PoiModel>{
      for (final poi in verifiedNoviSad) poi.id: poi,
      for (final poi in verifiedBelgrade) poi.id: poi,
      for (final poi in verifiedNis)
        if (hasValidCoordinates(poi)) poi.id: poi,
      for (final poi in KragujevacDogPlacesSeed.all)
        if (hasValidCoordinates(poi)) poi.id: poi,
      for (final poi in verifiedZrenjanin) poi.id: poi,
      for (final poi in verifiedSubotica) poi.id: poi,
    };
    return byId.values.toList();
  }

  /// Seed of a newer city: valid coordinates only, duplicates (same city,
  /// name and address / pin) dropped, ids kept as written.
  static List<PoiModel> _cleanCitySeed(List<PoiModel> seed) =>
      PlaceDuplicates.dedupe(seed.where(hasValidCoordinates));

  static List<PoiModel> get verifiedZrenjanin =>
      _cleanCitySeed(ZrenjaninDogPlacesSeed.all);

  static List<PoiModel> get verifiedSubotica =>
      _cleanCitySeed(SuboticaDogPlacesSeed.all);

  /// Rejects 0,0 / out-of-range points so a failed geocode never becomes a
  /// marker.
  static bool hasValidCoordinates(PoiModel poi) {
    final lat = poi.latitude;
    final lng = poi.longitude;
    if (lat.isNaN || lng.isNaN) return false;
    if (lat == 0 && lng == 0) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static List<PoiModel> get verifiedNis => NisDogPlacesSeed.all;

  static List<PoiModel> get verifiedCafes => [
        _cafe(
          id: 'cafe-fontana',
          name: 'Caffe Fontana',
          address: 'Nikole Pašića 27',
          latitude: 45.25513,
          longitude: 19.84490,
          rating: 4.6,
        ),
        _cafe(
          id: 'cafe-gabby',
          name: 'Caffe Gabby',
          address: 'Dunavska 2',
          latitude: 45.25555,
          longitude: 19.84735,
          rating: 4.8,
        ),
        _cafe(
          id: 'cafe-play',
          name: 'Caffe Play',
          address: 'Novosadskog sajma 4',
          latitude: 45.25340,
          longitude: 19.82580,
          rating: 4.5,
        ),
        _cafe(
          id: 'cafe-pastis',
          name: 'Caffe Pastis',
          address: 'Uroša Predića 16',
          latitude: 45.25405,
          longitude: 19.84355,
          rating: 4.7,
        ),
        _cafe(
          id: 'cafe-tesla',
          name: 'Tesla Lounge & Bar',
          address: 'Dunavska 31',
          latitude: 45.25590,
          longitude: 19.85095,
          rating: 4.6,
        ),
        _cafe(
          id: 'cafe-crni-ovan',
          name: 'Crni Ovan',
          address: 'Ilije Ognjanovića 2',
          latitude: 45.25470,
          longitude: 19.84690,
          rating: 4.7,
        ),
        _cafe(
          id: 'cafe-drago-djordja',
          name: 'Drago mi je',
          address: 'Đorđa Jovanovića 8',
          latitude: 45.25610,
          longitude: 19.84220,
          rating: 4.8,
        ),
        _cafe(
          id: 'cafe-drago-jevrejska',
          name: 'Drago mi je',
          address: 'Jevrejska 12',
          latitude: 45.25580,
          longitude: 19.84480,
          rating: 4.8,
        ),
        _cafe(
          id: 'cafe-filipenko',
          name: 'Filipenko Coffee Bar',
          address: 'Njegoševa 18',
          latitude: 45.25525,
          longitude: 19.84415,
          rating: 4.7,
        ),
        _cafe(
          id: 'cafe-le-bol',
          name: 'Le Bol',
          address: 'Ise Bajića 6',
          latitude: 45.25715,
          longitude: 19.84780,
          rating: 4.6,
        ),
        _cafe(
          id: 'cafe-zenit',
          name: 'Zenit',
          address: 'Njegoševa 24',
          latitude: 45.25540,
          longitude: 19.84370,
          rating: 4.5,
        ),
      ];

  static List<PoiModel> get verifiedDogParks => [
        _park(
          id: 'park-ive-andrica',
          name: 'Park za pse — Ive Andrića',
          address: 'Ive Andrića',
          latitude: 45.23890,
          longitude: 19.83240,
        ),
        _park(
          id: 'park-jovana-popovica',
          name: 'Park za pse — Jovana Popovića',
          address: 'Jovana Popovića',
          latitude: 45.24620,
          longitude: 19.82890,
        ),
        _park(
          id: 'park-oblacica-rada',
          name: 'Park za pse — Oblačića Rada',
          address: 'Oblačića Rada',
          latitude: 45.24880,
          longitude: 19.83470,
        ),
        _park(
          id: 'park-kneza-milosa',
          name: 'Park za pse — Bulevar kneza Miloša',
          address: 'Bulevar kneza Miloša',
          latitude: 45.25180,
          longitude: 19.80890,
        ),
        _park(
          id: 'park-petrovaradin',
          name: 'Park za pse — Petrovaradin',
          address: 'Petrovaradin',
          latitude: 45.25120,
          longitude: 19.86180,
        ),
        _park(
          id: 'park-rotkvarija',
          name: 'Park za pse — Rotkvarija',
          address: 'Rotkvarija',
          latitude: 45.25890,
          longitude: 19.83750,
        ),
        _park(
          id: 'park-jugovicevo',
          name: 'Park za pse — Jugovićevo',
          address: 'Jugovićevo',
          latitude: 45.26620,
          longitude: 19.80480,
        ),
        _park(
          id: 'park-liman-4',
          name: 'Park za pse — Liman 4',
          address: 'Liman 4',
          latitude: 45.23580,
          longitude: 19.84750,
        ),
        _park(
          id: 'park-satelit',
          name: 'Park za pse — Satelit',
          address: 'Satelit',
          latitude: 45.24480,
          longitude: 19.79850,
        ),
        _park(
          id: 'park-podbara',
          name: 'Park za pse — Podbara',
          address: 'Podbara',
          latitude: 45.26140,
          longitude: 19.85220,
        ),
        _park(
          id: 'park-banatic',
          name: 'Park za pse — Banatić',
          address: 'Banatić',
          latitude: 45.26050,
          longitude: 19.82480,
        ),
        _park(
          id: 'park-detelinara',
          name: 'Park za pse — Detelinara',
          address: 'Detelinara',
          latitude: 45.25780,
          longitude: 19.81420,
        ),
        _park(
          id: 'park-avijaticarsko',
          name: 'Park za pse — Avijatičarsko naselje',
          address: 'Avijatičarsko naselje',
          latitude: 45.27180,
          longitude: 19.83100,
        ),
        _park(
          id: 'park-slana-bara',
          name: 'Park za pse — Slana Bara',
          address: 'Slana Bara',
          latitude: 45.27520,
          longitude: 19.81450,
        ),
      ];

  static PoiModel _cafe({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    double? rating,
  }) {
    return _verified(
      id: id,
      name: name,
      category: PoiCategory.cafe,
      address: address,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
    );
  }

  static PoiModel _park({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    return _verified(
      id: id,
      name: name,
      category: PoiCategory.park,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static PoiModel _verified({
    required String id,
    required String name,
    required PoiCategory category,
    required String address,
    required double latitude,
    required double longitude,
    String phone = '',
    String? website,
    bool is24_7 = false,
    bool isEmergencyService = false,
    bool overnightStay = false,
    bool dayCare = false,
    bool hasYard = false,
    double? pricePerNight,
    double? rating,
    MapCity city = MapCity.noviSad,
  }) {
    return PoiModel(
      id: id,
      name: name,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      phone: phone,
      website: website,
      is24_7: is24_7,
      isEmergencyService: isEmergencyService,
      overnightStay: overnightStay,
      dayCare: dayCare,
      hasYard: hasYard,
      pricePerNight: pricePerNight,
      petFriendly: true,
      city: city,
      verificationStatus: PoiVerificationStatus.verified,
      lastVerified: lastVerified,
      source: source,
      rating: rating,
    );
  }

  static List<PoiModel> get emergencyVets => [
        _verified(
          id: 'vet-familyvet',
          name: 'FamilyVet & Dežurni Veterinar',
          category: PoiCategory.vet,
          address: 'Lilike Bem 1 / 1A, Novi Sad',
          latitude: 45.2398,
          longitude: 19.8416,
          phone: '+381 21 443 137 / +381 60 057 5721',
          is24_7: true,
          isEmergencyService: true,
        ),
        _verified(
          id: 'vet-milenium',
          name: 'Milenium Vet',
          category: PoiCategory.vet,
          address: 'Subotička 55A, Novi Sad',
          latitude: 45.2624,
          longitude: 19.8331,
          phone: '065/474-9212',
          is24_7: true,
          isEmergencyService: true,
        ),
        _verified(
          id: 'vet-city',
          name: 'City Vet',
          category: PoiCategory.vet,
          address: 'Rodoljuba Čolakovića 8, Novi Sad',
          latitude: 45.2466,
          longitude: 19.8034,
          is24_7: true,
          isEmergencyService: true,
        ),
      ];

  static List<PoiModel> get dogHotels => [
        _verified(
          id: 'hotel-fancy-dog',
          name: 'Fancy Dog Hotel',
          category: PoiCategory.dogHotel,
          address: 'Doža Đerđa 62, Novi Sad',
          latitude: 45.2611,
          longitude: 19.8372,
          phone: '063 532 609',
          overnightStay: true,
          dayCare: true,
          is24_7: true,
        ),
        _verified(
          id: 'hotel-dogs-empire',
          name: 'Dogs Empire',
          category: PoiCategory.dogHotel,
          address: 'Igmanska 2, Novi Sad',
          latitude: 45.2521,
          longitude: 19.8204,
          phone: '064 328 0784',
          overnightStay: true,
          pricePerNight: 2000,
        ),
        _verified(
          id: 'hotel-king-smash',
          name: 'King & Smash',
          category: PoiCategory.dogHotel,
          address: 'Ribnjak srednji put 5, Novi Sad',
          latitude: 45.2682,
          longitude: 19.8554,
          phone: '062 105 6417',
          overnightStay: true,
          hasYard: true,
          is24_7: true,
        ),
        _verified(
          id: 'hotel-zigi',
          name: 'Pansion za pse Zigi',
          category: PoiCategory.dogHotel,
          address: 'Livade 28a, Novi Sad',
          latitude: 45.2704,
          longitude: 19.8402,
          phone: '063 269 758',
          overnightStay: true,
          hasYard: true,
        ),
        _verified(
          id: 'hotel-djekidjoni',
          name: 'DžekiDžoni Pansion za pse',
          category: PoiCategory.dogHotel,
          address: 'Petrovaradin',
          latitude: 45.2468,
          longitude: 19.8752,
          phone: '062 115 3405',
          overnightStay: true,
        ),
        _verified(
          id: 'hotel-pegonni',
          name: 'Pansion za pse Pegonni',
          category: PoiCategory.dogHotel,
          address: 'Adi Endrea 75, Rumenka',
          latitude: 45.2942,
          longitude: 19.7518,
          phone: '061 601 4363',
          overnightStay: true,
          hasYard: true,
        ),
        _verified(
          id: 'hotel-borova-sumica',
          name: 'Pansion Borova Šumica',
          category: PoiCategory.dogHotel,
          address: 'Rakovac',
          latitude: 45.2041,
          longitude: 19.7604,
          phone: '062 219 796',
          overnightStay: true,
          hasYard: true,
        ),
        _verified(
          id: 'hotel-darvin',
          name: 'Pansion za pse Darvin',
          category: PoiCategory.dogHotel,
          address: 'Kovilj',
          latitude: 45.2302,
          longitude: 20.0231,
          phone: '069 120 9975',
          overnightStay: true,
        ),
        _verified(
          id: 'hotel-salas-137',
          name: 'Salaš 137',
          category: PoiCategory.dogHotel,
          address: 'Čenej',
          latitude: 45.3718,
          longitude: 19.8104,
          overnightStay: true,
          hasYard: true,
          dayCare: true,
        ),
      ];

  static List<PoiModel> get petSitters => [
        _verified(
          id: 'sitter-pet-nanny',
          name: 'Kućno čuvanje / Pet Nanny',
          category: PoiCategory.petSitter,
          address: 'Hadži Ruvimova, Novi Sad',
          latitude: 45.2546,
          longitude: 19.8302,
          phone: '060 550 1882',
          dayCare: true,
        ),
        _verified(
          id: 'sitter-petguards',
          name: 'PetGuards',
          category: PoiCategory.petSitter,
          address: 'Novi Sad',
          latitude: 45.2551,
          longitude: 19.8451,
          phone: '062 895 5037',
          dayCare: true,
        ),
      ];

  static List<PoiModel> get belgradeEmergencyVets => [
        _verified(
          id: 'bg-vet-boban',
          name: 'Veterinarska ambulanta Boban 24/7',
          category: PoiCategory.vet,
          address: 'Valterova 42, Beograd',
          latitude: 44.8428,
          longitude: 20.4021,
          phone: '+381 63 241 668',
          is24_7: true,
          isEmergencyService: true,
          city: MapCity.belgrade,
        ),
        _verified(
          id: 'bg-vet-fakultet',
          name: 'Klinika za male životinje - Vet Fakultet',
          category: PoiCategory.vet,
          address: 'Bulevar oslobođenja 18, Beograd',
          latitude: 44.8004,
          longitude: 20.4666,
          phone: '+381 11 3615 436',
          is24_7: true,
          isEmergencyService: true,
          city: MapCity.belgrade,
        ),
        _verified(
          id: 'bg-vet-jkp',
          name: 'JKP Veterina Beograd Hitna Pomoć',
          category: PoiCategory.vet,
          address: 'Bulevar despota Stefana 119, Beograd',
          latitude: 44.8216,
          longitude: 20.4762,
          phone: '+381 62 8041 090',
          is24_7: true,
          isEmergencyService: true,
          city: MapCity.belgrade,
        ),
      ];

  /// Legacy Belgrade POIs kept when not present in the geocoded corpus.
  /// Fake / unverifiable phone entries were removed.
  static List<PoiModel> get belgradeLegacyExtras => [
        _verified(
          id: 'bg-park-karadjordjev',
          name: 'Park za pse Karađorđev park',
          category: PoiCategory.park,
          address: 'Bulevar oslobođenja, Vračar',
          latitude: 44.7969,
          longitude: 20.4663,
          city: MapCity.belgrade,
        ),
        _verified(
          id: 'bg-park-kalemegdan',
          name: 'Park za pse Kalemegdan',
          category: PoiCategory.park,
          address: 'Kalemegdanska tvrđava, Stari Grad',
          latitude: 44.8230,
          longitude: 20.4506,
          city: MapCity.belgrade,
        ),
        _verified(
          id: 'bg-park-miljakovac',
          name: 'Park za pse Miljakovac',
          category: PoiCategory.park,
          address: 'Vukasovićeva, Rakovica',
          latitude: 44.7376,
          longitude: 20.4491,
          city: MapCity.belgrade,
        ),
        _verified(
          id: 'bg-cafe-witch',
          name: 'Witch Bar',
          category: PoiCategory.cafe,
          address: 'Pariska 13, Beograd',
          latitude: 44.8199,
          longitude: 20.4503,
          phone: '+381 61 416 6641',
          city: MapCity.belgrade,
          rating: 4.7,
        ),
        _verified(
          id: 'bg-cafe-smokvica',
          name: 'Smokvica',
          category: PoiCategory.cafe,
          address: 'Kralja Petra 73, Beograd',
          latitude: 44.8216,
          longitude: 20.4569,
          city: MapCity.belgrade,
          rating: 4.8,
        ),
        _verified(
          id: 'bg-hotel-golden-pets',
          name: 'Golden Pets Hotel',
          category: PoiCategory.dogHotel,
          address: 'Nikole Beševića 2, Voždovac',
          latitude: 44.7706,
          longitude: 20.4751,
          phone: '+381 69 283 2227',
          overnightStay: true,
          hasYard: true,
          city: MapCity.belgrade,
        ),
        _verified(
          id: 'bg-hotel-dzesi',
          name: 'Pansion Džesi i Lesi',
          category: PoiCategory.dogHotel,
          address: 'Krnjača, Beograd',
          latitude: 44.8461,
          longitude: 20.4962,
          phone: '+381 62 410 442',
          overnightStay: true,
          hasYard: true,
          city: MapCity.belgrade,
        ),
      ];
}
