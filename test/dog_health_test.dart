import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/services/notification_service.dart';
import 'package:vauvau/features/dogs/data/local_health_repository.dart';
import 'package:vauvau/features/dogs/domain/health_record.dart';
import 'package:vauvau/features/dogs/presentation/health/dog_health_tab.dart';
import 'package:vauvau/features/dogs/presentation/health/health_controller.dart';
import 'package:vauvau/features/dogs/presentation/health/health_strings.dart';

class _RecordingNotificationService extends NotificationService {
  final List<int> cancelled = [];
  final List<DateTime> scheduled = [];
  bool allowScheduling = true;

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
    if (!allowScheduling) {
      return false;
    }
    scheduled.add(scheduledDate);
    return true;
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    cancelled.add(notificationId);
  }
}

void main() {
  final now = DateTime(2026, 9, 29);

  test('status reflects the next due date', () {
    HealthRecord record(DateTime? due) => HealthRecord(
          id: 'r1',
          dogId: 'dog-1',
          category: HealthCategory.vaccineRabies,
          title: 'Vakcina protiv besnila',
          administeredDate: DateTime(2026, 1, 1),
          nextDueDate: due,
        );

    expect(record(DateTime(2027, 1, 1)).statusAt(now), HealthStatus.valid);
    expect(
      record(DateTime(2026, 10, 10)).statusAt(now),
      HealthStatus.expiringSoon,
    );
    expect(record(DateTime(2026, 9, 1)).statusAt(now), HealthStatus.expired);
    expect(record(null).statusAt(now), HealthStatus.unknown);
  });

  test('reminder instant is 09:00 on the due date', () {
    final when = NotificationService.reminderInstant(DateTime(2026, 12, 24));
    expect(when.hour, 9);
    expect(when.day, 24);
    expect(when.month, 12);
  });

  test('saving schedules a reminder and stores its id', () async {
    final repo = LocalHealthRepository();
    addTearDown(repo.dispose);
    final notifications = _RecordingNotificationService();
    final container = ProviderContainer(
      overrides: [
        healthRepositoryProvider.overrideWith((ref) => repo),
        notificationServiceProvider.overrideWith((ref) => notifications),
      ],
    );
    addTearDown(container.dispose);

    final due = DateTime.now().add(const Duration(days: 40));
    final result = await container.read(healthControllerProvider).save(
          record: HealthRecord(
            id: '',
            dogId: 'dog-1',
            category: HealthCategory.tickProtection,
            title: 'Bravecto',
            administeredDate: DateTime.now(),
            nextDueDate: due,
          ),
          dogName: 'Luna',
          withReminder: true,
        );

    expect(result.reminderSet, isTrue);
    expect(notifications.scheduled.single, due);
    final stored = await repo.watchRecords('dog-1').first;
    expect(stored.single.id, result.recordId);
    expect(
      stored.single.notificationId,
      HealthRecord.notificationIdFor(result.recordId),
    );
  });

  test('saving without a reminder cancels any previous one', () async {
    final repo = LocalHealthRepository();
    addTearDown(repo.dispose);
    final notifications = _RecordingNotificationService();
    final container = ProviderContainer(
      overrides: [
        healthRepositoryProvider.overrideWith((ref) => repo),
        notificationServiceProvider.overrideWith((ref) => notifications),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(healthControllerProvider).save(
          record: HealthRecord(
            id: '',
            dogId: 'dog-1',
            category: HealthCategory.deworming,
            title: 'Tablete',
            administeredDate: DateTime.now(),
          ),
          dogName: 'Luna',
          withReminder: true,
        );

    expect(result.reminderSet, isFalse);
    expect(notifications.scheduled, isEmpty);
    expect(
      notifications.cancelled.single,
      HealthRecord.notificationIdFor(result.recordId),
    );
    final stored = await repo.watchRecords('dog-1').first;
    expect(stored.single.notificationId, isNull);
  });

  testWidgets('health section shows a card per category', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final repo = LocalHealthRepository(
      seed: [
        HealthRecord(
          id: 'rabies-1',
          dogId: 'dog-1',
          category: HealthCategory.vaccineRabies,
          title: 'Vakcina protiv besnila',
          administeredDate: DateTime(2026, 3, 1),
          nextDueDate: DateTime(2027, 3, 1),
          notificationId: 42,
        ),
      ],
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthRepositoryProvider.overrideWith((ref) => repo),
          notificationServiceProvider
              .overrideWith((ref) => _RecordingNotificationService()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DogHealthTab(dogId: 'dog-1', dogName: 'Luna'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(HealthStrings.sectionTitle), findsOneWidget);
    for (final category in HealthCategory.values) {
      expect(
        find.text(HealthStrings.categoryLabel(category)),
        findsOneWidget,
      );
    }
    expect(find.text('Vakcina protiv besnila'), findsOneWidget);
    expect(find.text(HealthStrings.statusValid), findsOneWidget);
    expect(find.text(HealthStrings.reminderBadge), findsOneWidget);
    expect(find.text(HealthStrings.noRecord), findsNWidgets(3));

    await tester.tap(find.text(HealthStrings.categoryLabel(
      HealthCategory.deworming,
    )));
    await tester.pumpAndSettle();
    expect(find.text(HealthStrings.reminderToggle), findsOneWidget);
    expect(find.text(HealthStrings.administeredDate), findsOneWidget);
    expect(find.text(HealthStrings.nextDueDate), findsOneWidget);
  });
}
