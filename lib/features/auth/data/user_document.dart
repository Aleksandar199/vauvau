import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/user_dog_profile.dart';

const String userCollection = 'users';

/// `users/{uid}` is readable by every signed-in user, so private data lives
/// in `users/{uid}/private/account` (owner + admin only, see firestore.rules).
const String userPrivateCollection = 'private';
const String userPrivateDocId = 'account';

/// Fields that must never be on the public `users/{uid}` doc
/// (firestore.rules only allows removing them there).
const List<String> userPrivateFields = [
  'email',
  'fcmToken',
  'fcmTokenUpdatedAt',
  'contentReports',
  'placeChangeRequests',
  'isWalking',
  'walkStatus',
  'walkStartedAt',
  'lastKnownLocation',
  'geohash',
  'latitude',
  'longitude',
];

DocumentReference<Map<String, dynamic>> userPrivateDoc(
  FirebaseFirestore firestore,
  String uid,
) {
  return firestore
      .collection(userCollection)
      .doc(uid)
      .collection(userPrivateCollection)
      .doc(userPrivateDocId);
}

/// Merges [data] into the private doc. While the previous firestore.rules
/// (no `private` match) are still deployed that write is denied, so it falls
/// back to the legacy public doc; [moveUserPrivateFields] moves it later.
Future<void> setUserPrivateFields(
  FirebaseFirestore firestore,
  String uid,
  Map<String, dynamic> data,
) async {
  try {
    await userPrivateDoc(firestore, uid).set(data, SetOptions(merge: true));
  } on FirebaseException catch (error) {
    if (error.code != 'permission-denied') {
      rethrow;
    }
    await firestore
        .collection(userCollection)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }
}

/// Moves legacy private fields from the public doc into the private doc
/// (arrays are merged, never dropped). Runs on the owner's own client.
Future<void> moveUserPrivateFields(
  FirebaseFirestore firestore,
  String uid, {
  String? authEmail,
}) async {
  final publicRef = firestore.collection(userCollection).doc(uid);
  final data = (await publicRef.get()).data();
  if (data == null) {
    return;
  }
  final legacy = [
    for (final field in userPrivateFields)
      if (data.containsKey(field)) field,
  ];
  if (legacy.isEmpty) {
    return;
  }
  final private = <String, dynamic>{};
  for (final field in legacy) {
    final value = data[field];
    if (value is List) {
      if (value.isNotEmpty) {
        private[field] = FieldValue.arrayUnion(value);
      }
    } else if (value != null) {
      private[field] = value;
    }
  }
  final email = (authEmail ?? '').trim();
  if (email.isNotEmpty) {
    private['email'] = email;
  }
  final batch = firestore.batch()
    ..set(userPrivateDoc(firestore, uid), private, SetOptions(merge: true))
    ..update(publicRef, {
      for (final field in legacy) field: FieldValue.delete(),
    });
  await batch.commit();
}

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
    // Preserve the caller's role (admin must not be overwritten to "user"
    // on ordinary profile saves).
    payload['role'] = user.role.firestoreValue;
  }
  if (includeCreatedAt) {
    payload['createdAt'] = FieldValue.serverTimestamp();
  }
  if (includeDog) {
    payload['dog'] = user.dog.hasProfile ? user.dog.toMap() : emptyDogMap();
  }
  return payload;
}
