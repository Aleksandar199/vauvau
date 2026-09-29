import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_status.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/firestore_health_repository.dart';
import '../../data/local_health_repository.dart';
import '../../domain/health_record.dart';
import '../../domain/health_repository.dart';
import 'health_strings.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreHealthRepository(firestore: FirebaseFirestore.instance);
  }
  final repo = LocalHealthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final healthRecordsProvider =
    StreamProvider.family<List<HealthRecord>, String>((ref, dogId) {
  return ref.watch(healthRepositoryProvider).watchRecords(dogId);
});

/// Latest record per category, so each status card shows one entry.
final latestHealthRecordsProvider = Provider.family<
    Map<HealthCategory, HealthRecord>, String>((ref, dogId) {
  final records = ref.watch(healthRecordsProvider(dogId)).asData?.value;
  final latest = <HealthCategory, HealthRecord>{};
  for (final record in records ?? const <HealthRecord>[]) {
    final current = latest[record.category];
    if (current == null ||
        record.administeredDate.isAfter(current.administeredDate)) {
      latest[record.category] = record;
    }
  }
  return latest;
});

class HealthSaveResult {
  const HealthSaveResult({required this.recordId, required this.reminderSet});

  final String recordId;
  final bool reminderSet;
}

class HealthController {
  const HealthController(this._ref);

  final Ref _ref;

  /// Saves the record and keeps the scheduled reminder in sync: a reminder is
  /// (re)scheduled when asked for and the due date is still ahead, otherwise
  /// any previous reminder for the record is cancelled.
  Future<HealthSaveResult> save({
    required HealthRecord record,
    required String dogName,
    required bool withReminder,
  }) async {
    final repo = _ref.read(healthRepositoryProvider);
    final notifications = _ref.read(notificationServiceProvider);
    final recordId = await repo.saveRecord(record);
    final notificationId = HealthRecord.notificationIdFor(recordId);
    await notifications.cancelReminder(notificationId);

    final due = record.nextDueDate;
    var reminderSet = false;
    if (withReminder && due != null) {
      reminderSet = await notifications.scheduleHealthReminder(
        notificationId: notificationId,
        title: HealthStrings.reminderTitle(dogName),
        body: HealthStrings.reminderBody(dogName, record.title),
        scheduledDate: due,
      );
    }
    if (reminderSet != (record.notificationId == notificationId)) {
      try {
        await repo.saveRecord(
          record.copyWith(
            id: recordId,
            notificationId: reminderSet ? notificationId : null,
            clearNotificationId: !reminderSet,
          ),
        );
      } catch (error) {
        debugPrint('Health reminder id not stored: $error');
      }
    }
    return HealthSaveResult(recordId: recordId, reminderSet: reminderSet);
  }

  Future<void> delete(HealthRecord record) async {
    final notificationId = record.notificationId ??
        HealthRecord.notificationIdFor(record.id);
    await _ref.read(notificationServiceProvider).cancelReminder(notificationId);
    await _ref.read(healthRepositoryProvider).deleteRecord(
          dogId: record.dogId,
          recordId: record.id,
        );
  }
}

final healthControllerProvider = Provider<HealthController>(
  HealthController.new,
);
