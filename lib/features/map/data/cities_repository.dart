import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/city_model.dart';

abstract class CitiesRepository {
  Stream<List<CityModel>> watchActive();
}

class FirestoreCitiesRepository implements CitiesRepository {
  FirestoreCitiesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _cities =>
      _firestore.collection('cities');

  @override
  Stream<List<CityModel>> watchActive() async* {
    try {
      await for (final snapshot in _cities.snapshots()) {
        final cities = snapshot.docs
            .map(_fromDoc)
            .where((city) => city.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        yield cities.isEmpty ? SeedCities.all : cities;
      }
    } catch (error, stack) {
      debugPrint('cities watch failed: $error\n$stack');
      yield SeedCities.all;
    }
  }

  CityModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CityModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? doc.id,
      latitude: (data['lat'] as num?)?.toDouble() ??
          (data['latitude'] as num?)?.toDouble() ??
          0,
      longitude: (data['lng'] as num?)?.toDouble() ??
          (data['longitude'] as num?)?.toDouble() ??
          0,
      radiusKm: (data['radiusKm'] as num?)?.toDouble() ?? 15,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

class LocalCitiesRepository implements CitiesRepository {
  @override
  Stream<List<CityModel>> watchActive() async* {
    yield SeedCities.all;
  }
}
