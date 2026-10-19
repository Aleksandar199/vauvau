import 'package:latlong2/latlong.dart';

enum MapCity { noviSad, belgrade, nis, kragujevac, zrenjanin, subotica, other }

enum MapCityFocus {
  noviSad,
  belgrade,
  nis,
  kragujevac,
  zrenjanin,
  subotica,
  myLocation,
}

extension MapCityX on MapCity {
  String get label => switch (this) {
        MapCity.noviSad => 'Novi Sad',
        MapCity.belgrade => 'Beograd',
        MapCity.nis => 'Niš',
        MapCity.kragujevac => 'Kragujevac',
        MapCity.zrenjanin => 'Zrenjanin',
        MapCity.subotica => 'Subotica',
        MapCity.other => 'Drugo',
      };

  /// Id used by `cities`, `places` and `pois` documents (see [SeedCities]).
  String get cityId => switch (this) {
        MapCity.noviSad => 'novi-sad',
        MapCity.belgrade => 'beograd',
        MapCity.nis => 'nis',
        MapCity.kragujevac => 'kragujevac',
        MapCity.zrenjanin => 'zrenjanin',
        MapCity.subotica => 'subotica',
        MapCity.other => '',
      };

  LatLng? get camera => switch (this) {
        MapCity.noviSad => MapCityCameras.noviSad,
        MapCity.belgrade => MapCityCameras.belgrade,
        MapCity.nis => MapCityCameras.nis,
        MapCity.kragujevac => MapCityCameras.kragujevac,
        MapCity.zrenjanin => MapCityCameras.zrenjanin,
        MapCity.subotica => MapCityCameras.subotica,
        MapCity.other => null,
      };

  static MapCity fromCityId(String cityId) {
    return switch (cityId.trim().toLowerCase()) {
      'beograd' || 'belgrade' => MapCity.belgrade,
      'novi-sad' || 'novi_sad' || 'novisad' => MapCity.noviSad,
      'nis' || 'niš' => MapCity.nis,
      'kragujevac' => MapCity.kragujevac,
      'zrenjanin' => MapCity.zrenjanin,
      'subotica' => MapCity.subotica,
      _ => MapCity.other,
    };
  }
}

abstract final class MapCityCameras {
  static const noviSad = LatLng(45.2671, 19.8335);
  static const belgrade = LatLng(44.8125, 20.4612);
  static const nis = LatLng(43.3209, 21.8958);
  static const kragujevac = LatLng(44.0128, 20.9114);
  static const zrenjanin = LatLng(45.3803, 20.3908);
  static const subotica = LatLng(46.1002, 19.6653);
  static const cityZoom = 13.0;
}
