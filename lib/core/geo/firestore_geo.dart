import 'package:cloud_firestore/cloud_firestore.dart';

import 'geo.dart';

Map<String, dynamic> firestoreLocationFields(
  GeoCoord location, {
  bool? isWalking,
}) {
  return {
    'isWalking': ?isWalking,
    'lastKnownLocation': GeoPoint(location.latitude, location.longitude),
    'geohash': GeoHash.encode(location.latitude, location.longitude),
    'latitude': location.latitude,
    'longitude': location.longitude,
  };
}

GeoCoord? geoCoordFromMap(Map<String, dynamic> data) {
  final point = data['lastKnownLocation'];
  if (point is GeoPoint) {
    return GeoCoord(point.latitude, point.longitude);
  }
  final latitude = data['latitude'] as num?;
  final longitude = data['longitude'] as num?;
  if (latitude != null && longitude != null) {
    return GeoCoord(latitude.toDouble(), longitude.toDouble());
  }
  return null;
}
