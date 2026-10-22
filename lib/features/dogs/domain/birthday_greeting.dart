import 'dog_reminder.dart';

/// "Srećan rođendan" for a dog: a local notification at 09:00 ON the birthday
/// (the reminder date itself), next to the usual reminder that may fire some
/// days before. Yearly birthday reminders roll forward, so every year gets a
/// new greeting.
abstract final class BirthdayGreeting {
  static bool appliesTo(DogReminder reminder) =>
      reminder.type == ReminderType.birthday && !reminder.isCompleted;

  /// Separate id so the greeting and the "upcoming birthday" reminder do not
  /// replace each other.
  static int notificationIdFor(String reminderId) =>
      ('birthday_$reminderId'.hashCode) & 0x7fffffff;

  /// The greeting day (the birthday itself, without time).
  static DateTime greetingDay(DogReminder reminder) => DateTime(
    reminder.date.year,
    reminder.date.month,
    reminder.date.day,
  );

  /// The normal reminder is skipped when it would fire the same morning as
  /// the greeting (offset "na dan").
  static bool reminderIsSameDay(DogReminder reminder) {
    final notify = reminder.notifyDate;
    final day = greetingDay(reminder);
    return notify.year == day.year &&
        notify.month == day.month &&
        notify.day == day.day;
  }
}
