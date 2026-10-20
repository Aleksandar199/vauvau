import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
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
    // Newest first (every listing gets a server createdAt; a single-field
    // order needs no composite index), capped so the list stays responsive.
    return FirestoreAuthGuard.guardedStream<List<LostDog>>(
      label: 'lostDogs.watch',
      empty: const [],
      create: () => _col
          .orderBy('createdAt', descending: true)
          .limit(60)
          .snapshots()
          .map(_dogsFromSnapshot),
    );
  }

  @override
  Stream<List<LostDog>> watchLostDogsInCity(String cityId) {
    // Equality only (no orderBy): needs no composite index. Sorted below.
    return FirestoreAuthGuard.guardedStream<List<LostDog>>(
      label: 'lostDogs.watchCity',
      empty: const [],
      create: () => _col
          .where('cityId', isEqualTo: cityId)
          .limit(40)
          .snapshots()
          .map(_dogsFromSnapshot),
    );
  }

  List<LostDog> _dogsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final dogs = <LostDog>[];
    for (final doc in snapshot.docs) {
      try {
        dogs.add(_fromDoc(doc));
      } catch (error) {
        debugPrint('Lost dog parse skipped (${doc.id}): $error');
      }
    }
    dogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return dogs;
  }

  @override
  Stream<List<LostDogComment>> watchComments(String dogId) {
    return FirestoreAuthGuard.guardedStream<List<LostDogComment>>(
      label: 'lostDogs.comments',
      empty: const [],
      create: () => _col.doc(dogId).snapshots().map((snapshot) {
        final data = snapshot.data() ?? const <String, dynamic>{};
        return _commentsFromData(data);
      }),
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
      imageUrl = await ImageUploadService.uploadFile(
        photo,
        folderName: 'lost_dogs',
      );
    }
    final eventDate = dog.eventDate;
    await _col.add({
      'dogName': dog.dogName,
      'breed': dog.breed,
      'type': dog.type,
      'city': dog.city,
      if (dog.cityId.isNotEmpty) 'cityId': dog.cityId,
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
      'comments': <Map<String, dynamic>>[],
      'commentLikes': <String, List<String>>{},
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('Lost/found listing created by ${user.uid} (${dog.type})');
  }

  @override
  Future<void> addComment(
    String dogId,
    String text, {
    String authorName = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Morate biti prijavljeni.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    var name = authorName.trim();
    if (name.isEmpty) {
      name = user.displayName?.trim() ?? '';
      if (name.isEmpty) {
        // Never the email: lost-dog comments are public.
        name = 'Korisnik';
      }
    }
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'id': 'c-${now.microsecondsSinceEpoch}',
      'authorUserId': user.uid,
      'authorName': name,
      'text': trimmed,
      'likes': <String>[],
      'createdAt': Timestamp.fromDate(now),
    };
    try {
      // Stored on the listing doc so it works under owner update rules.
      // Community comments also need the comments/commentsCount rule deployed.
      await _col.doc(dogId).update({
        'comments': FieldValue.arrayUnion([payload]),
        'commentsCount': FieldValue.increment(1),
      });
    } catch (error, stack) {
      debugPrint('Lost dog comment update failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  @override
  Future<void> toggleCommentLike(String dogId, String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Morate biti prijavljeni.');
    }
    final uid = user.uid;
    final trimmedId = commentId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final ref = _col.doc(dogId);
    try {
      await _toggleCommentLikeTx(ref, trimmedId, uid, legacyFormat: false);
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        debugPrint('Lost dog comment like failed: $error');
        rethrow;
      }
      // Previous firestore.rules only accept the whole commentLikes map.
      await _toggleCommentLikeTx(ref, trimmedId, uid, legacyFormat: true);
    }
  }

  Future<void> _toggleCommentLikeTx(
    DocumentReference<Map<String, dynamic>> ref,
    String commentId,
    String uid, {
    required bool legacyFormat,
  }) {
    // Store likes in commentLikes map so we don't rewrite the comments array
    // (array rewrites are fragile with Timestamps and often hit rule denials).
    return firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        return;
      }
      final data = snap.data() ?? const <String, dynamic>{};
      final likesByComment = _commentLikesFromData(data);
      final current = [...(likesByComment[commentId] ?? const <String>[])];
      if (current.contains(uid)) {
        current.remove(uid);
      } else {
        current.add(uid);
      }
      if (legacyFormat) {
        likesByComment[commentId] = current;
        tx.update(ref, {
          'commentLikes': {
            for (final entry in likesByComment.entries) entry.key: entry.value,
          },
        });
        return;
      }
      // Only this comment's list changes; commentLikeTarget tells the rules
      // which entry to check (caller may add/remove only their own uid).
      tx.update(ref, {
        FieldPath(['commentLikes', commentId]): current,
        'commentLikeTarget': commentId,
      });
    });
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
      cityId: data['cityId'] is String ? data['cityId'] as String : '',
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

  LostDogComment _commentFromMap(
    Map<String, dynamic> data,
    String fallbackId, {
    List<String>? likesOverride,
  }) {
    final id = (data['id'] as String?)?.trim().isNotEmpty == true
        ? data['id'] as String
        : fallbackId;
    final embedded = [
      for (final value in data['likes'] as List? ?? const [])
        if (value is String) value,
    ];
    return LostDogComment(
      id: id,
      authorUserId: data['authorUserId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Korisnik',
      text: data['text'] as String? ?? '',
      createdAt: _date(data['createdAt']),
      likes: likesOverride ?? embedded,
    );
  }

  Map<String, List<String>> _commentLikesFromData(Map<String, dynamic> data) {
    final raw = data['commentLikes'];
    if (raw is! Map) {
      return <String, List<String>>{};
    }
    final out = <String, List<String>>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) {
        continue;
      }
      final value = entry.value;
      if (value is! List) {
        continue;
      }
      out[key] = [
        for (final item in value)
          if (item is String && item.isNotEmpty) item,
      ];
    }
    return out;
  }

  List<LostDogComment> _commentsFromData(Map<String, dynamic> data) {
    final raw = data['comments'];
    if (raw is! List) {
      return const [];
    }
    final likesByComment = _commentLikesFromData(data);
    final comments = <LostDogComment>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      final map = item is Map<String, dynamic>
          ? item
          : item is Map
          ? Map<String, dynamic>.from(item)
          : null;
      if (map == null) {
        continue;
      }
      final fallbackId = 'c-$i';
      final id = (map['id'] as String?)?.trim().isNotEmpty == true
          ? map['id'] as String
          : fallbackId;
      final embeddedLikes = [
        for (final value in map['likes'] as List? ?? const [])
          if (value is String) value,
      ];
      comments.add(
        _commentFromMap(
          map,
          fallbackId,
          likesOverride: likesByComment[id] ?? embeddedLikes,
        ),
      );
    }
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
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
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.now();
  }
}
