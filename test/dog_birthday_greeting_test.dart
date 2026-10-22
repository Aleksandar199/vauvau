import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/services/notification_service.dart';
import 'package:vauvau/features/dogs/data/local_reminder_repository.dart';
import 'package:vauvau/features/dogs/domain/birthday_greeting.dart';
import 'package:vauvau/features/dogs/domain/dog_reminder.dart';
import 'package:vauvau/features/dogs/presentation/health/reminder_controller.dart';
import 'package:vauvau/features/rewards/data/birthday_reward_source.dart';
import 'package:vauvau/features/rewards/domain/birthday_reward.dart';

class _Scheduled {
  _Scheduled(this.id, this.title, this.body, this.date);

  final int id;
  final String title;
  final String body;
  final DateTime date;
}

class _RecordingNotifications extends NotificationService {
  final scheduled = <_Scheduled>[];
  final cancelled = <int>[];

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
    scheduled.add(_Scheduled(notificationId, title, body, scheduledDate));
    return true;
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    cancelled.add(notificationId);
  }
}

DogReminder _birthday({
  ReminderOffset offset = ReminderOffset.oneDayBefore,
  ReminderType type = ReminderType.birthday,
}) {
  final day = DateTime.now().add(const Duration(days: 40));
  return DogReminder(
    id: '',
    dogId: 'dog-1',
    title: 'Rođendan',
    type: type,
    date: DateTime(day.year, day.month, day.day),
    repeatType: ReminderRepeat.yearly,
    reminderOffset: offset,
  );
}

({ProviderContainer container, _RecordingNotifications notifications})
_setup({BirthdayRewardConfig reward = BirthdayRewardConfig.disabled}) {
  final repo = LocalReminderRepository();
  addTearDown(repo.dispose);
  final notifications = _RecordingNotifications();
  final container = ProviderContainer(
    overrides: [
      reminderRepositoryProvider.overrideWith((ref) => repo),
      notificationServiceProvider.overrideWith((ref) => notifications),
      birthdayRewardConfigProvider.overrideWith((ref) async => reward),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, notifications: notifications);
}

void main() {
  test('rođendan: podsetnik dan pre + čestitka na sam dan u 09:00', () async {
    final s = _setup();
    final reminder = _birthday();
    final result = await s.container
        .read(reminderControllerProvider)
        .save(reminder: reminder, dogName: 'Dzeki');

    expect(result.reminderSet, isTrue);
    expect(s.notifications.scheduled, hasLength(2));
    final greeting = s.notifications.scheduled.firstWhere(
      (n) => n.id == BirthdayGreeting.notificationIdFor(result.reminderId),
    );
    expect(greeting.date, reminder.date);
    expect(greeting.title, contains('Srećan rođendan, Dzeki'));
    expect(greeting.body, isNot(contains('🎁')));
    expect(
      s.notifications.scheduled.where((n) => n.id != greeting.id).single.date,
      reminder.date.subtract(const Duration(days: 1)),
    );
  });

  test('podsetnik „na dan“: samo čestitka, bez duplog obaveštenja', () async {
    final s = _setup();
    await s.container
        .read(reminderControllerProvider)
        .save(reminder: _birthday(offset: ReminderOffset.onDay), dogName: 'Dzeki');

    expect(s.notifications.scheduled, hasLength(1));
    expect(
      s.notifications.scheduled.single.title,
      contains('Srećan rođendan'),
    );
  });

  test('drugi podsetnici nemaju čestitku', () async {
    final s = _setup();
    await s.container.read(reminderControllerProvider).save(
      reminder: _birthday(type: ReminderType.grooming),
      dogName: 'Dzeki',
    );
    expect(s.notifications.scheduled, hasLength(1));
    expect(s.notifications.scheduled.single.title, isNot(contains('rođendan')));
  });

  test('završen ili obrisan rođendan otkazuje čestitku', () async {
    final s = _setup();
    final controller = s.container.read(reminderControllerProvider);
    final saved = await controller.save(reminder: _birthday(), dogName: 'Dzeki');
    final greetingId = BirthdayGreeting.notificationIdFor(saved.reminderId);
    s.notifications.scheduled.clear();

    await controller.save(
      reminder: _birthday().copyWith(id: saved.reminderId, isCompleted: true),
      dogName: 'Dzeki',
    );
    expect(s.notifications.cancelled, contains(greetingId));
    expect(s.notifications.scheduled, isEmpty);

    s.notifications.cancelled.clear();
    await controller.delete(_birthday().copyWith(id: saved.reminderId));
    expect(s.notifications.cancelled, contains(greetingId));
  });

  test('poklon se pominje samo kad je uključen i ima kupon', () async {
    expect(BirthdayRewardConfig.fromMap(null).isActive, isFalse);
    expect(
      BirthdayRewardConfig.fromMap({'enabled': true, 'couponId': ''}).isActive,
      isFalse,
    );
    expect(
      BirthdayRewardConfig.fromMap({'enabled': 'yes', 'couponId': 'c1'})
          .isActive,
      isFalse,
    );

    final s = _setup(
      reward: BirthdayRewardConfig.fromMap({
        'enabled': true,
        'couponId': 'rodjendan',
        'partnerName': 'Pet shop Šapa',
      }),
    );
    await s.container
        .read(reminderControllerProvider)
        .save(reminder: _birthday(offset: ReminderOffset.onDay), dogName: 'Dzeki');
    final body = s.notifications.scheduled.single.body;
    expect(body, contains('🎁'));
    expect(body, contains('Pet shop Šapa'));
  });
}
