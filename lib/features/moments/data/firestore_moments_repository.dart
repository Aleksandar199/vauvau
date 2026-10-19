import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../services/storage_service.dart';
import '../domain/moment_model.dart';
import '../domain/moments_repository.dart';

class FirestoreMomentsRepository implements MomentsRepository {
  FirestoreMomentsRepository({
    required this.firestore,
    required this.currentUserId,
    required this.authorName,
    this.authorPhotoUrl = '',
    this.storage,
  });

  final FirebaseFirestore firestore;
  final String currentUserId;
  final String authorName;
  final String authorPhotoUrl;
  final StorageService? storage;

  StorageService get _storageService => storage ?? StorageService();

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('moments');

  CollectionReference<Map<String, dynamic>> _comments(String momentId) =>
      _col.doc(momentId).collection('comments');

  /// The auth stream can still be loading when a screen is first built, so the
  /// live FirebaseAuth user is used as a fallback. Firestore rules require the
  /// stored `authorUserId` to equal the signed-in uid.
  String get _uid {
    final injected = currentUserId.trim();
    if (injected.isNotEmpty) {
      return injected;
    }
    return (FirestoreAuthGuard.currentUser?.uid ?? '').trim();
  }

  String _requireUid() {
    final uid = _uid;
    if (uid.isEmpty) {
      throw StateError('Morate biti prijavljeni.');
    }
    return uid;
  }

  String _resolveAuthorName(String candidate) {
    for (final value in [
      candidate,
      authorName,
      FirestoreAuthGuard.currentUser?.displayName ?? '',
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
    return FirestoreAuthGuard.guardedStream<List<MomentModel>>(
      label: 'moments.watchMoments',
      empty: const [],
      create: () => _col
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(_fromSnapshot),
    );
  }

  @override
  Future<MomentsPage> fetchMomentsPage({
    Object? cursor,
    int limit = 20,
  }) {
    return FirestoreAuthGuard.run(
      label: 'moments.fetchMomentsPage',
      fallback: const MomentsPage(items: [], hasMore: false),
      action: () async {
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
      },
    );
  }

  // --- Feed ----------------------------------------------------------------

  Query<Map<String, dynamic>> _feedQuery(
    MomentFeedRequest request,
    List<String>? authors,
  ) {
    var query = _col.where('kind', isEqualTo: MomentModel.postKind);
    if (request.feed == MomentFeed.nearby) {
      query = query.where('cityId', isEqualTo: request.cityId);
    }
    if (authors != null) {
      query = query.where('authorUserId', whereIn: authors);
    }
    return query.orderBy('createdAt', descending: true);
  }

  @override
  Future<MomentsPage> fetchFeedPage(
    MomentFeedRequest request, {
    Object? cursor,
    int limit = 10,
  }) async {
    if (request.feed == MomentFeed.nearby && request.cityId.isEmpty) {
      return const MomentsPage(items: []);
    }
    final chunks = request.feed == MomentFeed.following
        ? request.authorChunks
        : const <List<String>?>[null];
    if (chunks.isEmpty) {
      return const MomentsPage(items: []);
    }
    if (cursor is _ScanCursor) {
      return _scanPage(request, cursor: cursor, limit: limit);
    }
    try {
      return await _mergedPage(
        request,
        chunks: chunks,
        cursor: cursor is _FeedCursor ? cursor : null,
        limit: limit,
      );
    } on FirebaseException catch (error) {
      // Composite index not deployed yet: read the plain createdAt order and
      // filter here, so the feed keeps working (less efficiently).
      if (error.code != 'failed-precondition') {
        rethrow;
      }
      debugPrint('moments feed index missing, scanning: ${error.message}');
      return _scanPage(request, cursor: null, limit: limit);
    }
  }

  /// One query per author chunk; results are merged newest first and each
  /// chunk continues after the last document it contributed.
  Future<MomentsPage> _mergedPage(
    MomentFeedRequest request, {
    required List<List<String>?> chunks,
    required _FeedCursor? cursor,
    required int limit,
  }) async {
    final last = cursor?.last ?? List.filled(chunks.length, null);
    final done = cursor?.done ?? List.filled(chunks.length, false);
    final snapshots = await Future.wait<QuerySnapshot<Map<String, dynamic>>?>([
      for (var i = 0; i < chunks.length; i++)
        if (done[i])
          Future.value(null)
        else
          () {
            var query = _feedQuery(request, chunks[i]);
            final after = last[i];
            if (after != null) {
              query = query.startAfterDocument(after);
            }
            return query.limit(limit).get();
          }(),
    ]);
    final candidates = <({int chunk, QueryDocumentSnapshot<Map<String, dynamic>> doc})>[];
    var fromCache = false;
    for (var i = 0; i < chunks.length; i++) {
      final snapshot = snapshots[i];
      if (snapshot == null) {
        continue;
      }
      fromCache = fromCache || snapshot.metadata.isFromCache;
      for (final doc in snapshot.docs) {
        candidates.add((chunk: i, doc: doc));
      }
    }
    candidates.sort(
      (a, b) => _timestamp(b.doc).compareTo(_timestamp(a.doc)),
    );
    final taken = candidates.take(limit).toList();
    final nextLast = [...last];
    final nextDone = [...done];
    for (var i = 0; i < chunks.length; i++) {
      final snapshot = snapshots[i];
      if (snapshot == null) {
        continue;
      }
      final mine = [
        for (final entry in taken)
          if (entry.chunk == i) entry.doc,
      ];
      if (mine.isNotEmpty) {
        nextLast[i] = mine.last;
      }
      nextDone[i] = snapshot.docs.length < limit &&
          mine.length == snapshot.docs.length;
    }
    final hasMore = nextDone.contains(false);
    return MomentsPage(
      items: [
        for (final entry in taken)
          _fromDoc(entry.doc, pending: entry.doc.metadata.hasPendingWrites),
      ],
      nextCursor: hasMore ? _FeedCursor(nextLast, nextDone) : null,
      hasMore: hasMore,
      isFromCache: fromCache,
    );
  }

  Future<MomentsPage> _scanPage(
    MomentFeedRequest request, {
    required _ScanCursor? cursor,
    required int limit,
  }) async {
    final scan = limit * 4;
    var query = _col.orderBy('createdAt', descending: true);
    final after = cursor?.last;
    if (after != null) {
      query = query.startAfterDocument(after);
    }
    final snapshot = await query.limit(scan).get();
    final authors = request.authorIds.toSet();
    final items = [
      for (final doc in snapshot.docs)
        if (doc.data()['kind'] == MomentModel.postKind &&
            (request.feed != MomentFeed.nearby ||
                doc.data()['cityId'] == request.cityId) &&
            (request.feed != MomentFeed.following ||
                authors.contains(doc.data()['authorUserId'])))
          _fromDoc(doc, pending: doc.metadata.hasPendingWrites),
    ];
    final hasMore = snapshot.docs.length >= scan;
    return MomentsPage(
      items: items,
      nextCursor: hasMore ? _ScanCursor(snapshot.docs.last) : null,
      hasMore: hasMore,
      isFromCache: snapshot.metadata.isFromCache,
    );
  }

  DateTime _timestamp(DocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()?['createdAt'];
    return value is Timestamp ? value.toDate() : DateTime.now();
  }

  @override
  Future<List<MomentModel>> fetchByIds(List<String> ids) async {
    final unique = ids.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (unique.isEmpty) {
      return const [];
    }
    final result = <MomentModel>[];
    for (var i = 0; i < unique.length; i += MomentFeedRequest.inQueryLimit) {
      final chunk = unique.sublist(
        i,
        i + MomentFeedRequest.inQueryLimit > unique.length
            ? unique.length
            : i + MomentFeedRequest.inQueryLimit,
      );
      final snapshot = await _col
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        result.add(_fromDoc(doc, pending: doc.metadata.hasPendingWrites));
      }
    }
    return result;
  }

  @override
  Future<List<MomentModel>> fetchByAuthor(
    String userId, {
    int limit = 60,
  }) async {
    if (userId.isEmpty) {
      return const [];
    }
    final byAuthor = _col.where('authorUserId', isEqualTo: userId);
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await byAuthor
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') {
        rethrow;
      }
      snapshot = await byAuthor.limit(limit).get();
    }
    return [
      for (final doc in snapshot.docs)
        _fromDoc(doc, pending: doc.metadata.hasPendingWrites),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> countByAuthor(String userId) async {
    if (userId.isEmpty) {
      return 0;
    }
    final aggregate = await _col
        .where('authorUserId', isEqualTo: userId)
        .count()
        .get();
    return aggregate.count ?? 0;
  }

  // --- Comments ------------------------------------------------------------

  @override
  Stream<List<MomentComment>> watchComments(
    String momentId, {
    int limit = 30,
  }) {
    return FirestoreAuthGuard.guardedStream<List<MomentComment>>(
      label: 'moments.watchComments',
      empty: const [],
      create: () => _comments(momentId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map(_commentFromDoc).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
          ),
    );
  }

  @override
  String newMomentId() => _col.doc().id;

  @override
  String newCommentId(String momentId) => _comments(momentId).doc().id;

  @override
  Future<void> setLike(String momentId, {required bool liked}) async {
    final uid = _requireUid();
    await _col.doc(momentId).update({
      'likes': liked
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<void> toggleLike(String momentId) async {
    final uid = _requireUid();
    final snap = await _col.doc(momentId).get();
    final likes = snap.data()?['likes'] as List? ?? const [];
    await setLike(momentId, liked: !likes.contains(uid));
  }

  @override
  Future<void> toggleCommentLike(String momentId, String commentId) async {
    final uid = _requireUid();
    final ref = _comments(momentId).doc(commentId);
    final snap = await ref.get();
    if (!snap.exists) {
      return;
    }
    final likes = snap.data()?['likes'] as List? ?? const [];
    await ref.update({
      'likes': likes.contains(uid)
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
  }

  @override
  Future<String> addComment(
    String momentId,
    String text, {
    String? commentId,
    String replyToCommentId = '',
    String replyToAuthorName = '',
  }) async {
    final trimmed = text.trim();
    final uid = _requireUid();
    if (trimmed.isEmpty) {
      throw StateError('Komentar je prazan.');
    }
    final id = (commentId ?? '').isEmpty ? newCommentId(momentId) : commentId!;
    final ref = _comments(momentId).doc(id);
    if (await _existsOnServer(ref)) {
      return id;
    }
    final batch = firestore.batch()
      ..set(ref, {
        'authorUserId': uid,
        'authorName': _resolveAuthorName(''),
        'text': trimmed.length > MomentComment.maxTextLength
            ? trimmed.substring(0, MomentComment.maxTextLength)
            : trimmed,
        'likes': <String>[],
        if (replyToCommentId.isNotEmpty) 'replyToCommentId': replyToCommentId,
        if (replyToCommentId.isNotEmpty)
          'replyToAuthorName': replyToAuthorName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(_col.doc(momentId), {
        'commentsCount': FieldValue.increment(1),
      });
    await batch.commit();
    return id;
  }

  @override
  Future<void> deleteComment(String momentId, String commentId) async {
    _requireUid();
    final ref = _comments(momentId).doc(commentId);
    final snap = await ref.get();
    if (!snap.exists) {
      return;
    }
    final batch = firestore.batch()
      ..delete(ref)
      ..update(_col.doc(momentId), {
        'commentsCount': FieldValue.increment(-1),
      });
    await batch.commit();
  }

  /// Retry guard: a previous attempt may have reached the server even though
  /// the client saw an error. Offline the check is skipped.
  Future<bool> _existsOnServer(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final snap = await ref.get(const GetOptions(source: Source.server));
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  // --- Create / delete -----------------------------------------------------

  @override
  Future<String> createMoment(MomentModel moment) async {
    final uid = _requireUid();
    var photo = moment.momentPhotoUrl.trim();
    if (photo.isEmpty) {
      throw StateError('Fotografija momenta nije otpremljena.');
    }
    // Legacy rows / bad uploads may store gs:// — convert before write.
    if (StorageService.isGsUri(photo)) {
      photo = await _storageService.resolveDownloadUrl(photo);
    }
    if (!(photo.startsWith('https://') || photo.startsWith('http://'))) {
      throw StateError('Fotografija momenta nije otpremljena.');
    }
    final id = moment.id.trim().isEmpty ? newMomentId() : moment.id.trim();
    final ref = _col.doc(id);
    if (await _existsOnServer(ref)) {
      return id;
    }
    final caption = moment.caption.trim();
    final avatar = moment.authorPhotoUrl.trim().isEmpty
        ? authorPhotoUrl.trim()
        : moment.authorPhotoUrl.trim();
    final dogId = moment.dogId.trim();
    await ref.set(<String, Object>{
      'kind': MomentModel.postKind,
      'authorUserId': uid,
      'authorName': _resolveAuthorName(moment.authorName),
      'authorPhotoUrl': avatar,
      'dogId': dogId,
      'dogName': dogId.isEmpty ? '' : moment.dogName.trim(),
      'dogBreed': dogId.isEmpty ? '' : moment.dogBreed.trim(),
      'dogPhotoUrl': dogId.isEmpty ? '' : moment.dogPhotoUrl.trim(),
      'momentPhotoUrl': photo,
      'mediaType': 'image',
      'caption': caption.length > MomentModel.maxCaptionLength
          ? caption.substring(0, MomentModel.maxCaptionLength)
          : caption,
      'locationName': moment.locationName.trim(),
      'cityId': moment.cityId.trim(),
      'likes': <String>[],
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  @override
  Future<void> deleteMoment(String momentId) async {
    final uid = _requireUid();
    final ref = _col.doc(momentId);
    final snap = await ref.get();
    if (!snap.exists) {
      return;
    }
    final data = snap.data() ?? const <String, dynamic>{};
    // Comments first: the moment's author / admin may delete them (rules).
    // Older deployed rules refuse other people's comments; the post is still
    // deleted and its comments are no longer reachable from the app.
    try {
      while (true) {
        final page = await _comments(momentId).limit(200).get();
        if (page.docs.isEmpty) {
          break;
        }
        final batch = firestore.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        if (page.docs.length < 200) {
          break;
        }
      }
    } catch (error) {
      debugPrint('Moment comments delete skipped: $error');
    }
    await ref.delete();
    if (data['authorUserId'] == uid) {
      await _storageService.tryDeleteImageByUrl(
        data['momentPhotoUrl'] as String?,
      );
    }
  }

  // --- Mapping -------------------------------------------------------------

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
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool pending,
  }) {
    return momentFromMap(
      doc.id,
      doc.data() ?? const {},
      pendingCreatedAt: pending ? DateTime.now() : null,
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
      likes: _strings(data['likes']),
      replyToCommentId: data['replyToCommentId'] as String? ?? '',
      replyToAuthorName: data['replyToAuthorName'] as String? ?? '',
    );
  }
}

/// Firestore map → [MomentModel]. Tolerates legacy documents (no `kind`,
/// `cityId`, `authorPhotoUrl`) and wrong types.
@visibleForTesting
MomentModel momentFromMap(
  String id,
  Map<String, dynamic> data, {
  DateTime? pendingCreatedAt,
}) {
  String text(String key) {
    final value = data[key];
    return value is String ? value.trim() : '';
  }

  final kind = data['kind'] == MomentModel.postKind
      ? MomentKind.post
      : MomentKind.legacy;
  final dogId = text('dogId');
  final dogName = text('dogName');
  final locationName = text('locationName');
  final momentPhotoUrl = text('momentPhotoUrl');
  final authorName = text('authorName');
  return MomentModel(
    id: id,
    kind: kind,
    authorUserId: text('authorUserId'),
    authorName: authorName.isEmpty ? 'Korisnik' : authorName,
    authorPhotoUrl: text('authorPhotoUrl'),
    dogId: dogId,
    dogName: dogName.isEmpty && dogId.isNotEmpty ? 'Pas' : dogName,
    dogBreed: text('dogBreed'),
    dogPhotoUrl: text('dogPhotoUrl'),
    momentPhotoUrl:
        momentPhotoUrl.isEmpty ? kFallbackDogPhotoUrl : momentPhotoUrl,
    caption: data['caption'] is String ? data['caption'] as String : '',
    locationName: locationName.isEmpty && kind == MomentKind.legacy
        ? 'Novi Sad'
        : locationName,
    cityId: text('cityId'),
    likes: _strings(data['likes']),
    commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
    createdAt: pendingCreatedAt ?? _date(data['createdAt']),
  );
}

List<String> _strings(Object? value) => [
      for (final item in value is List ? value : const [])
        if (item is String) item,
    ];

DateTime _date(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

class _FeedCursor {
  const _FeedCursor(this.last, this.done);

  final List<DocumentSnapshot<Map<String, dynamic>>?> last;
  final List<bool> done;
}

class _ScanCursor {
  const _ScanCursor(this.last);

  final DocumentSnapshot<Map<String, dynamic>> last;
}
