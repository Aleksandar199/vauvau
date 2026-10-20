import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../domain/lost_dog.dart';
import '../domain/lost_dog_repository.dart';

class LocalLostDogRepository implements LostDogRepository {
  LocalLostDogRepository({
    List<LostDog>? seed,
    this.currentUserId = 'local-user',
  }) : _dogs = List<LostDog>.from(seed ?? const []);

  final String currentUserId;
  final List<LostDog> _dogs;
  final Map<String, List<LostDogComment>> _comments = {};
  final _controller = StreamController<List<LostDog>>.broadcast();
  final Map<String, StreamController<List<LostDogComment>>>
  _commentControllers = {};

  void dispose() {
    _controller.close();
    for (final controller in _commentControllers.values) {
      controller.close();
    }
  }

  @override
  Stream<List<LostDog>> watchLostDogs() async* {
    yield List<LostDog>.from(_dogs);
    yield* _controller.stream;
  }

  @override
  Stream<List<LostDog>> watchLostDogsInCity(String cityId) {
    return watchLostDogs().map(
      (dogs) => [
        for (final dog in dogs)
          if (dog.cityId == cityId) dog,
      ],
    );
  }

  @override
  Stream<List<LostDogComment>> watchComments(String dogId) async* {
    yield List<LostDogComment>.from(_comments[dogId] ?? const []);
    yield* _commentController(dogId).stream;
  }

  @override
  Future<void> reportLostDog(LostDog dog, {XFile? photo}) async {
    final id = dog.id.isEmpty
        ? 'lost-${DateTime.now().millisecondsSinceEpoch}'
        : dog.id;
    _dogs.insert(0, dog.copyWith(id: id, imageUrl: dog.imageUrl));
    _controller.add(List<LostDog>.from(_dogs));
  }

  @override
  Future<void> addComment(
    String dogId,
    String text, {
    String authorName = '',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final comment = LostDogComment(
      id: 'c-${DateTime.now().microsecondsSinceEpoch}',
      authorUserId: currentUserId,
      authorName: authorName.trim().isEmpty ? 'Ti' : authorName.trim(),
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final next = [..._comments[dogId] ?? const <LostDogComment>[], comment];
    _comments[dogId] = next;
    _commentController(dogId).add(List<LostDogComment>.from(next));
  }

  @override
  Future<void> toggleCommentLike(String dogId, String commentId) async {
    if (currentUserId.isEmpty) {
      return;
    }
    final comments = _comments[dogId];
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
    _comments[dogId] = next;
    _commentController(dogId).add(List<LostDogComment>.from(next));
  }

  @override
  Future<void> markFound(String id) async {
    for (var i = 0; i < _dogs.length; i++) {
      if (_dogs[i].id == id) {
        _dogs[i] = _dogs[i].copyWith(status: LostDogStatus.resolved);
      }
    }
    _controller.add(List<LostDog>.from(_dogs));
  }

  @override
  Future<void> deleteLostDog(String id) async {
    _dogs.removeWhere((dog) => dog.id == id);
    _comments.remove(id);
    _controller.add(List<LostDog>.from(_dogs));
  }

  StreamController<List<LostDogComment>> _commentController(String dogId) {
    return _commentControllers.putIfAbsent(
      dogId,
      StreamController<List<LostDogComment>>.broadcast,
    );
  }
}
