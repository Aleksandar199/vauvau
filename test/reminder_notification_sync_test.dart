import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/services/notification_service.dart';
import 'package:vauvau/features/dogs/data/local_health_repository.dart';
import 'package:vauvau/features/dogs/data/local_reminder_repository.dart';
import 'package:vauvau/features/dogs/domain/birthday_greeting.dart';
import 'package:vauvau/features/dogs/domain/dog_reminder.dart';
import 'package:vauvau/features/dogs/domain/health_record.dart';
import 'package:vauvau/features/dogs/presentation/dog_providers.dart';
import 'package:vauvau/features/dogs/presentation/health/health_controller.dart';
import 'package:vauvau/features/dogs/presentation/health/reminder_controller.dart';
import 'package:vauvau/features/dogs/presentation/health/reminder_notification_sync.dart';
import 'package:vauvau/features/rewards/data/birthday_reward_source.dart';
import 'package:vauvau/features/rewards/domain/birthday_reward.dart';

import 'fakes/fake_dogs_repository.dart';

class _Notifications extends NotificationService {
  final scheduled = <int, DateTime>{};
  final titles = <int, String>{};

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
    if (!scheduledDate.isAfter(DateTime.now())) return false;
    scheduled[notificationId] = scheduledDate;
    titles[notificationId] = title;
    return true;
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    scheduled.remove(notificationId);
  }
}

DateTime _day(int daysFromToday) {
  final d = DateTime.now().add(Duration(days: daysFromToday));
  return DateTime(d.year, d.month, d.day);
}

void main() {
  late LocalReminderRepository reminders;
  late LocalHealthRepository health;
  late _Notifications notifications;
  late ProviderContainer container;

  setUp(() {
    reminders = LocalReminderRepository();
    health = LocalHealthRepository();
    notifications = _Notifications();
    container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWith((ref) => reminders),
        healthRepositoryProvider.overrideWith((ref) => health),
        notificationServiceProvider.overrideWith((ref) => notifications),
        birthdayRewardConfigProvider.overrideWith(
          (ref) async => BirthdayRewardConfig.disabled,
        ),
        ownerDogsProvider.overrideWith((ref) => Stream.value([fakeDog()])),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(reminders.dispose);
    addTearDown(health.dispose);
  });

  test('podsetnici: zakazuje aktivne, preskače završene, pomera ponavljajuće',
      () async {
    final upcoming = DogReminder(
      id: 'r1',
      dogId: 'dog-1',
      title: 'Krpelji',
      type: ReminderType.ticksFleas,
      date: _day(10),
    );
    final done = upcoming.copyWith(id: 'r2', isCompleted: true);
    final monthlyPast = DogReminder(
      id: 'r3',
      dogId: 'dog-1',
      title: 'Kupanje',
      type: ReminderType.bathing,
      date: _day(-3),
      repeatType: ReminderRepeat.monthly,
    );
    for (final r in [upcoming, done, monthlyPast]) {
      await reminders.saveReminder(r);
    }

    await container
        .read(reminderControllerProvider)
        .resync([upcoming, done, monthlyPast], dogName: 'Luna');

    expect(
      notifications.scheduled[DogReminder.notificationIdFor('r1')],
      upcoming.notifyDate,
    );
    expect(
      notifications.scheduled.containsKey(DogReminder.notificationIdFor('r2')),
      isFalse,
    );
    final next = notifications.scheduled[DogReminder.notificationIdFor('r3')];
    expect(next, isNotNull);
    expect(next!.isAfter(DateTime.now()), isTrue);
    final stored = (await reminders.watchReminders('dog-1').first)
        .firstWhere((r) => r.id == 'r3');
    expect(stored.date.isAfter(DateTime.now()), isTrue);
  });

  test('karton: samo zapisi sa uključenim podsetnikom i budućim rokom',
      () async {
    final records = [
      HealthRecord(
        id: 'h1',
        dogId: 'dog-1',
        category: HealthCategory.vaccineRabies,
        title: 'Besnilo',
        administeredDate: _day(-300),
        nextDueDate: _day(65),
        notificationId: HealthRecord.notificationIdFor('h1'),
      ),
      HealthRecord(
        id: 'h2',
        dogId: 'dog-1',
        category: HealthCategory.deworming,
        title: 'Bez podsetnika',
        administeredDate: _day(-10),
        nextDueDate: _day(20),
      ),
    ];
    await container
        .read(healthControllerProvider)
        .resync(records, dogName: 'Luna');

    expect(
      notifications.scheduled[HealthRecord.notificationIdFor('h1')],
      _day(65),
    );
    expect(
      notifications.scheduled.containsKey(HealthRecord.notificationIdFor('h2')),
      isFalse,
    );
  });

  test('pri otvaranju aplikacije zakazuje sve za moje pse, jednom', () async {
    await reminders.saveReminder(
      DogReminder(
        id: 'b1',
        dogId: 'dog-1',
        title: 'Rođendan',
        type: ReminderType.birthday,
        date: _day(40),
        repeatType: ReminderRepeat.yearly,
        reminderOffset: ReminderOffset.oneDayBefore,
      ),
    );
    await health.saveRecord(
      HealthRecord(
        id: 'h1',
        dogId: 'dog-1',
        category: HealthCategory.vaccineRabies,
        title: 'Besnilo',
        administeredDate: _day(-300),
        nextDueDate: _day(65),
        notificationId: HealthRecord.notificationIdFor('h1'),
      ),
    );

    final sub = container.listen(reminderNotificationSyncProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(ownerDogsProvider.future);
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(container.read(reminderNotificationSyncProvider), {'dog-1'});
    expect(
      notifications.scheduled[DogReminder.notificationIdFor('b1')],
      _day(39),
    );
    expect(
      notifications.titles[BirthdayGreeting.notificationIdFor('b1')],
      contains('Luna'),
    );
    expect(
      notifications.scheduled[HealthRecord.notificationIdFor('h1')],
      _day(65),
    );
  });
}
