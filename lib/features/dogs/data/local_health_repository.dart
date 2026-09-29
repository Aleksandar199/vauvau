import 'dart:async';

import '../domain/health_record.dart';
import '../domain/health_repository.dart';

/// In-memory health records used when Firebase is not configured.
class LocalHealthRepository implements HealthRepository {
  LocalHealthRepository({List<HealthRecord> seed = const []})
      : _records = List<HealthRecord>.from(seed);

  final List<HealthRecord> _records;
  final StreamController<List<HealthRecord>> _controller =
      StreamController<List<HealthRecord>>.broadcast();
  var _nextId = 1;

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<HealthRecord>> watchRecords(String dogId) async* {
    yield _forDog(dogId);
    yield* _controller.stream.map((_) => _forDog(dogId));
  }

  @override
  Future<String> saveRecord(HealthRecord record) async {
    final id = record.id.isEmpty ? 'health-${_nextId++}' : record.id;
    final stored = record.copyWith(id: id);
    final index = _records.indexWhere((item) => item.id == id);
    if (index == -1) {
      _records.add(stored);
    } else {
      _records[index] = stored;
    }
    _controller.add(const []);
    return id;
  }

  @override
  Future<void> deleteRecord({
    required String dogId,
    required String recordId,
  }) async {
    _records.removeWhere(
      (record) => record.dogId == dogId && record.id == recordId,
    );
    _controller.add(const []);
  }

  List<HealthRecord> _forDog(String dogId) {
    final records = [
      for (final record in _records)
        if (record.dogId == dogId) record,
    ]..sort((a, b) => b.administeredDate.compareTo(a.administeredDate));
    return records;
  }
}
