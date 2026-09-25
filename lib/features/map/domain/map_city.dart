import 'package:latlong2/latlong.dart';

enum MapCity { noviSad, belgrade, other }

enum MapCityFocus { noviSad, belgrade, myLocation }

extension MapCityX on MapCity {
  String get label => switch (this) {
        MapCity.noviSad => 'Novi Sad',
        MapCity.belgrade => 'Beograd',
        MapCity.other => 'Drugo',
      };
}

abstract final class MapCityCameras {
  static const noviSad = LatLng(45.2671, 19.8335);
  static const belgrade = LatLng(44.8125, 20.4612);
  static const cityZoom = 13.0;
}
