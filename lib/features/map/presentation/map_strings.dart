enum MapLayerFilter { all, parks, cafes, walkers }

abstract final class MapStrings {
  static const String tabLabel = 'Mapa';
  static const String title = 'Mapa';
  static const String startWalk = 'Započni šetnju';
  static const String readyToWalk = 'Spreman za šetnju po gradu?';
  static const String endWalk = 'Završi šetnju';
  static const String walking = 'U šetnji';
  static const String statusHint =
      'Npr. Šetamo se kod spomenika u Limanskom parku sledećih 30 min';
  static const String statusLabel = 'Kratka poruka (opciono)';
  static const String confirm = 'Potvrdi';
  static const String cancel = 'Otkaži';
  static const String join = 'Pridruži se';
  static const String directions = 'Smernice';
  static const String directionsSoon = 'Smernice uskoro stižu.';
  static const String nearbyDogs = 'Pasa u blizini';
  static const String openChat = 'Poruka';
  static const String viewCard = 'Mini-kartica';
  static const String park = 'Park / istrčavalište';
  static const String cafe = 'Pet-friendly kafić';
  static const String walkingDogs = 'Psi trenutno u šetnji';
  static const String joinWalkStatusPrefix = 'Šetamo se kod';
  static const String searchHint = 'Pretraži parkove i pet-friendly kafiće...';
  static const String filterAll = 'Sve';
  static const String filterParks = 'Parkovi 🌳';
  static const String filterCafes = 'Kafići ☕';
  static const String filterWalkers = 'Psi u šetnji 🐕';
  static const String zoomIn = 'Uvećaj';
  static const String zoomOut = 'Umanji';
  static const String myLocation = 'Moja lokacija';

  static String remaining(int minutes) => 'Aktivno još $minutes min';

  static String nearbyCount(int count) => '$count aktivnih pasa u blizini';
}
