import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../auth/domain/app_user.dart';
import '../domain/dog.dart';
import '../domain/dog_area.dart';
import '../domain/dog_draft.dart';
import '../domain/dog_enums.dart';
import '../domain/dogs_exception.dart';
import '../domain/dogs_repository.dart';
import 'dog_photo_storage.dart';

class DogsRepositoryImpl implements DogsRepository {
  DogsRepositoryImpl({
    required this._firestore,
    required this._photoStorage,
  });

  final FirebaseFirestore _firestore;
  final DogPhotoStorage _photoStorage;

  CollectionReference<Map<String, dynamic>> get _dogs =>
      _firestore.collection('dogs');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<List<Dog>> watchByOwner(String ownerId) {
    return _dogs.where('ownerId', isEqualTo: ownerId).snapshots().map(
          (snapshot) => snapshot.docs.map(_dogFromDoc).toList(),
        );
  }

  @override
  Future<Dog> createFirstDog({
    required AppUser owner,
    required DogDraft draft,
  }) async {
    try {
      final area = _resolveArea(draft);
      final dogRef = _dogs.doc();
      final now = FieldValue.serverTimestamp();
      final dogPayload = <String, dynamic>{
        'id': dogRef.id,
        'ownerId': owner.uid,
        'name': draft.name.trim(),
        'breed': draft.breed.trim(),
        'gender': draft.gender!.firestoreValue,
        'ageYears': draft.ageYears,
        'size': draft.size!.firestoreValue,
        'weightKg': draft.weightKg,
        'energyLevel': draft.energyLevel!.firestoreValue,
        'temperament':
            draft.temperament.map((tag) => tag.firestoreValue).toList(),
        'area': area.toMap(),
        'photoUrls': <String>[],
        'createdAt': now,
        'updatedAt': now,
      };

      await dogRef.set(dogPayload);

      final photoUrls = <String>[];
      for (var i = 0; i < draft.photos.length; i++) {
        final url = await _photoStorage.upload(
          dogId: dogRef.id,
          index: i,
          file: draft.photos[i],
        );
        photoUrls.add(url);
      }

      await dogRef.update({
        'photoUrls': photoUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _users.doc(owner.uid).set(
        {
          'uid': owner.uid,
          'displayName': owner.displayName,
          'email': owner.email,
          'primaryDogId': dogRef.id,
          'area': area.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': now,
        },
        SetOptions(merge: true),
      );

      return Dog(
        id: dogRef.id,
        ownerId: owner.uid,
        name: draft.name.trim(),
        breed: draft.breed.trim(),
        gender: draft.gender!,
        ageYears: draft.ageYears!,
        size: draft.size!,
        weightKg: draft.weightKg,
        energyLevel: draft.energyLevel!,
        temperament: draft.temperament,
        area: area,
        photoUrls: photoUrls,
      );
    } on DogsException {
      rethrow;
    } catch (error) {
      throw DogsException(error.toString());
    }
  }

  Dog _dogFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final areaMap = data['area'] as Map<String, dynamic>? ?? {};
    final temperamentRaw = data['temperament'] as List<dynamic>? ?? [];
    return Dog(
      id: data['id'] as String? ?? doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      gender: _enumByName(DogGender.values, data['gender'], DogGender.unknown),
      ageYears: (data['ageYears'] as num?)?.toInt() ?? 0,
      size: _enumByName(DogSize.values, data['size'], DogSize.medium),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      energyLevel: _enumByName(
        DogEnergyLevel.values,
        data['energyLevel'],
        DogEnergyLevel.moderate,
      ),
      temperament: temperamentRaw
          .map(
            (value) => _enumByName(
              DogTemperament.values,
              value,
              DogTemperament.friendly,
            ),
          )
          .toList(),
      area: DogArea.fromMap(areaMap),
      photoUrls: (data['photoUrls'] as List<dynamic>? ?? [])
          .map((url) => url.toString())
          .toList(),
    );
  }

  DogArea _resolveArea(DogDraft draft) {
    final city = SerbiaLocations.cityById(draft.cityId ?? '');
    if (city == null) {
      throw const DogsException('Select a city and neighborhood.');
    }
    Neighborhood? neighborhood;
    for (final item in city.neighborhoods) {
      if (item.id == draft.neighborhoodId) {
        neighborhood = item;
        break;
      }
    }
    if (neighborhood == null) {
      throw const DogsException('Select a city and neighborhood.');
    }
    return DogArea(
      cityId: city.id,
      cityName: city.name,
      neighborhoodId: neighborhood.id,
      neighborhoodName: neighborhood.name,
    );
  }

  T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
    final name = raw?.toString();
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}
