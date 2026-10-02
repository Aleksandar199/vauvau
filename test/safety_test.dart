import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/moderation/data/local_blocked_users_repository.dart';
import 'package:vauvau/features/moderation/domain/content_report.dart';
import 'package:vauvau/features/moderation/presentation/block_controller.dart';
import 'package:vauvau/features/moments/data/local_moments_repository.dart';
import 'package:vauvau/features/moments/data/seed_moments.dart';
import 'package:vauvau/features/moments/presentation/moments_controller.dart';
import 'package:vauvau/features/moments/presentation/moments_screen.dart';

void main() {
  test('maps report status and target keys', () {
    expect(
      ContentReport.statusKeyOf(ReportStatus.actionTaken),
      'action_taken',
    );
    expect(ContentReport.statusFromKey('action_taken'),
        ReportStatus.actionTaken);
    expect(ContentReport.statusFromKey('resolved'), ReportStatus.reviewed);
    expect(ContentReport.statusFromKey(null), ReportStatus.pending);
    expect(ContentReport.typeFromKey('moment'), ReportContentType.moment);
    expect(ContentReport.typeFromKey('user'), ReportContentType.user);
    expect(ContentReport.typeFromKey(null), ReportContentType.dog);
  });

  test('blocked users repository emits updates', () async {
    final repo = LocalBlockedUsersRepository();
    addTearDown(repo.dispose);

    final emissions = <Set<String>>[];
    final sub = repo.watchBlocked().listen(emissions.add);
    await Future<void>.delayed(Duration.zero);
    await repo.block('seed-nikola');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(emissions.first, isEmpty);
    expect(emissions.last, {'seed-nikola'});
  });

  testWidgets('moments feed hides blocked authors', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final momentsRepo = LocalMomentsRepository(currentUserId: 'local-user');
    addTearDown(momentsRepo.dispose);
    final blockedRepo = LocalBlockedUsersRepository(seed: {'seed-nikola'});
    addTearDown(blockedRepo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          momentsRepositoryProvider.overrideWith((ref) => momentsRepo),
          blockedUsersRepositoryProvider.overrideWith((ref) => blockedRepo),
        ],
        child: const MaterialApp(home: MomentsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final blocked = SeedMoments.all.firstWhere(
      (moment) => moment.authorUserId == 'seed-nikola',
    );
    final visible = SeedMoments.all.firstWhere(
      (moment) => moment.authorUserId != 'seed-nikola',
    );

    expect(find.text(blocked.caption, skipOffstage: false), findsNothing);
    expect(find.text(visible.caption, skipOffstage: false), findsOneWidget);
  });
}
