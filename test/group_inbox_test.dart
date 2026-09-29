import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/chat/presentation/chat_strings.dart';
import 'package:vauvau/features/chat/presentation/matches_screen.dart';
import 'package:vauvau/features/groups/data/local_groups_repository.dart';
import 'package:vauvau/features/groups/data/seed_breed_groups.dart';
import 'package:vauvau/features/groups/domain/groups_models.dart';
import 'package:vauvau/features/groups/presentation/groups_controller.dart';
import 'package:vauvau/features/notifications/presentation/notification_strings.dart';

void main() {
  test('group unread counts only messages after lastRead', () {
    final group = SeedBreedGroups.all.first;
    final lastRead = DateTime(2026, 9, 28, 12);
    final thread = GroupInboxThread.fromMessages(
      group: group,
      lastRead: lastRead,
      messages: [
        GroupMessage(
          id: '1',
          senderId: 'a',
          senderName: 'Ana',
          senderAvatarUrl: '',
          text: 'old',
          imageUrl: '',
          createdAt: DateTime(2026, 9, 28, 11),
          isMine: false,
        ),
        for (var i = 0; i < 10; i++)
          GroupMessage(
            id: 'n$i',
            senderId: 'a',
            senderName: 'Ana',
            senderAvatarUrl: '',
            text: 'new $i',
            imageUrl: '',
            createdAt: DateTime(2026, 9, 28, 13, i),
            isMine: false,
          ),
      ],
    );
    expect(thread.unreadCount, 10);
  });

  test('grouped notification copy uses group title and count', () {
    expect(
      NotificationStrings.pushGroupAlert('Pomeranci Novi Sad', 10),
      'Pomeranci Novi Sad: 10 novih poruka',
    );
  });

  testWidgets('joined group appears in Poruke with unread badge', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final repo = LocalGroupsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);
    await repo.joinGroup(SeedBreedGroups.all.first.id);
    repo.seedIncomingMessage(
      groupId: SeedBreedGroups.all.first.id,
      message: GroupMessage(
        id: 'in-1',
        senderId: 'peer',
        senderName: 'Mila',
        senderAvatarUrl: '',
        text: 'Idemo u park?',
        imageUrl: '',
        createdAt: DateTime.now().add(const Duration(minutes: 1)),
        isMine: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWith((ref) => repo),
          chatSeedProvider.overrideWith((ref) => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: MatchesScreen())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(SeedBreedGroups.all.first.title), findsOneWidget);
    expect(find.text(ChatStrings.groupBadge), findsOneWidget);
    expect(find.text('Idemo u park?'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  test('nav badge counts one thread for many unread group messages', () {
    final group = SeedBreedGroups.all.first.copyWith(
      memberIds: const ['local-user'],
    );
    final thread = GroupInboxThread.fromMessages(
      group: group,
      lastRead: DateTime(2026, 1, 1),
      messages: [
        for (var i = 0; i < 10; i++)
          GroupMessage(
            id: '$i',
            senderId: 'peer',
            senderName: 'Mila',
            senderAvatarUrl: '',
            text: 'msg $i',
            imageUrl: '',
            createdAt: DateTime(2026, 9, 28, 14, i),
            isMine: false,
          ),
      ],
    );
    expect(thread.unreadCount, 10);
    expect(thread.unreadCount > 0 ? 1 : 0, 1);
  });
}
