import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/moments/data/local_moments_repository.dart';
import 'package:vauvau/features/moments/presentation/moments_controller.dart';
import 'package:vauvau/features/moments/presentation/moments_screen.dart';
import 'package:vauvau/features/moments/presentation/moments_strings.dart';

void main() {
  testWidgets('shows seeded moments and toggles like', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final repo = LocalMomentsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          momentsRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const MaterialApp(home: MomentsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(MomentsStrings.title), findsOneWidget);
    expect(find.text('Bobi'), findsWidgets);
    expect(find.text(MomentsStrings.viewDog), findsWidgets);

    await tester.tap(find.textContaining('🤍').first);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('❤️'), findsWidgets);
  });
}
