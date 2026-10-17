import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/moderation/data/local_blocked_users_repository.dart';
import 'package:vauvau/features/moderation/presentation/block_controller.dart';
import 'package:vauvau/features/moderation/presentation/blocked_users_screen.dart';
import 'package:vauvau/features/moderation/presentation/moderation_strings.dart';
import 'package:vauvau/features/profile/data/owner_public_profile.dart';

Future<LocalBlockedUsersRepository> _pump(
  WidgetTester tester,
  Set<String> seed,
) async {
  final repo = LocalBlockedUsersRepository(seed: seed);
  addTearDown(repo.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        blockedUsersRepositoryProvider.overrideWithValue(repo),
        ownerProfileLoaderProvider.overrideWithValue(
          (id) async => OwnerPublicProfile(
            userId: id,
            name: id == 'u1' ? 'Marko Marković' : 'Ana Anić',
            photoUrl: '',
            location: '',
            bio: '',
            dogs: const [],
          ),
        ),
      ],
      child: const MaterialApp(home: BlockedUsersScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return repo;
}

void main() {
  testWidgets('lists blocked users by name and unblocks after confirming', (
    tester,
  ) async {
    await _pump(tester, {'u1', 'u2'});
    expect(find.text('Marko Marković'), findsOneWidget);
    expect(find.text('Ana Anić'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('unblock-u1')));
    await tester.pumpAndSettle();
    expect(find.text(ModerationStrings.unblockTitle), findsOneWidget);
    // Cancel keeps the block.
    await tester.tap(find.text(ModerationStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.text('Marko Marković'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('unblock-u1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, ModerationStrings.unblock));
    await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Marko Marković'), findsNothing);
    expect(find.text('Ana Anić'), findsOneWidget);
    expect(find.text(ModerationStrings.unblockDone), findsOneWidget);
  });

  testWidgets('shows an empty state when nobody is blocked', (tester) async {
    await _pump(tester, {});
    expect(find.byKey(const ValueKey('blocked-empty')), findsOneWidget);
  });
}
