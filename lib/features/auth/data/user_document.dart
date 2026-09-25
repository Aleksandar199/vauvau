import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/user_dog_profile.dart';

const String userCollection = 'users';

Map<String, dynamic> emptyDogMap() => const UserDogProfile().toMap();

Map<String, dynamic> userDocumentPayload(
  AppUser user, {
  required bool includeCreatedAt,
  bool includeRole = true,
  bool includeDog = true,
  bool includeOwnerPhoto = false,
}) {
  final cityName = user.cityName;
  final payload = <String, dynamic>{
    'uid': user.uid,
    'email': user.email ?? '',
    'name': user.displayName ?? '',
    'city': cityName,
    'cityId': user.cityId,
    'cityName': cityName,
    'neighborhoodId': user.neighborhoodId,
    'neighborhoodName': user.neighborhoodName,
    'bio': user.bio,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (includeOwnerPhoto) {
    final ownerPhoto = user.customPhotoUrl.trim().isNotEmpty
        ? user.customPhotoUrl.trim()
        : user.photoUrl.trim();
    payload['photoUrl'] = ownerPhoto;
    payload['customPhotoUrl'] = ownerPhoto;
  }
  if (includeRole) {
    payload['role'] = UserRole.user.firestoreValue;
  }
  if (includeCreatedAt) {
    payload['createdAt'] = FieldValue.serverTimestamp();
  }
  if (includeDog) {
    payload['dog'] = user.dog.hasProfile ? user.dog.toMap() : emptyDogMap();
  }
  return payload;
}
