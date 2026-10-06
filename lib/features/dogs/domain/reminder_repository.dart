import 'dog_reminder.dart';

abstract class ReminderRepository {
  Stream<List<DogReminder>> watchReminders(String dogId);

  Future<String> saveReminder(DogReminder reminder);

  Future<void> deleteReminder({
    required String dogId,
    required String reminderId,
  });
}
