import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/follows/data/local_follow_repository.dart';
import 'package:vauvau/features/follows/presentation/follow_controller.dart';
import 'package:vauvau/features/location/presentation/home_city_provider.dart';
import 'package:vauvau/features/moderation/presentation/block_controller.dart';
import 'package:vauvau/features/moments/data/firestore_moments_repository.dart';
import 'package:vauvau/features/moments/data/local_highlights_repository.dart';
import 'package:vauvau/features/moments/data/local_moments_repository.dart';
import 'package:vauvau/features/moments/domain/moment_model.dart';
import 'package:vauvau/features/moments/domain/moments_repository.dart';
import 'package:vauvau/features/moments/domain/story_highlight.dart';
import 'package:vauvau/features/moments/presentation/create_moment_sheet.dart';
import 'package:vauvau/features/moments/presentation/moment_feed_controller.dart';
import 'package:vauvau/features/moments/presentation/moments_controller.dart';
import 'package:vauvau/features/moments/presentation/moments_screen.dart';
import 'package:vauvau/features/moments/presentation/moments_strings.dart';
import 'package:vauvau/features/moments/presentation/stories_controller.dart';
import 'package:vauvau/features/moments/presentation/story_viewer.dart';
import 'package:vauvau/features/moments/presentation/widgets/story_widgets.dart';

const _me = 'local-user';

MomentModel _post(
  String id, {
  String author = 'ana',
  String authorName = 'Ana',
  Duration age = const Duration(hours: 1),
  String cityId = SerbiaLocations.noviSadId,
  MomentKind kind = MomentKind.post,
  String dogId = '',
  String dogName = '',
  List<String> likes = const [],
  int comments = 0,
}) {
  return MomentModel(
    id: id,
    kind: kind,
    authorUserId: author,
    authorName: authorName,
    dogId: dogId,
    dogName: dogName,
    dogBreed: '',
    dogPhotoUrl: '',
    momentPhotoUrl: '',
    caption: 'Opis $id',
    locationName: '',
    cityId: cityId,
    likes: likes,
    commentsCount: comments,
    createdAt: DateTime.now().subtract(age),
  );
}

/// 1×1 PNG, accepted by ContentValidationService.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _Harness {
  _Harness({
    List<MomentModel> moments = const [],
    Map<String, List<MomentComment>>? comments,
    Iterable<(String, String)> follows = const [],
    this.blocked = const {},
    this.city = const HomeCity(
      id: SerbiaLocations.noviSadId,
      name: 'Novi Sad',
      coord: GeoCoord(45.2671, 19.8335),
    ),
    List<StoryHighlight> highlights = const [],
  })  : repo = LocalMomentsRepository(
          currentUserId: _me,
          authorName: 'Ti',
          seed: moments,
          comments: comments ?? const {},
        ),
        followRepo = LocalFollowRepository(seed: follows),
        highlightsRepo = LocalHighlightsRepository(
          currentUserId: _me,
          seed: highlights,
        );

  final LocalMomentsRepository repo;
  final LocalFollowRepository followRepo;
  final LocalHighlightsRepository highlightsRepo;
  final Set<String> blocked;
  final HomeCity? city;
  final uploads = <String>[];

  List<Override> get overrides => [
        momentsRepositoryProvider.overrideWithValue(repo),
        momentsMemberIdProvider.overrideWithValue(_me),
        socialUserIdProvider.overrideWithValue(_me),
        followRepositoryProvider.overrideWithValue(followRepo),
        blockedUserIdsProvider.overrideWithValue(blocked),
        homeCityProvider.overrideWithValue(city),
        highlightsRepositoryProvider.overrideWithValue(highlightsRepo),
        momentPhotoUploaderProvider.overrideWithValue((photo, draftId) async {
          uploads.add(draftId);
          return 'https://firebasestorage.googleapis.com/v0/b/x/o/$draftId.png';
        }),
      ];

  void dispose() {
    repo.dispose();
    followRepo.dispose();
    highlightsRepo.dispose();
  }
}

Future<_Harness> _pumpScreen(
  WidgetTester tester,
  _Harness h, {
  Widget child = const MomentsScreen(),
  Size size = const Size(412, 892),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(h.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: h.overrides,
      child: MaterialApp(home: child),
    ),
  );
  await _settle(tester);
  return h;
}

/// The feed skeleton shimmers forever, so pumpAndSettle is never used.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<ProviderContainer> _container(_Harness h) async {
  final container = ProviderContainer(overrides: h.overrides);
  addTearDown(container.dispose);
  addTearDown(h.dispose);
  return container;
}

Future<MomentFeedState> _loaded(
  ProviderContainer container,
  MomentFeed feed,
) async {
  final sub = container.listen(visibleMomentFeedProvider(feed), (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 20 && container.read(momentFeedProvider(feed)).isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  if (container.read(momentFeedProvider(feed)).blocker ==
      MomentFeedBlocker.none) {
    expect(container.read(momentFeedProvider(feed)).isLoading, isFalse);
  }
  return container.read(visibleMomentFeedProvider(feed));
}

void main() {
  group('model', () {
    test('legacy documents (no kind) are not feed posts', () {
      final legacy = momentFromMap('a', {
        'authorUserId': 'u',
        'dogId': 'd',
        'momentPhotoUrl': 'https://x/y.jpg',
        'likes': ['x', 3, 'y'],
        'commentsCount': 2,
      });
      expect(legacy.kind, MomentKind.legacy);
      expect(legacy.isPost, isFalse);
      expect(legacy.dogName, 'Pas');
      expect(legacy.locationName, 'Novi Sad');
      expect(legacy.likes, ['x', 'y']);

      final post = momentFromMap('b', {
        'kind': 'post',
        'authorUserId': 'u',
        'cityId': 'nis',
        'momentPhotoUrl': 'https://x/y.jpg',
      });
      expect(post.isPost, isTrue);
      expect(post.hasDog, isFalse);
      expect(post.dogName, '');
      expect(post.locationName, '');
      expect(post.cityId, 'nis');
      expect(post.authorName, 'Korisnik');
    });

    test('replies are threaded under their root comment', () {
      final now = DateTime.now();
      final thread = threadComments([
        MomentComment(id: 'r1', authorUserId: 'b', authorName: 'B', text: 'odgovor', createdAt: now, replyToCommentId: 'c1'),
        MomentComment(id: 'c2', authorUserId: 'c', authorName: 'C', text: 'drugi', createdAt: now.subtract(const Duration(minutes: 1))),
        MomentComment(id: 'c1', authorUserId: 'a', authorName: 'A', text: 'prvi', createdAt: now.subtract(const Duration(minutes: 5))),
        MomentComment(id: 'r2', authorUserId: 'd', authorName: 'D', text: 'siroče', createdAt: now, replyToCommentId: 'missing'),
      ]);
      expect([for (final e in thread) e.comment.id], ['c1', 'r1', 'c2', 'r2']);
      expect([for (final e in thread) e.nested], [false, true, false, false]);
    });

    test('following request splits authors into chunks of 30', () {
      final ids = [for (var i = 0; i < 65; i++) 'u$i'];
      final chunks = MomentFeedRequest.following(ids).authorChunks;
      expect(chunks.map((c) => c.length), [30, 30, 5]);
    });
  });

  group('feed', () {
    test('Za tebe shows only posts, newest first, paginated by 10', () async {
      final h = _Harness(moments: [
        for (var i = 0; i < 23; i++) _post('p$i', age: Duration(minutes: i)),
        _post('legacy', kind: MomentKind.legacy, age: Duration.zero),
      ]);
      final container = await _container(h);
      var state = await _loaded(container, MomentFeed.forYou);
      expect(state.items.map((m) => m.id).take(3), ['p0', 'p1', 'p2']);
      expect(state.items, hasLength(10));
      expect(state.hasMore, isTrue);
      expect(state.items.any((m) => m.id == 'legacy'), isFalse);

      final controller = container.read(momentFeedProvider(MomentFeed.forYou).notifier);
      await controller.loadMore();
      await controller.loadMore();
      state = container.read(visibleMomentFeedProvider(MomentFeed.forYou));
      expect(state.items, hasLength(23));
      expect(state.items.map((m) => m.id).toSet(), hasLength(23));
      expect(state.hasMore, isFalse);
      expect(h.repo.feedReads, 3);
      await controller.loadMore();
      expect(h.repo.feedReads, 3, reason: 'no read after the last page');
    });

    test('Pratim follows the follows collection, follow / unfollow update it', () async {
      final h = _Harness(
        moments: [_post('a1', author: 'ana'), _post('b1', author: 'boris')],
        follows: [(_me, 'ana')],
      );
      final container = await _container(h);
      var state = await _loaded(container, MomentFeed.following);
      expect(state.items.map((m) => m.id), ['a1']);

      await h.followRepo.follow(followerUserId: _me, followedUserId: 'boris');
      await Future<void>.delayed(Duration.zero);
      state = await _loaded(container, MomentFeed.following);
      expect(state.items.map((m) => m.id).toSet(), {'a1', 'b1'});

      await h.followRepo.unfollow(followerUserId: _me, followedUserId: 'ana');
      await h.followRepo.unfollow(followerUserId: _me, followedUserId: 'boris');
      await Future<void>.delayed(Duration.zero);
      state = await _loaded(container, MomentFeed.following);
      expect(state.items, isEmpty);
      expect(state.blocker, MomentFeedBlocker.noFollowing);
    });

    test('following does not create a match or a like', () async {
      final h = _Harness(moments: [_post('a1', author: 'ana')]);
      final container = await _container(h);
      await h.followRepo.follow(followerUserId: _me, followedUserId: 'ana');
      final state = await _loaded(container, MomentFeed.following);
      expect(state.items.single.likes, isEmpty);
      expect(h.followRepo.edges, {'${_me}_ana'});
    });

    test('U blizini: only posts tagged with my city; no city = explained', () async {
      final h = _Harness(moments: [
        _post('ns', cityId: SerbiaLocations.noviSadId),
        _post('nis', cityId: SerbiaLocations.nisId),
        _post('nocity', cityId: ''),
      ]);
      final container = await _container(h);
      final state = await _loaded(container, MomentFeed.nearby);
      expect(state.items.map((m) => m.id), ['ns']);

      final noCity = _Harness(moments: [_post('ns')], city: null);
      final c2 = await _container(noCity);
      final empty = await _loaded(c2, MomentFeed.nearby);
      expect(empty.blocker, MomentFeedBlocker.noCity);
      expect(empty.items, isEmpty);
    });

    test('blocked authors are hidden in every tab', () async {
      final h = _Harness(
        moments: [_post('a1', author: 'ana'), _post('b1', author: 'boris')],
        follows: [(_me, 'ana'), (_me, 'boris')],
        blocked: {'boris'},
      );
      final container = await _container(h);
      expect((await _loaded(container, MomentFeed.forYou)).items.map((m) => m.id), ['a1']);
      expect((await _loaded(container, MomentFeed.following)).items.map((m) => m.id), ['a1']);
    });

    test('like is optimistic, idempotent and reverted on error', () async {
      final h = _Harness(moments: [_post('a1', likes: ['x'])]);
      final container = await _container(h);
      var shown = (await _loaded(container, MomentFeed.forYou)).items.single;
      final actions = container.read(momentActionsProvider);

      await actions.toggleLike(shown);
      shown = container.read(visibleMomentFeedProvider(MomentFeed.forYou)).items.single;
      expect(shown.likes, ['x', _me]);
      expect(h.repo.moments.single.likes, ['x', _me]);

      await h.repo.setLike('a1', liked: true);
      expect(h.repo.moments.single.likes, ['x', _me], reason: 'no duplicate');

      h.repo.failNextWrite = StateError('offline');
      await expectLater(actions.toggleLike(shown), throwsStateError);
      shown = container.read(visibleMomentFeedProvider(MomentFeed.forYou)).items.single;
      expect(shown.isLikedBy(_me), isTrue, reason: 'reverted');
    });

    test('comments: count follows add / delete, retry keeps one comment', () async {
      final h = _Harness(moments: [_post('a1', comments: 0)]);
      final container = await _container(h);
      final shown = (await _loaded(container, MomentFeed.forYou)).items.single;
      final actions = container.read(momentActionsProvider);
      final id = actions.newCommentId('a1');

      h.repo.failNextWrite = StateError('offline');
      await expectLater(
        actions.addComment(shown, 'Super šetnja', commentId: id),
        throwsStateError,
      );
      await actions.addComment(shown, 'Super šetnja', commentId: id);
      await h.repo.addComment('a1', 'Super šetnja', commentId: id);
      expect(h.repo.commentsOf('a1'), hasLength(1));
      expect(
        container.read(visibleMomentFeedProvider(MomentFeed.forYou)).items.single.commentsCount,
        1,
      );

      final reply = await actions.addComment(
        shown,
        'Hvala!',
        commentId: actions.newCommentId('a1'),
        replyTo: h.repo.commentsOf('a1').first,
      );
      final stored = h.repo.commentsOf('a1').firstWhere((c) => c.id == reply);
      expect(stored.replyToCommentId, id);

      await actions.deleteComment(shown, stored);
      expect(h.repo.commentsOf('a1'), hasLength(1));
      expect(
        container.read(visibleMomentFeedProvider(MomentFeed.forYou)).items.single.commentsCount,
        1,
      );
    });

    test('deleting a post removes it from all tabs', () async {
      final h = _Harness(
        moments: [_post('mine', author: _me), _post('a1', author: 'ana')],
        follows: [(_me, 'ana')],
      );
      final container = await _container(h);
      final mine = (await _loaded(container, MomentFeed.forYou))
          .items
          .firstWhere((m) => m.id == 'mine');
      await container.read(momentActionsProvider).delete(mine);
      expect(
        container.read(visibleMomentFeedProvider(MomentFeed.forYou)).items.map((m) => m.id),
        ['a1'],
      );
      expect(h.repo.moments.map((m) => m.id), ['a1']);
    });
  });

  group('screen', () {
    testWidgets('shows tabs, post cards and the new post button', (tester) async {
      await _pumpScreen(tester, _Harness(moments: [
        _post('a1', authorName: 'Ana', dogId: 'luna', dogName: 'Luna', likes: ['x', 'y']),
        _post('old', kind: MomentKind.legacy, authorName: 'Stari'),
      ]));

      expect(find.text(MomentsStrings.tabForYou), findsOneWidget);
      expect(find.text(MomentsStrings.tabFollowing), findsOneWidget);
      expect(find.text(MomentsStrings.tabNearby), findsOneWidget);
      expect(find.text(MomentsStrings.newPost), findsWidgets);
      expect(find.textContaining('Opis a1', findRichText: true), findsOneWidget);
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text(MomentsStrings.likesCount(2)), findsOneWidget);
      expect(find.textContaining('Opis old', findRichText: true), findsNothing, reason: 'legacy is not a feed post');
      // No old 24h story rail on Moments.
      expect(find.text(MomentsStrings.yourStory), findsNothing);
    });

    testWidgets('like button toggles and shows the count', (tester) async {
      final h = await _pumpScreen(tester, _Harness(moments: [_post('a1', likes: ['x'])]));
      await tester.tap(find.byKey(const ValueKey('moment-like-a1')));
      await _settle(tester);
      expect(find.text(MomentsStrings.likesCount(2)), findsOneWidget);
      expect(h.repo.moments.single.isLikedBy(_me), isTrue);

      await tester.tap(find.byKey(const ValueKey('moment-like-a1')));
      await _settle(tester);
      expect(find.text(MomentsStrings.likesCount(1)), findsOneWidget);
    });

    testWidgets('comments sheet: add, reply, older page', (tester) async {
      final now = DateTime.now();
      final h = await _pumpScreen(
        tester,
        _Harness(
          moments: [_post('a1', comments: 1)],
          comments: {
            'a1': [
              MomentComment(id: 'c1', authorUserId: 'ana', authorName: 'Ana', text: 'Prvi komentar', createdAt: now),
            ],
          },
        ),
      );
      await tester.tap(find.byKey(const ValueKey('moment-comments-a1')));
      await _settle(tester);
      expect(find.text(MomentsStrings.commentsTitle), findsOneWidget);
      expect(find.textContaining('Prvi komentar'), findsOneWidget);

      await tester.tap(find.text(MomentsStrings.reply));
      await _settle(tester);
      expect(find.text(MomentsStrings.replyingTo('Ana')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('moment-comment-input')), 'Slažem se');
      await tester.tap(find.byTooltip(MomentsStrings.send));
      await _settle(tester);

      final saved = h.repo.commentsOf('a1');
      expect(saved, hasLength(2));
      expect(saved.last.replyToCommentId, 'c1');
      expect(saved.last.authorUserId, _me);
      expect(find.textContaining('Slažem se'), findsOneWidget);
      expect(h.repo.moments.single.commentsCount, 2);
    });

    testWidgets('own post can be deleted, others can only be reported', (tester) async {
      final h = await _pumpScreen(
        tester,
        _Harness(moments: [
          _post('mine', author: _me, authorName: 'Ja', age: Duration.zero),
          _post('a1', author: 'ana', age: const Duration(hours: 2)),
        ]),
      );
      await tester.tap(find.byTooltip(MomentsStrings.postOptions).first);
      await _settle(tester);
      expect(find.text(MomentsStrings.deletePost), findsOneWidget);
      expect(find.text(MomentsStrings.reportPost), findsNothing);
      await tester.tap(find.text(MomentsStrings.deletePost));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, MomentsStrings.delete));
      await _settle(tester);
      expect(find.textContaining('Opis mine', findRichText: true), findsNothing);
      expect(h.repo.moments.map((m) => m.id), ['a1']);

      await tester.tap(find.byTooltip(MomentsStrings.postOptions).first);
      await _settle(tester);
      expect(find.text(MomentsStrings.deletePost), findsNothing);
      expect(find.text(MomentsStrings.reportPost), findsOneWidget);
      expect(find.text(MomentsStrings.blockAuthor), findsOneWidget);
    });

    testWidgets('Pratim tab explains how to follow', (tester) async {
      await _pumpScreen(tester, _Harness(moments: [_post('a1')]));
      await tester.tap(find.text(MomentsStrings.tabFollowing));
      await _settle(tester);
      expect(find.text(MomentsStrings.emptyFollowingNone), findsOneWidget);
    });

    testWidgets('empty Za tebe shows no fake posts', (tester) async {
      await _pumpScreen(tester, _Harness());
      expect(find.text(MomentsStrings.emptyForYou), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });
  });

  group('new post', () {
    testWidgets('failed publish shows retry; retry creates exactly one post', (tester) async {
      final h = _Harness();
      h.repo.failNextWrite = StateError('Nema mreže');
      await _pumpScreen(
        tester,
        h,
        size: const Size(412, 2400),
        child: Scaffold(
          body: CreateMomentSheet(
            initialPhoto: XFile.fromData(_png, name: 'pas.png', mimeType: 'image/png'),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text(MomentsStrings.newPostHint), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('moment-caption')), 'Prva šetnja');
      await tester.ensureVisible(find.byKey(const ValueKey('moment-publish')));
      await tester.tap(find.byKey(const ValueKey('moment-publish')));
      await _settle(tester);

      expect(find.byKey(const ValueKey('moment-publish-error')), findsOneWidget);
      expect(find.text(MomentsStrings.retryPublish), findsOneWidget);
      expect(h.repo.moments, isEmpty);

      await tester.ensureVisible(find.byKey(const ValueKey('moment-publish')));
      await tester.tap(find.byKey(const ValueKey('moment-publish')));
      await _settle(tester);

      expect(h.repo.moments, hasLength(1));
      final post = h.repo.moments.single;
      expect(post.isPost, isTrue);
      expect(post.caption, 'Prva šetnja');
      expect(post.cityId, SerbiaLocations.noviSadId);
      expect(post.authorUserId, _me);
      expect(h.uploads, hasLength(1), reason: 'photo uploaded once');
      expect(h.uploads.single, post.id, reason: 'draft id = post id');
    });

    testWidgets('publishing without a photo is refused', (tester) async {
      final h = _Harness();
      await _pumpScreen(
        tester,
        h,
        size: const Size(412, 2400),
        child: const Scaffold(body: CreateMomentSheet()),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('moment-publish')));
      await tester.tap(find.byKey(const ValueKey('moment-publish')));
      await _settle(tester);
      expect(find.text(MomentsStrings.photoRequired), findsOneWidget);
      expect(h.repo.moments, isEmpty);
      expect(h.uploads, isEmpty);
    });
  });

  group('legacy highlights', () {
    testWidgets('old moment stays playable through a highlight', (tester) async {
      final old = _post(
        'old',
        author: _me,
        kind: MomentKind.legacy,
        dogId: 'dog-rex',
        dogName: 'Reks',
        age: const Duration(days: 30),
      );
      await _pumpScreen(
        tester,
        _Harness(
          moments: [old],
          highlights: [
            StoryHighlight(
              id: 'h1',
              ownerId: _me,
              dogId: 'dog-rex',
              title: 'Plaža',
              momentIds: const ['old'],
              createdAt: DateTime.now(),
            ),
          ],
        ),
        child: const Scaffold(body: DogStoriesSection(dogId: 'dog-rex')),
      );

      expect(find.text('Plaža'), findsOneWidget);
      await tester.tap(find.text('Plaža'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(StoryViewerScreen), findsOneWidget);
      expect(find.text('Opis old'), findsOneWidget);
      await tester.tap(find.byTooltip(MomentsStrings.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('highlight editor lists my legacy moments and posts', (tester) async {
      await _pumpScreen(
        tester,
        _Harness(moments: [
          _post('m1', author: _me, dogId: 'dog-rex', dogName: 'Reks'),
          _post('m2', author: _me, kind: MomentKind.legacy, dogId: 'dog-rex', dogName: 'Reks', age: const Duration(days: 9)),
        ]),
        child: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: StoryHighlightsRow(dogId: 'dog-rex', editable: true),
          ),
        ),
      );
      expect(find.text(MomentsStrings.highlights), findsOneWidget);
      await tester.tap(find.text(MomentsStrings.newHighlight));
      await _settle(tester);
      expect(find.text(MomentsStrings.newHighlightTitle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
    });
  });

  group('firestore repository', () {
    late FakeFirebaseFirestore db;
    late FirestoreMomentsRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreMomentsRepository(
        firestore: db,
        currentUserId: 'alice',
        authorName: 'Alisa',
        authorPhotoUrl: 'https://x/a.jpg',
      );
    });

    MomentModel draft(String id) => MomentModel(
          id: id,
          authorUserId: '',
          authorName: 'Alisa',
          dogId: '',
          dogName: 'ignorisano',
          dogBreed: '',
          dogPhotoUrl: '',
          momentPhotoUrl: 'https://firebasestorage.googleapis.com/x.jpg',
          caption: '  Zdravo  ',
          locationName: 'Liman',
          cityId: 'novi_sad',
          likes: const ['fake'],
          commentsCount: 99,
          createdAt: DateTime.now(),
        );

    test('create writes a post with clean counters; same id twice = one post', () async {
      final id = repo.newMomentId();
      await repo.createMoment(draft(id));
      await repo.createMoment(draft(id));
      final docs = await db.collection('moments').get();
      expect(docs.docs, hasLength(1));
      final data = docs.docs.single.data();
      expect(data['kind'], 'post');
      expect(data['authorUserId'], 'alice');
      expect(data['authorPhotoUrl'], 'https://x/a.jpg');
      expect(data['likes'], isEmpty);
      expect(data['commentsCount'], 0);
      expect(data['caption'], 'Zdravo');
      expect(data['dogName'], '', reason: 'no dog selected');
    });

    test('feed reads only posts and pages across follow chunks', () async {
      final base = DateTime(2026, 10, 1);
      for (var i = 0; i < 40; i++) {
        await db.collection('moments').doc('p$i').set({
          'kind': 'post',
          'authorUserId': 'u$i',
          'cityId': i.isEven ? 'novi_sad' : 'nis',
          'momentPhotoUrl': 'https://x/$i.jpg',
          'likes': <String>[],
          'commentsCount': 0,
          'createdAt': base.add(Duration(minutes: i)),
        });
      }
      await db.collection('moments').doc('legacy').set({
        'authorUserId': 'u1',
        'momentPhotoUrl': 'https://x/l.jpg',
        'createdAt': base.add(const Duration(days: 1)),
      });

      final first = await repo.fetchFeedPage(const MomentFeedRequest.forYou());
      expect(first.items.map((m) => m.id).take(2), ['p39', 'p38']);
      expect(first.items.any((m) => m.id == 'legacy'), isFalse);

      // 40 followed authors = 2 `in` queries merged by time.
      final request = MomentFeedRequest.following([for (var i = 0; i < 40; i++) 'u$i']);
      final seen = <String>[];
      Object? cursor;
      var pages = 0;
      do {
        final page = await repo.fetchFeedPage(request, cursor: cursor, limit: 15);
        seen.addAll(page.items.map((m) => m.id));
        cursor = page.nextCursor;
        pages++;
      } while (cursor != null && pages < 10);
      expect(seen, hasLength(40));
      expect(seen.toSet(), hasLength(40));
      expect(seen.first, 'p39');
      expect(seen.last, 'p0');

      final nearby = await repo.fetchFeedPage(const MomentFeedRequest.nearby('nis'), limit: 50);
      expect(nearby.items, hasLength(20));
      expect(nearby.items.every((m) => m.cityId == 'nis'), isTrue);
    });

    test('like is a set operation and comments update the counter atomically', () async {
      final id = repo.newMomentId();
      await repo.createMoment(draft(id));
      await repo.setLike(id, liked: true);
      await repo.setLike(id, liked: true);
      var data = (await db.collection('moments').doc(id).get()).data()!;
      expect(data['likes'], ['alice']);

      final commentId = repo.newCommentId(id);
      await repo.addComment(id, 'Lepo', commentId: commentId);
      await repo.addComment(id, 'Lepo', commentId: commentId);
      data = (await db.collection('moments').doc(id).get()).data()!;
      expect(data['commentsCount'], 1);
      final comments = await db.collection('moments/$id/comments').get();
      expect(comments.docs, hasLength(1));

      await repo.deleteComment(id, commentId);
      data = (await db.collection('moments').doc(id).get()).data()!;
      expect(data['commentsCount'], 0);

      await repo.addComment(id, 'Opet', commentId: repo.newCommentId(id));
      await repo.deleteMoment(id);
      expect((await db.collection('moments').doc(id).get()).exists, isFalse);
      expect((await db.collection('moments/$id/comments').get()).docs, isEmpty);
    });

    test('highlights resolve old moments by id', () async {
      await db.collection('moments').doc('old').set({
        'authorUserId': 'alice',
        'momentPhotoUrl': 'https://x/o.jpg',
        'createdAt': DateTime(2025, 1, 1),
      });
      final found = await repo.fetchByIds(['old', 'deleted']);
      expect(found.single.id, 'old');
      expect(found.single.kind, MomentKind.legacy);
      final mine = await repo.fetchByAuthor('alice');
      expect(mine.map((m) => m.id), ['old']);
    });
  });
}
