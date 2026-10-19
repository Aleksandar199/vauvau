import '../domain/map_city.dart';
import '../domain/models/poi_model.dart';

/// Zrenjanin dog places (istraživanje 2026-10-19,
/// `docs/zrenjanin_subotica_mesta.md`).
///
/// - Parks: OpenStreetMap features (way centroids), status verified.
/// - Dog parks: four fenced dog parks named by Dnevnik (8. 1. 2026: Bagljaš kod
///   BIG-a, Motel, Šećerana, Železnički park), matched to OSM `leisure=dog_park`.
///   Motel is not clearly matched → unknown.
/// - Businesses: verified only when the business' own site confirms name,
///   address and contact; then phone, site and hours come from that site.
///   Others are confirmed by a public listing / local press only →
///   [PoiVerificationStatus.unknown], without phone, site or hours.
/// - Coordinates: Nominatim house-number match
///   (`tool/geocode_places_nominatim.ps1`, `tool/zrenjanin_places_nominatim.json`)
///   or the OSM node of the business. No city-center fallback.
abstract final class ZrenjaninDogPlacesSeed {
  static const String cityId = 'zrenjanin';
  static const String osmSource = 'OpenStreetMap';
  static const String pressSource = 'Dnevnik / OpenStreetMap';
  static const String officialSource = 'Zvanični sajt';
  static const String candidateSource =
      'VauVau kandidat (javni listing, adresa geokodirana, nije potvrđeno)';
  static final DateTime lastVerified = DateTime(2026, 10, 19);

  static const _dogParksArticle =
      'https://www.dnevnik.rs/vojvodina/banat/zrenjanincima-jasno-stavljeno-'
      'do-znanja-pravila-ponasanja-parku-koja-vlasnici-pasa-moraju-da-'
      'postuju-2026-01-08';

  static List<PoiModel> get all => [
        ...parks,
        ...dogParks,
        ...vets,
        ...petShops,
      ];

  static List<PoiModel> get parks => [
        for (final p in _parks) p.copyWith(isDogPark: false),
      ];

  static List<PoiModel> get dogParks => [
        for (final p in _dogParks) p.copyWith(isDogPark: true),
      ];

  static List<PoiModel> get _parks => [
        _poi(
          id: 'zr-park-karadjordjev',
          name: 'Karađorđev park',
          category: PoiCategory.park,
          address: 'Karađorđev park, Zrenjanin',
          latitude: 45.3853527,
          longitude: 20.3964626,
          description: 'Gradski park uz centar, pogodan za šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/96241144',
        ),
        _poi(
          id: 'zr-park-gradska-basta',
          name: 'Gradska bašta',
          category: PoiCategory.park,
          address: 'Gradska bašta, Centar, Zrenjanin',
          latitude: 45.3807820,
          longitude: 20.3893102,
          municipality: 'Centar',
          description: 'Park u centru grada za kraću šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/463524809',
        ),
        _poi(
          id: 'zr-park-titov-gaj',
          name: 'Titov gaj',
          category: PoiCategory.park,
          address: 'Titov gaj, Zrenjanin',
          latitude: 45.3926246,
          longitude: 20.3820431,
          description: 'Veća zelena površina za šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/1271825251',
        ),
        _poi(
          id: 'zr-park-zeleznicki',
          name: 'Železnički park',
          category: PoiCategory.park,
          address: 'Železnički park, Zrenjanin',
          latitude: 45.3794205,
          longitude: 20.3771113,
          description: 'Park kod železničke stanice; u njemu je i ograđen '
              'park za pse.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/418275694',
        ),
        _poi(
          id: 'zr-park-secerana',
          name: 'Šećeranski park',
          category: PoiCategory.park,
          address: 'Šećeranski park, Zrenjanin',
          latitude: 45.3653563,
          longitude: 20.4098452,
          description: 'Kvartovski park kod Šećerane; pored je ograđen park '
              'za pse.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/143996737',
        ),
        _poi(
          id: 'zr-park-streliste',
          name: 'Park Strelište',
          category: PoiCategory.park,
          address: 'Park Strelište, Zrenjanin',
          latitude: 45.3733219,
          longitude: 20.4203338,
          description: 'Kvartovski park za šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/1273325262',
        ),
      ];

  static const _dogParkRules =
      'Ograđen prostor; ulaz samo za vakcinisane pse, vlasnik nadgleda psa i '
      'čisti za njim (pravila na ogradi parka na Bagljašu).';

  static List<PoiModel> get _dogParks => [
        _poi(
          id: 'zr-dogpark-bagljas',
          name: 'Park za pse Bagljaš',
          category: PoiCategory.park,
          address: 'Bagljaš, kod tržnog centra BIG, Zrenjanin',
          latitude: 45.3792516,
          longitude: 20.3603040,
          municipality: 'Bagljaš',
          description: 'Ograđeni park za pse kod BIG-a. $_dogParkRules',
          source: pressSource,
          sourceUrl: _dogParksArticle,
        ),
        _poi(
          id: 'zr-dogpark-zeleznicki',
          name: 'Park za pse u Železničkom parku',
          category: PoiCategory.park,
          address: 'Železnički park, Zrenjanin',
          latitude: 45.3801799,
          longitude: 20.3767086,
          description: 'Ograđeni park za pse (OSM way 1086222200).',
          source: pressSource,
          sourceUrl: _dogParksArticle,
        ),
        _poi(
          id: 'zr-dogpark-secerana',
          name: 'Park za pse Šećerana',
          category: PoiCategory.park,
          address: 'Šećeranski park, Zrenjanin',
          latitude: 45.3657436,
          longitude: 20.4098317,
          description: 'Ograđeni park za pse kod Šećeranskog parka '
              '(OSM way 1118597340).',
          source: pressSource,
          sourceUrl: _dogParksArticle,
        ),
        _poi(
          id: 'zr-dogpark-motel',
          name: 'Park za pse Motel',
          category: PoiCategory.park,
          address: 'Naselje Motel, Zrenjanin',
          latitude: 45.3929946,
          longitude: 20.4096306,
          description: 'Dnevnik navodi park za pse „Motel“; pin je ograđeni '
              'park za pse iz OpenStreetMap-a (way 1208252981) — proverite '
              'da li je to ista lokacija.',
          source: pressSource,
          sourceUrl: 'https://www.openstreetmap.org/way/1208252981',
          status: PoiVerificationStatus.unknown,
        ),
      ];

  static List<PoiModel> get vets => [
        _poi(
          id: 'zr-vet-dimic',
          name: 'Veterina Dimić',
          category: PoiCategory.vet,
          address: 'Žarka Zrenjanina 78, Zrenjanin',
          latitude: 45.391252,
          longitude: 20.380111,
          phone: '023 567 021',
          website: 'https://vetdimic.com/',
          openingHours: 'Pon–pet 08–19, sub 09–14, ned 10–13; '
              'dežurna služba 19–24',
          description: 'Veterinarska ambulanta i apoteka. Nije 24/7 — dežurna '
              'služba do ponoći (prema sajtu).',
          source: officialSource,
          sourceUrl: 'https://vetdimic.com/?page_id=7',
        ),
        _candidate(
          id: 'zr-vet-laki-vet',
          name: 'Laki Vet',
          category: PoiCategory.vet,
          address: 'Topličina 13a, Zrenjanin',
          latitude: 45.389845,
          longitude: 20.402213,
          description: 'Veterinarska ambulanta za kućne ljubimce (otvorena '
              '2023. prema lokalnim medijima).',
          sourceUrl: 'https://volimzrenjanin.com/zrenjanin-je-dobio-novu-'
              'savremenu-veterinarsku-ambulantu-laki-vet/',
        ),
        _candidate(
          id: 'zr-vet-mila-vet',
          name: 'Mila Vet',
          category: PoiCategory.vet,
          address: 'Miletićeva 20, Zrenjanin',
          latitude: 45.379719,
          longitude: 20.401344,
          sourceUrl: 'https://www.facebook.com/p/Veterinarska-ambulanta-'
              'Mila-Vet-100063680996913/',
        ),
        _candidate(
          id: 'zr-vet-ultimate-vet',
          name: 'Ultimate Vet',
          category: PoiCategory.vet,
          address: 'Cara Dušana 14a, Zrenjanin',
          latitude: 45.384091,
          longitude: 20.391156,
          description: 'Adresa iz imenika dežurnih veterinara; zvanični sajt '
              'nije dostupan, radno vreme i dežurstvo nisu potvrđeni.',
          sourceUrl: 'http://www.dezurniveterinar.com/dezurni-veterinar-'
              'zrenjanin-ultimate-vet.html',
        ),
        _candidate(
          id: 'zr-vet-stanica-zrenjanin',
          name: 'Veterinarska stanica Zrenjanin',
          category: PoiCategory.vet,
          address: 'Koče Kolarova 38, Zrenjanin',
          latitude: 45.374147,
          longitude: 20.401393,
          sourceUrl: 'https://www.planplus.rs/zrenjanin/veterinarske-stanice',
        ),
        _candidate(
          id: 'zr-vet-canis',
          name: 'Veterinarska ambulanta Canis',
          category: PoiCategory.vet,
          address: 'Knićaninova 12, Zrenjanin',
          latitude: 45.378654,
          longitude: 20.406635,
          sourceUrl: 'https://imenik.rs/veterinarska-ambulanta-canis',
        ),
        _candidate(
          id: 'zr-vet-taurus',
          name: 'Veterinarska stanica Taurus',
          category: PoiCategory.vet,
          address: 'Elemirski drum 56, Zrenjanin',
          latitude: 45.3924894,
          longitude: 20.3737929,
          description: 'Pin je OSM čvor ambulante (kućni broj iz Waze listinga).',
          sourceUrl: 'https://www.openstreetmap.org/node/5310930623',
        ),
      ];

  static List<PoiModel> get petShops => [
        _candidate(
          id: 'zr-shop-gama-pet',
          name: 'Gama Pet',
          category: PoiCategory.petShop,
          address: 'Koče Kolarova 39, Zrenjanin',
          latitude: 45.374128,
          longitude: 20.402429,
          description: 'Pet shop (u OpenStreetMap-u na istoj adresi kao '
              '„Gama pet shop“).',
          sourceUrl: 'https://www.openstreetmap.org/node/4734330123',
        ),
        _candidate(
          id: 'zr-shop-aristo-pets',
          name: 'Aristo Pets',
          category: PoiCategory.petShop,
          address: 'Bagljaš zapad 5, Zrenjanin',
          latitude: 45.378149,
          longitude: 20.354984,
          municipality: 'Bagljaš',
          sourceUrl: 'https://www.planplus.rs/en/zrenjanin/pet-shops',
        ),
      ];

  /// Unconfirmed business: no phone, site or hours until an admin verifies it.
  static PoiModel _candidate({
    required String id,
    required String name,
    required PoiCategory category,
    required String address,
    required double latitude,
    required double longitude,
    String municipality = '',
    String description = '',
    String sourceUrl = '',
  }) {
    return _poi(
      id: id,
      name: name,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      municipality: municipality,
      description: description,
      source: candidateSource,
      sourceUrl: sourceUrl,
      status: PoiVerificationStatus.unknown,
    );
  }

  static PoiModel _poi({
    required String id,
    required String name,
    required PoiCategory category,
    required String address,
    required double latitude,
    required double longitude,
    required String source,
    String phone = '',
    String? website,
    String openingHours = '',
    String municipality = '',
    String description = '',
    String sourceUrl = '',
    PoiVerificationStatus status = PoiVerificationStatus.verified,
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
      openingHours: openingHours,
      municipality: municipality,
      description: description,
      sourceUrl: sourceUrl,
      city: MapCity.zrenjanin,
      cityId: cityId,
      verificationStatus: status,
      lastVerified: lastVerified,
      source: source,
    );
  }
}
