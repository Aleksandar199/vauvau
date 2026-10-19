import '../domain/map_city.dart';
import '../domain/models/poi_model.dart';

/// Subotica dog places (istraživanje 2026-10-19,
/// `docs/zrenjanin_subotica_mesta.md`).
///
/// - Parks: OpenStreetMap features (way centroids), status verified.
/// - Dog parks: Grad Subotica opened fenced dog areas in Dudova šuma and
///   Prozivka (9. 1. 2020). Prozivka is mapped in OSM (`leisure=dog_park`) →
///   verified pin; the exact spot in Dudova šuma is not mapped, so it is only
///   mentioned in the park description (no guessed pin).
/// - Businesses: verified only when the business' own site confirms name,
///   address and contact; then phone, site and hours come from that site.
///   Others come from public listings / OSM only →
///   [PoiVerificationStatus.unknown], without phone, site or hours.
/// - Coordinates: Nominatim house-number match
///   (`tool/geocode_places_nominatim.ps1`, `tool/subotica_places_nominatim.json`)
///   or the OSM node of the business. No city-center fallback.
abstract final class SuboticaDogPlacesSeed {
  static const String cityId = 'subotica';
  static const String osmSource = 'OpenStreetMap';
  static const String citySource = 'Grad Subotica / lokalni mediji';
  static const String officialSource = 'Zvanični sajt';
  static const String candidateSource =
      'VauVau kandidat (javni listing, adresa geokodirana, nije potvrđeno)';
  static const String osmCandidateSource =
      'VauVau kandidat (OpenStreetMap, nije potvrđeno)';
  static final DateTime lastVerified = DateTime(2026, 10, 19);

  static const _dogParksArticle =
      'https://gradsubotica.co.rs/u-parkovima-dudova-suma-i-prozivka-'
      'otvoreni-prostori-za-pse/';

  static List<PoiModel> get all => [
        ...parks,
        ...dogParks,
        ...vets,
        ...petShops,
        ...grooming,
        ...services,
      ];

  static List<PoiModel> get parks => [
        for (final p in _parks) p.copyWith(isDogPark: false),
      ];

  static List<PoiModel> get dogParks => [
        for (final p in _dogParks) p.copyWith(isDogPark: true),
      ];

  static List<PoiModel> get _parks => [
        _poi(
          id: 'su-park-dudova-suma',
          name: 'Dudova šuma',
          category: PoiCategory.park,
          address: 'Dudova šuma, Subotica',
          latitude: 46.1103682,
          longitude: 19.6530388,
          municipality: 'Dudova šuma',
          description: 'Velika parkovska šuma za šetnju. Grad je 2020. otvorio '
              'ograđen prostor za pse levo od ulaza sa Radijalca '
              '(tačna lokacija nije ucrtana na mapi).',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/359835105',
        ),
        _poi(
          id: 'su-park-prozivka',
          name: 'Park Prozivka',
          category: PoiCategory.park,
          address: 'Park Prozivka, Subotica',
          latitude: 46.0869730,
          longitude: 19.6759206,
          municipality: 'Prozivka',
          description: 'Kvartovski park sa šetalištem prema Bajnatskoj; u '
              'parku je ograđen prostor za pse.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/400328561',
        ),
        _poi(
          id: 'su-park-ferenca-rajhla',
          name: 'Park Ferenca Rajhla',
          category: PoiCategory.park,
          address: 'Park Ferenca Rajhla, Subotica',
          latitude: 46.1009775,
          longitude: 19.6701155,
          description: 'Gradski park kod centra za kraću šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/75683509',
        ),
        _poi(
          id: 'su-park-slobode',
          name: 'Park slobode',
          category: PoiCategory.park,
          address: 'Park slobode, Centar, Subotica',
          latitude: 46.0994584,
          longitude: 19.6654268,
          description: 'Park u centru grada za kraću šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/78067069',
        ),
        _poi(
          id: 'su-park-mali-bajmok',
          name: 'Park Mali Bajmok',
          category: PoiCategory.park,
          address: 'Mali Bajmok, Subotica',
          latitude: 46.0849653,
          longitude: 19.6395645,
          municipality: 'Mali Bajmok',
          description: 'Kvartovski park za šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/1088618682',
        ),
      ];

  static List<PoiModel> get _dogParks => [
        _poi(
          id: 'su-dogpark-prozivka',
          name: 'Park za pse Prozivka',
          category: PoiCategory.park,
          address: 'Park Prozivka, kod Bajnatske, Subotica',
          latitude: 46.0854145,
          longitude: 19.6772830,
          municipality: 'Prozivka',
          description: 'Zvanični ograđeni prostor za pse (otvoren 9. 1. 2020): '
              'gledano sa Bajnatske levo za male, desno za velike pse.',
          source: citySource,
          sourceUrl: _dogParksArticle,
        ),
      ];

  static List<PoiModel> get vets => [
        _poi(
          id: 'su-vet-veterinar',
          name: 'Veterinarska stanica Veterinar',
          category: PoiCategory.vet,
          address: 'Trg Paje Kujundžića 2/a, Subotica',
          latitude: 46.090367,
          longitude: 19.673814,
          phone: '024 671 060',
          website: 'https://veterinarsubotica.rs/',
          openingHours: 'Pon–pet 07–19, sub 07–14, ned 08–11',
          description: 'Veterinarska stanica kod Senćanske crkve. Nije 24/7.',
          source: officialSource,
          sourceUrl: 'https://veterinarsubotica.rs/kontakt/',
        ),
        _poi(
          id: 'su-vet-panvet',
          name: 'Panvet',
          category: PoiCategory.vet,
          address: 'Koste Racina 5, Subotica',
          latitude: 46.107677,
          longitude: 19.665692,
          phone: '024 571 920',
          website: 'https://www.panvet.info/',
          description: 'Veterinarska stanica. Radno vreme i broj za hitne '
              'intervencije proverite na sajtu.',
          source: officialSource,
          sourceUrl: 'https://www.panvet.info/',
        ),
        _poi(
          id: 'su-vet-viva',
          name: 'Veterinarska ambulanta Viva',
          category: PoiCategory.vet,
          address: 'Pačirski put 21, Subotica',
          latitude: 46.080313,
          longitude: 19.66873,
          phone: '060 1304878',
          website: 'https://vivaveterinar.rs/',
          source: officialSource,
          sourceUrl: 'https://vivaveterinar.rs/',
        ),
        _candidate(
          id: 'su-vet-animed',
          name: 'Animed',
          category: PoiCategory.vet,
          address: 'Blaška Rajića 30, Subotica',
          latitude: 46.088306,
          longitude: 19.668503,
          description: 'Zvanični sajt nije bio dostupan pri proveri.',
          sourceUrl: 'https://www.openstreetmap.org/node/9368486449',
        ),
        _osmCandidate(
          id: 'su-vet-happy-vet',
          name: 'Happy Vet',
          address: 'Partizanskih baza 35, Subotica',
          latitude: 46.1066548,
          longitude: 19.6889271,
          node: 9555822307,
        ),
        _osmCandidate(
          id: 'su-vet-ekosvet',
          name: 'Ekosvet',
          address: 'Braće Majera 40, Subotica',
          latitude: 46.1028405,
          longitude: 19.6520835,
          node: 13206349370,
        ),
        _osmCandidate(
          id: 'su-vet-sudarevic',
          name: 'Sudarević-vet',
          address: 'Vlasenička 41, Subotica',
          latitude: 46.0720390,
          longitude: 19.6698278,
          node: 13206349371,
        ),
        _osmCandidate(
          id: 'su-vet-libero',
          name: 'Libero veterina',
          address: 'Bore Stankovića 6, Subotica',
          latitude: 46.1059440,
          longitude: 19.6635059,
          node: 13206349372,
        ),
        _osmCandidate(
          id: 'su-vet-radakovic',
          name: 'Radaković vet',
          address: 'Lazara Bačića 6, Subotica',
          latitude: 46.0835259,
          longitude: 19.6627030,
          node: 13206349367,
        ),
        _osmCandidate(
          id: 'su-vet-stanica-subotica',
          name: 'Veterinarska stanica Subotica',
          address: 'Segedinski put 88, Subotica',
          latitude: 46.1010369,
          longitude: 19.6994546,
          node: 13206349366,
          description: 'Javna veterinarska služba (radi i sa farmskim '
              'životinjama).',
        ),
      ];

  static List<PoiModel> get petShops => [
        _poi(
          id: 'su-shop-pet-centar',
          name: 'Pet Centar Subotica',
          category: PoiCategory.petShop,
          address: 'Bajnatska 25, Subotica',
          latitude: 46.085155,
          longitude: 19.678366,
          phone: '024 52 25 82',
          website: 'https://www.pet-centar.rs/pages/lokacija/pet-centar-subotica',
          openingHours: 'Pon–ned 09–21',
          description: 'Prodavnica i veterinarska apoteka (jedina filijala u '
              'Subotici prema sajtu; „Bajnatska bb“ iz imenika je ista radnja).',
          source: officialSource,
          sourceUrl:
              'https://www.pet-centar.rs/pages/lokacija/pet-centar-subotica',
        ),
        _candidate(
          id: 'su-shop-pet-zone',
          name: 'Pet Zone',
          category: PoiCategory.petShop,
          address: 'Segedinski put 88a, Subotica',
          latitude: 46.100435,
          longitude: 19.697353,
          sourceUrl: 'https://www.planplus.rs/en/subotica/pet-shops',
        ),
        _candidate(
          id: 'su-shop-petbox',
          name: 'Petbox',
          category: PoiCategory.petShop,
          address: 'Somborski put 35, Subotica',
          latitude: 46.094444,
          longitude: 19.65355,
          sourceUrl: 'https://www.planplus.rs/en/subotica/pet-shops',
        ),
        _candidate(
          id: 'su-shop-svet-kucnih-ljubimaca',
          name: 'Svet kućnih ljubimaca',
          category: PoiCategory.petShop,
          address: 'Ivana Milankovića 40, Subotica',
          latitude: 46.08952,
          longitude: 19.675462,
          description: 'OpenStreetMap ima „Svet ljubimaca“ na broju 42 — '
              'proverite tačan broj.',
          sourceUrl: 'https://www.planplus.rs/en/subotica/pet-shops',
        ),
        _osmCandidate(
          id: 'su-shop-pet-svet-024-lajosa-joa',
          name: 'Pet Svet 024',
          category: PoiCategory.petShop,
          address: 'Lajoša Joa 5, Subotica',
          latitude: 46.0948292,
          longitude: 19.6662858,
          node: 7551931549,
        ),
        _osmCandidate(
          id: 'su-shop-pet-svet-024-osmog-marta',
          name: 'Pet Svet 024 (Osmog marta)',
          category: PoiCategory.petShop,
          address: 'Osmog marta 9v, Subotica',
          latitude: 46.0890558,
          longitude: 19.6697367,
          node: 13174220467,
        ),
        _osmCandidate(
          id: 'su-shop-maxpet',
          name: 'MaxPet',
          category: PoiCategory.petShop,
          address: 'Braće Radić 118, Subotica',
          latitude: 46.0901780,
          longitude: 19.6731930,
          node: 9366300419,
        ),
        _osmCandidate(
          id: 'su-shop-little-pet-shop',
          name: 'Little Pet Shop 024',
          category: PoiCategory.petShop,
          address: 'Gundulićeva 53, Subotica',
          latitude: 46.0893056,
          longitude: 19.6584207,
          node: 13165470301,
        ),
        _osmCandidate(
          id: 'su-shop-mondo-animale',
          name: 'Mondo Animale',
          category: PoiCategory.petShop,
          address: 'Trg Jakaba i Komora 8, Subotica',
          latitude: 46.1018423,
          longitude: 19.6606658,
          node: 13206349365,
          description: 'Veterinarska apoteka.',
        ),
      ];

  static List<PoiModel> get grooming => [
        _candidate(
          id: 'su-groom-anastazija',
          name: 'Anastazija Grooming',
          category: PoiCategory.groomer,
          address: 'Petra Čajkovskog 12, Subotica',
          latitude: 46.104274,
          longitude: 19.692081,
          description: 'Salon za šišanje i negu pasa i mačaka.',
          sourceUrl: 'https://www.planplus.rs/en/anastazija-grooming-pet-'
              'grooming/88999',
        ),
        _candidate(
          id: 'su-groom-bokine-sape',
          name: 'Bokine šape',
          category: PoiCategory.groomer,
          address: 'Šumska 9, Subotica',
          latitude: 46.107905,
          longitude: 19.657873,
          description: 'Salon za negu pasa, rad po zakazivanju.',
          sourceUrl: 'https://www.subotica.biz/Kategorija/Nega-i-frizer-za-'
              'kucne-ljubimce---groomig/241/',
        ),
        _candidate(
          id: 'su-groom-diego',
          name: 'Grooming salon Diego',
          category: PoiCategory.groomer,
          address: 'Braće Radić 87, Subotica',
          latitude: 46.089914,
          longitude: 19.674504,
          description: 'Rad po zakazivanju.',
          sourceUrl: 'https://www.openstreetmap.org/node/9368486334',
        ),
        _candidate(
          id: 'su-groom-godzi',
          name: 'Godži Groom',
          category: PoiCategory.groomer,
          address: 'Nade Dimić 17, Subotica',
          latitude: 46.086884,
          longitude: 19.671686,
          description: 'Rad po zakazivanju.',
          sourceUrl: 'https://www.openstreetmap.org/node/13119600510',
        ),
      ];

  static List<PoiModel> get services => [
        _candidate(
          id: 'su-wash-samousluzno-kupanje',
          name: 'Samouslužno kupanje pasa',
          category: PoiCategory.selfWash,
          address: 'Trg sinagoge 1a, Subotica',
          latitude: 46.102028,
          longitude: 19.661029,
          description: 'Samouslužna perionica za pse; prema sajtu otvoreno '
              '0–24 (noću ulaz sa kodom). Adresa nije na zvaničnoj strani.',
          sourceUrl: 'https://kupanjepasa.com/subotica/?lang=sr',
        ),
        _candidate(
          id: 'su-shelter-prihvataliste',
          name: 'Prihvatilište za napuštene pse i mačke',
          category: PoiCategory.shelter,
          address: 'Deveta nova 249, Zorka, Subotica',
          latitude: 46.140306,
          longitude: 19.646497,
          municipality: 'Zorka',
          description: 'Gradsko prihvatilište (JKP „Čistoća i zelenilo“, '
              'članak iz 2019). Imenik navodi i „Zapadni vinogradi bb“ — '
              'proverite adresu i termine za udomljavanje.',
          sourceUrl: 'https://gradsubotica.co.rs/u-prihvatilistu-za-pse-i-'
              'macke-u-subotici-imaju-sve-sto-pozele-ali/',
        ),
      ];

  /// Business known only from OpenStreetMap ([node] = OSM node id).
  static PoiModel _osmCandidate({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required int node,
    PoiCategory category = PoiCategory.vet,
    String description = '',
  }) {
    return _candidate(
      id: id,
      name: name,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      description: description,
      sourceUrl: 'https://www.openstreetmap.org/node/$node',
      source: osmCandidateSource,
    );
  }

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
    String source = candidateSource,
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
      source: source,
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
      city: MapCity.subotica,
      cityId: cityId,
      verificationStatus: status,
      lastVerified: lastVerified,
      source: source,
    );
  }
}
