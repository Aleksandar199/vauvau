import '../domain/map_place_type.dart';

enum MapLayerFilter {
  all,
  cafes,
  parks,
  hotels,
  sitters,
  emergency,
  walkers,
  petShops,
  groomers,
  vets,
}

enum HotelAmenityFilter { overnight, dayCare, yard, allDay }

extension MapLayerFilterX on MapLayerFilter {
  String get label => switch (this) {
        MapLayerFilter.all => MapStrings.filterAll,
        MapLayerFilter.parks => MapStrings.filterParks,
        MapLayerFilter.cafes => MapStrings.filterCafes,
        MapLayerFilter.hotels => MapStrings.filterHotels,
        MapLayerFilter.sitters => MapStrings.filterSitters,
        MapLayerFilter.emergency => MapStrings.filterEmergency,
        MapLayerFilter.petShops => MapStrings.filterPetShops,
        MapLayerFilter.groomers => MapStrings.filterGroomers,
        MapLayerFilter.vets => MapStrings.filterVets,
        MapLayerFilter.walkers => MapStrings.filterWalkers,
      };

  MapPlaceType? get placeType => switch (this) {
        MapLayerFilter.parks => MapPlaceType.park,
        MapLayerFilter.cafes => MapPlaceType.cafe,
        MapLayerFilter.hotels => MapPlaceType.dogHotel,
        MapLayerFilter.sitters => MapPlaceType.petSitter,
        MapLayerFilter.petShops => MapPlaceType.petShop,
        MapLayerFilter.groomers => MapPlaceType.groomer,
        MapLayerFilter.vets => MapPlaceType.vet,
        _ => null,
      };

  bool get showsPlaces => this != MapLayerFilter.walkers;

  bool get showsWalkers =>
      this == MapLayerFilter.all || this == MapLayerFilter.walkers;

  bool get isExtraPlaceFilter =>
      this == MapLayerFilter.petShops ||
      this == MapLayerFilter.groomers ||
      this == MapLayerFilter.vets ||
      this == MapLayerFilter.hotels ||
      this == MapLayerFilter.sitters ||
      this == MapLayerFilter.emergency;

  static const primary = [
    MapLayerFilter.all,
    MapLayerFilter.cafes,
    MapLayerFilter.parks,
    MapLayerFilter.walkers,
  ];

  static const extra = [
    MapLayerFilter.vets,
    MapLayerFilter.petShops,
    MapLayerFilter.groomers,
    MapLayerFilter.hotels,
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
      'Da li ovaj kafić više nije pet-friendly ili je park zatvoren?';
  static const String reportConfirm = 'Prijavi';
  static const String reportThanks = 'Hvala, prijava je zabeležena.';
  static const String verifiedBadge = '✓ Potvrđeno';
  static const String reportedBadge = 'Prijavljeno';
  static const String submittedBadge = 'Predloženo';
  static const String pendingBadge = 'Na čekanju';
  static const String unknownBadge = 'Nije provereno';
  static const String cafeFriendlyBadge = '☕ Pet Friendly';
  static const String dogParkBadge = '🐕 Park za pse';
  static const String emergencyBadge = '🚨 DEŽURNO 0-24H';
  static const String amenityOvernight = '🌙 Prenoćište';
  static const String amenityDayCare = '☀️ Dnevni boravak';
  static const String amenityYard = '🌳 Dvorište';
  static const String amenity24h = '00-24h dostupnost';
  static const String sourceLabel = 'Izvor';
  static const String userSource = 'VauVau Zajednica';
  static const String navigationFailed = 'Navigacija nije dostupna na uređaju.';
  static const String nearbyDogs = 'Pasa u blizini';
  static const String openChat = 'Poruka';
  static const String viewCard = 'Mini-kartica';
  static const String park = 'Park / istrčavalište';
  static const String cafe = 'Pet-friendly kafić';
  static const String petShop = 'Pet shop';
  static const String groomer = 'Grumer';
  static const String vet = 'Veterinar';
  static const String dogHotel = 'Hotel za pse';
  static const String petSitter = 'Kućno čuvanje';
  static const String walkingDogs = 'Psi trenutno u šetnji';
  static const String joinWalkStatusPrefix = 'Šetamo se kod';
  static const String searchHint =
      'Pretraži parkove, kafiće, hotele i dežurne veterinarske...';
  static const String filterAll = 'Sve';
  static const String filterParks = 'Parkovi';
  static const String filterCafes = 'Kafići';
  static const String filterHotels = 'Hoteli za pse';
  static const String filterSitters = 'Dog Sitter / Čuvanje';
  static const String filterEmergency = '24/7 Hitno';
  static const String filterPetShops = 'Pet Shop';
  static const String filterGroomers = 'Grooming / Frizerski saloni';
  static const String filterVets = 'Veterinari';
  static const String filterWalkers = 'Psi u šetnji';
  static const String filterMore = '⚙️ Više filtera';
  static const String addPlace = '+ Dodaj mesto / lokal';
  static const String cityNoviSad = 'Novi Sad';
  static const String cityBelgrade = 'Beograd';
  static const String cityMyLocation = 'Moja lokacija 📍';
  static const String placeCity = 'Grad';
  static const String placeName = 'Naziv objekta / mesta';
  static const String placeNameRequired = 'Unesite naziv mesta.';
  static const String placeCategory = 'Kategorija';
  static const String placeAddress = 'Adresa / lokacija';
  static const String placeAddressRequired = 'Unesite adresu.';
  static const String placePhone = 'Kontakt telefon';
  static const String toggle24h = 'Radno vreme 24/7';
  static const String toggleEmergency = 'Hitne intervencije 0-24';
  static const String toggleOvernight = 'Prenoćište';
  static const String toggleDayCare = 'Dnevni boravak';
  static const String toggleYard = 'Ima dvorište';
  static const String pricePerNight = 'Cena po noćenju (RSD)';
  static const String submitPlace = 'Sačuvaj mesto';
  static const String placeAdded = 'Mesto je dodato na vašu mapu.';
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
