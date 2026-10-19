import 'dart:async';

/// Collects ids requested in the same frame and fetches them with one call
/// (e.g. one `whereIn` query for all names on a list), caching results.
class BatchedLoader<T> {
  BatchedLoader(this._fetch);

  final Future<Map<String, T>> Function(Set<String> ids) _fetch;
  final Map<String, T> _cache = {};
  final Map<String, Completer<T>> _pending = {};
  Timer? _timer;

  T? cached(String id) => _cache[id];

  Future<T> load(String id) {
    final hit = _cache[id];
    if (hit != null) return Future.value(hit);
    final waiting = _pending[id];
    if (waiting != null) return waiting.future;
    final completer = Completer<T>();
    _pending[id] = completer;
    _timer ??= Timer(Duration.zero, _flush);
    return completer.future;
  }

  /// Forgets [id] (after an admin edit) so the next load reads it again.
  void invalidate(String id) => _cache.remove(id);

  Future<void> _flush() async {
    _timer = null;
    final batch = Map.of(_pending);
    _pending.clear();
    try {
      final result = await _fetch(batch.keys.toSet());
      for (final entry in batch.entries) {
        final value = result[entry.key];
        if (value == null) {
          entry.value.completeError(StateError('missing ${entry.key}'));
          continue;
        }
        _cache[entry.key] = value;
        entry.value.complete(value);
      }
    } catch (error, stack) {
      for (final completer in batch.values) {
        completer.completeError(error, stack);
      }
    }
  }
}
