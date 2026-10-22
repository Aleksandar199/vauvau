import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/events/presentation/events_controller.dart';
import 'package:vauvau/features/groups/data/firestore_groups_repository.dart';
import 'package:vauvau/features/groups/data/local_groups_repository.dart';
import 'package:vauvau/features/groups/data/seed_breed_groups.dart';
import 'package:vauvau/features/groups/domain/groups_models.dart';
import 'package:vauvau/features/groups/presentation/group_chat_screen.dart';
import 'package:vauvau/features/groups/presentation/group_unread_alerts.dart';
import 'package:vauvau/features/groups/presentation/groups_controller.dart';
import 'package:vauvau/features/notifications/data/push_notification_gateway.dart';
import 'package:vauvau/features/notifications/domain/push_payload.dart';
import 'package:vauvau/features/profile/domain/app_settings.dart';
import 'package:vauvau/features/profile/presentation/profile_controller.dart';

class _RecordingGateway extends NoopPushNotificationGateway {
  final presented = <PushPayload>[];

  @override
  Future<void> present(PushPayload payload) async => presented.add(payload);
}

class _Settings extends AppSettingsController {
  @override
  AppSettings build() => const AppSettings();
}

class _Threads extends Notifier<List<GroupInboxThread>> {
  @override
  List<GroupInboxThread> build() => const [];

  void set(List<GroupInboxThread> value) => state = value;
}

final _threads = NotifierProvider<_Threads, List<GroupInboxThread>>(
  _Threads.new,
);

GroupInboxThread _thread(String id, int unread) {
  return GroupInboxThread(
    group: BreedGroup(
      id: id,
      title: 'Grupa $id',
      description: '',
      imageUrl: '',
      memberIds: const ['me'],
      memberCount: 1,
    ),
    lastMessage: 'Ćao',
    lastActivityAt: DateTime.now(),
    unreadCount: unread,
  );
}

void main() {
  test('local repository remembers mute per group', () async {
    final repo = LocalGroupsRepository(currentUserId: 'me');
    addTearDown(repo.dispose);
    final seen = <bool>[];
    final sub = repo.watchMuted('g1').listen(seen.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);

    await repo.setMuted('g1', true);
    await repo.setMuted('g2', true);
    await repo.setMuted('g1', false);
    await Future<void>.delayed(Duration.zero);

    expect(seen, [false, true, false]);
  });

  test('Firestore mute is members/{me}.muted and keeps the read cursor',
      () async {
    final firestore = FakeFirebaseFirestore();
    final member = firestore.doc('breed_groups/g1/members/me');
    await member.set({'lastReadTimestamp': DateTime(2026, 10, 22)});
    final repo = FirestoreGroupsRepository(
      firestore: firestore,
      currentUserId: 'me',
      senderName: 'Ja',
      senderAvatarUrl: '',
    );

    await repo.setMuted('g1', true);
    var data = (await member.get()).data()!;
    expect(data['muted'], isTrue);
    expect(data.containsKey('lastReadTimestamp'), isTrue);

    await repo.setMuted('g1', false);
    data = (await member.get()).data()!;
    expect(data.containsKey('muted'), isFalse);
    expect(data.containsKey('lastReadTimestamp'), isTrue);
  });

  test('a muted group gets no phone alert, others still do', () async {
    final gateway = _RecordingGateway();
    final container = ProviderContainer(
      overrides: [
        pushNotificationGatewayProvider.overrideWithValue(gateway),
        appSettingsProvider.overrideWith(_Settings.new),
        joinedGroupThreadsProvider.overrideWith((ref) => ref.watch(_threads)),
        joinedEventThreadsProvider.overrideWith((ref) => const []),
        groupMutedProvider('muted').overrideWith((ref) => Stream.value(true)),
        groupMutedProvider('loud').overrideWith((ref) => Stream.value(false)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(groupUnreadAlertsProvider, (_, _) {});
    // Resolve the mute streams before messages arrive.
    container.listen(groupMutedProvider('muted'), (_, _) {});
    container.listen(groupMutedProvider('loud'), (_, _) {});
    await Future<void>.delayed(Duration.zero);

    container.read(_threads.notifier).set([
      _thread('muted', 0),
      _thread('loud', 0),
    ]);
    await Future<void>.delayed(Duration.zero);
    container.read(_threads.notifier).set([
      _thread('muted', 3),
      _thread('loud', 1),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(gateway.presented.map((p) => p.groupId), ['loud']);
  });

  testWidgets('bell in the group chat mutes and unmutes', (tester) async {
    final repo = LocalGroupsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);
    final groupId = SeedBreedGroups.all.first.id;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWith((ref) => repo),
          groupMessagesProvider(
            groupId,
          ).overrideWith((ref) => Stream.value(const <GroupMessage>[])),
        ],
        child: MaterialApp(home: GroupChatScreen(groupId: groupId)),
      ),
    );
    await tester.pump();
    await tester.pump();

    final bell = find.byKey(const ValueKey('group-chat-mute'));
    expect(
      find.descendant(
        of: bell,
        matching: find.byIcon(Icons.notifications_active_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(bell);
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(
        of: bell,
        matching: find.byIcon(Icons.notifications_off_outlined),
      ),
      findsOneWidget,
    );
    expect(await repo.watchMuted(groupId).first, isTrue);

    await tester.tap(bell);
    await tester.pump();
    await tester.pump();
    expect(await repo.watchMuted(groupId).first, isFalse);
  });
}
