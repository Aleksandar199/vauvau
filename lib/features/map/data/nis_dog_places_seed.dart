import '../domain/map_city.dart';
import '../domain/models/poi_model.dart';

/// Niš dog places.
///
/// - Parks / promenade / squares: OpenStreetMap features (centroid or POI
///   node), status verified. Public parks are NOT dog parks ([isDogPark] false).
/// - Official dog park: fenced area in Park Čair (OSM `leisure=dog_park`,
///   opened 2016 per local press), status verified.
/// - Businesses: candidate list geocoded to the exact house number via
///   Nominatim (`tool/geocode_places_nominatim.ps1`). Operating status is not
///   confirmed → [PoiVerificationStatus.unknown] until an admin approves.
///   Entries without a house-level match were left out.
/// - Venues verified only where the business's own website states the pet
///   policy; phone / hours only from that official page.
abstract final class NisDogPlacesSeed {
  static const String cityId = 'nis';
  static const String osmSource = 'OpenStreetMap';
  static const String citySource = 'Grad Niš / lokalni mediji';
  static const String officialSource = 'Zvanični sajt objekta';
  static const String candidateSource =
      'VauVau kandidat (adresa geokodirana, nije potvrđeno)';
  static final DateTime lastVerified = DateTime(2026, 10, 14);

  static List<PoiModel> get all => [
        ...parks,
        ...dogParks,
        ...petShops,
        ...vets,
        ...grooming,
        ...cafes,
        ...services,
      ];

  static List<PoiModel> get parks => [
        _poi(
          id: 'nis-park-cair',
          name: 'Park Čair',
          category: PoiCategory.park,
          address: '9. brigade bb (Park Čair), Niš',
          latitude: 43.3150022,
          longitude: 21.9050759,
          description: 'Najveći gradski park, pogodan za šetnju. Ograđeni '
              'park za pse je posebna lokacija u okviru parka.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/relation/12890686',
          isDogPark: false,
        ),
        _poi(
          id: 'nis-park-svetog-save',
          name: 'Park Svetog Save',
          category: PoiCategory.park,
          address: 'Park Svetog Save, Niš',
          latitude: 43.3207314,
          longitude: 21.9190849,
          description: 'Javna zelena površina za šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/135704130',
          isDogPark: false,
        ),
        _poi(
          id: 'nis-park-kod-delte',
          name: 'Park kod Delte',
          category: PoiCategory.park,
          address: 'Park kod Delte, Niš',
          latitude: 43.3232013,
          longitude: 21.9119309,
          description: 'Novije uređen gradski park, pogodan za šetnju.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/945407753',
          isDogPark: false,
        ),
        _poi(
          id: 'nis-park-tvrdjava',
          name: 'Niška tvrđava',
          category: PoiCategory.park,
          address: 'Tvrđava, Niš',
          latitude: 43.3257724,
          longitude: 21.8954469,
          description: 'Istorijska tvrđava i okolni javni prostor za šetnju. '
              'Pravila za pse unutar kompleksa nisu potvrđena — držite psa '
              'na povocu.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/node/2306977248',
          petFriendly: false,
          isDogPark: false,
        ),
        _poi(
          id: 'nis-park-bubanj',
          name: 'Spomen-park Bubanj',
          category: PoiCategory.park,
          address: 'Vojvode Putnika, Bubanj, Niš',
          latitude: 43.3049095,
          longitude: 21.8724219,
          description: 'Memorijalni park sa šumom i stazama. Poštujte pravila '
              'memorijalnog prostora; slobodno kretanje pasa nije potvrđeno.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/node/6788181966',
          petFriendly: false,
          isDogPark: false,
        ),
        _poi(
          id: 'nis-park-kej-nisave',
          name: 'Kej na Nišavi',
          category: PoiCategory.other,
          address: 'Kej, Beogradska mala (kod Tvrđave), Niš',
          latitude: 43.3252082,
          longitude: 21.8999858,
          description: 'Šetalište uz Nišavu. Pin je na pešačkoj stazi „Kej“ '
              'kod Tvrđave; nije park za pse.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/way/290403311',
        ),
        _poi(
          id: 'nis-trg-sindjelicev',
          name: 'Sinđelićev trg',
          category: PoiCategory.other,
          address: 'Sinđelićev trg, Niš',
          latitude: 43.3209123,
          longitude: 21.9002904,
          description: 'Gradski trg za kraću šetnju. Nije park niti park za '
              'pse.',
          source: osmSource,
          sourceUrl: 'https://www.openstreetmap.org/relation/19425035',
        ),
      ];

  static List<PoiModel> get dogParks => [
        _poi(
          id: 'nis-dogpark-cair',
          name: 'Park za pse u Čairu',
          category: PoiCategory.park,
          address: 'Park Čair, Medijana, Niš',
          latitude: 43.3148263,
          longitude: 21.9067922,
          description: 'Zvanični ograđeni park za pse sa penjalicama i '
              'stazama, otvoren 2016, osvetljen noću. Najavljena je '
              'rekonstrukcija Čaira (podela na zone za male i velike pse) — '
              'proverite trenutno stanje.',
          source: citySource,
          sourceUrl: 'https://www.kurir.rs/vesti/srbija/2149911/'
              'nislije-dobile-park-za-pse-u-cairu',
          isDogPark: true,
        ),
      ];

  static List<PoiModel> get petShops => [
        _candidate(
          id: 'nis-shop-pet-centar-nemanjica',
          name: 'Pet Centar — Bulevar Nemanjića',
          category: PoiCategory.petShop,
          address: 'Bulevar Nemanjića 11B, Niš',
          latitude: 43.32462,
          longitude: 21.908284,
        ),
        _candidate(
          id: 'nis-shop-pet-centar-medijana',
          name: 'Pet Centar — Bulevar Medijana',
          category: PoiCategory.petShop,
          address: 'Bulevar Medijana 36, Niš',
          latitude: 43.313617,
          longitude: 21.935206,
          description: 'Zasebna lokacija (OSM ima „Pet centar“ na ovoj '
              'adresi).',
        ),
        _candidate(
          id: 'nis-shop-fido',
          name: 'Pet shop Fido',
          category: PoiCategory.petShop,
          address: 'Cara Dušana 35B, Niš',
          latitude: 43.317436,
          longitude: 21.89762,
        ),
        _candidate(
          id: 'nis-shop-gallus',
          name: 'Pet Shop Gallus',
          category: PoiCategory.petShop,
          address: 'Cara Dušana 81, Niš',
          latitude: 43.31824,
          longitude: 21.903636,
        ),
        _candidate(
          id: 'nis-shop-muppet',
          name: 'Muppet Shop',
          category: PoiCategory.petShop,
          address: 'Obilićev venac 74, Niš',
          latitude: 43.316059,
          longitude: 21.887664,
        ),
        _candidate(
          id: 'nis-shop-premium-pet',
          name: 'Premium Pet',
          category: PoiCategory.petShop,
          address: 'Obrenovićeva 42, Niš',
          latitude: 43.318782,
          longitude: 21.89486,
        ),
        _candidate(
          id: 'nis-shop-aki-i-drugari',
          name: 'Pet shop Aki i drugari',
          category: PoiCategory.petShop,
          address: 'Vojvode Mišića 48B, Niš',
          latitude: 43.320874,
          longitude: 21.907638,
        ),
        _candidate(
          id: 'nis-shop-cici',
          name: 'Pet Shop Cici',
          category: PoiCategory.petShop,
          address: 'Pariske komune 1A, Niš',
          latitude: 43.321051,
          longitude: 21.916915,
        ),
      ];

  static List<PoiModel> get vets => [
        _candidate(
          id: 'nis-vet-nova',
          name: 'Veterinarska ambulanta Nova',
          category: PoiCategory.vet,
          address: 'Pantelejska 56A, Niš',
          latitude: 43.328493,
          longitude: 21.908929,
        ),
        _candidate(
          id: 'nis-vet-impuls',
          name: 'Vet Impuls',
          category: PoiCategory.vet,
          address: 'Josifa Pančića 4, Niš',
          latitude: 43.317378,
          longitude: 21.900444,
        ),
        _candidate(
          id: 'nis-vet-drpetgood',
          name: 'DrPetGood',
          category: PoiCategory.vet,
          address: 'Vizantijski bulevar 84, Niš',
          latitude: 43.322857,
          longitude: 21.931734,
        ),
        _candidate(
          id: 'nis-vet-specijalisticki-institut',
          name: 'Veterinarski specijalistički institut Niš',
          category: PoiCategory.vet,
          address: 'Dimitrija Tucovića 175, Niš',
          latitude: 43.316319,
          longitude: 21.84651,
          description: 'Državna veterinarska ustanova (dijagnostika). '
              'Proverite da li prima kućne ljubimce na pregled.',
        ),
      ];

  static List<PoiModel> get grooming => [
        _candidate(
          id: 'nis-groom-nis-grooming',
          name: 'Salon za pse Niš Grooming',
          category: PoiCategory.groomer,
          address: 'Stanka Vlasotinčanina 8A, Niš',
          latitude: 43.313225,
          longitude: 21.894895,
        ),
        _candidate(
          id: 'nis-groom-mimi',
          name: 'Salon za šišanje pasa Mimi',
          category: PoiCategory.groomer,
          address: 'Bulevar Nemanjića 25, Niš',
          latitude: 43.321699,
          longitude: 21.914925,
        ),
        _candidate(
          id: 'nis-groom-groom-room-018',
          name: 'Groom Room 018',
          category: PoiCategory.groomer,
          address: 'Vojvode Vuka 2, Niš',
          latitude: 43.317918,
          longitude: 21.901217,
          description: 'Salon i škola za šišanje pasa.',
        ),
        _candidate(
          id: 'nis-groom-pinky-paw',
          name: 'Pinky Paw',
          category: PoiCategory.groomer,
          address: 'Bulevar Nemanjića 38, Niš',
          latitude: 43.321202,
          longitude: 21.914203,
        ),
        _candidate(
          id: 'nis-groom-moni',
          name: 'Salon za pse Moni',
          category: PoiCategory.groomer,
          address: 'Branka Krsmanovića 3, Niš',
          latitude: 43.32456,
          longitude: 21.915649,
          description: 'Trenutna adresa nije potvrđena.',
        ),
        _candidate(
          id: 'nis-groom-baniland',
          name: 'BaniLand Dog Grooming',
          category: PoiCategory.groomer,
          address: 'Drugog srpskog ustanka 23, Niš',
          latitude: 43.313443,
          longitude: 21.928198,
          description: 'Trenutna adresa nije potvrđena.',
        ),
      ];

  static List<PoiModel> get cafes => [
        _poi(
          id: 'nis-cafe-off',
          name: 'OFF Cafe',
          category: PoiCategory.cafe,
          address: 'Todora Milovanovića 13, Niš',
          latitude: 43.321396,
          longitude: 21.904137,
          phone: '066 641 1319',
          website: 'https://www.offcafenis.com/',
          openingHours: 'Pon–Čet 08–00, Pet–Sub 08–01, Ned zatvoreno',
          description: 'Lokal navodi da su ljubimci dobrodošli, posebno u '
              'bašti.',
          source: officialSource,
          sourceUrl: 'https://www.offcafenis.com/',
          dogFriendlyOutdoor: true,
        ),
        _poi(
          id: 'nis-restaurant-la-vie',
          name: 'La Vie Caffe & Restaurant',
          category: PoiCategory.restaurant,
          address: '7. juli 5, Niš',
          latitude: 43.3227007,
          longitude: 21.8989006,
          phone: '063 549 929',
          website: 'https://www.laviecafferestaurant.com/',
          openingHours: 'Pon–Čet 08–00, Pet–Sub 08–01, Ned 09–00',
          description: 'Lokal se predstavlja kao pet friendly restoran i '
              'obezbeđuje vodu za ljubimce.',
          source: officialSource,
          sourceUrl: 'https://www.laviecafferestaurant.com/o-nama/',
          waterAvailable: true,
        ),
        _poi(
          id: 'nis-cafe-retro-bar',
          name: 'Retro Bar u Parkiću',
          category: PoiCategory.cafe,
          address: 'Trg Svetog Save 15A, Niš',
          latitude: 43.3181124,
          longitude: 21.9029381,
          website: 'https://retrobar.rs/',
          description: 'Sajt navodi „pet friendly for mini dogs“ — samo mali '
              'psi. Pin je OSM tačka lokala „Retro“.',
          source: officialSource,
          sourceUrl: 'https://retrobar.rs/',
        ),
        _candidate(
          id: 'nis-cafe-hush-hush',
          name: 'Hush Hush Cafe & Bar',
          category: PoiCategory.cafe,
          address: 'Generala Tranijea, Niš',
          latitude: 43.3184605,
          longitude: 21.8982879,
          description: _policyUnknown,
          sourceUrl: 'https://www.openstreetmap.org/node/2700340635',
          petFriendly: false,
        ),
        _candidate(
          id: 'nis-cafe-tramvaj',
          name: 'Tramvaj Caffe',
          category: PoiCategory.cafe,
          address: 'Obrenovićeva 20, Niš',
          latitude: 43.3199929,
          longitude: 21.8951404,
          description: _policyUnknown,
          sourceUrl: 'https://www.openstreetmap.org/node/2700311779',
          petFriendly: false,
        ),
      ];

  static List<PoiModel> get services => [
        _poi(
          id: 'nis-training-dog-guard-team',
          name: 'Dog Guard Team — dresura pasa',
          category: PoiCategory.training,
          address: 'Obrenovićeva 59, Niš',
          latitude: 43.315539,
          longitude: 21.89482,
          phone: '060 540 6754',
          website: 'https://www.dresurapasa.net/',
          description: 'Adresa je sedište firme; mesto obuke dogovorite '
              'telefonom.',
          source: officialSource,
          sourceUrl: 'https://www.dresurapasa.net/kontakt/',
        ),
        _poi(
          id: 'nis-training-baci-pet',
          name: 'Dresura pasa Baci Pet',
          category: PoiCategory.training,
          address: 'Đorđa Stamenkovića 11, Čalije, Niš',
          latitude: 43.33093,
          longitude: 21.941079,
          phone: '060 081 7380',
          website: 'https://obukapasa-bacipet.com/',
          source: officialSource,
          sourceUrl: 'https://obukapasa-bacipet.com/',
        ),
        _candidate(
          id: 'nis-hotel-animal-house',
          name: 'Pansion za pse Animal House',
          category: PoiCategory.dogHotel,
          address: 'Mariborska 7, Niš',
          latitude: 43.34776,
          longitude: 21.885895,
          sourceUrl: 'https://www.planplus.rs/pansion-za-pse-animal-house-nis/156021',
        ),
        _candidate(
          id: 'nis-hotel-oni',
          name: 'Hotel za pse Oni',
          category: PoiCategory.dogHotel,
          address: 'Vinsenta Van Goga 10, Niš',
          latitude: 43.320217,
          longitude: 21.821423,
        ),
      ];

  static const _policyUnknown =
      'Pravilo za pse nije potvrđeno — nije označeno kao pet friendly.';

  static PoiModel _candidate({
    required String id,
    required String name,
    required PoiCategory category,
    required String address,
    required double latitude,
    required double longitude,
    String description = '',
    String sourceUrl = '',
    bool petFriendly = true,
  }) {
    return _poi(
      id: id,
      name: name,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      description: description,
      source: candidateSource,
      sourceUrl: sourceUrl,
      status: PoiVerificationStatus.unknown,
      petFriendly: petFriendly,
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
    String description = '',
    String sourceUrl = '',
    bool petFriendly = true,
    bool? dogFriendlyOutdoor,
    bool? waterAvailable,
    bool? isDogPark,
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
      description: description,
      sourceUrl: sourceUrl,
      petFriendly: petFriendly,
      dogFriendlyOutdoor: dogFriendlyOutdoor,
      waterAvailable: waterAvailable,
      isDogPark: isDogPark,
      city: MapCity.nis,
      cityId: cityId,
      verificationStatus: status,
      lastVerified: lastVerified,
      source: source,
    );
  }
}
