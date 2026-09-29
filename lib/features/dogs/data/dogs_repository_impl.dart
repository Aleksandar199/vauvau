import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/geo/firestore_geo.dart';
import '../../../core/geo/geo.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../auth/domain/app_user.dart';
import '../domain/dog.dart';
import '../domain/dog_area.dart';
import '../domain/dog_draft.dart';
import '../domain/dog_enums.dart';
import '../domain/dogs_exception.dart';
import '../domain/dogs_repository.dart';

class DogsRepositoryImpl implements DogsRepository {
  DogsRepositoryImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _dogs =>
      _firestore.collection('dogs');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<List<Dog>> watchByOwner(String ownerId) {
    return _dogs
        .where('ownerId', isEqualTo: ownerId)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache || snapshot.docs.isNotEmpty)
        .map((snapshot) => snapshot.docs.map(_dogFromDoc).toList());
  }

  @override
  Future<Dog> createFirstDog({
    required AppUser owner,
    required DogDraft draft,
  }) async {
    try {
      final area = _areaFromOwner(owner, draft);
      final dogRef = _dogs.doc();
      final now = FieldValue.serverTimestamp();
      final location = area == null
          ? ''
          : '${area.cityName} - ${area.neighborhoodName}';
      final coord = area?.cityId == 'beograd'
          ? GeoCoord.belgrade
          : GeoCoord.noviSad;
      final photoUrls = uniquePhotoUrls(draft.photos);
      final photos = firestorePhotoFields(photoUrls);
      final energy = draft.energyLevel ?? DogEnergyLevel.moderate;
      final dogPayload = <String, dynamic>{
        'id': dogRef.id,
        'ownerId': owner.uid,
        'name': draft.name.trim(),
        'breed': draft.breed.trim(),
        'gender': draft.gender!.firestoreValue,
        'age': draft.ageYears,
        'ageYears': draft.ageYears,
        'size': draft.size!.firestoreValue,
        'bio': '',
        'isVaccinated': draft.vaccinated,
        'isMicrochipped': draft.chipped,
        'isSterilized': draft.sterilized,
        'location': location,
        'cityId': area?.cityId ?? owner.cityId,
        'cityName': area?.cityName ?? owner.cityName,
        'neighborhoodId': area?.neighborhoodId ?? owner.neighborhoodId,
        'neighborhoodName':
            area?.neighborhoodName ?? owner.neighborhoodName,
        'weightKg': draft.weightKg,
        'energyLevel': energy.firestoreValue,
        'temperament':
            draft.temperament.map((tag) => tag.firestoreValue).toList(),
        'likesTags': draft.likesTags,
        'dislikesTags': draft.dislikesTags,
        if (area != null) 'area': area.toMap(),
        'ownerName': owner.displayName ?? '',
        'createdAt': now,
        'updatedAt': now,
        ...firestoreLocationFields(coord, isWalking: false),
        ...photos,
        'primaryPhotoUrl': photos['photoUrl'],
      };

      try {
        await dogRef.set(dogPayload).timeout(const Duration(seconds: 4));
      } catch (_) {}
      unawaited(
        _users.doc(owner.uid).set(
          {
            'uid': owner.uid,
            'name': owner.displayName,
            'email': owner.email,
            'city': owner.cityName,
            'cityId': owner.cityId,
            'cityName': owner.cityName,
            'neighborhoodId': owner.neighborhoodId,
            'neighborhoodName': owner.neighborhoodName,
            'primaryDogId': dogRef.id,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': now,
            'dog': {
              'id': dogRef.id,
              'name': draft.name.trim(),
              'breed': draft.breed.trim(),
              'age': draft.ageYears,
              'gender': draft.gender!.firestoreValue,
              'bio': '',
              'size': draft.size!.firestoreValue,
              'temperament':
                  draft.temperament.map((tag) => tag.firestoreValue).toList(),
              'likesTags': draft.likesTags,
              'dislikesTags': draft.dislikesTags,
              ...photos,
            },
          },
          SetOptions(merge: true),
        ),
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
        energyLevel: energy,
        temperament: draft.temperament,
        area: area ??
            DogArea(
              cityId: owner.cityId,
              cityName: owner.cityName,
              neighborhoodId: owner.neighborhoodId,
              neighborhoodName: owner.neighborhoodName,
            ),
        photoUrls: List<String>.from(photos['photoUrls'] as List),
        vaccinated: draft.vaccinated,
        chipped: draft.chipped,
        sterilized: draft.sterilized,
        likesTags: draft.likesTags,
        dislikesTags: draft.dislikesTags,
      );
    } on DogsException {
      rethrow;
    } catch (error) {
      throw const DogsException();
    }
  }

  @override
  Future<void> updateDog(Dog dog, {int ageMonths = 0}) async {
    final photos = firestorePhotoFields(dog.photoUrls);
    await _dogs.doc(dog.id).set(
      {
        'id': dog.id,
        'ownerId': dog.ownerId,
        'name': dog.name,
        'breed': dog.breed,
        'gender': dog.gender.firestoreValue,
        'age': dog.ageYears,
        'ageYears': dog.ageYears,
        'ageMonths': ageMonths,
        'size': dog.size.firestoreValue,
        'bio': dog.bio,
        'weightKg': dog.weightKg,
        'energyLevel': dog.energyLevel.firestoreValue,
        'temperament':
            dog.temperament.map((tag) => tag.firestoreValue).toList(),
        'likesTags': dog.likesTags,
        'dislikesTags': dog.dislikesTags,
        'isVaccinated': dog.vaccinated,
        'isMicrochipped': dog.chipped,
        'isSterilized': dog.sterilized,
        'location': dog.location,
        'cityId': dog.area.cityId,
        'cityName': dog.area.cityName,
        'neighborhoodId': dog.area.neighborhoodId,
        'neighborhoodName': dog.area.neighborhoodName,
        'area': dog.area.toMap(),
        'primaryPhotoUrl': photos['photoUrl'],
        'updatedAt': FieldValue.serverTimestamp(),
        ...photos,
      },
      SetOptions(merge: true),
    );
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
      ageYears: (data['ageYears'] as num?)?.toInt() ??
          (data['age'] as num?)?.toInt() ??
          0,
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
      area: DogArea.fromMap(areaMap).cityId.isEmpty &&
              (data['cityId'] as String? ?? '').isNotEmpty
          ? DogArea(
              cityId: data['cityId'] as String? ?? '',
              cityName: data['cityName'] as String? ?? '',
              neighborhoodId: data['neighborhoodId'] as String? ?? '',
              neighborhoodName: data['neighborhoodName'] as String? ?? '',
            )
          : DogArea.fromMap(areaMap),
      photoUrls: collectPhotoUrls(data),
      bio: data['bio'] as String? ?? '',
      vaccinated: data['isVaccinated'] as bool? ??
          data['vaccinated'] as bool? ??
          false,
      chipped: data['isMicrochipped'] as bool? ??
          data['chipped'] as bool? ??
          false,
      sterilized: data['isSterilized'] as bool? ?? false,
      likesTags: [
        for (final value in data['likesTags'] as List? ?? const [])
          if (value is String) value,
      ],
      dislikesTags: [
        for (final value in data['dislikesTags'] as List? ?? const [])
          if (value is String) value,
      ],
    );
  }

  DogArea? _areaFromOwner(AppUser owner, DogDraft draft) {
    if (owner.cityId.isNotEmpty && owner.neighborhoodId.isNotEmpty) {
      return DogArea(
        cityId: owner.cityId,
        cityName: owner.cityName,
        neighborhoodId: owner.neighborhoodId,
        neighborhoodName: owner.neighborhoodName,
      );
    }
    if (draft.cityId != null && draft.neighborhoodId != null) {
      return _resolveArea(draft);
    }
    if (owner.cityName.isNotEmpty) {
      return DogArea(
        cityId: owner.cityId,
        cityName: owner.cityName,
        neighborhoodId: owner.neighborhoodId,
        neighborhoodName: owner.neighborhoodName,
      );
    }
    return null;
  }

  DogArea _resolveArea(DogDraft draft) {
    final city = SerbiaLocations.cityById(draft.cityId ?? '');
    if (city == null) {
      throw const DogsException('Izaberite grad i naselje.');
    }
    Neighborhood? neighborhood;
    for (final item in city.neighborhoods) {
      if (item.id == draft.neighborhoodId) {
        neighborhood = item;
        break;
      }
    }
    if (neighborhood == null) {
      throw const DogsException('Izaberite grad i naselje.');
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
