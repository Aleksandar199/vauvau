import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/services/notification_service.dart';
import 'package:vauvau/features/dogs/data/local_health_repository.dart';
import 'package:vauvau/features/dogs/data/local_reminder_repository.dart';
import 'package:vauvau/features/dogs/domain/dog_reminder.dart';
import 'package:vauvau/features/dogs/domain/health_record.dart';
import 'package:vauvau/features/dogs/presentation/health/dog_health_tab.dart';
import 'package:vauvau/features/dogs/presentation/health/health_controller.dart';
import 'package:vauvau/features/dogs/presentation/health/reminder_controller.dart';
import 'package:vauvau/features/dogs/presentation/health/reminder_strings.dart';

class _RecordingNotificationService extends NotificationService {
  final List<DateTime> scheduled = [];

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
  Future<void> cancelReminder(int notificationId) async {}
}

void main() {
  final now = DateTime(2026, 10, 6);

  test('urgency reflects the reminder date', () {
    DogReminder reminder(DateTime date) => DogReminder(
          id: 'r1',
          dogId: 'dog-1',
          title: 'Test',
          type: ReminderType.ticksFleas,
          date: date,
        );

    expect(
      reminder(DateTime(2026, 10, 1)).urgencyAt(now),
      ReminderUrgency.overdue,
    );
    expect(
      reminder(DateTime(2026, 10, 6)).urgencyAt(now),
      ReminderUrgency.today,
    );
    expect(
      reminder(DateTime(2026, 10, 7)).urgencyAt(now),
      ReminderUrgency.tomorrow,
    );
    expect(
      reminder(DateTime(2026, 10, 16)).urgencyAt(now),
      ReminderUrgency.soon,
    );
    expect(
      reminder(DateTime(2026, 12, 1)).urgencyAt(now),
      ReminderUrgency.upcoming,
    );
  });

  test('notifyDate respects reminder offset', () {
    final reminder = DogReminder(
      id: 'r1',
      dogId: 'dog-1',
      title: 'Krpelji',
      type: ReminderType.ticksFleas,
      date: DateTime(2026, 10, 22),
      reminderOffset: ReminderOffset.threeDaysBefore,
    );
    expect(reminder.notifyDate, DateTime(2026, 10, 19));
  });

  test('saving schedules notification on notify date', () async {
    final repo = LocalReminderRepository();
    addTearDown(repo.dispose);
    final notifications = _RecordingNotificationService();
    final container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWith((ref) => repo),
        notificationServiceProvider.overrideWith((ref) => notifications),
      ],
    );
    addTearDown(container.dispose);

    final due = DateTime.now().add(const Duration(days: 40));
    final result = await container.read(reminderControllerProvider).save(
          reminder: DogReminder(
            id: '',
            dogId: 'dog-1',
            title: 'Zaštita od krpelja',
            type: ReminderType.ticksFleas,
            date: due,
            reminderOffset: ReminderOffset.threeDaysBefore,
          ),
          dogName: 'Leo',
        );

    expect(result.reminderSet, isTrue);
    expect(
      notifications.scheduled.single,
      DateTime(due.year, due.month, due.day).subtract(const Duration(days: 3)),
    );
  });

  testWidgets('profile summary hides empty predefined categories',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final healthRepo = LocalHealthRepository();
    final reminderRepo = LocalReminderRepository();
    addTearDown(healthRepo.dispose);
    addTearDown(reminderRepo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthRepositoryProvider.overrideWith((ref) => healthRepo),
          reminderRepositoryProvider.overrideWith((ref) => reminderRepo),
          notificationServiceProvider
              .overrideWith((ref) => _RecordingNotificationService()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DogHealthTab(dogId: 'dog-1', dogName: 'Leo'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(ReminderStrings.sectionTitle), findsOneWidget);
    expect(find.text(ReminderStrings.emptyTitle), findsOneWidget);
    expect(find.text(ReminderStrings.addFirst), findsOneWidget);
    expect(find.text('Nema zapisa'), findsNothing);
    expect(find.text('💉 Besnilo'), findsNothing);
    expect(find.text('🛡️ Zarazne bolesti'), findsNothing);
  });

  testWidgets('profile summary shows nearest reminders only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final healthRepo = LocalHealthRepository(
      seed: [
        HealthRecord(
          id: 'h1',
          dogId: 'dog-1',
          category: HealthCategory.vaccineRabies,
          title: 'Besnilo',
          administeredDate: DateTime(2026, 1, 1),
          nextDueDate: DateTime(2027, 1, 1),
        ),
      ],
    );
    final reminderRepo = LocalReminderRepository(
      seed: [
        DogReminder(
          id: 'r1',
          dogId: 'dog-1',
          title: 'Zaštita od krpelja',
          type: ReminderType.ticksFleas,
          date: DateTime(2026, 10, 22),
        ),
        DogReminder(
          id: 'r2',
          dogId: 'dog-1',
          title: 'Besnilo',
          type: ReminderType.vaccineRabies,
          date: DateTime(2026, 11, 18),
        ),
        DogReminder(
          id: 'r3',
          dogId: 'dog-1',
          title: 'Grooming',
          type: ReminderType.grooming,
          date: DateTime(2026, 12, 5),
        ),
      ],
    );
    addTearDown(healthRepo.dispose);
    addTearDown(reminderRepo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthRepositoryProvider.overrideWith((ref) => healthRepo),
          reminderRepositoryProvider.overrideWith((ref) => reminderRepo),
          notificationServiceProvider
              .overrideWith((ref) => _RecordingNotificationService()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DogHealthTab(dogId: 'dog-1', dogName: 'Leo'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(ReminderStrings.typeShortLabel(ReminderType.ticksFleas)),
        findsOneWidget);
    expect(
      find.text(ReminderStrings.typeShortLabel(ReminderType.vaccineRabies)),
      findsOneWidget,
    );
    // Third reminder stays off the compact profile summary.
    expect(
      find.text(ReminderStrings.typeShortLabel(ReminderType.grooming)),
      findsNothing,
    );
    expect(find.text(ReminderStrings.activeCount(3)), findsOneWidget);
    expect(find.text(ReminderStrings.showAll), findsOneWidget);
    expect(find.text(ReminderStrings.openHealthCard), findsOneWidget);
  });
}
