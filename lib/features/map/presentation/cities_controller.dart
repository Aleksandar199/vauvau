import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/geo/geo.dart';
import '../../location/presentation/home_city_provider.dart';
import '../data/cities_repository.dart';
import '../data/places_repository.dart';
import '../domain/city_model.dart';
import '../domain/map_place.dart';

/// Selected map region: either GPS ("Moja lokacija") or a Firestore city.
class MapRegionSelection {
  const MapRegionSelection.myLocation()
      : city = null,
        isMyLocation = true;

  const MapRegionSelection.city(CityModel this.city)
      : isMyLocation = false;

  final CityModel? city;
  final bool isMyLocation;

  String get label =>
      isMyLocation ? 'Moja lokacija' : (city?.name ?? 'Grad');

  String? get cityId => city?.id;

  double get radiusKm => isMyLocation ? 25 : (city?.radiusKm ?? 15);

  double get zoom => isMyLocation ? 14.5 : 13.0;
}

class MapRegionController extends Notifier<MapRegionSelection> {
  @override
  MapRegionSelection build() {
    final home = ref.watch(homeCityProvider);
    if (home == null) {
      return const MapRegionSelection.myLocation();
    }
    final available = ref.read(citiesProvider).asData?.value ?? SeedCities.all;
    final city = SeedCities.byId(home.mapCityId, available);
    return city == null
        ? const MapRegionSelection.myLocation()
        : MapRegionSelection.city(city);
  }

  void selectMyLocation() {
    state = const MapRegionSelection.myLocation();
  }

  void selectCity(CityModel city) {
    state = MapRegionSelection.city(city);
  }
}

final mapRegionProvider =
    NotifierProvider<MapRegionController, MapRegionSelection>(
  MapRegionController.new,
);

final citiesRepositoryProvider = Provider<CitiesRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreCitiesRepository(FirebaseFirestore.instance);
  }
  return LocalCitiesRepository();
});

final citiesProvider = StreamProvider<List<CityModel>>((ref) {
  return ref.watch(citiesRepositoryProvider).watchActive();
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  if (isFirebaseReady) {
    return FirestorePlacesRepository(FirebaseFirestore.instance);
  }
  return LocalPlacesRepository();
});

final livePlacesProvider = StreamProvider<List<MapPlace>>((ref) {
  return ref.watch(placesRepositoryProvider).watchPlaces();
});

/// Focus center for camera / distance filtering.
GeoCoord mapRegionCenter(MapRegionSelection selection, GeoCoord userCoord) {
  if (selection.isMyLocation || selection.city == null) {
    return userCoord;
  }
  return GeoCoord(selection.city!.latitude, selection.city!.longitude);
}
