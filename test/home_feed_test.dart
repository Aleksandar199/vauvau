import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vauvau/core/constants/app_strings.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/follows/data/local_follow_repository.dart';
import 'package:vauvau/features/follows/domain/follow_repository.dart';
import 'package:vauvau/features/follows/presentation/follow_controller.dart';
import 'package:vauvau/features/home/presentation/home_tab.dart';
import 'package:vauvau/features/moderation/presentation/block_controller.dart';
import 'package:vauvau/features/moments/data/local_moments_repository.dart';
import 'package:vauvau/features/moments/domain/moment_model.dart';
import 'package:vauvau/features/moments/presentation/home_feed_screen.dart';
import 'package:vauvau/features/moments/presentation/moments_controller.dart';
import 'package:vauvau/features/moments/presentation/moments_strings.dart';
import 'package:vauvau/features/notifications/data/social_notifications.dart';
import 'package:vauvau/features/stories/data/local_story_repository.dart';
import 'package:vauvau/features/stories/domain/story.dart';
import 'package:vauvau/features/stories/presentation/create_story_sheet.dart';
import 'package:vauvau/features/stories/presentation/story_providers.dart';
import 'package:vauvau/features/stories/presentation/widgets/stories_bar.dart';

const _me = 'me';

MomentModel _post(String id, String author, {int hoursAgo = 1}) => MomentModel(
  id: id,
  authorUserId: author,
  authorName: 'Ime $author',
  dogId: '',
  dogName: '',
  dogBreed: '',
  dogPhotoUrl: '',
  momentPhotoUrl: '',
  caption: 'Opis $id',
  locationName: '',
  likes: const [],
  commentsCount: 0,
  createdAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
);

Story _story(String id, String author) {
  final created = DateTime.now().subtract(const Duration(hours: 1));
  return Story(
    id: id,
    authorUserId: author,
    authorName: 'Ime $author',
    mediaPath: Story.mediaPathFor(author, id),
    audience: StoryAudience.everyone,
    createdAt: created,
    expiresAt: created.add(Story.lifetime),
  );
}

/// The feed skeleton shimmers forever, so pumpAndSettle is never used.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<LocalFollowRepository> _pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(412, 892));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // I follow ana (her story is in the bar); ivan is someone new.
  final follows = LocalFollowRepository(seed: const [(_me, 'ana')]);
  final stories = LocalStoryRepository(
    seed: [_story('s1', 'ana')],
    isFollowing: (a, b) => follows.edges.contains(FollowRepository.docId(a, b)),
  )..currentUserId = _me;
  final moments = LocalMomentsRepository(
    currentUserId: _me,
    // p1 is the newest, so it is the first card on screen.
    seed: [
      _post('p1', 'ivan'),
      _post('p2', 'ana', hoursAgo: 2),
      _post('p3', _me, hoursAgo: 3),
    ],
  );
  addTearDown(moments.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialUserIdProvider.overrideWithValue(_me),
        socialUserNameProvider.overrideWithValue('Ja'),
        momentsMemberIdProvider.overrideWithValue(_me),
        momentsRepositoryProvider.overrideWithValue(moments),
        followRepositoryProvider.overrideWithValue(follows),
        storyRepositoryProvider.overrideWithValue(stories),
        socialNotificationWriterProvider.overrideWithValue(
          LocalSocialNotificationWriter(),
        ),
        blockedUserIdsProvider.overrideWithValue(const {}),
        chatSeedProvider.overrideWith((ref) => const []),
      ],
      child: const MaterialApp(
        home: Scaffold(appBar: HomeFeedAppBar(), body: HomeFeedScreen()),
      ),
    ),
  );
  await _settle(tester);
  return follows;
}

void main() {
  test('aplikacija se otvara na Otkrij, Početna je prvi tab', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(homeTabIndexProvider), HomeTabIndex.discover);
    expect(HomeTabIndex.home, 0);
    container.read(homeTabIndexProvider.notifier).showHome();
    expect(container.read(homeTabIndexProvider), HomeTabIndex.home);
  });

  testWidgets('Početna: +, VauVau, srce, priče i tri taba feeda', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byKey(const ValueKey('home-add-story')), findsOneWidget);
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.byKey(const ValueKey('home-activity')), findsOneWidget);
    expect(find.byType(StoriesBar), findsOneWidget);
    expect(find.byKey(const ValueKey('stories-bar-ana')), findsOneWidget);
    expect(find.text('Ime ana'), findsWidgets);
    expect(find.text(MomentsStrings.tabForYou), findsOneWidget);
    expect(find.text(MomentsStrings.tabFollowing), findsOneWidget);
    expect(find.text(MomentsStrings.tabNearby), findsOneWidget);
    expect(
      find.byKey(const ValueKey('moment-post-p1')),
      findsOneWidget,
    );
  });

  testWidgets('„Prati“ samo kod onih koje ne pratim, ne kod sebe', (
    tester,
  ) async {
    final follows = await _pumpHome(tester);

    expect(find.byKey(const ValueKey('compact-follow-ivan')), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-follow-ana')), findsNothing);
    expect(find.byKey(const ValueKey('compact-follow-$_me')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('compact-follow-ivan')));
    await _settle(tester);

    expect(follows.edges, contains(FollowRepository.docId(_me, 'ivan')));
    expect(find.byKey(const ValueKey('compact-follow-ivan')), findsNothing);
  });

  testWidgets('+ gore levo otvara dodavanje priče', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home-add-story')));
    await _settle(tester);

    expect(find.byType(CreateStorySheet), findsOneWidget);
  });
}
