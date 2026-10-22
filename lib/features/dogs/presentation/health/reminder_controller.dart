import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_status.dart';
import '../../../../core/services/notification_service.dart';
import '../../../rewards/data/birthday_reward_source.dart';
import '../../../rewards/domain/birthday_reward.dart';
import '../../data/firestore_reminder_repository.dart';
import '../../data/local_reminder_repository.dart';
import '../../domain/birthday_greeting.dart';
import '../../domain/dog_reminder.dart';
import '../../domain/reminder_repository.dart';
import '../../domain/reminder_schedule.dart';
import '../dog_providers.dart';
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
    final reminderId = await repo.saveReminder(normalized);
    final notificationId = DogReminder.notificationIdFor(reminderId);
    final stored = normalized.copyWith(id: reminderId);
    final reminderSet = await _schedule(stored, dogName);

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

  /// (Re)schedules the local notifications of a saved reminder: the reminder
  /// itself on its notify date, plus the birthday greeting. Scheduling the
  /// same id again replaces it, so this is safe to repeat.
  Future<bool> _schedule(DogReminder stored, String dogName) async {
    final notifications = _ref.read(notificationServiceProvider);
    final notificationId = DogReminder.notificationIdFor(stored.id);
    await notifications.cancelReminder(notificationId);
    final greetingSet = await _scheduleBirthdayGreeting(stored, dogName);
    if (greetingSet && BirthdayGreeting.reminderIsSameDay(stored)) {
      // Offset "na dan": the greeting replaces the plain reminder.
      return true;
    }
    if (stored.isCompleted) {
      return false;
    }
    return notifications.scheduleHealthReminder(
      notificationId: notificationId,
      title: ReminderStrings.typeShortLabel(stored.type),
      body: '$dogName: ${stored.title} — ${ReminderStrings.date(stored.date)}',
      scheduledDate: stored.notifyDate,
    );
  }

  /// App start: local notifications live only on this phone (lost after a
  /// reinstall or on a new phone, missing for reminders saved on another
  /// device). Re-creates them from the stored reminders; repeating reminders
  /// whose date has passed move to the next occurrence (saved once).
  Future<void> resync(
    List<DogReminder> items, {
    required String dogName,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    for (final item in items) {
      if (item.id.isEmpty) continue;
      try {
        final rolled = item.rolledForward(clock);
        if (!_sameDay(rolled.date, item.date)) {
          await save(reminder: rolled, dogName: dogName);
        } else {
          await _schedule(item, dogName);
        }
      } catch (error) {
        debugPrint('Reminder resync failed for ${item.id}: $error');
      }
    }
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

  /// Birthday reminders also get a "Srećan rođendan" notification at 09:00 on
  /// the birthday itself (cancelled for other types, completed or deleted
  /// reminders). Mentions the partner gift only when `app_config/birthday`
  /// turns it on. Returns whether the greeting was scheduled.
  Future<bool> _scheduleBirthdayGreeting(
    DogReminder reminder,
    String dogName,
  ) async {
    final notifications = _ref.read(notificationServiceProvider);
    final greetingId = BirthdayGreeting.notificationIdFor(reminder.id);
    await notifications.cancelReminder(greetingId);
    if (!BirthdayGreeting.appliesTo(reminder)) {
      return false;
    }
    // Roll-forward to next year saves without a name: use my dog's name.
    var name = dogName.trim();
    if (name.isEmpty) {
      final dogs = _ref.read(ownerDogsProvider).value ?? const [];
      for (final dog in dogs) {
        if (dog.id == reminder.dogId) {
          name = dog.name;
        }
      }
    }
    var reward = BirthdayRewardConfig.disabled;
    try {
      reward = await _ref.read(birthdayRewardConfigProvider.future);
    } catch (_) {
      // No gift info: the greeting is still sent.
    }
    return notifications.scheduleHealthReminder(
      notificationId: greetingId,
      title: ReminderStrings.birthdayGreetingTitle(name),
      body: ReminderStrings.birthdayGreetingBody(
        name,
        hasReward: reward.isActive,
        rewardPartner: reward.partnerName,
      ),
      scheduledDate: BirthdayGreeting.greetingDay(reminder),
    );
  }

  Future<void> delete(DogReminder reminder) async {
    final notificationId =
        reminder.notificationId ?? DogReminder.notificationIdFor(reminder.id);
    await _ref.read(notificationServiceProvider).cancelReminder(notificationId);
    await _ref
        .read(notificationServiceProvider)
        .cancelReminder(BirthdayGreeting.notificationIdFor(reminder.id));
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
