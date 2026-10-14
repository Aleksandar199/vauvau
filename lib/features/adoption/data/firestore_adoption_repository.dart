import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../dogs/domain/dogs_exception.dart';
import '../domain/adoption_dog.dart';
import '../domain/adoption_repository.dart';

class FirestoreAdoptionRepository implements AdoptionRepository {
  FirestoreAdoptionRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('adoption_dogs');

  @override
  Stream<List<AdoptionDog>> watchAdoptionDogs() {
    return FirestoreAuthGuard.guardedStream<List<AdoptionDog>>(
      label: 'adoption.watch',
      empty: const [],
      create: () => _col
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(_fromDoc).toList()),
    );
  }

  @override
  Future<List<AdoptionDog>> getAdoptionDogs() async {
    final snapshot =
        await _col.orderBy('createdAt', descending: true).limit(20).get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> addAdoptionDog(
    AdoptionDog dog, {
    List<XFile> photos = const [],
    String city = '',
    String neighborhood = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Morate biti prijavljeni.');
    }
    final urls = List<String>.from(dog.imageUrls);
    for (final photo in photos) {
      urls.add(await _upload(photo));
    }
    final imageUrls = uniquePhotoUrls(urls);
    final photoUrl = imageUrls.isEmpty ? '' : imageUrls.first;
    final place = neighborhood.isEmpty ? city : '$city, $neighborhood';
    final displayName = user.displayName?.trim() ?? '';
    await _col.add({
      'name': dog.name,
      'breed': dog.breed,
      'age': dog.age,
      'gender': dog.gender,
      'size': dog.size,
      'location': place,
      'city': city,
      'neighborhood': neighborhood,
      'description': dog.description,
      'imageUrls': imageUrls,
      'photos': imageUrls,
      'photoUrl': photoUrl,
      'contactPhone': dog.contactPhone,
      'uploaderUserId': user.uid,
      'uploaderName': displayName.isEmpty ? 'Korisnik' : displayName,
      'isVaccinated': dog.isVaccinated,
      'isSterilized': dog.isSterilized,
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('Adoption listing created by ${user.uid}');
  }

  @override
  Future<void> markAdopted(String id) async {
    await _col.doc(id).update({'status': 'adopted'});
  }

  Future<String> _upload(XFile file) async {
    final error = await ContentValidationService.validateImage(file);
    if (error != null) {
      throw DogsException(error);
    }
    return ImageUploadService.uploadFile(file, folderName: 'adoption');
  }

  AdoptionDog _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final created = data['createdAt'];
    return AdoptionDog(
      id: doc.id,
      name: data['name'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      age: data['age'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      size: data['size'] as String? ?? 'srednji',
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrls: uniquePhotoUrls(
        [
          ...(data['imageUrls'] as List<dynamic>? ?? [])
              .map((item) => item.toString()),
          ...(data['photos'] as List<dynamic>? ?? [])
              .map((item) => item.toString()),
        ],
      ),
      contactPhone: data['contactPhone'] as String? ?? '',
      uploaderUserId: data['uploaderUserId'] as String? ?? '',
      uploaderName: data['uploaderName'] as String? ?? '',
      isVaccinated: data['isVaccinated'] as bool? ?? false,
      isSterilized: data['isSterilized'] as bool? ?? false,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      status: data['status'] as String? ?? 'available',
    );
  }
}
