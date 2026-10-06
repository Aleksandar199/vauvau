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
  static const String tabLabel = 'Mapa';
  static const String title = 'Mapa';
  static const String startWalk = '🟢 Započni šetnju';
  static const String readyToWalk = 'Spreman za šetnju po gradu?';
  static const String endWalk = 'Završi šetnju';
  static const String pauseWalk = 'Pauza';
  static const String resumeWalk = 'Nastavi';
  static const String endWalkTitle = 'Završiti šetnju?';
  static const String endWalkBody =
      'Da li ste sigurni da želite da završite šetnju?';
  static const String walkTime = 'Vreme';
  static const String walkDistance = 'Km';
  static const String walkHistory = 'Moje šetnje';
  static const String walkHistoryTitle = 'Istorija šetnji';
  static const String walkHistoryEmpty =
      'Još nema sačuvanih šetnji. Završi šetnju da se upiše ovde.';
  static const String walkHistoryLastDays = 'Poslednjih 7 dana';
  static const String walkHistoryTotal = 'Ukupno';
  static const String walkSaved = 'Šetnja je sačuvana.';
  static const String walkSaveFailed =
      'Šetnja nije sačuvana. Pokušajte ponovo kasnije.';
  static const String gpsActiveBanner =
      'GPS Praćenje aktivno • Aplikacija prati šetnju u pozadini';
  static const String gpsPausedBanner =
      'Šetnja je pauzirana • GPS praćenje na čekanju';
  static const String walking = 'U šetnji';
  static const String statusHint =
      'Npr. U šetnji, Odmaram, Tražim društvo za igru';
  static const String statusWalking = 'U šetnji';
  static const String statusResting = 'Odmaram';
  static const String statusLookingForPlay = 'Tražim društvo za igru';
  static const String statusLabel = 'Kratka poruka (opciono)';
  static const String confirm = 'Potvrdi';
  static const String cancel = 'Otkaži';
  static const String join = 'Pridruži se';
  static const String directions = 'Smernice';
  static const String directionsSoon = 'Smernice uskoro stižu.';
  static const String openProfile = 'Otvori profil';
  static const String navigation = 'Navigacija';
  static const String callNow = 'Pozovi odmah';
  static const String callFailed = 'Poziv nije moguć na ovom uređaju.';
  static const String reportChange = 'Prijavi promenu';
  static const String reportTitle = 'Prijavi promenu';
  static const String reportBody =
      'Potvrdite da je objekat tačan, ili prijavite šta treba ispraviti.';
  static const String reportConfirm = 'Prijavi';
  static const String reportThanks =
      'Hvala! Vaša prijava je poslata adminu.';
  static const String reportChangeTypeLabel = 'Vrsta promene';
  static const String reportChangeDescriptionLabel = 'Opis (opciono)';
  static const String reportChangeDescriptionHint =
      'Npr. novo radno vreme, tačnija adresa...';
  static const String reportChangeTypeRequired = 'Izaberite vrstu promene.';
  static const String reportChangeConfirmVerified =
      'Potvrđujem da je objekat proveren';
  static const String reportChangeWrongHours = 'Pogrešno radno vreme';
  static const String reportChangeClosed = 'Objekat je zatvoren';
  static const String reportChangeWrongLocation = 'Netačna lokacija';
  static const String reportChangeOther = 'Ostalo';
  static const String reportChangeFailed =
      'Prijava nije poslata. Pokušajte ponovo.';
  static const String reportChangeSubmit = 'Pošalji prijavu';
  static const String reportConfirmThanks =
      'Hvala! Potvrda je zabeležena i poslata adminu.';
  static const String verifiedBadge = '✓ Potvrđeno';
  static const String reportedBadge = 'Prijavljeno';
  static const String submittedBadge = 'Predloženo';
  static const String pendingBadge = 'Na čekanju';
  static const String unknownBadge = 'Nije provereno';
  static const String cafeFriendlyBadge = '☕ Pet Friendly';
  static const String restaurantBadge = '🍽️ Dog-friendly restoran';
  static const String dogParkBadge = '🐕 Park za pse';
  static const String emergencyBadge = '🚨 DEŽURNO 0-24H';
  static const String sponsoredBadge = 'PREMIUM PARTNER';
  static const String amenityOvernight = '🌙 Prenoćište';
  static const String amenityDayCare = '☀️ Dnevni boravak';
  static const String amenityYard = '🌳 Dvorište';
  static const String amenity24h = '00-24h dostupnost';
  static const String amenityDogFriendly = '🐶 Dog friendly';
  static const String amenityOutdoor = '🌳 Outdoor';
  static const String amenityWater = '💧 Voda';
  static const String hoursLabel = 'Radno vreme';
  static const String sourceLabel = 'Izvor';
  static const String userSource = 'VauVau Zajednica';
  static const String navigationFailed = 'Navigacija nije dostupna na uređaju.';
  static const String nearbyDogs = 'Pasa u blizini';
  static const String openChat = 'Poruka';
  static const String viewCard = 'Mini-kartica';
  static const String park = 'Park / istrčavalište';
  static const String cafe = 'Pet-friendly kafić';
  static const String restaurant = 'Dog-friendly restoran';
  static const String petShop = 'Pet shop';
  static const String groomer = 'Grumer';
  static const String vet = 'Veterinar';
  static const String lodging = 'Pet-friendly smeštaj';
  static const String training = 'Dresura / škola za pse';
  static const String dogHotel = 'Hotel za pse';
  static const String selfWash = 'Samouslužna perionica';
  static const String dogTreats = 'Hrana / poslastice za pse';
  static const String shelter = 'Azil / udomljavanje';
  static const String waterForDogs = 'Voda za pse';
  static const String otherPlace = 'Dog-friendly mesto';
  static const String petSitter = 'Kućno čuvanje';
  static const String walkingDogs = 'Psi trenutno u šetnji';
  static const String joinWalkStatusPrefix = 'Šetamo se kod';
  static const String searchHint = 'Pretraži mesta...';
  static const String filterAll = 'Sve';
  static const String filterNearby = 'U blizini';
  static const String filterParks = '🐕 Parkovi';
  static const String filterCafes = '☕ Kafići';
  static const String filterRestaurants = '🍽️ Restorani';
  static const String filterHotels = '🏠 Pansion';
  static const String filterLodging = '🏨 Smeštaj';
  static const String filterTraining = '🎓 Dresura';
  static const String filterSelfWash = '🛁 Perionica';
  static const String filterDogTreats = '🥩 Hrana';
  static const String filterShelter = '🐾 Udomljavanje';
  static const String filterWater = '💧 Voda';
  static const String filterSitters = 'Dog Sitter / Čuvanje';
  static const String filterEmergency = '🚨 24/7 Hitno';
  static const String filterPetShops = '🛍️ Pet Shop';
  static const String filterGroomers = '✂️ Grooming';
  static const String filterVets = '🏥 Veterinar';
  static const String filterWalkers = 'Psi u šetnji';
  static const String filterMore = '⚙️ Više filtera';
  static const String emptyCategoryTitle = 'Još nema lokacija u ovoj kategoriji.';
  static const String emptyCategoryBody = 'Uskoro dodajemo još mesta.';
  static const String placesListTitle = 'Lista mesta';
  static const String showList = 'Lista';
  static const String showMap = 'Mapa';
  static const String openNavigation = 'Pokreni navigaciju';
  static const String websiteAction = 'Sajt';
  static const String addPlace = '+ Dodaj mesto / lokal';
  static const String addPlaceAdminTitle = 'Dodaj mesto (Admin)';
  static const String adminOnlyPlace = 'Samo admin može da dodaje mesta.';
  static const String chooseCity = 'Izaberi grad';
  static const String cityNoviSad = 'Novi Sad';
  static const String cityBelgrade = 'Beograd';
  static const String cityMyLocation = 'Moja lokacija 📍';
  static const String cityMyLocationSubtitle = 'Koristi GPS poziciju uređaja';
  static const String placeCity = 'Grad';
  static const String placeCityRequired = 'Izaberite grad.';
  static const String placeName = 'Naziv objekta / mesta';
  static const String placeNameRequired = 'Unesite naziv mesta.';
  static const String placeCategory = 'Kategorija';
  static const String placeAddress = 'Adresa / lokacija';
  static const String placeAddressSearch = 'Adresa / pretraga ulice';
  static const String placeAddressRequired = 'Unesite adresu.';
  static const String searchAddress = 'Pronađi adresu';
  static const String addressNotFound = 'Adresa nije pronađena. Probajte drugačiji upit.';
  static const String addressSearchFailed =
      'Pretraga adrese nije uspela. Pokušajte ponovo.';
  static const String fineTuneLocation = 'Podesi tačnu lokaciju';
  static const String fineTuneLocationHint =
      'Dodirnite mapu da pomerite pin na tačno mesto.';
  static const String coordinates = 'Koordinate';
  static const String openingHoursOptional = 'Radno vreme (opciono)';
  static const String openingHoursHint = 'Npr. Pon–Pet 09–20';
  static const String placePhone = 'Kontakt telefon';
  static const String toggle24h = 'Radno vreme 24/7';
  static const String toggleEmergency = 'Hitne intervencije 0-24';
  static const String toggleOvernight = 'Prenoćište';
  static const String toggleDayCare = 'Dnevni boravak';
  static const String toggleYard = 'Ima dvorište';
  static const String pricePerNight = 'Cena po noćenju (RSD)';
  static const String submitPlace = 'Sačuvaj mesto';
  static const String placeAdded = 'Mesto je dodato na mapu.';
  static const String placeAddFailed = 'Mesto nije sačuvano. Pokušajte ponovo.';
  static const String zoomIn = 'Uvećaj';
  static const String zoomOut = 'Umanji';
  static const String myLocation = 'Moja lokacija';
  static const String joinWalk = 'Pridruži se u šetnji';
  static const String walkRequestSent = 'Zahtev za šetnju je poslat.';
  static const String fallbackBanner =
      'Koristimo centar Novog Sada. Dozvolite lokaciju za tačan prikaz u blizini.';
  static const String locationDeniedTitle = 'Lokacija nije dozvoljena';
  static const String locationDeniedBody =
      'VauVau koristi vašu lokaciju da prikaže pse u blizini i status „U šetnji“. Možete nastaviti sa Novim Sadom kao podrazumevanom lokacijom.';
  static const String locationPermanentTitle = 'Lokacija je trajno odbijena';
  static const String locationPermanentBody =
      'Uključite lokaciju za VauVau u podešavanjima uređaja da biste videli pse oko sebe.';
  static const String locationDisabledTitle = 'Usluge lokacije su isključene';
  static const String locationDisabledBody =
      'Uključite GPS / usluge lokacije na uređaju. Do tada koristimo centar Novog Sada.';
  static const String allowLocation = 'Dozvoli lokaciju';
  static const String openSettings = 'Otvori podešavanja';
  static const String useDefaultCity = 'Koristi Novi Sad';

  static String remaining(int minutes) => 'Aktivno još $minutes min';

  static String nearbyCount(int count) => '$count aktivnih pasa u blizini';

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
    return '$formatted RSD / noć';
  }
}
