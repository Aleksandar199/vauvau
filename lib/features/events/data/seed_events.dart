import 'package:latlong2/latlong.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../map/domain/map_place.dart';
import '../../map/domain/map_place_type.dart';
import '../domain/event_model.dart';

abstract final class EventVenues {
  static const String customOption = 'Ostalo / Ručni unos';

  static const List<String> names = [
    'Limanski park',
    'Kamenički park',
    'Dunavski park',
    'Petrovaradinska tvrđava',
    'Železnički park',
    'Šandora Petefija (Telep)',
    customOption,
  ];

  static const Map<String, LatLng> coordinates = {
    'Limanski park': LatLng(45.2456, 19.8472),
    'Kamenički park': LatLng(45.2168, 19.8514),
    'Dunavski park': LatLng(45.2540, 19.8517),
    'Petrovaradinska tvrđava': LatLng(45.2522, 19.8631),
    'Železnički park': LatLng(45.2548, 19.8336),
    'Šandora Petefija (Telep)': LatLng(45.2394, 19.8218),
    'Kej Žrtava Racije': LatLng(45.2555, 19.8610),
  };

  static bool isCustom(String value) => value == customOption;

  static LatLng? latLngFor(String locationName) => coordinates[locationName];

  /// Walk spots for [cityId]: parks, dog parks, promenades and squares from
  /// the map catalog (seed + Firestore), plus the classic Novi Sad venues.
  /// Always ends with [customOption].
  static List<String> forCity(String cityId, Iterable<MapPlace> places) {
    final mapCityId = cityId.replaceAll('_', '-');
    final legacy = cityId == SerbiaLocations.noviSadId
        ? [for (final name in names) if (!isCustom(name)) name]
        : const <String>[];
    final fromMap = <String>{
      for (final place in places)
        if ((place.type == MapPlaceType.park ||
                place.type == MapPlaceType.other) &&
            (place.cityId == mapCityId || place.cityId == cityId) &&
            place.name.trim().isNotEmpty)
          place.name.trim(),
    }.difference(legacy.toSet()).toList()
      ..sort();
    return [...legacy, ...fromMap, customOption];
  }

  /// City of an event; older events without `cityId` are matched by venue.
  static String? cityIdForEvent(EventModel event) {
    final explicit = event.cityId.trim();
    if (explicit.isNotEmpty) return explicit;
    if (coordinates.containsKey(event.locationName)) {
      return SerbiaLocations.noviSadId;
    }
    return SerbiaLocations.cityIdForLabel(event.locationName);
  }
}

abstract final class SeedEvents {
  static const _dummies = [
    'seed-1',
    'seed-2',
    'seed-3',
    'seed-4',
    'seed-5',
    'seed-6',
    'seed-7',
    'seed-8',
    'seed-9',
    'seed-10',
    'seed-11',
  ];

  static DateTime get _now => DateTime.now();

  static final List<EventModel> all = [
    EventModel(
      id: 'event-liman',
      title: 'Grupna šetnja Liman',
      locationName: 'Limanski park',
      dateTime: _now.add(const Duration(days: 1, hours: 5)),
      description: 'Opustena vecernja šetnja uz Dunav. Ponesite vodu i kesice.',
      imageUrl: '',
      organizerUserId: 'vauvau',
      organizerName: 'VauVau',
      participantUserIds: _dummies,
      createdAt: _now.subtract(const Duration(days: 2)),
      cityId: SerbiaLocations.noviSadId,
    ),
    EventModel(
      id: 'event-malenici',
      title: 'Playdate za male pse',
      locationName: 'Kamenički park',
      dateTime: _now.add(const Duration(days: 3, hours: 2)),
      description: 'Igra i druženje za male i srednje pse. Držimo se staze.',
      imageUrl: '',
      organizerUserId: 'vauvau',
      organizerName: 'VauVau',
      participantUserIds: _dummies.take(8).toList(),
      createdAt: _now.subtract(const Duration(days: 1)),
      cityId: SerbiaLocations.noviSadId,
    ),
    EventModel(
      id: 'event-tvrdjava',
      title: 'Vikend šetnja na Tvrđavi',
      locationName: 'Petrovaradinska tvrđava',
      dateTime: _now.add(const Duration(days: 7, hours: 3)),
      description: 'Jutarnja šetnja bedemima. Pogled i kafa posle.',
      imageUrl: '',
      organizerUserId: 'vauvau',
      organizerName: 'VauVau',
      participantUserIds: _dummies.take(5).toList(),
      createdAt: _now.subtract(const Duration(hours: 12)),
      cityId: SerbiaLocations.noviSadId,
    ),
  ];

  static Map<String, dynamic> firestoreData(EventModel event) {
    return {
      'title': event.title,
      'locationName': event.locationName,
      'dateTime': event.dateTime.toIso8601String(),
      'description': event.description,
      'imageUrl': event.imageUrl,
      'organizerUserId': event.organizerUserId,
      'organizerName': event.organizerName,
      'participantUserIds': event.participantUserIds,
      'createdAt': event.createdAt.toIso8601String(),
      'lastMessage': event.lastMessage,
      'cityId': event.cityId,
    };
  }
}
