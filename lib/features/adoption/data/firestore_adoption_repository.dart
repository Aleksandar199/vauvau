import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

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
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(_fromDoc).toList(),
        );
  }

  @override
  Future<List<AdoptionDog>> getAdoptionDogs() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> addAdoptionDog(
    AdoptionDog dog, {
    List<XFile> photos = const [],
  }) async {
    final doc = dog.id.isEmpty ? _col.doc() : _col.doc(dog.id);
    final urls = List<String>.from(dog.imageUrls);
    for (var i = 0; i < photos.length; i++) {
      try {
        urls.add(await _upload(photos[i]));
      } catch (_) {}
    }
    final saved = dog.copyWith(
      id: doc.id,
      imageUrls: uniquePhotoUrls(urls),
      createdAt: dog.createdAt,
    );
    await doc.set(_toMap(saved));
  }

  Future<String> _upload(XFile file) async {
    final error = await ContentValidationService.validateImage(file);
    if (error != null) {
      throw DogsException(error);
    }
    return ImageUploadService.upload(await file.readAsBytes());
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
        (data['imageUrls'] as List<dynamic>? ?? [])
            .map((item) => item.toString()),
      ),
      contactPhone: data['contactPhone'] as String? ?? '',
      uploaderUserId: data['uploaderUserId'] as String? ?? '',
      uploaderName: data['uploaderName'] as String? ?? '',
      isVaccinated: data['isVaccinated'] as bool? ?? false,
      isSterilized: data['isSterilized'] as bool? ?? false,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> _toMap(AdoptionDog dog) {
    return {
      'name': dog.name,
      'breed': dog.breed,
      'age': dog.age,
      'gender': dog.gender,
      'size': dog.size,
      'location': dog.location,
      'description': dog.description,
      'imageUrls': dog.imageUrls,
      'contactPhone': dog.contactPhone,
      'uploaderUserId': dog.uploaderUserId,
      'uploaderName': dog.uploaderName,
      'isVaccinated': dog.isVaccinated,
      'isSterilized': dog.isSterilized,
      'createdAt': Timestamp.fromDate(dog.createdAt),
    };
  }
}
