import 'dart:async';

import '../domain/moment_model.dart';
import '../domain/moments_repository.dart';
import 'seed_moments.dart';

/// In-memory moments (tests, and the app without Firebase). Pass
/// `seed: const []` for an empty store. Permissions are checked by
/// firestore.rules; the UI offers delete only to the author / admin.
class LocalMomentsRepository implements MomentsRepository {
  LocalMomentsRepository({
    required this.currentUserId,
    this.authorName = 'Ti',
    this.authorPhotoUrl = '',
    List<MomentModel>? seed,
    Map<String, List<MomentComment>>? comments,
  }) : _moments = List<MomentModel>.from(seed ?? SeedMoments.all) {
    if (comments != null) {
      _comments.addAll(comments);
    } else if (seed == null) {
      _comments['moment-liman'] = [
        MomentComment(
          id: 'c1',
          authorUserId: 'seed-ana',
          authorName: 'Ana',
          text: 'Kakva ekipa, vidimo se sutra! 🐾',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ];
    }
  }

  final String currentUserId;
  final String authorName;
  final String authorPhotoUrl;
  final List<MomentModel> _moments;
  final Map<String, List<MomentComment>> _comments = {};
  final StreamController<List<MomentModel>> _momentsController =
      StreamController<List<MomentModel>>.broadcast();
  final Map<String, StreamController<List<MomentComment>>> _commentControllers =
      {};
  var _ids = 0;

  /// Test hook: the next write throws this once (simulated network error).
  Object? failNextWrite;

  /// How many feed pages were read (pagination tests).
  int feedReads = 0;

  List<MomentModel> get moments => _sorted();

  List<MomentComment> commentsOf(String momentId) =>
      List.unmodifiable(_comments[momentId] ?? const <MomentComment>[]);

  void dispose() {
    _momentsController.close();
    for (final controller in _commentControllers.values) {
      controller.close();
    }
  }

  void _maybeFail() {
    final error = failNextWrite;
    if (error != null) {
      failNextWrite = null;
      throw error;
    }
  }

  @override
  Stream<List<MomentModel>> watchMoments({int limit = 20}) async* {
    yield _sorted().take(limit).toList();
    yield* _momentsController.stream.map((items) => items.take(limit).toList());
  }

  @override
  Future<MomentsPage> fetchMomentsPage({
    Object? cursor,
    int limit = 20,
  }) async {
    return _page(_sorted(), cursor is int ? cursor : limit, limit);
  }

  MomentsPage _page(List<MomentModel> all, int start, int limit) {
    if (start >= all.length) {
      return const MomentsPage(items: [], hasMore: false);
    }
    final end = (start + limit).clamp(0, all.length);
    final next = end < all.length ? end : null;
    return MomentsPage(
      items: all.sublist(start, end),
      nextCursor: next,
      hasMore: next != null,
    );
  }

  @override
  Future<MomentsPage> fetchFeedPage(
    MomentFeedRequest request, {
    Object? cursor,
    int limit = 10,
  }) async {
    feedReads++;
    final authors = request.authorIds.toSet();
    final matching = [
      for (final moment in _sorted())
        if (moment.isPost &&
            (request.feed != MomentFeed.nearby ||
                (request.cityId.isNotEmpty &&
                    moment.cityId == request.cityId)) &&
            (request.feed != MomentFeed.following ||
                authors.contains(moment.authorUserId)))
          moment,
    ];
    return _page(matching, cursor is int ? cursor : 0, limit);
  }

  @override
  Future<List<MomentModel>> fetchByIds(List<String> ids) async {
    final wanted = ids.toSet();
    return [
      for (final moment in _moments)
        if (wanted.contains(moment.id)) moment,
    ];
  }

  @override
  Future<List<MomentModel>> fetchByAuthor(
    String userId, {
    int limit = 60,
  }) async {
    return [
      for (final moment in _sorted())
        if (moment.authorUserId == userId) moment,
    ].take(limit).toList();
  }

  @override
  Future<int> countByAuthor(String userId) async =>
      _moments
          .where((moment) => moment.authorUserId == userId && moment.isPost)
          .length;

  @override
  Stream<List<MomentComment>> watchComments(
    String momentId, {
    int limit = 30,
  }) async* {
    List<MomentComment> latest(List<MomentComment> all) {
      final sorted = [...all]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return sorted.length <= limit
          ? sorted
          : sorted.sublist(sorted.length - limit);
    }

    yield latest(_comments[momentId] ?? const []);
    yield* _commentController(momentId).stream.map(latest);
  }

  @override
  String newMomentId() =>
      'moment-${DateTime.now().microsecondsSinceEpoch}-${_ids++}';

  @override
  String newCommentId(String momentId) =>
      'c-${DateTime.now().microsecondsSinceEpoch}-${_ids++}';

  @override
  Future<void> setLike(String momentId, {required bool liked}) async {
    if (currentUserId.isEmpty) {
      return;
    }
    _maybeFail();
    for (var i = 0; i < _moments.length; i++) {
      final moment = _moments[i];
      if (moment.id != momentId) {
        continue;
      }
      final likes = [
        for (final id in moment.likes)
          if (id != currentUserId) id,
        if (liked) currentUserId,
      ];
      _moments[i] = moment.copyWith(likes: likes);
    }
    _momentsController.add(_sorted());
  }

  @override
  Future<void> toggleLike(String momentId) async {
    final moment = _moments.where((item) => item.id == momentId).firstOrNull;
    if (moment == null) {
      return;
    }
    await setLike(momentId, liked: !moment.isLikedBy(currentUserId));
  }

  @override
  Future<void> toggleCommentLike(String momentId, String commentId) async {
    if (currentUserId.isEmpty) {
      return;
    }
    final comments = _comments[momentId];
    if (comments == null) {
      return;
    }
    final next = [
      for (final comment in comments)
        if (comment.id == commentId)
          comment.copyWith(
            likes: comment.isLikedBy(currentUserId)
                ? [
                    for (final id in comment.likes)
                      if (id != currentUserId) id,
                  ]
                : [...comment.likes, currentUserId],
          )
        else
          comment,
    ];
    _comments[momentId] = next;
    _commentController(momentId).add(List<MomentComment>.from(next));
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
    if (trimmed.isEmpty || currentUserId.isEmpty) {
      throw StateError('Komentar je prazan.');
    }
    final id = (commentId ?? '').isEmpty ? newCommentId(momentId) : commentId!;
    final existing = _comments[momentId] ?? const <MomentComment>[];
    if (existing.any((comment) => comment.id == id)) {
      return id;
    }
    _maybeFail();
    final comment = MomentComment(
      id: id,
      authorUserId: currentUserId,
      authorName: authorName,
      text: trimmed,
      createdAt: DateTime.now(),
      replyToCommentId: replyToCommentId,
      replyToAuthorName: replyToAuthorName,
    );
    final next = [...existing, comment];
    _comments[momentId] = next;
    _commentController(momentId).add(List<MomentComment>.from(next));
    _bumpComments(momentId, 1);
    return id;
  }

  @override
  Future<void> deleteComment(String momentId, String commentId) async {
    final comments = _comments[momentId] ?? const <MomentComment>[];
    final comment = comments.where((item) => item.id == commentId).firstOrNull;
    if (comment == null) {
      return;
    }
    final next = [
      for (final item in comments)
        if (item.id != commentId) item,
    ];
    _comments[momentId] = next;
    _commentController(momentId).add(List<MomentComment>.from(next));
    _bumpComments(momentId, -1);
  }

  void _bumpComments(String momentId, int delta) {
    for (var i = 0; i < _moments.length; i++) {
      if (_moments[i].id == momentId) {
        final count = _moments[i].commentsCount + delta;
        _moments[i] = _moments[i].copyWith(commentsCount: count < 0 ? 0 : count);
      }
    }
    _momentsController.add(_sorted());
  }

  @override
  Future<String> createMoment(MomentModel moment) async {
    final id = moment.id.isEmpty ? newMomentId() : moment.id;
    if (_moments.any((item) => item.id == id)) {
      return id;
    }
    _maybeFail();
    _moments.insert(
      0,
      MomentModel(
        id: id,
        kind: moment.kind,
        authorUserId: currentUserId,
        authorName: moment.authorName,
        authorPhotoUrl: moment.authorPhotoUrl.isEmpty
            ? authorPhotoUrl
            : moment.authorPhotoUrl,
        dogId: moment.dogId,
        dogName: moment.dogName,
        dogBreed: moment.dogBreed,
        dogPhotoUrl: moment.dogPhotoUrl,
        momentPhotoUrl: moment.momentPhotoUrl,
        caption: moment.caption,
        locationName: moment.locationName,
        cityId: moment.cityId,
        mediaType: moment.mediaType,
        likes: const [],
        commentsCount: 0,
        createdAt: DateTime.now(),
      ),
    );
    _momentsController.add(_sorted());
    return id;
  }

  @override
  Future<void> deleteMoment(String momentId) async {
    _moments.removeWhere((item) => item.id == momentId);
    _comments.remove(momentId);
    _momentsController.add(_sorted());
  }

  StreamController<List<MomentComment>> _commentController(String momentId) {
    return _commentControllers.putIfAbsent(
      momentId,
      StreamController<List<MomentComment>>.broadcast,
    );
  }

  List<MomentModel> _sorted() {
    final copy = List<MomentModel>.from(_moments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }
}
