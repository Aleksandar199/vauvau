import '../domain/map_city.dart';
import '../domain/models/poi_model.dart';

/// Kragujevac dog places.
///
/// - Parks / squares: OpenStreetMap features (way centroids), status verified.
/// - Official pet parks: City of Kragujevac / local press, status verified;
///   Metino brdo was still under construction per source → unknown.
/// - Businesses: candidate list geocoded to the exact house number via
///   Nominatim (`tool/geocode_places_nominatim.ps1`). Operating status and
///   details are NOT confirmed → [PoiVerificationStatus.unknown] until an admin
///   approves them. Entries without a house-level match were left out.
/// - Cafes: tagged "Dogs allowed" on public map listings only; the venue's own
///   policy (indoor / terrace) is unconfirmed, so dog-access flags stay null.
abstract final class KragujevacDogPlacesSeed {
  static const String cityId = 'kragujevac';
  static const String osmSource = 'OpenStreetMap';
  static const String citySource = 'Grad Kragujevac / lokalni mediji';
  static const String candidateSource = 'VauVau kandidat (adresa geokodirana, nije potvrđeno)';
  static final DateTime lastVerified = DateTime(2026, 10, 14);

  static List<PoiModel> get all => [
        ...parks,
        ...dogParks,
        ...petShops,
        ...vets,
        ...grooming,
        ...cafes,
      ];

  static List<PoiModel> get parks => [
        for (final p in _parks)
          p.category == PoiCategory.park ? p.copyWith(isDogPark: false) : p,
      ];

  static List<PoiModel> get dogParks => [
        for (final p in _dogParks) p.copyWith(isDogPark: true),
      ];

  static List<PoiModel> get _parks => [
        _poi(
          id: 'kg-park-veliki-park',
          name: 'Veliki park',
          category: PoiCategory.park,
          address: 'Veliki park, Kragujevac',
          latitude: 44.0176323,
          longitude: 20.9038528,
          description: 'Najveća zelena površina u centru, pogodna za šetnju. '
              'Ograđeni pet park je pored skejt parka.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/83350839',
        ),
        _poi(
          id: 'kg-park-sumarice',
          name: 'Spomen-park Šumarice',
          category: PoiCategory.park,
          address: 'Spomen-park Kragujevački oktobar, Šumarice, Kragujevac',
          latitude: 44.0219918,
          longitude: 20.8837459,
          description: 'Velika zelena površina i memorijalni kompleks. Poštujte '
              'pravila memorijalnog prostora; slobodno kretanje pasa nije '
              'potvrđeno na celoj površini.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/168707959',
        ),
        _poi(
          id: 'kg-park-ilina-voda',
          name: 'Ekopark Ilina voda',
          category: PoiCategory.park,
          address: 'Ilina voda, Kragujevac',
          latitude: 44.0167472,
          longitude: 20.9403597,
          description: 'Gradski park za šetnju i rekreaciju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/94701885',
        ),
        _poi(
          id: 'kg-park-pivarski',
          name: 'Pivarski park',
          category: PoiCategory.park,
          address: 'Pivara, Kragujevac',
          latitude: 44.0040091,
          longitude: 20.9188015,
          description: 'Kvartovski park u naselju Pivara.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/158605428',
        ),
        _poi(
          id: 'kg-trg-radomira-putnika',
          name: 'Trg Radomira Putnika',
          category: PoiCategory.other,
          address: 'Trg Radomira Putnika, Kragujevac',
          latitude: 44.010928,
          longitude: 20.916326,
          description: 'Gradski trg i pešačka zona za kraću šetnju. Nije park '
              'niti park za pse.',
          source: osmSource,
        ),
      ];

  static List<PoiModel> get _dogParks => [
        _poi(
          id: 'kg-dogpark-gradska-uprava',
          name: 'Pet park iza Gradske uprave',
          category: PoiCategory.park,
          address: 'Trg slobode 3 (iza zgrade Gradske uprave), Kragujevac',
          latitude: 44.013407,
          longitude: 20.919714,
          description: 'Zvanični ograđeni park za pse (oko 1 ar) sa spravama, '
              'klupama i pravilima ponašanja. Otvoren 26. 3. 2024.',
          source: citySource,
          sourceUrl: 'https://rtk.co.rs/kragujevac-dobio-prvi-park-za-pse/',
        ),
        _poi(
          id: 'kg-dogpark-veliki-park',
          name: 'Pet park u Velikom parku',
          category: PoiCategory.park,
          address: 'Veliki park, pored skejt parka, Kragujevac',
          latitude: 44.0186779,
          longitude: 20.9038399,
          description: 'Zvanični ograđeni pet park (oko 3 ara) sa agility '
              'spravama, pored skejt parka. Pin je na skejt parku.',
          source: citySource,
          sourceUrl: 'https://www.kragujevac.ls.gov.rs/vest/69138/'
              'u-velikom-parku-prostor-za-kucne-ljubimce.php',
        ),
        _poi(
          id: 'kg-dogpark-metino-brdo',
          name: 'Poligon za pse Metino brdo',
          category: PoiCategory.park,
          address: 'Metino brdo, Kragujevac',
          latitude: 43.9962995,
          longitude: 20.9231963,
          description: 'Ograđeni poligon za pse; prema izvoru radovi su bili u '
              'toku — proverite da li je otvoren.',
          source: citySource,
          sourceUrl: 'https://www.infokg.rs/info/na-metinom-brdu-poligon-za-pse-'
              'a-nema-decjeg-igralista-evo-sta-kazu-u-gradskoj-upravi-foto.html',
          status: PoiVerificationStatus.unknown,
        ),
      ];

  static List<PoiModel> get petShops => [
        _candidate(
          id: 'kg-shop-pawz-sapice',
          name: 'Pawz Šapice Pet Shop',
          category: PoiCategory.petShop,
          address: 'Kneza Mihaila 33B, Kragujevac',
          latitude: 44.006982,
          longitude: 20.9076,
        ),
        _candidate(
          id: 'kg-shop-zoo-centar',
          name: 'Zoo Centar',
          category: PoiCategory.petShop,
          address: 'Darinke Plave Pavlović 1, Kragujevac',
          latitude: 44.010966,
          longitude: 20.915285,
        ),
        _candidate(
          id: 'kg-shop-premium-pet',
          name: 'Premium Pet',
          category: PoiCategory.petShop,
          address: 'Save Kovačevića 48A, Kragujevac',
          latitude: 44.013827,
          longitude: 20.922,
        ),
        _candidate(
          id: 'kg-shop-scooby-doo',
          name: 'Pet Shop Scooby Doo',
          category: PoiCategory.petShop,
          address: 'Kralja Aleksandra I Karađorđevića 70, Kragujevac',
          latitude: 44.013661,
          longitude: 20.910043,
          description: 'Pet shop i veterinarska apoteka.',
        ),
        _candidate(
          id: 'kg-shop-pet-centar-big',
          name: 'Pet Centar Kragujevac BIG',
          category: PoiCategory.petShop,
          address: 'Dimitrija Tucovića 23 (BIG), Kragujevac',
          latitude: 44.009478,
          longitude: 20.894013,
          website: 'https://www.pet-centar.rs',
        ),
        _candidate(
          id: 'kg-wash-snoopy',
          name: 'Samouslužna perionica za pse Snoopy',
          category: PoiCategory.selfWash,
          address: 'Ljube Vučkovića 2, lokal 4, Kragujevac',
          latitude: 44.03016,
          longitude: 20.90328,
        ),
      ];

  static List<PoiModel> get vets => [
        _candidate(
          id: 'kg-vet-kragujvet',
          name: 'KragujVet',
          category: PoiCategory.vet,
          address: 'Kneza Miloša 1, Kragujevac',
          latitude: 44.013181,
          longitude: 20.912876,
        ),
        _candidate(
          id: 'kg-vet-kragujvet-pet',
          name: 'KragujVet Pet',
          category: PoiCategory.vet,
          address: 'Luja Pastera 12, Kragujevac',
          latitude: 44.017104,
          longitude: 20.912596,
        ),
        _candidate(
          id: 'kg-vet-radicevic',
          name: 'Veterinarska ambulanta Radičević',
          category: PoiCategory.vet,
          address: 'Kralja Aleksandra I Karađorđevića 124, Kragujevac',
          latitude: 44.015445,
          longitude: 20.907208,
        ),
        _candidate(
          id: 'kg-vet-daca-vet',
          name: 'Dača Vet',
          category: PoiCategory.vet,
          address: 'Sinđelićeva 8, Kragujevac',
          latitude: 44.004021,
          longitude: 20.929878,
        ),
        _candidate(
          id: 'kg-vet-dog-ma',
          name: 'Dog-Ma Vet',
          category: PoiCategory.vet,
          address: 'Braće Poljakovića 27, Kragujevac',
          latitude: 44.010464,
          longitude: 20.926842,
        ),
        _candidate(
          id: 'kg-vet-dr-karic',
          name: 'Veterinarska ambulanta Dr Karić',
          category: PoiCategory.vet,
          address: 'Daničićeva 64, Kragujevac',
          latitude: 44.011213,
          longitude: 20.904411,
        ),
        _candidate(
          id: 'kg-vet-fortuna',
          name: 'Fortuna Vet',
          category: PoiCategory.vet,
          address: 'Gružanska 1, Kragujevac',
          latitude: 44.006736,
          longitude: 20.903906,
        ),
        _candidate(
          id: 'kg-vet-lav-vet',
          name: 'Lav Vet',
          category: PoiCategory.vet,
          address: 'Cetinjska 3A, Kragujevac',
          latitude: 44.012491,
          longitude: 20.910244,
        ),
        _candidate(
          id: 'kg-vet-medicus',
          name: 'Medicus Vet',
          category: PoiCategory.vet,
          address: 'Bregalnička 8, Kragujevac',
          latitude: 44.024549,
          longitude: 20.91075,
        ),
        _candidate(
          id: 'kg-vet-medikavet',
          name: 'Medikavet',
          category: PoiCategory.vet,
          address: 'Hadži Milentijeva 3, Kragujevac',
          latitude: 44.003046,
          longitude: 20.899908,
        ),
        _candidate(
          id: 'kg-vet-milvet',
          name: 'Milvet',
          category: PoiCategory.vet,
          address: 'Janka Veselinovića 10, Kragujevac',
          latitude: 44.015961,
          longitude: 20.917369,
        ),
      ];

  static List<PoiModel> get grooming => [
        _candidate(
          id: 'kg-groom-mona',
          name: 'Salon za pse Mona',
          category: PoiCategory.groomer,
          address: 'Dr Ilije Kolovića 5, Kragujevac',
          latitude: 44.011598,
          longitude: 20.910364,
        ),
        _candidate(
          id: 'kg-groom-grooming',
          name: 'Salon za šišanje i negu pasa Grooming',
          category: PoiCategory.groomer,
          address: 'Kneza Mihaila 144, Kragujevac',
          latitude: 44.004442,
          longitude: 20.90043,
        ),
        _candidate(
          id: 'kg-groom-laika',
          name: 'Salon za šišanje pasa Laika',
          category: PoiCategory.groomer,
          address: 'Starine Novaka 8a/1, Kragujevac',
          latitude: 44.007743,
          longitude: 20.904887,
        ),
      ];

  static const _listingDogsAllowed =
      'Na javnim map listinzima označeno „psi dozvoljeni“. Pravilo lokala '
      '(unutra / bašta) nije potvrđeno — pitajte osoblje.';

  static List<PoiModel> get cafes => [
        for (final cafe in _cafeCandidates) cafe.copyWith(petFriendly: false),
      ];

  static List<PoiModel> get _cafeCandidates => [
        _candidate(
          id: 'kg-cafe-kafemat-27',
          name: 'Kafemat 27',
          category: PoiCategory.cafe,
          address: 'Karađorđeva 19, Kragujevac',
          latitude: 44.013682,
          longitude: 20.912888,
          phone: '061 286 4827',
          description: _listingDogsAllowed,
          sourceUrl: 'https://www.planplus.rs/kafemat-27/118959',
        ),
        _candidate(
          id: 'kg-cafe-coffee-dream-cetinjska',
          name: 'Coffee Dream Cetinjska',
          category: PoiCategory.cafe,
          address: 'Cetinjska 14, Kragujevac',
          latitude: 44.012256,
          longitude: 20.911298,
          phone: '034 209 611',
          website: 'https://coffeedream.rs/',
          description: _listingDogsAllowed,
        ),
        _candidate(
          id: 'kg-cafe-coffee-dream-big',
          name: 'Coffee Dream BIG',
          category: PoiCategory.cafe,
          address: 'Dimitrija Tucovića 23 (BIG), Kragujevac',
          latitude: 44.009478,
          longitude: 20.894013,
          phone: '063 196 5015',
          website: 'https://coffeedream.rs/',
          description: _listingDogsAllowed,
        ),
        _candidate(
          id: 'kg-cafe-nase-mesto',
          name: 'Naše mesto cafe bar',
          category: PoiCategory.cafe,
          address: 'Kosovska 5, Kragujevac',
          latitude: 44.007229,
          longitude: 20.917167,
          phone: '065 234 9090',
          description: _listingDogsAllowed,
        ),
      ];

  static PoiModel _candidate({
    required String id,
    required String name,
    required PoiCategory category,
    required String address,
    required double latitude,
    required double longitude,
    String phone = '',
    String? website,
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
      phone: phone,
      website: website,
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
      description: description,
      sourceUrl: sourceUrl,
      city: MapCity.kragujevac,
      cityId: cityId,
      verificationStatus: status,
      lastVerified: lastVerified,
      source: source,
    );
  }
}
