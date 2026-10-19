import 'package:latlong2/latlong.dart';

/// City document from Firestore `cities` (or local seed fallback).
class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 15,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final int sortOrder;
  final bool isActive;

  LatLng get center => LatLng(latitude, longitude);

  CityModel copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? sortOrder,
    bool? isActive,
  }) {
    return CityModel(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Built-in cities used when Firestore `cities` is empty / unreachable.
abstract final class SeedCities {
  static const noviSad = CityModel(
    id: 'novi-sad',
    name: 'Novi Sad',
    latitude: 45.2671,
    longitude: 19.8335,
    radiusKm: 15,
    sortOrder: 1,
  );

  static const belgrade = CityModel(
    id: 'beograd',
    name: 'Beograd',
    latitude: 44.8125,
    longitude: 20.4612,
    // Wider radius covers Beograd + neposredna okolina (Surčin, Borča…).
    radiusKm: 35,
    sortOrder: 2,
  );

  static const nis = CityModel(
    id: 'nis',
    name: 'Niš',
    latitude: 43.3209,
    longitude: 21.8958,
    radiusKm: 15,
    sortOrder: 3,
  );

  static const kragujevac = CityModel(
    id: 'kragujevac',
    name: 'Kragujevac',
    latitude: 44.0128,
    longitude: 20.9114,
    radiusKm: 15,
    sortOrder: 4,
  );

  // Centers: OpenStreetMap / Nominatim place of the city
  // (Zrenjanin relation 9853233, Subotica node 1547830258).
  static const zrenjanin = CityModel(
    id: 'zrenjanin',
    name: 'Zrenjanin',
    latitude: 45.3803,
    longitude: 20.3908,
    radiusKm: 15,
    sortOrder: 5,
  );

  static const subotica = CityModel(
    id: 'subotica',
    name: 'Subotica',
    latitude: 46.1002,
    longitude: 19.6653,
    radiusKm: 15,
    sortOrder: 6,
  );

  static const List<CityModel> all = [
    noviSad,
    belgrade,
    nis,
    kragujevac,
    zrenjanin,
    subotica,
  ];

  /// City with [id] from [available] (Firestore), else the built-in one.
  static CityModel? byId(String id, [List<CityModel> available = const []]) {
    for (final city in [...available, ...all]) {
      if (city.id == id) {
        return city;
      }
    }
    return null;
  }

  /// Firestore list plus any built-in city it does not define yet.
  static List<CityModel> mergeWith(List<CityModel> remote) {
    if (remote.isEmpty) {
      return all;
    }
    final ids = {for (final city in remote) city.id};
    return [
      ...remote,
      for (final seed in all)
        if (!ids.contains(seed.id)) seed,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
