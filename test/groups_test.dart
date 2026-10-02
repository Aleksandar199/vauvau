import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/groups/data/local_groups_repository.dart';
import 'package:vauvau/features/groups/data/seed_breed_groups.dart';
import 'package:vauvau/features/groups/presentation/group_chat_screen.dart';
import 'package:vauvau/features/groups/presentation/groups_controller.dart';
import 'package:vauvau/features/groups/presentation/groups_list_screen.dart';
import 'package:vauvau/features/groups/presentation/groups_strings.dart';

void main() {
  test('seed presets cover parks, drop small-dogs group, and sort by members',
      () {
    final titles = SeedBreedGroups.all.map((group) => group.title).toList();
    expect(titles, contains('🌳 Limanski park'));
    expect(titles, contains('🍃 Futoški park'));
    expect(titles, contains('🌊 Kej / Žeželjev most'));
    expect(titles, contains('🌲 Kamenički park'));
    expect(titles, contains('🏰 Petrovaradinska tvrđava'));
    expect(titles, isNot(contains('🐾 Vlasnici malih pasa Novi Sad')));

    final pomeranci = SeedBreedGroups.all
        .firstWhere((group) => group.id == 'pomeranci-novi-sad');
    expect(pomeranci.memberCount, 34);

    for (final group in SeedBreedGroups.all) {
      expect(group.isApproved, isTrue);
      expect(group.memberCount, inInclusiveRange(12, 45));
    }

    final sorted = SeedBreedGroups.sortByPopularity(SeedBreedGroups.all);
    expect(sorted.first.title, '🏃‍♂️ Aktivne šetnje & Playdate');
    expect(
      sorted.first.memberCount >= sorted.last.memberCount,
      isTrue,
    );
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
    expect(find.text('🌊 Kej / Žeželjev most'), findsOneWidget);
    expect(find.text(GroupsStrings.createGroup), findsOneWidget);
    expect(find.text(GroupsStrings.join), findsWidgets);

    await tester.tap(find.text(GroupsStrings.join).first);
    await tester.pump();
    await tester.pump();

    expect(find.byType(GroupChatScreen), findsOneWidget);
    expect(find.text(GroupsStrings.composeHint), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cao copore');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump();
    expect(find.text('Cao copore'), findsWidgets);
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

    await tester.tap(find.text(GroupsStrings.createGroup));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, GroupsStrings.groupName),
      'Nova park grupa',
    );
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
    await tester.pumpAndSettle();
    expect(find.byType(CreateGroupSheet), findsNothing);
  });
}
