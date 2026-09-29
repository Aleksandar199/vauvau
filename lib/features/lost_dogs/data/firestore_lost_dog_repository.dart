import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/images/image_upload_service.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../dogs/domain/dogs_exception.dart';
import '../domain/lost_dog.dart';
import '../domain/lost_dog_repository.dart';

class FirestoreLostDogRepository implements LostDogRepository {
  FirestoreLostDogRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('lost_dogs');

  @override
  Stream<List<LostDog>> watchLostDogs() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(_fromDoc).toList(),
        );
  }

  @override
  Future<void> reportLostDog(LostDog dog, {XFile? photo}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Morate biti prijavljeni.');
    }
    var imageUrl = dog.imageUrl;
    if (photo != null) {
      final error = await ContentValidationService.validateImage(photo);
      if (error != null) {
        throw DogsException(error);
      }
      imageUrl = await ImageUploadService.upload(await photo.readAsBytes());
    }
    final eventDate = dog.eventDate;
    await _col.add({
      'dogName': dog.dogName,
      'breed': dog.breed,
      'type': dog.type,
      'city': dog.city,
      'neighborhood': dog.neighborhood,
      'lostDate': Timestamp.fromDate(
        dog.isFoundListing ? eventDate : dog.lostDate,
      ),
      'foundDate': Timestamp.fromDate(
        dog.isFoundListing ? eventDate : dog.lostDate,
      ),
      'description': dog.description,
      'imageUrl': imageUrl,
      'photoUrl': imageUrl,
      'contactPhone': dog.contactPhone,
      'uploaderUserId': user.uid,
      'status': LostDogStatus.active,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('Lost/found listing created by ${user.uid} (${dog.type})');
  }

  @override
  Future<void> markFound(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Morate biti prijavljeni.');
    }
    await _col.doc(id).update({'status': LostDogStatus.resolved});
  }

  @override
  Future<void> deleteLostDog(String id) async {
    await _col.doc(id).delete();
  }

  LostDog _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final type = _typeOf(data['type']);
    final lostDate = _date(data['lostDate'] ?? data['createdAt']);
    final foundDate = data['foundDate'] == null
        ? (type == LostDogType.found ? lostDate : null)
        : _date(data['foundDate']);
    return LostDog(
      id: doc.id,
      dogName: data['dogName'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      type: type,
      city: data['city'] as String? ?? '',
      neighborhood: data['neighborhood'] as String? ?? '',
      lostDate: lostDate,
      foundDate: foundDate,
      description: data['description'] as String? ?? '',
      imageUrl: (data['imageUrl'] as String?)?.trim().isNotEmpty == true
          ? data['imageUrl'] as String
          : (data['photoUrl'] as String? ?? ''),
      contactPhone: data['contactPhone'] as String? ?? '',
      uploaderUserId: data['uploaderUserId'] as String? ?? '',
      status: _statusOf(data['status']),
      createdAt: _date(data['createdAt']),
    );
  }

  String _typeOf(Object? raw) {
    return raw?.toString() == LostDogType.found
        ? LostDogType.found
        : LostDogType.lost;
  }

  String _statusOf(Object? raw) {
    final value = raw?.toString() ?? '';
    if (value == LostDogStatus.resolved || value == LostDogStatus.legacyFound) {
      return LostDogStatus.resolved;
    }
    if (value == LostDogStatus.legacyMissing) {
      return LostDogStatus.legacyMissing;
    }
    return LostDogStatus.active;
  }

  DateTime _date(Object? raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    return DateTime.now();
  }
}
