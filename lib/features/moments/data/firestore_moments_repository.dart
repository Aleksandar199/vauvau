import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/images/dog_photo_urls.dart';
import '../domain/moment_model.dart';
import '../domain/moments_repository.dart';

class FirestoreMomentsRepository implements MomentsRepository {
  FirestoreMomentsRepository({
    required this.firestore,
    required this.currentUserId,
    required this.authorName,
  });

  final FirebaseFirestore firestore;
  final String currentUserId;
  final String authorName;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('moments');

  /// The auth stream can still be loading when a screen is first built, so the
  /// live FirebaseAuth user is used as a fallback. Firestore rules require the
  /// stored `authorUserId` to equal the signed-in uid.
  String get _uid {
    final injected = currentUserId.trim();
    if (injected.isNotEmpty) {
      return injected;
    }
    return (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
  }

  String _resolveAuthorName(String candidate) {
    for (final value in [
      candidate,
      authorName,
      FirebaseAuth.instance.currentUser?.displayName ?? '',
    ]) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed != 'Korisnik') {
        return trimmed;
      }
    }
    return 'Korisnik';
  }

  @override
  Stream<List<MomentModel>> watchMoments({int limit = 20}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_fromSnapshot);
  }

  @override
  Future<MomentsPage> fetchMomentsPage({
    Object? cursor,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query =
        _col.orderBy('createdAt', descending: true).limit(limit);

    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    } else {
      // First "load more": skip the live window (newest [limit] docs).
      final head = await _col
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      if (head.docs.isEmpty) {
        return const MomentsPage(items: [], hasMore: false);
      }
      query = _col
          .orderBy('createdAt', descending: true)
          .startAfterDocument(head.docs.last)
          .limit(limit);
    }

    final snapshot = await query.get();
    final items = [
      for (final doc in snapshot.docs)
        _fromDoc(doc, pending: doc.metadata.hasPendingWrites),
    ];
    final last = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    return MomentsPage(
      items: items,
      nextCursor: last,
      hasMore: snapshot.docs.length >= limit,
    );
  }

  @override
  Stream<List<MomentComment>> watchComments(String momentId) {
    return _col
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_commentFromDoc).toList());
  }

  @override
  Future<void> toggleLike(String momentId) async {
    final uid = _uid;
    if (uid.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    final ref = _col.doc(momentId);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final ids = [
        for (final value in snap.data()?['likes'] as List? ?? const [])
          if (value is String) value,
      ];
      if (ids.contains(uid)) {
        ids.remove(uid);
      } else {
        ids.add(uid);
      }
      tx.update(ref, {'likes': ids});
    });
  }

  @override
  Future<void> addComment(String momentId, String text) async {
    final trimmed = text.trim();
    final uid = _uid;
    if (trimmed.isEmpty || uid.isEmpty) {
      return;
    }
    final ref = _col.doc(momentId);
    await ref.collection('comments').add({
      'authorUserId': uid,
      'authorName': _resolveAuthorName(''),
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final count = (snap.data()?['commentsCount'] as num?)?.toInt() ?? 0;
      tx.update(ref, {'commentsCount': count + 1});
    });
  }

  @override
  Future<String> createMoment(MomentModel moment) async {
    final uid = _uid;
    if (uid.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    try {
      final photo = moment.momentPhotoUrl.trim();
      final dogPhoto = moment.dogPhotoUrl.trim();
      final location = moment.locationName.trim();
      final dogName = moment.dogName.trim();
      final doc = await _col.add(<String, Object>{
        'authorUserId': uid,
        'authorName': _resolveAuthorName(moment.authorName),
        'dogId': moment.dogId.trim(),
        'dogName': dogName.isEmpty ? 'Pas' : dogName,
        'dogBreed': moment.dogBreed.trim(),
        'dogPhotoUrl': dogPhoto.isEmpty ? kFallbackDogPhotoUrl : dogPhoto,
        'momentPhotoUrl': photo.isEmpty ? kFallbackDogPhotoUrl : photo,
        'caption': moment.caption.trim(),
        'locationName': location.isEmpty ? 'Novi Sad' : location,
        'likes': <String>[],
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (error, stack) {
      debugPrint('Moment create FAILED: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  @override
  Future<void> deleteMoment(String momentId) async {
    try {
      await _col.doc(momentId).delete();
    } catch (error, stack) {
      debugPrint('Moment delete FAILED: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// `createdAt` is written with a server timestamp, so it stays null in the
  /// local cache until the write is acknowledged. Those documents are dated
  /// with the current time and the list is re-sorted client side, otherwise a
  /// freshly created moment would sort last instead of first.
  List<MomentModel> _fromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final moments = [
      for (final doc in snapshot.docs)
        _fromDoc(doc, pending: doc.metadata.hasPendingWrites),
    ];
    moments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return moments;
  }

  MomentModel _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool pending,
  }) {
    final data = doc.data();
    final dogName = (data['dogName'] as String? ?? '').trim();
    final locationName = (data['locationName'] as String? ?? '').trim();
    final momentPhotoUrl = (data['momentPhotoUrl'] as String? ?? '').trim();
    final authorName = (data['authorName'] as String? ?? '').trim();
    return MomentModel(
      id: doc.id,
      authorUserId: data['authorUserId'] as String? ?? '',
      authorName: authorName.isEmpty ? 'Korisnik' : authorName,
      dogId: data['dogId'] as String? ?? '',
      dogName: dogName.isEmpty ? 'Pas' : dogName,
      dogBreed: data['dogBreed'] as String? ?? '',
      dogPhotoUrl: data['dogPhotoUrl'] as String? ?? '',
      momentPhotoUrl: momentPhotoUrl.isEmpty
          ? kFallbackDogPhotoUrl
          : momentPhotoUrl,
      caption: data['caption'] as String? ?? '',
      locationName: locationName.isEmpty ? 'Novi Sad' : locationName,
      likes: [
        for (final value in data['likes'] as List? ?? const [])
          if (value is String) value,
      ],
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: pending ? DateTime.now() : _date(data['createdAt']),
    );
  }

  MomentComment _commentFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final authorName = (data['authorName'] as String? ?? '').trim();
    return MomentComment(
      id: doc.id,
      authorUserId: data['authorUserId'] as String? ?? '',
      authorName: authorName.isEmpty ? 'Korisnik' : authorName,
      text: data['text'] as String? ?? '',
      createdAt: doc.metadata.hasPendingWrites
          ? DateTime.now()
          : _date(data['createdAt']),
    );
  }

  DateTime _date(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
