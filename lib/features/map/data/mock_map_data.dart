import '../domain/map_place.dart';
import '../domain/map_place_type.dart';
import '../domain/models/poi_model.dart';
import '../domain/walking_dog_pin.dart';
import 'poi_seed_data.dart';

const double noviSadLat = 45.2551;
const double noviSadLng = 19.8451;
const double mapCenterLat = 45.2471;
const double mapCenterLng = 19.8423;
const double limanLat = 45.2392;
const double limanLng = 19.8395;
const double defaultMapZoom = 14.5;
const double limanZoom = 15.6;

final List<MapPlace> catalogServicePlaces = [
  MapPlace(
    id: 'pet-house',
    name: 'Pet House',
    type: MapPlaceType.petShop,
    neighborhood: 'Novosadskog sajma 48, Novi Sad',
    latitude: 45.2538,
    longitude: 19.8240,
    nearbyDogs: 1,
    is24_7: true,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'VauVau Zajednica',
  ),
  MapPlace(
    id: 'pet-centar',
    name: 'Pet Centar',
    type: MapPlaceType.petShop,
    neighborhood: 'BIG, Novi Sad',
    latitude: 45.2678,
    longitude: 19.8295,
    is24_7: true,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'Google Places',
  ),
  MapPlace(
    id: 'premium-pet',
    name: 'Premium Pet',
    type: MapPlaceType.petShop,
    neighborhood: 'Mercator Centar, Novi Sad',
    latitude: 45.2490,
    longitude: 19.8155,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'Google Places',
  ),
  MapPlace(
    id: 'grooming-katerina',
    name: 'Grooming by Katerina',
    type: MapPlaceType.groomer,
    neighborhood: 'Branimira Ćosića 23, Novi Sad',
    latitude: 45.2548,
    longitude: 19.8285,
    nearbyDogs: 1,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'VauVau Zajednica',
  ),
  MapPlace(
    id: 'vanna-grooming',
    name: 'Salon za pse Vanna Grooming',
    type: MapPlaceType.groomer,
    neighborhood: 'Trg republike 10, Novi Sad',
    latitude: 45.2551,
    longitude: 19.8451,
    nearbyDogs: 1,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'VauVau Zajednica',
  ),
  MapPlace(
    id: 'mona-style',
    name: 'Mona Style Grooming',
    type: MapPlaceType.groomer,
    neighborhood: 'Miloša Obilića 1, Novi Sad',
    latitude: 45.2565,
    longitude: 19.8380,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'Google Places',
  ),
  MapPlace(
    id: 'salon-bony',
    name: 'Salon Bony',
    type: MapPlaceType.groomer,
    neighborhood: 'Karađorđeva 24, Novi Sad',
    latitude: 45.2540,
    longitude: 19.8445,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'Google Places',
  ),
  MapPlace(
    id: 'dog-tales',
    name: 'Dog Tales',
    type: MapPlaceType.groomer,
    neighborhood: 'Radnička 31a, Novi Sad',
    latitude: 45.2505,
    longitude: 19.8370,
    nearbyDogs: 1,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'VauVau Zajednica',
  ),
  MapPlace(
    id: 'vet-liman',
    name: 'Veterinarska ambulanta Liman',
    type: MapPlaceType.vet,
    neighborhood: 'Bulevar cara Lazara 5, Novi Sad',
    latitude: 45.2418,
    longitude: 19.8432,
    nearbyDogs: 1,
    verificationStatus: PoiVerificationStatus.unknown,
    source: 'VauVau Zajednica',
  ),
];

List<MapPlace> get mockMapPlaces => [
      ...PoiSeedData.allVerified.map(MapPlace.fromPoi),
      ...catalogServicePlaces,
    ];

/// No fake walkers — map pins come only from live presence.
const List<WalkingDogPin> mockWalkingDogs = [];
