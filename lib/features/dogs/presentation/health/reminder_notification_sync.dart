import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../dog_providers.dart';
import 'health_controller.dart';
import 'reminder_controller.dart';

/// Re-creates the local notifications of every reminder and health record of
/// my dogs once per dog per app session (watched by `HomeShellScreen`).
/// Local notifications live only on this phone: without this they were lost
/// after a reinstall / on a new phone, missing for items saved on another
/// device, and a repeating reminder got its next date only when the health
/// tab was opened. State = dog ids already synced.
class ReminderNotificationSync extends Notifier<Set<String>> {
  final _started = <String>{};

  @override
  Set<String> build() {
    final dogs = ref.watch(ownerDogsProvider).value ?? const [];
    if (!ref.read(notificationServiceProvider).isSupported) {
      return const {};
    }
    for (final dog in dogs) {
      if (dog.id.isEmpty || !_started.add(dog.id)) continue;
      Future<void>.microtask(() => _sync(dog.id, dog.name));
    }
    return {..._started};
  }

  Future<void> _sync(String dogId, String dogName) async {
    try {
      final reminders = await ref
          .read(reminderRepositoryProvider)
          .watchReminders(dogId)
          .first;
      await ref
          .read(reminderControllerProvider)
          .resync(reminders, dogName: dogName);
      final records = await ref
          .read(healthRepositoryProvider)
          .watchRecords(dogId)
          .first;
      await ref
          .read(healthControllerProvider)
          .resync(records, dogName: dogName);
    } catch (error) {
      // Next app start tries again.
      debugPrint('Reminder notification sync failed for $dogId: $error');
      _started.remove(dogId);
    }
  }
}

final reminderNotificationSyncProvider =
    NotifierProvider<ReminderNotificationSync, Set<String>>(
      ReminderNotificationSync.new,
    );
