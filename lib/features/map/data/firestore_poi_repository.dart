import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/map_city.dart';
import '../domain/models/poi_model.dart';
import '../domain/poi_repository.dart';

class FirestorePoiRepository implements PoiRepository {
  FirestorePoiRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _pois =>
      _firestore.collection('pois');

  @override
  Stream<List<PoiModel>> watchAll() {
    return _pois.snapshots().map(
          (snapshot) => snapshot.docs.map(_fromDoc).toList(),
        );
  }

  @override
  Future<void> upsert(PoiModel poi) {
    return _pois.doc(poi.id).set(_toMap(poi), SetOptions(merge: true));
  }

  PoiModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final verified = data['lastVerified'];
    return PoiModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      category: _category(data['category'] as String?),
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      phone: data['phone'] as String? ?? '',
      website: data['website'] as String?,
      is24_7: data['is24_7'] as bool? ?? false,
      isEmergencyService: data['isEmergencyService'] as bool? ?? false,
      overnightStay: data['overnightStay'] as bool? ?? false,
      dayCare: data['dayCare'] as bool? ?? false,
      hasYard: data['hasYard'] as bool? ?? false,
      pricePerNight: (data['pricePerNight'] as num?)?.toDouble(),
      petFriendly: data['petFriendly'] as bool? ?? true,
      city: _city(data['city'] as String?),
      verificationStatus: PoiVerificationStatusX.fromString(
        data['verificationStatus'] as String?,
      ),
      lastVerified: verified is Timestamp ? verified.toDate() : DateTime.now(),
      source: data['source'] as String? ?? 'VauVau',
      rating: (data['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> _toMap(PoiModel poi) {
    return {
      'id': poi.id,
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
      'petFriendly': poi.petFriendly,
      'city': poi.city.name,
      'verificationStatus': poi.verificationStatus.firestoreValue,
      'lastVerified': Timestamp.fromDate(poi.lastVerified),
      'source': poi.source,
      'rating': poi.rating,
    };
  }

  PoiCategory _category(String? raw) {
    for (final value in PoiCategory.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return PoiCategory.park;
  }

  MapCity _city(String? raw) {
    for (final value in MapCity.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return MapCity.noviSad;
  }
}

class LocalPoiRepository implements PoiRepository {
  LocalPoiRepository();

  final List<PoiModel> _items = [];

  @override
  Stream<List<PoiModel>> watchAll() => Stream.value(List.unmodifiable(_items));

  @override
  Future<void> upsert(PoiModel poi) async {
    _items.removeWhere((item) => item.id == poi.id);
    _items.add(poi);
  }
}
