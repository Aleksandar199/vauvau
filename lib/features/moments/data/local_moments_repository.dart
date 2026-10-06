import 'dart:async';

import '../domain/moment_model.dart';
import '../domain/moments_repository.dart';
import 'seed_moments.dart';

class LocalMomentsRepository implements MomentsRepository {
  LocalMomentsRepository({
    required this.currentUserId,
    this.authorName = 'Ti',
    List<MomentModel>? seed,
  }) : _moments = List<MomentModel>.from(seed ?? SeedMoments.all) {
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

  final String currentUserId;
  final String authorName;
  final List<MomentModel> _moments;
  final Map<String, List<MomentComment>> _comments = {};
  final StreamController<List<MomentModel>> _momentsController =
      StreamController<List<MomentModel>>.broadcast();
  final Map<String, StreamController<List<MomentComment>>> _commentControllers =
      {};

  void dispose() {
    _momentsController.close();
    for (final controller in _commentControllers.values) {
      controller.close();
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
    final all = _sorted();
    final start = cursor is int ? cursor : limit;
    if (start >= all.length) {
      return const MomentsPage(items: [], hasMore: false);
    }
    final end = (start + limit).clamp(0, all.length);
    final slice = all.sublist(start, end);
    final next = end < all.length ? end : null;
    return MomentsPage(
      items: slice,
      nextCursor: next,
      hasMore: next != null,
    );
  }

  @override
  Stream<List<MomentComment>> watchComments(String momentId) async* {
    yield List<MomentComment>.from(_comments[momentId] ?? const []);
    yield* _commentController(momentId).stream;
  }

  @override
  Future<void> toggleLike(String momentId) async {
    if (currentUserId.isEmpty) {
      return;
    }
    for (var i = 0; i < _moments.length; i++) {
      final moment = _moments[i];
      if (moment.id != momentId) {
        continue;
      }
      final likes = [...moment.likes];
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
      }
      _moments[i] = moment.copyWith(likes: likes);
    }
    _momentsController.add(_sorted());
  }

  @override
  Future<void> addComment(String momentId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || currentUserId.isEmpty) {
      return;
    }
    final comment = MomentComment(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      authorUserId: currentUserId,
      authorName: authorName,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final next = [..._comments[momentId] ?? const <MomentComment>[], comment];
    _comments[momentId] = next;
    _commentController(momentId).add(List<MomentComment>.from(next));
    for (var i = 0; i < _moments.length; i++) {
      if (_moments[i].id == momentId) {
        _moments[i] = _moments[i].copyWith(commentsCount: next.length);
      }
    }
    _momentsController.add(_sorted());
  }

  @override
  Future<String> createMoment(MomentModel moment) async {
    final id = moment.id.isEmpty
        ? 'moment-${DateTime.now().millisecondsSinceEpoch}'
        : moment.id;
    _moments.insert(
      0,
      MomentModel(
        id: id,
        authorUserId: currentUserId,
        authorName: moment.authorName,
        dogId: moment.dogId,
        dogName: moment.dogName,
        dogBreed: moment.dogBreed,
        dogPhotoUrl: moment.dogPhotoUrl,
        momentPhotoUrl: moment.momentPhotoUrl,
        caption: moment.caption,
        locationName: moment.locationName,
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
    _moments.removeWhere((moment) => moment.id == momentId);
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
