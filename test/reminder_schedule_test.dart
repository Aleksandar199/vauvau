import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/services/notification_service.dart';
import 'package:vauvau/features/dogs/data/local_reminder_repository.dart';
import 'package:vauvau/features/dogs/domain/dog_reminder.dart';
import 'package:vauvau/features/dogs/domain/reminder_schedule.dart';
import 'package:vauvau/features/dogs/presentation/health/reminder_controller.dart';

class _RecordingNotificationService extends NotificationService {
  final List<DateTime> scheduled = [];
  final List<int> cancelled = [];

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> scheduleHealthReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    scheduled.add(scheduledDate);
    return true;
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    cancelled.add(notificationId);
  }
}

DogReminder _reminder({
  required DateTime date,
  required ReminderRepeat repeat,
  int? repeatDayOfMonth,
}) {
  return DogReminder(
    id: 'r1',
    dogId: 'dog-1',
    title: 'Test',
    type: ReminderType.ticksFleas,
    date: date,
    repeatType: repeat,
    repeatDayOfMonth: repeatDayOfMonth ?? date.day,
  );
}

void main() {
  group('ReminderSchedule.nextOccurrence', () {
    test('daily', () {
      expect(
        ReminderSchedule.nextOccurrence(
          DateTime(2026, 10, 10),
          ReminderRepeat.daily,
          dayOfMonth: 10,
        ),
        DateTime(2026, 10, 11),
      );
    });

    test('weekly', () {
      expect(
        ReminderSchedule.nextOccurrence(
          DateTime(2026, 10, 10),
          ReminderRepeat.weekly,
          dayOfMonth: 10,
        ),
        DateTime(2026, 10, 17),
      );
    });

    test('monthly', () {
      expect(
        ReminderSchedule.nextOccurrence(
          DateTime(2026, 10, 10),
          ReminderRepeat.monthly,
          dayOfMonth: 10,
        ),
        DateTime(2026, 11, 10),
      );
    });

    test('every 3 months', () {
      expect(
        ReminderSchedule.nextOccurrence(
          DateTime(2026, 10, 10),
          ReminderRepeat.every3Months,
          dayOfMonth: 10,
        ),
        DateTime(2027, 1, 10),
      );
    });

    test('every 6 months', () {
      expect(
        ReminderSchedule.nextOccurrence(
          DateTime(2026, 10, 10),
          ReminderRepeat.every6Months,
          dayOfMonth: 10,
        ),
        DateTime(2027, 4, 10),
      );
    });

    test('yearly across year boundary', () {
      expect(
        ReminderSchedule.nextOccurrence(
          DateTime(2026, 10, 10),
          ReminderRepeat.yearly,
          dayOfMonth: 10,
        ),
        DateTime(2027, 10, 10),
      );
    });

    test('monthly clamps 31 Jan through shorter months', () {
      final feb = ReminderSchedule.nextOccurrence(
        DateTime(2026, 1, 31),
        ReminderRepeat.monthly,
        dayOfMonth: 31,
      );
      expect(feb, DateTime(2026, 2, 28));

      final mar = ReminderSchedule.nextOccurrence(
        feb,
        ReminderRepeat.monthly,
        dayOfMonth: 31,
      );
      expect(mar, DateTime(2026, 3, 31));
    });

    test('monthly clamps 31 Jan in leap year to 29 Feb', () {
      expect(
        ReminderSchedule.nextOccurrence(
          DateTime(2024, 1, 31),
          ReminderRepeat.monthly,
          dayOfMonth: 31,
        ),
        DateTime(2024, 2, 29),
      );
    });
  });

  group('advanceToUpcoming / rolledForward', () {
    test('skips multiple missed monthly cycles', () {
      final next = ReminderSchedule.advanceToUpcoming(
        DateTime(2026, 10, 10),
        ReminderRepeat.monthly,
        DateTime(2026, 12, 20),
        dayOfMonth: 10,
      );
      expect(next, DateTime(2027, 1, 10));
    });

    test('rolledForward sets lastCompletedDate to last past occurrence', () {
      final rolled = _reminder(
        date: DateTime(2026, 10, 10),
        repeat: ReminderRepeat.monthly,
      ).rolledForward(DateTime(2026, 12, 20));

      expect(rolled.date, DateTime(2027, 1, 10));
      expect(rolled.lastCompletedDate, DateTime(2026, 12, 10));
    });

    test('does not advance on the due day itself', () {
      final rolled = _reminder(
        date: DateTime(2026, 10, 10),
        repeat: ReminderRepeat.monthly,
      ).rolledForward(DateTime(2026, 10, 10, 15, 30));

      expect(rolled.date, DateTime(2026, 10, 10));
      expect(rolled.lastCompletedDate, isNull);
    });

    test('once does not advance', () {
      final once = _reminder(
        date: DateTime(2026, 10, 1),
        repeat: ReminderRepeat.once,
      ).rolledForward(DateTime(2026, 12, 20));

      expect(once.date, DateTime(2026, 10, 1));
    });

    test('custom advances by default 2-week interval', () {
      final next = ReminderSchedule.advanceToUpcoming(
        DateTime(2026, 10, 1),
        ReminderRepeat.custom,
        DateTime(2026, 10, 20),
        dayOfMonth: 1,
        customIntervalCount: DogReminder.defaultCustomIntervalCount,
        customIntervalUnit: CustomRepeatUnit.weeks,
      );
      // 01.10 + 14 = 15.10 (past), +14 = 29.10
      expect(next, DateTime(2026, 10, 29));
    });

    test('custom months advances by calendar months', () {
      final next = ReminderSchedule.nextOccurrence(
        DateTime(2026, 1, 31),
        ReminderRepeat.custom,
        dayOfMonth: 31,
        customIntervalCount: 1,
        customIntervalUnit: CustomRepeatUnit.months,
      );
      expect(next, DateTime(2026, 2, 28));
    });

    test('daily advances across many missed days', () {
      final next = ReminderSchedule.advanceToUpcoming(
        DateTime(2026, 10, 10),
        ReminderRepeat.daily,
        DateTime(2026, 10, 15),
        dayOfMonth: 10,
      );
      expect(next, DateTime(2026, 10, 15));
    });

    test('weekly advances across missed weeks', () {
      final next = ReminderSchedule.advanceToUpcoming(
        DateTime(2026, 10, 10),
        ReminderRepeat.weekly,
        DateTime(2026, 11, 1),
        dayOfMonth: 10,
      );
      expect(next, DateTime(2026, 11, 7));
    });

    test('preserves day-of-month after Feb clamp', () {
      final rolled = _reminder(
        date: DateTime(2026, 1, 31),
        repeat: ReminderRepeat.monthly,
        repeatDayOfMonth: 31,
      ).rolledForward(DateTime(2026, 3, 1));

      // Jan 31 and Feb 28 both passed; next is Mar 31.
      expect(rolled.date, DateTime(2026, 3, 31));
      expect(rolled.lastCompletedDate, DateTime(2026, 2, 28));
    });
  });

  test('rollForwardDueReminders persists next date and reschedules', () async {
    final repo = LocalReminderRepository(
      seed: [
        _reminder(
          date: DateTime(2026, 10, 10),
          repeat: ReminderRepeat.monthly,
        ),
      ],
    );
    addTearDown(repo.dispose);
    final notifications = _RecordingNotificationService();
    final container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWith((ref) => repo),
        notificationServiceProvider.overrideWith((ref) => notifications),
      ],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(reminderControllerProvider).rollForwardDueReminders(
              await repo.watchReminders('dog-1').first,
              now: DateTime(2026, 12, 20),
              dogName: 'Leo',
            );

    expect(result.single.date, DateTime(2027, 1, 10));
    final stored = await repo.watchReminders('dog-1').first;
    expect(stored.single.date, DateTime(2027, 1, 10));
    expect(stored.single.lastCompletedDate, DateTime(2026, 12, 10));
    expect(notifications.cancelled, isNotEmpty);
    expect(notifications.scheduled, isNotEmpty);
  });
}
