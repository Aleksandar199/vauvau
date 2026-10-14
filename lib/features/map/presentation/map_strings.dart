import '../../../core/l10n/l10n.dart';
import '../domain/map_place_type.dart';

enum MapLayerFilter {
  all,
  nearby,
  parks,
  petShops,
  groomers,
  vets,
  emergency,
  cafes,
  restaurants,
  lodging,
  training,
  hotels,
  selfWash,
  dogTreats,
  shelter,
  water,
  sitters,
  walkers,
}

enum HotelAmenityFilter { overnight, dayCare, yard, allDay }

extension MapLayerFilterX on MapLayerFilter {
  String get label => switch (this) {
        MapLayerFilter.all => MapStrings.filterAll,
        MapLayerFilter.nearby => MapStrings.filterNearby,
        MapLayerFilter.parks => MapStrings.filterParks,
        MapLayerFilter.petShops => MapStrings.filterPetShops,
        MapLayerFilter.groomers => MapStrings.filterGroomers,
        MapLayerFilter.vets => MapStrings.filterVets,
        MapLayerFilter.emergency => MapStrings.filterEmergency,
        MapLayerFilter.cafes => MapStrings.filterCafes,
        MapLayerFilter.restaurants => MapStrings.filterRestaurants,
        MapLayerFilter.lodging => MapStrings.filterLodging,
        MapLayerFilter.training => MapStrings.filterTraining,
        MapLayerFilter.hotels => MapStrings.filterHotels,
        MapLayerFilter.selfWash => MapStrings.filterSelfWash,
        MapLayerFilter.dogTreats => MapStrings.filterDogTreats,
        MapLayerFilter.shelter => MapStrings.filterShelter,
        MapLayerFilter.water => MapStrings.filterWater,
        MapLayerFilter.sitters => MapStrings.filterSitters,
        MapLayerFilter.walkers => MapStrings.filterWalkers,
      };

  MapPlaceType? get placeType => switch (this) {
        MapLayerFilter.parks => MapPlaceType.park,
        MapLayerFilter.cafes => MapPlaceType.cafe,
        MapLayerFilter.restaurants => MapPlaceType.restaurant,
        MapLayerFilter.petShops => MapPlaceType.petShop,
        MapLayerFilter.groomers => MapPlaceType.groomer,
        MapLayerFilter.vets => MapPlaceType.vet,
        MapLayerFilter.lodging => MapPlaceType.lodging,
        MapLayerFilter.training => MapPlaceType.training,
        MapLayerFilter.hotels => MapPlaceType.dogHotel,
        MapLayerFilter.selfWash => MapPlaceType.selfWash,
        MapLayerFilter.dogTreats => MapPlaceType.dogTreats,
        MapLayerFilter.shelter => MapPlaceType.shelter,
        MapLayerFilter.water => MapPlaceType.water,
        MapLayerFilter.sitters => MapPlaceType.petSitter,
        _ => null,
      };

  bool get showsPlaces => this != MapLayerFilter.walkers;

  bool get showsWalkers =>
      this == MapLayerFilter.all || this == MapLayerFilter.walkers;

  bool get isExtraPlaceFilter =>
      this == MapLayerFilter.nearby ||
      this == MapLayerFilter.petShops ||
      this == MapLayerFilter.groomers ||
      this == MapLayerFilter.vets ||
      this == MapLayerFilter.emergency ||
      this == MapLayerFilter.restaurants ||
      this == MapLayerFilter.lodging ||
      this == MapLayerFilter.training ||
      this == MapLayerFilter.hotels ||
      this == MapLayerFilter.selfWash ||
      this == MapLayerFilter.dogTreats ||
      this == MapLayerFilter.shelter ||
      this == MapLayerFilter.water ||
      this == MapLayerFilter.sitters;

  /// Compact chips on the map header.
  static const primary = [
    MapLayerFilter.all,
    MapLayerFilter.cafes,
    MapLayerFilter.parks,
    MapLayerFilter.walkers,
  ];

  /// Everything else lives under "Više filtera".
  static const extra = [
    MapLayerFilter.nearby,
    MapLayerFilter.petShops,
    MapLayerFilter.groomers,
    MapLayerFilter.vets,
    MapLayerFilter.emergency,
    MapLayerFilter.restaurants,
    MapLayerFilter.lodging,
    MapLayerFilter.training,
    MapLayerFilter.hotels,
    MapLayerFilter.selfWash,
    MapLayerFilter.dogTreats,
    MapLayerFilter.shelter,
    MapLayerFilter.water,
    MapLayerFilter.sitters,
  ];
}

extension HotelAmenityFilterX on HotelAmenityFilter {
  String get label => switch (this) {
        HotelAmenityFilter.overnight => MapStrings.amenityOvernight,
        HotelAmenityFilter.dayCare => MapStrings.amenityDayCare,
        HotelAmenityFilter.yard => MapStrings.amenityYard,
        HotelAmenityFilter.allDay => MapStrings.amenity24h,
      };
}

abstract final class MapStrings {
  static String get tabLabel => L10n.tr('Mapa', 'Map');
  static String get title => L10n.tr('Mapa', 'Map');
  static String get startWalk => L10n.tr('🟢 Započni šetnju', '🟢 Start walk');
  static String get readyToWalk =>
      L10n.tr('Spreman za šetnju po gradu?', 'Ready for a walk around town?');
  static String get endWalk => L10n.tr('Završi šetnju', 'End walk');
  static String get pauseWalk => L10n.tr('Pauza', 'Pause');
  static String get resumeWalk => L10n.tr('Nastavi', 'Resume');
  static String get endWalkTitle => L10n.tr('Završiti šetnju?', 'End walk?');
  static String get endWalkBody => L10n.tr(
        'Da li ste sigurni da želite da završite šetnju?',
        'Are you sure you want to end the walk?',
      );
  static String get walkTime => L10n.tr('Vreme', 'Time');
  static String get walkDistance => L10n.tr('Km', 'Km');
  static String get walkHistory => L10n.tr('Moje šetnje', 'My walks');
  static String get walkHistoryTitle => L10n.tr('Istorija šetnji', 'Walk history');
  static String get walkHistoryEmpty => L10n.tr(
        'Još nema sačuvanih šetnji. Završi šetnju da se upiše ovde.',
        'No saved walks yet. Finish a walk to log it here.',
      );
  static String get walkHistoryLastDays => L10n.tr('Poslednjih 7 dana', 'Last 7 days');
  static String get walkHistoryTotal => L10n.tr('Ukupno', 'Total');
  static String get walkSaved => L10n.tr('Šetnja je sačuvana.', 'Walk saved.');
  static String get walkSaveFailed => L10n.tr(
        'Šetnja nije sačuvana. Pokušajte ponovo kasnije.',
        'Walk was not saved. Try again later.',
      );
  static String get gpsActiveBanner => L10n.tr(
        'GPS praćenje aktivno • Šetnja se prati dok traje (obaveštenje)',
        'GPS tracking active • Walk tracked while active (notification)',
      );
  static String get gpsPausedBanner => L10n.tr(
        'Šetnja je pauzirana • GPS praćenje na čekanju',
        'Walk paused • GPS tracking on hold',
      );
  static String get walking => L10n.tr('U šetnji', 'On a walk');
  static String get statusHint => L10n.tr(
        'Npr. U šetnji, Odmaram, Tražim društvo za igru',
        'E.g. On a walk, Resting, Looking for playmates',
      );
  static String get statusWalking => L10n.tr('U šetnji', 'On a walk');
  static String get statusResting => L10n.tr('Odmaram', 'Resting');
  static String get statusLookingForPlay =>
      L10n.tr('Tražim društvo za igru', 'Looking for playmates');
  static String get statusLabel => L10n.tr('Kratka poruka (opciono)', 'Short message (optional)');
  static String get confirm => L10n.tr('Potvrdi', 'Confirm');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get join => L10n.tr('Pridruži se', 'Join');
  static String get directions => L10n.tr('Smernice', 'Directions');
  static String get directionsSoon => L10n.tr('Smernice uskoro stižu.', 'Directions coming soon.');
  static String get openProfile => L10n.tr('Otvori profil', 'Open profile');
  static String get navigation => L10n.tr('Navigacija', 'Navigation');
  static String get callNow => L10n.tr('Pozovi odmah', 'Call now');
  static String get callFailed =>
      L10n.tr('Poziv nije moguć na ovom uređaju.', 'Calling is not available on this device.');
  static String get reportChange => L10n.tr('Prijavi promenu', 'Report a change');
  static String get reportTitle => L10n.tr('Prijavi promenu', 'Report a change');
  static String get reportBody => L10n.tr(
        'Potvrdite da je objekat tačan, ili prijavite šta treba ispraviti.',
        'Confirm the place is correct, or report what needs fixing.',
      );
  static String get reportConfirm => L10n.tr('Prijavi', 'Report');
  static String get reportThanks =>
      L10n.tr('Hvala! Vaša prijava je poslata adminu.', 'Thanks! Your report was sent to the admin.');
  static String get reportChangeTypeLabel => L10n.tr('Vrsta promene', 'Type of change');
  static String get reportChangeDescriptionLabel => L10n.tr('Opis (opciono)', 'Description (optional)');
  static String get reportChangeDescriptionHint => L10n.tr(
        'Npr. novo radno vreme, tačnija adresa...',
        'E.g. new hours, more accurate address...',
      );
  static String get reportChangeTypeRequired =>
      L10n.tr('Izaberite vrstu promene.', 'Select type of change.');
  static String get reportChangeConfirmVerified =>
      L10n.tr('Potvrđujem da je objekat proveren', 'I confirm this place was verified');
  static String get reportChangeWrongHours =>
      L10n.tr('Pogrešno radno vreme', 'Wrong opening hours');
  static String get reportChangeClosed => L10n.tr('Objekat je zatvoren', 'Place is closed');
  static String get reportChangeWrongLocation =>
      L10n.tr('Netačna lokacija', 'Wrong location');
  static String get reportChangeOther => L10n.tr('Ostalo', 'Other');
  static String get reportChangeFailed =>
      L10n.tr('Prijava nije poslata. Pokušajte ponovo.', 'Report was not sent. Try again.');
  static String get reportChangeSubmit => L10n.tr('Pošalji prijavu', 'Submit report');
  static String get reportConfirmThanks => L10n.tr(
        'Hvala! Potvrda je zabeležena i poslata adminu.',
        'Thanks! Confirmation was recorded and sent to the admin.',
      );
  static String get verifiedBadge => L10n.tr('✓ Potvrđeno', '✓ Verified');
  static String get reportedBadge => L10n.tr('Prijavljeno', 'Reported');
  static String get submittedBadge => L10n.tr('Predloženo', 'Submitted');
  static String get pendingBadge => L10n.tr('Na čekanju', 'Pending');
  static String get unknownBadge => L10n.tr('Nije provereno', 'Not verified');
  static String get cafeFriendlyBadge => L10n.tr('☕ Pet Friendly', '☕ Pet Friendly');
  static String get restaurantBadge =>
      L10n.tr('🍽️ Dog-friendly restoran', '🍽️ Dog-friendly restaurant');
  static String get dogParkBadge => L10n.tr('🐕 Park za pse', '🐕 Dog park');
  static String get publicParkBadge => L10n.tr('🌳 Park', '🌳 Park');
  static String get cafePlainBadge => L10n.tr('☕ Kafić', '☕ Cafe');
  static String get restaurantPlainBadge =>
      L10n.tr('🍽️ Restoran', '🍽️ Restaurant');
  static String get amenityIndoor =>
      L10n.tr('🏠 Psi i unutra', '🏠 Dogs inside');
  static String get emergencyBadge => L10n.tr('🚨 DEŽURNO 0-24H', '🚨 ON-CALL 24/7');
  static String get sponsoredBadge => L10n.tr('PREMIUM PARTNER', 'PREMIUM PARTNER');
  static String get amenityOvernight => L10n.tr('🌙 Prenoćište', '🌙 Overnight');
  static String get amenityDayCare => L10n.tr('☀️ Dnevni boravak', '☀️ Day care');
  static String get amenityYard => L10n.tr('🌳 Dvorište', '🌳 Yard');
  static String get amenity24h => L10n.tr('00-24h dostupnost', 'Open 24/7');
  static String get amenityDogFriendly => L10n.tr('🐶 Dog friendly', '🐶 Dog friendly');
  static String get amenityOutdoor => L10n.tr('🌳 Outdoor', '🌳 Outdoor');
  static String get amenityWater => L10n.tr('💧 Voda', '💧 Water');
  static String get hoursLabel => L10n.tr('Radno vreme', 'Opening hours');
  static String get sourceLabel => L10n.tr('Izvor', 'Source');
  static String get userSource => L10n.tr('VauVau Zajednica', 'VauVau Community');
  static String get navigationFailed =>
      L10n.tr('Navigacija nije dostupna na uređaju.', 'Navigation unavailable on this device.');
  static String get nearbyDogs => L10n.tr('Pasa u blizini', 'Dogs nearby');
  static String get openChat => L10n.tr('Poruka', 'Message');
  static String get viewCard => L10n.tr('Mini-kartica', 'Mini card');
  static String get park => L10n.tr('Park / istrčavalište', 'Park / run area');
  static String get cafe => L10n.tr('Pet-friendly kafić', 'Pet-friendly café');
  static String get restaurant => L10n.tr('Dog-friendly restoran', 'Dog-friendly restaurant');
  static String get petShop => L10n.tr('Pet shop', 'Pet shop');
  static String get groomer => L10n.tr('Grumer', 'Groomer');
  static String get vet => L10n.tr('Veterinar', 'Vet');
  static String get lodging => L10n.tr('Pet-friendly smeštaj', 'Pet-friendly lodging');
  static String get training => L10n.tr('Dresura / škola za pse', 'Training / dog school');
  static String get dogHotel => L10n.tr('Hotel za pse', 'Dog hotel');
  static String get selfWash => L10n.tr('Samouslužna perionica', 'Self-service wash');
  static String get dogTreats => L10n.tr('Hrana / poslastice za pse', 'Food / treats for dogs');
  static String get shelter => L10n.tr('Azil / udomljavanje', 'Shelter / adoption');
  static String get waterForDogs => L10n.tr('Voda za pse', 'Water for dogs');
  static String get otherPlace => L10n.tr('Dog-friendly mesto', 'Dog-friendly place');
  static String get petSitter => L10n.tr('Kućno čuvanje', 'Pet sitting');
  static String get walkingDogs => L10n.tr('Psi trenutno u šetnji', 'Dogs walking now');
  static String get joinWalkStatusPrefix => L10n.tr('Šetamo se kod', 'Walking near');
  static String get searchHint => L10n.tr('Pretraži mesta...', 'Search places...');
  static String get filterAll => L10n.tr('Sve', 'All');
  static String get filterNearby => L10n.tr('U blizini', 'Nearby');
  static String get filterParks => L10n.tr('🐕 Parkovi', '🐕 Parks');
  static String get filterCafes => L10n.tr('☕ Kafići', '☕ Cafés');
  static String get filterRestaurants => L10n.tr('🍽️ Restorani', '🍽️ Restaurants');
  static String get filterHotels => L10n.tr('🏠 Pansion', '🏠 Boarding');
  static String get filterLodging => L10n.tr('🏨 Smeštaj', '🏨 Lodging');
  static String get filterTraining => L10n.tr('🎓 Dresura', '🎓 Training');
  static String get filterSelfWash => L10n.tr('🛁 Perionica', '🛁 Wash');
  static String get filterDogTreats => L10n.tr('🥩 Hrana', '🥩 Food');
  static String get filterShelter => L10n.tr('🐾 Udomljavanje', '🐾 Adoption');
  static String get filterWater => L10n.tr('💧 Voda', '💧 Water');
  static String get filterSitters => L10n.tr('Dog Sitter / Čuvanje', 'Dog sitter / boarding');
  static String get filterEmergency => L10n.tr('🚨 24/7 Hitno', '🚨 24/7 Emergency');
  static String get filterPetShops => L10n.tr('🛍️ Pet Shop', '🛍️ Pet shop');
  static String get filterGroomers => L10n.tr('✂️ Grooming', '✂️ Grooming');
  static String get filterVets => L10n.tr('🏥 Veterinar', '🏥 Vet');
  static String get filterWalkers => L10n.tr('Psi u šetnji', 'Dogs on walks');
  static String get filterMore => L10n.tr('⚙️ Više filtera', '⚙️ More filters');
  static String get emptyCategoryTitle =>
      L10n.tr('Još nema lokacija u ovoj kategoriji.', 'No locations in this category yet.');
  static String get emptyCategoryBody =>
      L10n.tr('Uskoro dodajemo još mesta.', 'We\'re adding more places soon.');
  static String get placesListTitle => L10n.tr('Lista mesta', 'Places list');
  static String get showList => L10n.tr('Lista', 'List');
  static String get showMap => L10n.tr('Mapa', 'Map');
  static String get openNavigation => L10n.tr('Pokreni navigaciju', 'Start navigation');
  static String get websiteAction => L10n.tr('Sajt', 'Website');
  static String get addPlace => L10n.tr('+ Dodaj mesto / lokal', '+ Add place / venue');
  static String get addPlaceAdminTitle => L10n.tr('Dodaj mesto (Admin)', 'Add place (Admin)');
  static String get adminOnlyPlace =>
      L10n.tr('Samo admin može da dodaje mesta.', 'Only admins can add places.');
  static String get chooseCity => L10n.tr('Izaberi grad', 'Choose city');
  static String get cityNoviSad => L10n.tr('Novi Sad', 'Novi Sad');
  static String get cityBelgrade => L10n.tr('Beograd', 'Belgrade');
  static String get cityNis => L10n.tr('Niš', 'Nis');
  static String get cityKragujevac => L10n.tr('Kragujevac', 'Kragujevac');
  static String get cityMyLocation => L10n.tr('Moja lokacija 📍', 'My location 📍');
  static String get cityMyLocationSubtitle =>
      L10n.tr('Koristi GPS poziciju uređaja', 'Use device GPS location');
  static String get placeCity => L10n.tr('Grad', 'City');
  static String get placeCityRequired => L10n.tr('Izaberite grad.', 'Select a city.');
  static String get placeName => L10n.tr('Naziv objekta / mesta', 'Place / venue name');
  static String get placeNameRequired => L10n.tr('Unesite naziv mesta.', 'Enter place name.');
  static String get placeCategory => L10n.tr('Kategorija', 'Category');
  static String get placeAddress => L10n.tr('Adresa / lokacija', 'Address / location');
  static String get placeAddressSearch => L10n.tr('Adresa / pretraga ulice', 'Address / street search');
  static String get placeAddressRequired => L10n.tr('Unesite adresu.', 'Enter address.');
  static String get searchAddress => L10n.tr('Pronađi adresu', 'Find address');
  static String get addressNotFound => L10n.tr(
        'Adresa nije pronađena. Probajte drugačiji upit.',
        'Address not found. Try a different query.',
      );
  static String get addressSearchFailed => L10n.tr(
        'Pretraga adrese nije uspela. Pokušajte ponovo.',
        'Address search failed. Try again.',
      );
  static String get fineTuneLocation => L10n.tr('Podesi tačnu lokaciju', 'Fine-tune location');
  static String get fineTuneLocationHint => L10n.tr(
        'Dodirnite mapu da pomerite pin na tačno mesto.',
        'Tap the map to move the pin to the exact spot.',
      );
  static String get coordinates => L10n.tr('Koordinate', 'Coordinates');
  static String get openingHoursOptional =>
      L10n.tr('Radno vreme (opciono)', 'Opening hours (optional)');
  static String get openingHoursHint => L10n.tr('Npr. Pon–Pet 09–20', 'E.g. Mon–Fri 09–20');
  static String get placePhone => L10n.tr('Kontakt telefon', 'Contact phone');
  static String get toggle24h => L10n.tr('Radno vreme 24/7', 'Open 24/7');
  static String get toggleEmergency => L10n.tr('Hitne intervencije 0-24', 'Emergency 24/7');
  static String get toggleOvernight => L10n.tr('Prenoćište', 'Overnight stay');
  static String get toggleDayCare => L10n.tr('Dnevni boravak', 'Day care');
  static String get toggleYard => L10n.tr('Ima dvorište', 'Has yard');
  static String get pricePerNight => L10n.tr('Cena po noćenju (RSD)', 'Price per night (RSD)');
  static String get submitPlace => L10n.tr('Sačuvaj mesto', 'Save place');
  static String get placeAdded => L10n.tr('Mesto je dodato na mapu.', 'Place added to the map.');
  static String get placeAddFailed =>
      L10n.tr('Mesto nije sačuvano. Pokušajte ponovo.', 'Place was not saved. Try again.');
  static String get zoomIn => L10n.tr('Uvećaj', 'Zoom in');
  static String get zoomOut => L10n.tr('Umanji', 'Zoom out');
  static String get myLocation => L10n.tr('Moja lokacija', 'My location');
  static String get joinWalk => L10n.tr('Pridruži se u šetnji', 'Join walk');
  static String get walkRequestSent =>
      L10n.tr('Zahtev za šetnju je poslat.', 'Walk request sent.');
  static String fallbackBanner(String city) => L10n.tr(
        'Koristimo centar grada: $city. Dozvolite lokaciju za tačan prikaz u blizini.',
        'Using the center of $city. Allow location for accurate nearby view.',
      );
  static String get locationDeniedTitle =>
      L10n.tr('Lokacija nije dozvoljena', 'Location not allowed');
  static String locationDeniedBody(String city) => L10n.tr(
        'VauVau koristi vašu lokaciju da prikaže pse u blizini i status „U šetnji“. Možete nastaviti sa gradom $city kao podrazumevanom lokacijom.',
        'VauVau uses your location to show nearby dogs and “On a walk” status. You can continue with $city as the default.',
      );
  static String get locationPermanentTitle =>
      L10n.tr('Lokacija je trajno odbijena', 'Location permanently denied');
  static String get locationPermanentBody => L10n.tr(
        'Uključite lokaciju za VauVau u podešavanjima uređaja da biste videli pse oko sebe.',
        'Enable location for VauVau in device settings to see dogs around you.',
      );
  static String get locationDisabledTitle =>
      L10n.tr('Usluge lokacije su isključene', 'Location services off');
  static String locationDisabledBody(String city) => L10n.tr(
        'Uključite GPS / usluge lokacije na uređaju. Do tada koristimo centar grada: $city.',
        'Turn on GPS / location services. Until then we use the center of $city.',
      );
  static String get allowLocation => L10n.tr('Dozvoli lokaciju', 'Allow location');
  static String get openSettings => L10n.tr('Otvori podešavanja', 'Open settings');
  static String useDefaultCity(String city) =>
      L10n.tr('Koristi $city', 'Use $city');

  static String remaining(int minutes) => L10n.tr(
        'Aktivno još $minutes min',
        '$minutes min left',
      );

  static String nearbyCount(int count) => L10n.isEnglish
      ? '$count active dogs nearby'
      : '$count aktivnih pasa u blizini';

  static String lastVerifiedOn(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String addressAndDistance(String address, double km) =>
      '$address • ${km.toStringAsFixed(1)} km';

  static String ratingLabel(double rating) => rating.toStringAsFixed(1);

  static String pricePerNightLabel(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (match) => '${match[1]}.',
        );
    return L10n.tr('$formatted RSD / noć', '$formatted RSD / night');
  }
}
