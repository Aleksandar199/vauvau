import 'dart:async';

import '../domain/dog_reminder.dart';
import '../domain/reminder_repository.dart';

/// In-memory reminders used when Firebase is not configured.
class LocalReminderRepository implements ReminderRepository {
  LocalReminderRepository({List<DogReminder> seed = const []})
      : _reminders = List<DogReminder>.from(seed);

  final List<DogReminder> _reminders;
  final StreamController<List<DogReminder>> _controller =
      StreamController<List<DogReminder>>.broadcast();
  var _nextId = 1;

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<DogReminder>> watchReminders(String dogId) async* {
    yield _forDog(dogId);
    yield* _controller.stream.map((_) => _forDog(dogId));
  }

  @override
  Future<String> saveReminder(DogReminder reminder) async {
    final id = reminder.id.isEmpty ? 'reminder-${_nextId++}' : reminder.id;
    final now = DateTime.now();
    final stored = reminder.copyWith(
      id: id,
      createdAt: reminder.createdAt ?? now,
      updatedAt: now,
    );
    final index = _reminders.indexWhere((item) => item.id == id);
    if (index == -1) {
      _reminders.add(stored);
    } else {
      _reminders[index] = stored;
    }
    _controller.add(const []);
    return id;
  }

  @override
  Future<void> deleteReminder({
    required String dogId,
    required String reminderId,
  }) async {
    _reminders.removeWhere(
      (item) => item.dogId == dogId && item.id == reminderId,
    );
    _controller.add(const []);
  }

  List<DogReminder> _forDog(String dogId) {
    final items = [
      for (final item in _reminders)
        if (item.dogId == dogId) item,
    ]..sort((a, b) => a.date.compareTo(b.date));
    return items;
  }
}
