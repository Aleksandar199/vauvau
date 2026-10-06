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

  static const List<CityModel> all = [noviSad, belgrade];
}
