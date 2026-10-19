import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/profile/presentation/owner_profile_sheet.dart';
import 'package:vauvau/features/groups/data/local_groups_repository.dart';
import 'package:vauvau/features/discover/presentation/widgets/dog_photo_gallery.dart';
import 'package:vauvau/features/discover/presentation/widgets/swipe_dog_card.dart';
import 'package:vauvau/features/groups/data/seed_breed_groups.dart';
import 'package:vauvau/features/groups/domain/group_ranking.dart';
import 'package:vauvau/features/groups/domain/groups_models.dart';
import 'package:vauvau/features/groups/presentation/group_chat_screen.dart';
import 'package:vauvau/features/groups/presentation/groups_controller.dart';
import 'package:vauvau/features/groups/presentation/groups_list_screen.dart';
import 'package:vauvau/features/groups/presentation/groups_strings.dart';

void main() {
  test('seed presets cover parks and drop the small-dogs group',
      () {
    final titles = SeedBreedGroups.all.map((group) => group.title).toList();
    expect(titles, contains('🌳 Limanski park'));
    expect(titles, contains('🍃 Futoški park'));
    expect(titles, contains('🌊 Kej / Žeželjev most'));
    expect(titles, contains('🌲 Kamenički park'));
    expect(titles, contains('🏰 Petrovaradinska tvrđava'));
    expect(titles, isNot(contains('🐾 Vlasnici malih pasa Novi Sad')));


    // No made-up popularity: preset groups start empty.
    for (final group in SeedBreedGroups.all) {
      expect(group.isApproved, isTrue);
      expect(group.memberCount, 0);
      expect(group.memberIds, isEmpty);
    }

    final sorted = GroupRanking.sort(SeedBreedGroups.all);
    expect(sorted.first.title, '🏃‍♂️ Aktivne šetnje & Playdate');
  });

  test('pending groups stay hidden until approved', () async {
    final repo = LocalGroupsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);

    final created = await repo.createGroup(
      title: 'Nova park grupa',
      description: 'Test',
    );
    expect(created.isApproved, isFalse);
    expect(
      (await repo.watchGroups().first).any((group) => group.id == created.id),
      isFalse,
    );
    expect(
      (await repo.watchPendingGroups().first).map((group) => group.id),
      contains(created.id),
    );

    await repo.approveGroup(created.id);
    final approved = await repo.watchGroups().first;
    expect(approved.any((group) => group.id == created.id), isTrue);
    expect(
      approved.firstWhere((group) => group.id == created.id).isApproved,
      isTrue,
    );
  });

  testWidgets('shows seeded groups and joins chat', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final repo = LocalGroupsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const MaterialApp(home: GroupsListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(GroupsStrings.title), findsOneWidget);
    expect(find.text('🏃‍♂️ Aktivne šetnje & Playdate'), findsOneWidget);
    expect(find.text('Šetnje pasa — Srbija'), findsOneWidget);
    expect(find.byTooltip(GroupsStrings.createGroup), findsOneWidget);
    expect(find.text(GroupsStrings.join), findsWidgets);

    await tester.tap(find.text(GroupsStrings.join).first);
    await tester.pump();
    await tester.pump();

    expect(find.byType(GroupChatScreen), findsOneWidget);
    expect(find.text(GroupsStrings.composeHint), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), 'Cao copore');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump();
    expect(find.text('Cao copore'), findsWidgets);
  });

  testWidgets('tapping a member avatar in group chat opens their profile',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final repo = LocalGroupsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);
    final groupId = SeedBreedGroups.all.first.id;
    final peerMessage = GroupMessage(
      id: 'g-1',
      senderId: 'user-marko',
      senderName: 'Marko',
      senderAvatarUrl: '',
      text: 'Ko je za šetnju?',
      imageUrl: '',
      createdAt: DateTime.now(),
      isMine: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWith((ref) => repo),
          groupMessagesProvider(groupId)
              .overrideWith((ref) => Stream.value([peerMessage])),
        ],
        child: MaterialApp(home: GroupChatScreen(groupId: groupId)),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Ko je za šetnju?'));
    await tester.pumpAndSettle();
    expect(find.byType(DogDetailSheet), findsNothing);

    await tester.tap(find.byKey(const ValueKey('group-sender-avatar')));
    await tester.pumpAndSettle();
    // The avatar opens the sender's own (person) profile.
    expect(find.byType(OwnerProfileSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(OwnerProfileSheet),
        matching: find.text('Marko'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a photo in group chat opens it full screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final repo = LocalGroupsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);
    final groupId = SeedBreedGroups.all.first.id;
    final photo = GroupMessage(
      id: 'g-photo',
      senderId: 'user-marko',
      senderName: 'Marko',
      senderAvatarUrl: '',
      text: '',
      imageUrl: 'https://example.com/dog.jpg',
      createdAt: DateTime.now(),
      isMine: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWith((ref) => repo),
          groupMessagesProvider(groupId)
              .overrideWith((ref) => Stream.value([photo])),
        ],
        child: MaterialApp(home: GroupChatScreen(groupId: groupId)),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('group-message-image')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DogPhotoViewer), findsOneWidget);
  });

  testWidgets('create group shows pending review dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final repo = LocalGroupsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const MaterialApp(home: GroupsListScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip(GroupsStrings.createGroup));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.widgetWithText(TextFormField, GroupsStrings.groupName),
      'Nova park grupa',
    );
    await tester.ensureVisible(find.text(GroupsStrings.submitGroup));
    await tester.tap(find.text(GroupsStrings.submitGroup));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(GroupsStrings.requestSentTitle), findsOneWidget);
    expect(find.text(GroupsStrings.requestSentBody), findsOneWidget);
    expect(
      (await repo.watchPendingGroups().first),
      hasLength(1),
    );

    await tester.tap(find.text(GroupsStrings.ok));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CreateGroupSheet), findsNothing);
  });
}
