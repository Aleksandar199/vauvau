import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/moments/data/local_highlights_repository.dart';
import 'package:vauvau/features/moments/data/local_moments_repository.dart';
import 'package:vauvau/features/moments/data/seed_moments.dart';
import 'package:vauvau/features/moments/domain/moment_model.dart';
import 'package:vauvau/features/moments/domain/story_highlight.dart';
import 'package:vauvau/features/moments/presentation/moments_controller.dart';
import 'package:vauvau/features/moments/presentation/moments_screen.dart';
import 'package:vauvau/features/moments/presentation/moments_strings.dart';
import 'package:vauvau/features/moments/presentation/stories_controller.dart';
import 'package:vauvau/features/moments/presentation/story_viewer.dart';
import 'package:vauvau/features/moments/presentation/widgets/story_widgets.dart';

MomentModel _ownMoment(String id, {required Duration age}) => MomentModel(
  id: id,
  authorUserId: 'local-user',
  authorName: 'Ti',
  dogId: 'dog-rex',
  dogName: 'Reks',
  dogBreed: 'Mešanac',
  dogPhotoUrl: '',
  momentPhotoUrl: '',
  caption: 'Priča $id',
  locationName: 'Liman',
  likes: const [],
  commentsCount: 0,
  createdAt: DateTime.now().subtract(age),
);

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  List<MomentModel>? moments,
  List<StoryHighlight> highlights = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(412, 892));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = LocalMomentsRepository(
    currentUserId: 'local-user',
    seed: moments,
  );
  addTearDown(repo.dispose);
  final highlightsRepo = LocalHighlightsRepository(
    currentUserId: 'local-user',
    seed: highlights,
  );
  addTearDown(highlightsRepo.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        momentsRepositoryProvider.overrideWith((ref) => repo),
        highlightsRepositoryProvider.overrideWith((ref) => highlightsRepo),
      ],
      child: MaterialApp(home: child),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  test('stories expire after 24h', () {
    final now = DateTime.now();
    expect(
      _ownMoment('a', age: const Duration(hours: 23)).isActiveStory(now),
      isTrue,
    );
    expect(
      _ownMoment('b', age: const Duration(hours: 25)).isActiveStory(now),
      isFalse,
    );
  });

  testWidgets('moments screen shows active stories and plays them', (
    tester,
  ) async {
    await _pump(tester, child: const MomentsScreen());

    expect(find.text(MomentsStrings.title), findsOneWidget);
    expect(find.text(MomentsStrings.yourStory), findsOneWidget);
    expect(find.text(MomentsStrings.activeStories), findsOneWidget);
    expect(find.text('Bobi'), findsNWidgets(2));

    await tester.tap(find.text('Bobi').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final viewer = find.byType(StoryViewerScreen);
    expect(viewer, findsOneWidget);
    final bobi = SeedMoments.all.firstWhere((m) => m.dogName == 'Bobi');
    expect(
      find.descendant(of: viewer, matching: find.text(bobi.caption)),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(MomentsStrings.like));
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(of: viewer, matching: find.text('${bobi.likeCount + 1}')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(MomentsStrings.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StoryViewerScreen), findsNothing);
  });

  testWidgets('expired story stays visible through a highlight', (
    tester,
  ) async {
    final old = _ownMoment('old', age: const Duration(days: 3));
    await _pump(
      tester,
      moments: [old],
      highlights: [
        StoryHighlight(
          id: 'h1',
          ownerId: 'local-user',
          dogId: 'dog-rex',
          title: 'Plaža',
          momentIds: const ['old'],
          createdAt: DateTime.now(),
        ),
      ],
      child: const Scaffold(body: DogStoriesSection(dogId: 'dog-rex')),
    );

    expect(find.text(MomentsStrings.story), findsNothing);
    expect(find.text('Plaža'), findsOneWidget);

    await tester.tap(find.text('Plaža'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StoryViewerScreen), findsOneWidget);
    expect(find.text('Priča old'), findsOneWidget);

    await tester.tap(find.byTooltip(MomentsStrings.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('owner creates a highlight from the story archive', (
    tester,
  ) async {
    await _pump(
      tester,
      moments: [
        _ownMoment('m1', age: const Duration(hours: 2)),
        _ownMoment('m2', age: const Duration(days: 2)),
      ],
      child: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: StoryHighlightsRow(dogId: 'dog-rex', editable: true),
        ),
      ),
    );

    expect(find.text(MomentsStrings.highlights), findsOneWidget);
    await tester.tap(find.text(MomentsStrings.newHighlight));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(MomentsStrings.newHighlightTitle), findsOneWidget);

    await tester.tap(find.text(MomentsStrings.highlightSave));
    await tester.pump();
    expect(find.text(MomentsStrings.highlightNameRequired), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Šetnje');
    await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
    await tester.pump();
    await tester.tap(find.text(MomentsStrings.highlightSave));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(MomentsStrings.newHighlightTitle), findsNothing);
    expect(find.text('Šetnje'), findsOneWidget);
  });
}
