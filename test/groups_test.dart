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
    expect(find.text(SeedBreedGroups.all.first.title), findsOneWidget);
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
}
