import 'dog_reminder.dart';

/// Pure scheduling helpers for repeating [DogReminder]s.
abstract final class ReminderSchedule {
  static bool isRepeating(
    ReminderRepeat repeat, {
    int customIntervalDays = DogReminder.defaultCustomIntervalDays,
  }) {
    return switch (repeat) {
      ReminderRepeat.once => false,
      ReminderRepeat.custom => customIntervalDays > 0,
      ReminderRepeat.daily ||
      ReminderRepeat.weekly ||
      ReminderRepeat.monthly ||
      ReminderRepeat.every3Months ||
      ReminderRepeat.every6Months ||
      ReminderRepeat.yearly =>
        true,
    };
  }

  /// Next single occurrence after [from] (not necessarily in the future).
  static DateTime nextOccurrence(
    DateTime from,
    ReminderRepeat repeat, {
    required int dayOfMonth,
    int customIntervalDays = DogReminder.defaultCustomIntervalDays,
  }) {
    final day = DateTime(from.year, from.month, from.day);
    return switch (repeat) {
      ReminderRepeat.once => day,
      ReminderRepeat.custom => DateTime(
          day.year,
          day.month,
          day.day + (customIntervalDays > 0
              ? customIntervalDays
              : DogReminder.defaultCustomIntervalDays),
        ),
      // Calendar-day math (not Duration) avoids DST off-by-one shifts.
      ReminderRepeat.daily => DateTime(day.year, day.month, day.day + 1),
      ReminderRepeat.weekly => DateTime(day.year, day.month, day.day + 7),
      ReminderRepeat.monthly => addMonths(day, 1, dayOfMonth: dayOfMonth),
      ReminderRepeat.every3Months =>
        addMonths(day, 3, dayOfMonth: dayOfMonth),
      ReminderRepeat.every6Months =>
        addMonths(day, 6, dayOfMonth: dayOfMonth),
      ReminderRepeat.yearly => addYears(day, 1, dayOfMonth: dayOfMonth),
    };
  }

  /// Advances [from] until the occurrence is on or after [now]'s calendar day.
  static DateTime advanceToUpcoming(
    DateTime from,
    ReminderRepeat repeat,
    DateTime now, {
    required int dayOfMonth,
    int customIntervalDays = DogReminder.defaultCustomIntervalDays,
  }) {
    if (!isRepeating(repeat, customIntervalDays: customIntervalDays)) {
      return DateTime(from.year, from.month, from.day);
    }
    final today = DateTime(now.year, now.month, now.day);
    var current = DateTime(from.year, from.month, from.day);
    var guard = 0;
    while (current.isBefore(today) && guard < 10000) {
      current = nextOccurrence(
        current,
        repeat,
        dayOfMonth: dayOfMonth,
        customIntervalDays: customIntervalDays,
      );
      guard++;
    }
    return current;
  }

  static DateTime addMonths(
    DateTime from,
    int months, {
    required int dayOfMonth,
  }) {
    final totalMonths = from.year * 12 + (from.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = dayOfMonth > daysInMonth ? daysInMonth : dayOfMonth;
    return DateTime(year, month, day);
  }

  static DateTime addYears(
    DateTime from,
    int years, {
    required int dayOfMonth,
  }) {
    final year = from.year + years;
    final month = from.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = dayOfMonth > daysInMonth ? daysInMonth : dayOfMonth;
    return DateTime(year, month, day);
  }
}

extension DogReminderScheduleX on DogReminder {
  int get effectiveRepeatDayOfMonth => repeatDayOfMonth ?? date.day;

  int get effectiveCustomIntervalDays =>
      customIntervalDays > 0
          ? customIntervalDays
          : DogReminder.defaultCustomIntervalDays;

  /// Returns this reminder with [date] rolled to the next upcoming occurrence
  /// when the current date has passed and [repeatType] is repeating.
  DogReminder rolledForward(DateTime now) {
    if (isCompleted ||
        !ReminderSchedule.isRepeating(
          repeatType,
          customIntervalDays: effectiveCustomIntervalDays,
        )) {
      return this;
    }
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);
    if (!current.isBefore(today)) {
      return this;
    }

    final dayOfMonth = effectiveRepeatDayOfMonth;
    final intervalDays = effectiveCustomIntervalDays;
    DateTime? lastCompleted;
    var cursor = current;
    var guard = 0;
    while (cursor.isBefore(today) && guard < 10000) {
      lastCompleted = cursor;
      cursor = ReminderSchedule.nextOccurrence(
        cursor,
        repeatType,
        dayOfMonth: dayOfMonth,
        customIntervalDays: intervalDays,
      );
      guard++;
    }

    if (cursor == current) {
      return this;
    }

    return copyWith(
      date: cursor,
      lastCompletedDate: lastCompleted,
      repeatDayOfMonth: dayOfMonth,
      customIntervalDays: intervalDays,
    );
  }
}
