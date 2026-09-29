import 'health_record.dart';

abstract class HealthRepository {
  Stream<List<HealthRecord>> watchRecords(String dogId);

  /// Creates or replaces the record and returns the stored document id.
  Future<String> saveRecord(HealthRecord record);

  Future<void> deleteRecord({required String dogId, required String recordId});
}
