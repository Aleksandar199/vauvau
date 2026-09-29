import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_status.dart';
import '../domain/discover_profile.dart';
import 'dog_profile_mapper.dart';

Future<DiscoverProfile?> loadDiscoverProfile({
  String? dogId,
  String? ownerId,
  FirebaseFirestore? firestore,
}) async {
  if (!isFirebaseReady) {
    return null;
  }
  final dogs = (firestore ?? FirebaseFirestore.instance).collection('dogs');
  final id = dogId?.trim() ?? '';
  if (id.isNotEmpty) {
    final snapshot = await dogs.doc(id).get();
    final data = snapshot.data();
    if (data != null) {
      return discoverProfileFromMap(id, data);
    }
  }
  final owner = ownerId?.trim() ?? '';
  if (owner.isEmpty) {
    return null;
  }
  final query = await dogs.where('ownerId', isEqualTo: owner).limit(1).get();
  if (query.docs.isEmpty) {
    return null;
  }
  final doc = query.docs.first;
  return discoverProfileFromMap(doc.id, doc.data());
}
