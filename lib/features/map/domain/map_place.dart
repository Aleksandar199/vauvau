import 'map_place_type.dart';

class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
    required this.nearbyDogs,
  });

  final String id;
  final String name;
  final MapPlaceType type;
  final String neighborhood;
  final double latitude;
  final double longitude;
  final int nearbyDogs;
}
