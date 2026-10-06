import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/map_city.dart';
import '../domain/map_place.dart';
import '../domain/map_place_type.dart';
import '../domain/models/poi_model.dart';

class PlaceDraft {
  const PlaceDraft({
    required this.name,
    required this.category,
    required this.cityId,
    required this.cityName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.openingHours = '',
    this.phone = '',
    required this.createdBy,
  });

  final String name;
  final String category;
  final String cityId;
  final String cityName;
  final String address;
  final double latitude;
  final double longitude;
  final String openingHours;
  final String phone;
  final String createdBy;
}

abstract class PlacesRepository {
  Stream<List<MapPlace>> watchPlaces();

  Future<String> createPlace(PlaceDraft draft);

  /// Atomically updates both `places/{id}` and `pois/{id}`.
  Future<void> updatePlace(PoiModel poi);

  /// Atomically deletes from both `places/{id}` and `pois/{id}`.
  Future<void> deletePlace(String placeId);
}

class FirestorePlacesRepository implements PlacesRepository {
  FirestorePlacesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _places =>
      _firestore.collection('places');

  CollectionReference<Map<String, dynamic>> get _pois =>
      _firestore.collection('pois');

  @override
  Stream<List<MapPlace>> watchPlaces() async* {
    try {
      await for (final snapshot in _places.snapshots()) {
        yield snapshot.docs.map(_fromDoc).whereType<MapPlace>().toList();
      }
    } catch (error, stack) {
      debugPrint('places watch failed: $error\n$stack');
      yield const [];
    }
  }

  @override
  Future<String> createPlace(PlaceDraft draft) async {
    final doc = _places.doc();
    final id = doc.id;
    final category = _categoryFromKey(draft.category);
    final placePayload = <String, Object?>{
      'id': id,
      'name': draft.name,
      'category': draft.category,
      'cityId': draft.cityId,
      'cityName': draft.cityName,
      'address': draft.address,
      'location': GeoPoint(draft.latitude, draft.longitude),
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'openingHours': draft.openingHours,
      'phone': draft.phone,
      'createdBy': draft.createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerified': true,
      'verificationStatus': 'verified',
    };
    final poiPayload = <String, Object?>{
      'id': id,
      'name': draft.name,
      'category': category.name,
      'address': draft.address,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'phone': draft.phone,
      'openingHours': draft.openingHours,
      'city': _mapCityFromCityId(draft.cityId).name,
      'cityId': draft.cityId,
      'petFriendly': true,
      'verificationStatus': 'verified',
      'lastVerified': FieldValue.serverTimestamp(),
      'source': 'Admin',
      'createdBy': draft.createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    batch.set(doc, placePayload);
    batch.set(_pois.doc(id), poiPayload, SetOptions(merge: true));
    await batch.commit();
    return id;
  }

  @override
  Future<void> updatePlace(PoiModel poi) async {
    final id = poi.id.trim();
    if (id.isEmpty) {
      throw ArgumentError('place id required');
    }
    final placePayload = <String, Object?>{
      'id': id,
      'name': poi.name,
      'category': _categoryKeyFromPoi(poi.category),
      'cityId': poi.resolvedCityId,
      'cityName': poi.city.name,
      'address': poi.address,
      'location': GeoPoint(poi.latitude, poi.longitude),
      'latitude': poi.latitude,
      'longitude': poi.longitude,
      'openingHours': poi.openingHours,
      'phone': poi.phone,
      'website': poi.website,
      'is24_7': poi.is24_7,
      'isEmergencyService': poi.isEmergencyService,
      'overnightStay': poi.overnightStay,
      'dayCare': poi.dayCare,
      'hasYard': poi.hasYard,
      'pricePerNight': poi.pricePerNight,
      'petFriendly': poi.petFriendly,
      'isVerified': poi.verificationStatus == PoiVerificationStatus.verified,
      'verificationStatus': poi.verificationStatus.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final poiPayload = <String, Object?>{
      'id': id,
      'name': poi.name,
      'category': poi.category.name,
      'address': poi.address,
      'latitude': poi.latitude,
      'longitude': poi.longitude,
      'phone': poi.phone,
      'website': poi.website,
      'is24_7': poi.is24_7,
      'isEmergencyService': poi.isEmergencyService,
      'overnightStay': poi.overnightStay,
      'dayCare': poi.dayCare,
      'hasYard': poi.hasYard,
      'pricePerNight': poi.pricePerNight,
      'openingHours': poi.openingHours,
      'petFriendly': poi.petFriendly,
      'dogFriendlyIndoor': poi.dogFriendlyIndoor,
      'dogFriendlyOutdoor': poi.dogFriendlyOutdoor,
      'waterAvailable': poi.waterAvailable,
      'municipality': poi.municipality,
      'description': poi.description,
      'imageUrl': poi.imageUrl,
      'sourceUrl': poi.sourceUrl,
      'city': poi.city.name,
      'cityId': poi.resolvedCityId,
      'verificationStatus': poi.verificationStatus.firestoreValue,
      'lastVerified': Timestamp.fromDate(poi.lastVerified),
      'source': poi.source,
      'rating': poi.rating,
      'isSponsored': poi.isSponsored,
      'sponsorName': poi.sponsorName,
      'sponsoredUntil': poi.sponsoredUntil == null
          ? null
          : Timestamp.fromDate(poi.sponsoredUntil!),
      'sponsorBadge': poi.sponsorBadge,
      'sponsorPriority': poi.sponsorPriority,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    batch.set(_places.doc(id), placePayload, SetOptions(merge: true));
    batch.set(_pois.doc(id), poiPayload, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<void> deletePlace(String placeId) async {
    final id = placeId.trim();
    if (id.isEmpty) {
      return;
    }
    final batch = _firestore.batch();
    batch.delete(_places.doc(id));
    batch.delete(_pois.doc(id));
    await batch.commit();
  }

  MapPlace? _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String? ?? '').trim();
    if (name.isEmpty) return null;

    double lat = (data['latitude'] as num?)?.toDouble() ?? 0;
    double lng = (data['longitude'] as num?)?.toDouble() ?? 0;
    final location = data['location'];
    if (location is GeoPoint) {
      lat = location.latitude;
      lng = location.longitude;
    }

    final categoryKey = data['category'] as String? ?? 'park';
    final type = _typeFromCategoryKey(categoryKey);
    final cityId = (data['cityId'] as String? ?? '').trim();
    final verified = data['isVerified'] as bool? ?? true;

    return MapPlace(
      id: data['id'] as String? ?? doc.id,
      name: name,
      type: type,
      neighborhood: data['address'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      phone: data['phone'] as String? ?? '',
      openingHours: data['openingHours'] as String? ?? '',
      city: _mapCityFromCityId(cityId),
      cityId: cityId,
      verificationStatus: verified
          ? PoiVerificationStatus.verified
          : PoiVerificationStatusX.fromString(
              data['verificationStatus'] as String?,
            ),
      lastVerified: DateTime.now(),
      source: 'Admin',
    );
  }

  static String _categoryKeyFromPoi(PoiCategory category) {
    return switch (category) {
      PoiCategory.petShop => 'pet_shop',
      PoiCategory.dogHotel => 'dog_hotel',
      PoiCategory.selfWash => 'self_wash',
      PoiCategory.dogTreats => 'dog_treats',
      PoiCategory.petSitter => 'pet_sitter',
      _ => category.name,
    };
  }

  static PoiCategory _categoryFromKey(String key) {
    return switch (key) {
      'pet_shop' || 'petShop' => PoiCategory.petShop,
      'cafe' || 'kafic' => PoiCategory.cafe,
      'restaurant' || 'restoran' => PoiCategory.restaurant,
      'groomer' || 'grooming' => PoiCategory.groomer,
      'vet' || 'veterinar' => PoiCategory.vet,
      'lodging' || 'hotel' => PoiCategory.lodging,
      'training' || 'dresura' => PoiCategory.training,
      'dog_hotel' || 'dogHotel' || 'pansion' => PoiCategory.dogHotel,
      'self_wash' || 'selfWash' || 'perionica' => PoiCategory.selfWash,
      'dog_treats' || 'dogTreats' || 'hrana' => PoiCategory.dogTreats,
      'shelter' || 'azil' => PoiCategory.shelter,
      'water' || 'voda' => PoiCategory.water,
      'pet_sitter' || 'petSitter' => PoiCategory.petSitter,
      'other' => PoiCategory.other,
      _ => PoiCategory.park,
    };
  }

  static MapPlaceType _typeFromCategoryKey(String key) {
    return switch (_categoryFromKey(key)) {
      PoiCategory.cafe => MapPlaceType.cafe,
      PoiCategory.restaurant => MapPlaceType.restaurant,
      PoiCategory.park => MapPlaceType.park,
      PoiCategory.petShop => MapPlaceType.petShop,
      PoiCategory.groomer => MapPlaceType.groomer,
      PoiCategory.vet => MapPlaceType.vet,
      PoiCategory.lodging => MapPlaceType.lodging,
      PoiCategory.training => MapPlaceType.training,
      PoiCategory.dogHotel => MapPlaceType.dogHotel,
      PoiCategory.selfWash => MapPlaceType.selfWash,
      PoiCategory.dogTreats => MapPlaceType.dogTreats,
      PoiCategory.shelter => MapPlaceType.shelter,
      PoiCategory.water => MapPlaceType.water,
      PoiCategory.petSitter => MapPlaceType.petSitter,
      PoiCategory.other => MapPlaceType.other,
    };
  }

  static MapCity _mapCityFromCityId(String cityId) {
    return switch (cityId) {
      'beograd' || 'belgrade' => MapCity.belgrade,
      'novi-sad' || 'noviSad' => MapCity.noviSad,
      _ => MapCity.other,
    };
  }
}

class LocalPlacesRepository implements PlacesRepository {
  final List<MapPlace> _items = [];
  final _controller = StreamController<List<MapPlace>>.broadcast();

  @override
  Stream<List<MapPlace>> watchPlaces() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<String> createPlace(PlaceDraft draft) async {
    final id = 'place-${DateTime.now().millisecondsSinceEpoch}';
    _items.add(
      MapPlace(
        id: id,
        name: draft.name,
        type: FirestorePlacesRepository._typeFromCategoryKey(draft.category),
        neighborhood: draft.address,
        latitude: draft.latitude,
        longitude: draft.longitude,
        phone: draft.phone,
        openingHours: draft.openingHours,
        city: FirestorePlacesRepository._mapCityFromCityId(draft.cityId),
        cityId: draft.cityId,
        verificationStatus: PoiVerificationStatus.verified,
        lastVerified: DateTime.now(),
        source: 'Admin',
      ),
    );
    _controller.add(List.unmodifiable(_items));
    return id;
  }

  @override
  Future<void> updatePlace(PoiModel poi) async {
    final index = _items.indexWhere((item) => item.id == poi.id);
    final next = MapPlace.fromPoi(poi);
    if (index == -1) {
      _items.add(next);
    } else {
      _items[index] = next;
    }
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> deletePlace(String placeId) async {
    _items.removeWhere((item) => item.id == placeId);
    _controller.add(List.unmodifiable(_items));
  }
}
