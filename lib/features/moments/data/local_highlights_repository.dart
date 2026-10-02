import 'dart:async';

import '../domain/highlights_repository.dart';
import '../domain/story_highlight.dart';

class LocalHighlightsRepository implements HighlightsRepository {
  LocalHighlightsRepository({
    required this.currentUserId,
    List<StoryHighlight> seed = const [],
  }) {
    for (final item in seed) {
      _items[item.id] = item;
    }
  }

  final String currentUserId;
  final Map<String, StoryHighlight> _items = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void dispose() => _changes.close();

  List<StoryHighlight> _forDog(String dogId) =>
      sortHighlights(_items.values.where((item) => item.dogId == dogId));

  @override
  Stream<List<StoryHighlight>> watchForDog(String dogId) async* {
    yield _forDog(dogId);
    yield* _changes.stream.map((_) => _forDog(dogId));
  }

  @override
  Future<String> create(StoryHighlight highlight) async {
    final id = 'highlight-${DateTime.now().microsecondsSinceEpoch}';
    _items[id] = StoryHighlight(
      id: id,
      ownerId: currentUserId,
      dogId: highlight.dogId,
      title: highlight.title.trim(),
      momentIds: highlight.momentIds,
      coverMomentId: highlight.coverMomentId,
      order: highlight.order,
      createdAt: DateTime.now(),
    );
    _changes.add(null);
    return id;
  }

  @override
  Future<void> update(StoryHighlight highlight) async {
    if (_items.containsKey(highlight.id)) {
      _items[highlight.id] = highlight;
      _changes.add(null);
    }
  }

  @override
  Future<void> delete(StoryHighlight highlight) async {
    _items.remove(highlight.id);
    _changes.add(null);
  }

  @override
  Future<void> reorder(List<StoryHighlight> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      final item = _items[ordered[i].id];
      if (item != null) {
        _items[item.id] = item.copyWith(order: i);
      }
    }
    _changes.add(null);
  }
}
