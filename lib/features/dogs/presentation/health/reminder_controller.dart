import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_status.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/firestore_reminder_repository.dart';
import '../../data/local_reminder_repository.dart';
import '../../domain/dog_reminder.dart';
import '../../domain/reminder_repository.dart';
import '../../domain/reminder_schedule.dart';
import 'reminder_strings.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  if (isFirebaseReady) {
    return FirestoreReminderRepository(firestore: FirebaseFirestore.instance);
  }
  final repo = LocalReminderRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final dogRemindersProvider =
    StreamProvider.family<List<DogReminder>, String>((ref, dogId) {
  final repo = ref.watch(reminderRepositoryProvider);
  final controller = ref.watch(reminderControllerProvider);
  return repo.watchReminders(dogId).asyncMap(controller.rollForwardDueReminders);
});

/// Active reminders for one dog, soonest first.
final activeDogRemindersProvider =
    Provider.family<List<DogReminder>, String>((ref, dogId) {
  final items = ref.watch(dogRemindersProvider(dogId)).asData?.value ??
      const <DogReminder>[];
  final active = [
    for (final item in items)
      if (item.isActive) item,
  ]..sort((a, b) => a.date.compareTo(b.date));
  return active;
});

class ReminderDogRef {
  const ReminderDogRef({required this.id, required this.name});

  final String id;
  final String name;
}

class ReminderSaveResult {
  const ReminderSaveResult({
    required this.reminderId,
    required this.reminderSet,
  });

  final String reminderId;
  final bool reminderSet;
}

class ReminderController {
  const ReminderController(this._ref);

  final Ref _ref;

  Future<ReminderSaveResult> save({
    required DogReminder reminder,
    required String dogName,
  }) async {
    final normalized = reminder.copyWith(
      repeatDayOfMonth: reminder.repeatDayOfMonth ?? reminder.date.day,
      customIntervalCount: reminder.customIntervalCount > 0
          ? reminder.customIntervalCount
          : DogReminder.defaultCustomIntervalCount,
      customIntervalUnit: reminder.customIntervalUnit,
    );
    final repo = _ref.read(reminderRepositoryProvider);
    final notifications = _ref.read(notificationServiceProvider);
    final reminderId = await repo.saveReminder(normalized);
    final notificationId = DogReminder.notificationIdFor(reminderId);
    await notifications.cancelReminder(notificationId);

    final stored = normalized.copyWith(id: reminderId);
    var reminderSet = false;
    if (!stored.isCompleted) {
      reminderSet = await notifications.scheduleHealthReminder(
        notificationId: notificationId,
        title: ReminderStrings.typeShortLabel(stored.type),
        body:
            '$dogName: ${stored.title} — ${ReminderStrings.date(stored.date)}',
        scheduledDate: stored.notifyDate,
      );
    }

    final shouldStoreId = reminderSet;
    final currentlyStored = reminder.notificationId == notificationId;
    if (shouldStoreId != currentlyStored || reminder.id.isEmpty) {
      try {
        await repo.saveReminder(
          stored.copyWith(
            notificationId: shouldStoreId ? notificationId : null,
            clearNotificationId: !shouldStoreId,
          ),
        );
      } catch (error) {
        debugPrint('Reminder notification id not stored: $error');
      }
    }

    return ReminderSaveResult(
      reminderId: reminderId,
      reminderSet: reminderSet,
    );
  }

  /// Rolls repeating reminders whose date is in the past up to the next
  /// upcoming occurrence, persists the change, and reschedules notifications.
  ///
  /// Safe to call on every stream emission — only writes when the date moves.
  Future<List<DogReminder>> rollForwardDueReminders(
    List<DogReminder> items, {
    DateTime? now,
    String dogName = '',
  }) async {
    final clock = now ?? DateTime.now();
    final result = <DogReminder>[];
    for (final item in items) {
      final rolled = item.rolledForward(clock);
      final dateChanged = !_sameDay(rolled.date, item.date);
      if (!dateChanged || rolled.id.isEmpty) {
        result.add(dateChanged ? rolled : item);
        continue;
      }
      try {
        await save(reminder: rolled, dogName: dogName);
        result.add(rolled);
      } catch (error) {
        debugPrint('Reminder roll-forward failed for ${item.id}: $error');
        result.add(item);
      }
    }
    return result;
  }

  Future<void> delete(DogReminder reminder) async {
    final notificationId =
        reminder.notificationId ?? DogReminder.notificationIdFor(reminder.id);
    await _ref.read(notificationServiceProvider).cancelReminder(notificationId);
    await _ref.read(reminderRepositoryProvider).deleteReminder(
          dogId: reminder.dogId,
          reminderId: reminder.id,
        );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final reminderControllerProvider = Provider<ReminderController>(
  ReminderController.new,
);
