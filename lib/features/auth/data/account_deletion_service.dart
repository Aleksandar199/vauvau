import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/images/dog_photo_urls.dart';
import '../../../services/storage_service.dart';

/// Cascading wipe of Firestore + Storage owned by [uid] before Auth delete.
class AccountDeletionService {
  AccountDeletionService({
    required this.firestore,
    StorageService? storage,
  }) : _storage = storage ?? StorageService();

  final FirebaseFirestore firestore;
  final StorageService _storage;

  Future<void> deleteAllUserData(String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final photoUrls = <String>{};

    // Dogs (+ nested health / reminders / likes) and gallery URLs.
    final dogs = await firestore
        .collection('dogs')
        .where('ownerId', isEqualTo: trimmed)
        .get();
    for (final doc in dogs.docs) {
      photoUrls.addAll(collectPhotoUrls(doc.data()));
      await _deleteSubcollection(doc.reference, 'health_records');
      await _deleteSubcollection(doc.reference, 'reminders');
      await _deleteSubcollection(doc.reference, 'likes');
      await doc.reference.delete();
    }

    // Moments (+ comments) and photos.
    final moments = await firestore
        .collection('moments')
        .where('authorUserId', isEqualTo: trimmed)
        .get();
    for (final doc in moments.docs) {
      final data = doc.data();
      final photo = (data['momentPhotoUrl'] as String? ?? '').trim();
      if (photo.isNotEmpty) {
        photoUrls.add(photo);
      }
      photoUrls.addAll(collectPhotoUrls(data));
      await _deleteSubcollection(doc.reference, 'comments');
      await doc.reference.delete();
    }

    // Comments the user left on other people's moments / lost dogs.
    await _deleteCollectionGroup(
      'comments',
      field: 'authorUserId',
      value: trimmed,
    );

    // Adoption + lost dog listings.
    await _deleteOwnedDocs(
      collection: 'adoption_dogs',
      field: 'uploaderUserId',
      uid: trimmed,
      collectPhotos: true,
      into: photoUrls,
    );
    await _deleteOwnedDocs(
      collection: 'lost_dogs',
      field: 'uploaderUserId',
      uid: trimmed,
      collectPhotos: true,
      into: photoUrls,
    );

    // Discover graph.
    await _deleteQuery(
      firestore.collection('swipes').where('fromUserId', isEqualTo: trimmed),
    );
    await _deleteQuery(
      firestore.collection('super_likes').where('fromUserId', isEqualTo: trimmed),
    );
    await _deleteQuery(
      firestore.collection('matches').where('userIds', arrayContains: trimmed),
    );
    await _deleteQuery(
      firestore
          .collection('matches')
          .where('participantIds', arrayContains: trimmed),
    );

    // Notifications received or sent.
    await _deleteQuery(
      firestore.collection('notifications').where('toUserId', isEqualTo: trimmed),
    );
    await _deleteQuery(
      firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: trimmed),
    );
    await _deleteQuery(
      firestore
          .collection('notifications')
          .where('fromUserId', isEqualTo: trimmed),
    );

    // Events: delete if organizer, otherwise leave membership.
    final organized = await firestore
        .collection('events')
        .where('organizerUserId', isEqualTo: trimmed)
        .get();
    for (final doc in organized.docs) {
      final data = doc.data();
      photoUrls.addAll(collectPhotoUrls(data));
      final image = (data['imageUrl'] as String? ?? '').trim();
      if (image.isNotEmpty) {
        photoUrls.add(image);
      }
      await _deleteSubcollection(doc.reference, 'messages');
      await _deleteSubcollection(doc.reference, 'members');
      await doc.reference.delete();
    }
    await _leaveArrayMembership(
      collection: 'events',
      arrayField: 'participantUserIds',
      uid: trimmed,
    );

    // Groups: leave membership (do not wipe shared groups).
    await _leaveArrayMembership(
      collection: 'breed_groups',
      arrayField: 'memberIds',
      uid: trimmed,
      alsoClearMemberDoc: true,
    );

    // Legacy top-level highlights (if any).
    await _deleteQuery(
      firestore.collection('highlights').where('ownerId', isEqualTo: trimmed),
    );

    // Own chat messages (DM + group/event via collection group) then leave DMs.
    await _deleteCollectionGroup(
      'messages',
      field: 'senderId',
      value: trimmed,
      collectImageUrls: true,
      into: photoUrls,
    );
    await _leaveChats(trimmed);

    // User subcollections + profile photo.
    final userRef = firestore.collection('users').doc(trimmed);
    final userSnap = await userRef.get();
    if (userSnap.exists) {
      photoUrls.addAll(collectPhotoUrls(userSnap.data() ?? const {}));
      final photo = (userSnap.data()?['photoUrl'] as String? ?? '').trim();
      final custom =
          (userSnap.data()?['customPhotoUrl'] as String? ?? '').trim();
      if (photo.isNotEmpty) {
        photoUrls.add(photo);
      }
      if (custom.isNotEmpty) {
        photoUrls.add(custom);
      }
    }
    await _deleteSubcollection(userRef, 'fcmInbox');
    await _deleteSubcollection(userRef, 'blocked_users');
    await _deleteSubcollection(userRef, 'walks');
    await _deleteSubcollection(userRef, 'place_change_requests');
    await userRef.delete();

    // Best-effort Storage cleanup (public HTTPS / gs:// URLs only).
    for (final url in photoUrls) {
      await _storage.tryDeleteImageByUrl(url);
    }
  }

  Future<void> _leaveChats(String uid) async {
    final chats = await firestore
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .get();
    for (final doc in chats.docs) {
      final data = doc.data();
      final ids = [
        for (final value in data['participantIds'] as List? ?? const [])
          if (value is String && value != uid) value,
      ];
      try {
        final unread = Map<String, dynamic>.from(
          data['unreadByUser'] as Map? ?? const {},
        )..remove(uid);
        await doc.reference.update({
          'participantIds': ids,
          'unreadByUser': unread,
        });
      } catch (error) {
        debugPrint('AccountDeletion leave chat ${doc.id}: $error');
      }
    }
  }

  Future<void> _leaveArrayMembership({
    required String collection,
    required String arrayField,
    required String uid,
    bool alsoClearMemberDoc = false,
  }) async {
    final snap = await firestore
        .collection(collection)
        .where(arrayField, arrayContains: uid)
        .get();
    for (final doc in snap.docs) {
      try {
        final patch = <String, Object?>{
          arrayField: FieldValue.arrayRemove([uid]),
        };
        if (arrayField == 'memberIds') {
          patch['memberCount'] = FieldValue.increment(-1);
        }
        await doc.reference.update(patch);
        if (alsoClearMemberDoc) {
          await doc.reference.collection('members').doc(uid).delete();
        }
      } catch (error) {
        debugPrint('AccountDeletion leave $collection/${doc.id}: $error');
      }
    }
  }

  Future<void> _deleteOwnedDocs({
    required String collection,
    required String field,
    required String uid,
    required bool collectPhotos,
    required Set<String> into,
  }) async {
    final snap =
        await firestore.collection(collection).where(field, isEqualTo: uid).get();
    for (final doc in snap.docs) {
      if (collectPhotos) {
        into.addAll(collectPhotoUrls(doc.data()));
        final image = (doc.data()['imageUrl'] as String? ?? '').trim();
        if (image.isNotEmpty) {
          into.add(image);
        }
      }
      // Lost-dog comments live as a subcollection in some schemas.
      await _deleteSubcollection(doc.reference, 'comments');
      await doc.reference.delete();
    }
  }

  Future<void> _deleteCollectionGroup(
    String name, {
    required String field,
    required String value,
    bool collectImageUrls = false,
    Set<String>? into,
  }) async {
    try {
      final snap = await firestore
          .collectionGroup(name)
          .where(field, isEqualTo: value)
          .get();
      await _commitDeletes(snap.docs, collectImageUrls: collectImageUrls, into: into);
    } catch (error, stack) {
      // Missing index / rules — log and continue so Auth delete can proceed.
      debugPrint('AccountDeletion collectionGroup($name): $error');
      debugPrint('$stack');
    }
  }

  Future<void> _deleteSubcollection(
    DocumentReference<Map<String, dynamic>> parent,
    String name,
  ) async {
    await _deleteQuery(parent.collection(name));
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    await _commitDeletes(snapshot.docs);
  }

  Future<void> _commitDeletes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    bool collectImageUrls = false,
    Set<String>? into,
  }) async {
    if (docs.isEmpty) {
      return;
    }
    var batch = firestore.batch();
    var count = 0;
    for (final doc in docs) {
      if (collectImageUrls && into != null) {
        final image = (doc.data()['imageUrl'] as String? ?? '').trim();
        if (image.isNotEmpty) {
          into.add(image);
        }
      }
      batch.delete(doc.reference);
      count++;
      if (count == 400) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }
}
