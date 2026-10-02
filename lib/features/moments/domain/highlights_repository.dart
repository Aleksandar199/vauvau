import 'story_highlight.dart';

abstract class HighlightsRepository {
  Stream<List<StoryHighlight>> watchForDog(String dogId);

  Future<String> create(StoryHighlight highlight);

  Future<void> update(StoryHighlight highlight);

  Future<void> delete(StoryHighlight highlight);

  Future<void> reorder(List<StoryHighlight> ordered);
}

List<StoryHighlight> sortHighlights(Iterable<StoryHighlight> items) {
  final list = items.toList()
    ..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.createdAt.compareTo(b.createdAt);
    });
  return list;
}
