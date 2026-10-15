import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/serbia_locations.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
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
    if (ownerId.isEmpty) {
      return Stream.value(const []);
    }
    return FirestoreAuthGuard.guardedStream<List<Dog>>(
      label: 'dogs.watchByOwner',
      empty: const [],
      create: () => _dogs
          .where('ownerId', isEqualTo: ownerId)
          .snapshots(includeMetadataChanges: true)
          .where(
            (snapshot) =>
                !snapshot.metadata.isFromCache || snapshot.docs.isNotEmpty,
          )
          .map((snapshot) => snapshot.docs.map(_dogFromDoc).toList()),
    );
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
      final coord = GeoCoord.forCityId(area?.cityId ?? '');
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
        'bio': draft.bio.trim(),
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

      await dogRef.set(dogPayload);
      unawaited(
        _users.doc(owner.uid).set(
          {
            'uid': owner.uid,
            'name': owner.displayName,
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
              'bio': draft.bio.trim(),
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
        bio: draft.bio.trim(),
        vaccinated: draft.vaccinated,
        chipped: draft.chipped,
        sterilized: draft.sterilized,
        likesTags: draft.likesTags,
        dislikesTags: draft.dislikesTags,
      );
    } on DogsException {
      rethrow;
    } catch (error) {
      throw DogsException();
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
        'ageMonths': ageMonths > 0 ? ageMonths : dog.ageMonths,
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
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      gender: _parseGender(data['gender']),
      ageYears: (data['ageYears'] as num?)?.toInt() ??
          (data['age'] as num?)?.toInt() ??
          0,
      ageMonths: (data['ageMonths'] as num?)?.toInt() ?? 0,
      size: _parseSize(data['size']),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      energyLevel: _parseEnergy(data['energyLevel']),
      temperament: [
        for (final value in temperamentRaw)
          _parseTemperament(value) ?? DogTemperament.friendly,
      ],
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

  @override
  Future<void> deleteDog(String dogId, {required String ownerId}) async {
    final trimmed = dogId.trim();
    if (trimmed.isEmpty || ownerId.isEmpty) {
      return;
    }
    // Rules reject deletes of missing docs, and legacy docs may carry an `id`
    // field that differs from the document ID — so delete only docs we own.
    final owned = await _dogs.where('ownerId', isEqualTo: ownerId).get();
    final targets = [
      for (final doc in owned.docs)
        if (doc.id == trimmed || doc.data()['id'] == trimmed) doc.reference,
    ];
    if (targets.isEmpty) {
      return;
    }
    final batch = _firestore.batch();
    for (final ref in targets) {
      batch.delete(ref);
    }
    await batch.commit();
  }

  DogArea _resolveArea(DogDraft draft) {
    final city = SerbiaLocations.cityById(draft.cityId ?? '');
    if (city == null) {
      throw DogsException('Izaberite grad i naselje.');
    }
    final neighborhoodId = draft.neighborhoodId;
    if (neighborhoodId == null || neighborhoodId.isEmpty) {
      throw DogsException('Izaberite grad i naselje.');
    }
    final name = SerbiaLocations.resolveNeighborhoodName(
      cityId: city.id,
      neighborhoodId: neighborhoodId,
      customName: draft.customNeighborhoodName,
    );
    if (name.isEmpty) {
      throw DogsException('Izaberite grad i naselje.');
    }
    final storedId = SerbiaLocations.usesCustomNeighborhood(
          city.id,
          neighborhoodId,
        )
        ? SerbiaLocations.customNeighborhoodId
        : neighborhoodId;
    return DogArea(
      cityId: city.id,
      cityName: city.name,
      neighborhoodId: storedId,
      neighborhoodName: name,
    );
  }

  DogGender _parseGender(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'male':
      case 'mužjak':
      case 'muzjak':
        return DogGender.male;
      case 'female':
      case 'ženka':
      case 'zenka':
        return DogGender.female;
      default:
        return DogGender.unknown;
    }
  }

  DogSize _parseSize(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'small':
      case 'mali':
        return DogSize.small;
      case 'medium':
      case 'srednji':
        return DogSize.medium;
      case 'large':
      case 'xlarge':
      case 'veliki':
        return DogSize.large;
      default:
        return DogSize.medium;
    }
  }

  DogEnergyLevel _parseEnergy(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'low':
      case 'niska':
      case 'nizak':
        return DogEnergyLevel.low;
      case 'high':
      case 'visoka':
      case 'visok':
        return DogEnergyLevel.high;
      default:
        return DogEnergyLevel.moderate;
    }
  }

  DogTemperament? _parseTemperament(Object? raw) {
    final key = raw?.toString().trim().toLowerCase() ?? '';
    for (final value in DogTemperament.values) {
      if (value.name == key || value.firestoreValue == key) {
        return value;
      }
    }
    return switch (key) {
      // Legacy "social" was a duplicate of friendly (both showed as Društven).
      'druželjubiv' ||
      'društven' ||
      'drustven' ||
      'social' =>
        DogTemperament.friendly,
      'razigran' || 'igračka' || 'igracka' || 'voli loptice' || 'voli lopticu' =>
        DogTemperament.playful,
      'miran' || 'mirna' => DogTemperament.calm,
      'sramežljiv' || 'sramezljiv' => DogTemperament.shy,
      'zaštitnički' || 'zastitnicki' => DogTemperament.protective,
      _ => null,
    };
  }
}
