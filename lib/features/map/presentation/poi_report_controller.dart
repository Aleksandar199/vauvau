import 'package:flutter_riverpod/flutter_riverpod.dart';

class PoiReports extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void report(String id) {
    state = {...state, id};
  }
}

final poiReportsProvider =
    NotifierProvider<PoiReports, Set<String>>(PoiReports.new);
