import '../../discover/data/mock_discover_profiles.dart';
import '../domain/map_place.dart';
import '../domain/map_place_type.dart';
import '../domain/walking_dog_pin.dart';

const double noviSadLat = 45.2551;
const double noviSadLng = 19.8451;
const double mapCenterLat = 45.2471;
const double mapCenterLng = 19.8423;
const double limanLat = 45.2392;
const double limanLng = 19.8395;
const double defaultMapZoom = 14.5;
const double limanZoom = 15.6;

const List<MapPlace> mockMapPlaces = [
  MapPlace(
    id: 'liman-park',
    name: 'Limanski park istrčavalište',
    type: MapPlaceType.park,
    neighborhood: 'Liman 3, Novi Sad',
    latitude: 45.2392,
    longitude: 19.8395,
    nearbyDogs: 4,
  ),
  MapPlace(
    id: 'dunavski-park',
    name: 'Dunavski park',
    type: MapPlaceType.park,
    neighborhood: 'Centar, Novi Sad',
    latitude: 45.2558,
    longitude: 19.8504,
    nearbyDogs: 3,
  ),
  MapPlace(
    id: 'veselina-maslese',
    name: 'Igralište za pse Veselina Masleše',
    type: MapPlaceType.park,
    neighborhood: 'Detelinara, Novi Sad',
    latitude: 45.2598,
    longitude: 19.8130,
    nearbyDogs: 2,
  ),
  MapPlace(
    id: 'strand',
    name: 'Štrand Beach - Pet Friendly Zona',
    type: MapPlaceType.park,
    neighborhood: 'Liman, Novi Sad',
    latitude: 45.2335,
    longitude: 19.8465,
    nearbyDogs: 5,
  ),
  MapPlace(
    id: 'za-moju-dusu',
    name: 'Restoran Za moju dušu',
    type: MapPlaceType.cafe,
    neighborhood: 'Trg Carice Milice 2, Novi Sad',
    latitude: 45.2512,
    longitude: 19.8478,
    nearbyDogs: 2,
  ),
  MapPlace(
    id: 'kamenicki',
    name: 'Kamenički park',
    type: MapPlaceType.park,
    neighborhood: 'Sremska Kamenica, Novi Sad',
    latitude: 45.2285,
    longitude: 19.8492,
    nearbyDogs: 1,
  ),
  MapPlace(
    id: 'dvoriste',
    name: 'Kafić Dvorište',
    type: MapPlaceType.cafe,
    neighborhood: 'Liman 1, Novi Sad',
    latitude: 45.2416,
    longitude: 19.8368,
    nearbyDogs: 2,
  ),
];

final List<WalkingDogPin> mockWalkingDogs = [
  WalkingDogPin(
    profile: mockDiscoverProfiles[0],
    latitude: 45.2408,
    longitude: 19.8418,
    status: 'Bobi trči u Limanskom parku.',
  ),
  WalkingDogPin(
    profile: mockDiscoverProfiles[3],
    latitude: 45.2387,
    longitude: 19.8384,
    status: 'Maza šeta stazom uz istrčavalište.',
  ),
  WalkingDogPin(
    profile: mockDiscoverProfiles[1],
    latitude: 45.2562,
    longitude: 19.8498,
    status: 'Lola šeta kroz Dunavski park.',
  ),
  WalkingDogPin(
    profile: mockDiscoverProfiles[5],
    latitude: 45.2551,
    longitude: 19.8511,
    status: 'Kiki je kod Dunavskog parka još 15 min.',
  ),
];
