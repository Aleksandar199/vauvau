import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../auth/domain/app_user.dart';
import '../../discover/data/dog_profile_mapper.dart';
import '../../discover/domain/discover_profile.dart';

/// What another user may see about a dog owner: the public `users/{uid}`
/// fields (never email / token / location, those are in `private/`) and
/// their dogs.
class OwnerPublicProfile {
  const OwnerPublicProfile({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.location,
    required this.bio,
    required this.dogs,
  });

  final String userId;
  final String name;
  final String photoUrl;
  final String location;
  final String bio;
  final List<DiscoverProfile> dogs;
}

/// Loads [userId]'s public profile; null when nothing is found (or Firebase
/// is not set up and no [firestore] is given).
Future<OwnerPublicProfile?> loadOwnerPublicProfile(
  String userId, {
  FirebaseFirestore? firestore,
}) async {
  final uid = userId.trim();
  if (uid.isEmpty || (firestore == null && !isFirebaseReady)) {
    return null;
  }
  final db = firestore ?? FirebaseFirestore.instance;
  final userSnap = await db.collection('users').doc(uid).get();
  final dogsSnap =
      await db.collection('dogs').where('ownerId', isEqualTo: uid).get();
  final data = userSnap.data();
  final dogs = [
    for (final doc in dogsSnap.docs) discoverProfileFromMap(doc.id, doc.data()),
  ];
  if (data == null && dogs.isEmpty) {
    return null;
  }
  final user = AppUser.fromAuthAndDocument(uid: uid, data: data);
  var name = (user.displayName ?? '').trim();
  if (name.isEmpty && dogs.isNotEmpty) {
    name = dogs.first.ownerName.trim();
  }
  return OwnerPublicProfile(
    userId: uid,
    name: name,
    photoUrl: user.ownerAvatarUrl,
    location: user.locationLabel,
    bio: user.bio.trim(),
    dogs: dogs,
  );
}
