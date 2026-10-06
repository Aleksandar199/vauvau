import 'dart:async';

import '../domain/content_report.dart';

class LocalReportRepository implements ReportRepository {
  LocalReportRepository({List<ContentReport>? seed}) : _items = [...?seed];

  final List<ContentReport> _items;
  final StreamController<List<ContentReport>> _controller =
      StreamController<List<ContentReport>>.broadcast();

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<ContentReport>> watchAll() async* {
    yield _sorted();
    yield* _controller.stream;
  }

  @override
  Future<void> submit(ContentReport report) async {
    _items.insert(0, report);
    _controller.add(_sorted());
  }

  @override
  Future<void> updateStatus({
    required String id,
    required ReportStatus status,
    String reporterId = '',
  }) async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == id) {
        _items[i] = _items[i].copyWith(status: status);
        break;
      }
    }
    _controller.add(_sorted());
  }

  List<ContentReport> _sorted() {
    return List<ContentReport>.from(_items)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
