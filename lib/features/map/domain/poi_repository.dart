import 'models/poi_model.dart';

abstract class PoiRepository {
  Stream<List<PoiModel>> watchAll();

  Future<void> upsert(PoiModel poi);
}
