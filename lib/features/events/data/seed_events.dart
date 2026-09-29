import 'package:latlong2/latlong.dart';

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

  static final List<EventModel> all = [
    EventModel(
      id: 'event-liman',
      title: 'Grupna šetnja Liman',
      locationName: 'Limanski park',
      dateTime: DateTime(2026, 10, 3, 17),
      description: 'Opustena vecernja šetnja uz Dunav. Ponesite vodu i kesice.',
      imageUrl:
          'https://images.unsplash.com/photo-1558788353-f76d92427f16?auto=format&fit=crop&w=800&q=80',
      organizerUserId: 'vauvau',
      organizerName: 'VauVau',
      participantUserIds: _dummies,
      createdAt: DateTime(2026, 9, 20),
    ),
    EventModel(
      id: 'event-malenici',
      title: 'Playdate za male pse',
      locationName: 'Kamenički park',
      dateTime: DateTime(2026, 10, 4, 11),
      description: 'Igra i druženje za male i srednje pse. Držimo se staze.',
      imageUrl:
          'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&w=800&q=80',
      organizerUserId: 'vauvau',
      organizerName: 'VauVau',
      participantUserIds: _dummies.take(8).toList(),
      createdAt: DateTime(2026, 9, 21),
    ),
    EventModel(
      id: 'event-tvrdjava',
      title: 'Vikend šetnja na Tvrđavi',
      locationName: 'Petrovaradinska tvrđava',
      dateTime: DateTime(2026, 10, 10, 10),
      description: 'Jutarnja šetnja bedemima. Pogled i kafa posle.',
      imageUrl:
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=800&q=80',
      organizerUserId: 'vauvau',
      organizerName: 'VauVau',
      participantUserIds: _dummies.take(5).toList(),
      createdAt: DateTime(2026, 9, 22),
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
    };
  }
}
