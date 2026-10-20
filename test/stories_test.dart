import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vauvau/core/media/video_limits.dart';
import 'package:vauvau/core/media/video_strings.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/discover/data/local_discover_repository.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/discover/presentation/discover_strings.dart';
import 'package:vauvau/features/discover/presentation/widgets/swipe_dog_card.dart';
import 'package:vauvau/features/follows/data/local_follow_repository.dart';
import 'package:vauvau/features/follows/domain/follow_repository.dart';
import 'package:vauvau/features/follows/presentation/follow_controller.dart';
import 'package:vauvau/features/follows/presentation/follows_strings.dart';
import 'package:vauvau/features/moderation/presentation/block_controller.dart';
import 'package:vauvau/features/notifications/data/social_notifications.dart';
import 'package:vauvau/features/stories/data/local_story_repository.dart';
import 'package:vauvau/features/stories/domain/story.dart';
import 'package:vauvau/features/stories/domain/story_repository.dart';
import 'package:vauvau/features/stories/presentation/create_story_sheet.dart';
import 'package:vauvau/features/stories/presentation/stories_strings.dart';
import 'package:vauvau/features/stories/presentation/story_providers.dart';
import 'package:vauvau/features/stories/presentation/widgets/stories_bar.dart';
import 'package:vauvau/features/stories/presentation/widgets/story_media.dart';

const me = 'me';

final Uint8List _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Story _story(
  String id,
  String author, {
  StoryAudience audience = StoryAudience.everyone,
  Duration age = const Duration(hours: 1),
}) {
  final created = DateTime.now().subtract(age);
  return Story(
    id: id,
    authorUserId: author,
    authorName: 'Ime $author',
    mediaPath: Story.mediaPathFor(author, id),
    audience: audience,
    createdAt: created,
    expiresAt: created.add(Story.lifetime),
    dogId: 'dog-$author',
    dogName: 'Pas $author',
  );
}

class _Harness {
  _Harness({
    Iterable<(String, String)> follows = const [],
    Iterable<Story> stories = const [],
    Set<String> blockedByAuthor = const {},
    Set<String> blockedByMe = const {},
  }) {
    followRepo = LocalFollowRepository(seed: follows);
    storyRepo = LocalStoryRepository(
      seed: stories,
      isFollowing: (a, b) =>
          followRepo.edges.contains(FollowRepository.docId(a, b)),
      // "author:viewer" pairs.
      isBlockedBy: (author, viewer) =>
          blockedByAuthor.contains('$author:$viewer'),
    )..currentUserId = me;
    notifications = LocalSocialNotificationWriter();
    overrides = [
      socialUserIdProvider.overrideWithValue(me),
      socialUserNameProvider.overrideWithValue('Marko'),
      followRepositoryProvider.overrideWithValue(followRepo),
      storyRepositoryProvider.overrideWithValue(storyRepo),
      socialNotificationWriterProvider.overrideWithValue(notifications),
      blockedUserIdsProvider.overrideWithValue(blockedByMe),
      chatSeedProvider.overrideWith((ref) => const []),
      discoverImageFactoryProvider.overrideWith(
        (ref) => (_) => MemoryImage(_png),
      ),
    ];
  }

  late final LocalFollowRepository followRepo;
  late final LocalStoryRepository storyRepo;
  late final LocalSocialNotificationWriter notifications;
  late final List<Override> overrides;

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [...overrides]);
    addTearDown(c.dispose);
    return c;
  }
}

Future<StoryBarState> _settledBar(ProviderContainer c) async {
  final sub = c.listen(storyBarProvider, (_, _) {});
  addTearDown(sub.close);
  await c.read(followingIdsProvider.future);
  await c.read(followerIdsProvider.future);
  await pumpEventQueue();
  await c.read(followedStoriesProvider.future);
  await pumpEventQueue();
  return c.read(storyBarProvider);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('grupisanje priča', () {
    test('moja prva, neviđene pre viđenih, istekle i blokirane se ne vide', () {
      final groups = groupStoriesByAuthor(
        [
          _story('a1', 'ana', age: const Duration(hours: 3)),
          _story('a2', 'ana', age: const Duration(hours: 1)),
          _story('b1', 'boris', age: const Duration(minutes: 5)),
          _story('m1', me),
          _story('old', 'ana', age: const Duration(hours: 30)),
          _story('x1', 'blokiran'),
        ],
        me: me,
        seen: {'b1'},
        now: DateTime.now(),
        blocked: {'blokiran'},
      );
      expect(groups.map((g) => g.authorUserId), [me, 'ana', 'boris']);
      final ana = groups[1];
      expect(ana.stories.map((s) => s.id), ['a1', 'a2']);
      expect(ana.hasUnseen({'b1'}), isTrue);
      expect(groups[2].hasUnseen({'b1'}), isFalse);
    });
  });

  group('traka priča', () {
    test('prikazuje moju priču i priče onih koje pratim, ne i ostale', () async {
      final h = _Harness(
        follows: const [(me, 'ana')],
        stories: [
          _story('m1', me),
          _story('a1', 'ana'),
          _story('a2', 'ana', audience: StoryAudience.followers),
          _story('b1', 'boris'), // public, but I do not follow boris
          _story('old', 'ana', age: const Duration(hours: 25)),
        ],
      );
      final c = h.container();
      final bar = await _settledBar(c);
      expect(bar.mine?.stories.map((s) => s.id), ['m1']);
      expect(bar.groups.map((g) => g.authorUserId), ['ana']);
      expect(
        bar.groups.single.stories.map((s) => s.id).toSet(),
        {'a1', 'a2'},
      );
      expect(bar.followsAnyone, isTrue);
    });

    test('viđena priča menja stanje prstena', () async {
      final h = _Harness(
        follows: const [(me, 'ana')],
        stories: [_story('a1', 'ana')],
      );
      final c = h.container();
      var bar = await _settledBar(c);
      final seen = c.read(seenStoriesStoreProvider);
      expect(bar.groups.single.hasUnseen(seen), isTrue);
      c.read(storyActionsProvider).markViewed(bar.groups.single.stories.single);
      bar = c.read(storyBarProvider);
      expect(bar.groups.single.hasUnseen(c.read(seenStoriesStoreProvider)), isFalse);
    });

    testWidgets('bez praćenja prikazuje jasnu poruku', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...h.overrides],
          child: const MaterialApp(home: Scaffold(body: StoriesBar())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(StoriesStrings.yourStory), findsOneWidget);
      expect(find.text(StoriesStrings.emptyNoFollows), findsOneWidget);
    });

    testWidgets('autor sa više priča ima oznaku broja', (tester) async {
      final h = _Harness(
        follows: const [(me, 'ana')],
        stories: [_story('a1', 'ana'), _story('a2', 'ana')],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...h.overrides],
          child: const MaterialApp(home: Scaffold(body: StoriesBar())),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('Ime ana'), findsOneWidget);
      expect(find.byKey(const ValueKey('story-count-badge')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('praćenje', () {
    test('prati i otprati vlasnika; nema duplikata ni praćenja sebe', () async {
      final h = _Harness();
      final c = h.container();
      // Riverpod 3 pauses providers nobody listens to.
      final sub = c.listen(followingIdsProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = c.read(followControllerProvider.notifier);
      // Two dogs of the same owner → one relationship with the owner.
      await controller.follow('ana');
      await controller.follow('ana');
      expect(h.followRepo.edges, {'me_ana'});
      expect(h.followRepo.createdCount, 1);
      expect(h.notifications.sent.keys, ['follow_me_ana']);
      expect(h.notifications.sent.values.single.type,
          SocialNotificationType.follow);
      await c.read(followingIdsProvider.future);
      await pumpEventQueue();
      expect(c.read(isFollowingProvider('ana')), isTrue);

      await controller.unfollow('ana');
      await pumpEventQueue();
      expect(h.followRepo.edges, isEmpty);
      expect(c.read(isFollowingProvider('ana')), isFalse);

      // Re-follow: no second notification (same deterministic id).
      await controller.follow('ana');
      expect(h.notifications.sent, hasLength(1));

      expect(() => controller.follow(me), throwsA(isA<FollowException>()));
    });

    testWidgets('kartica psa: lajk ostaje, Prati umesto X i Super lajka', (
      tester,
    ) async {
      final h = _Harness();
      final discover = LocalDiscoverRepository(seed: const []);
      const dog = DiscoverProfile(
        id: 'dog-ana',
        name: 'Leo',
        ownerName: 'Ana',
        ownerId: 'ana',
        breed: 'Mešanac',
        ageYears: 2,
        gender: 'mužjak',
        size: 'srednji',
        location: 'Novi Sad',
        bio: '',
        photoUrls: [],
      );
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...h.overrides,
            discoverRepositoryProvider.overrideWithValue(discover),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DogDetailSheet(profile: dog)),
          ),
        ),
      );
      await tester.pump();
      expect(find.byTooltip(DiscoverStrings.like), findsOneWidget);
      expect(find.byTooltip(DiscoverStrings.superLike), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.text(FollowsStrings.follow), findsOneWidget);

      await tester.tap(find.text(FollowsStrings.follow));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(FollowsStrings.following), findsOneWidget);
      expect(h.followRepo.edges, {'me_ana'});
      // Follow never likes, matches or swipes.
      expect(await discover.hasLiked(userId: me, dogId: dog.id), isFalse);

      await tester.tap(find.text(FollowsStrings.following));
      await tester.pump();
      expect(find.text(FollowsStrings.unfollowTitle('Ana')), findsOneWidget);
      await tester.tap(find.text(FollowsStrings.unfollow));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(h.followRepo.edges, isEmpty);
      expect(find.text(FollowsStrings.follow), findsOneWidget);
    });
  });

  group('publika i pristup', () {
    final all = _story('all', 'ana');
    final followers = _story('fol', 'ana', audience: StoryAudience.followers);
    final following = _story('fng', 'ana', audience: StoryAudience.following);

    LocalStoryRepository repo({
      Set<String> edges = const {},
      Set<String> blocks = const {},
    }) {
      return LocalStoryRepository(
        isFollowing: (a, b) => edges.contains('${a}_$b'),
        isBlockedBy: (author, viewer) => blocks.contains('$author:$viewer'),
        seed: [all, followers, following],
      );
    }

    test('Svi korisnici: svi prijavljeni', () {
      final r = repo();
      expect(r.canView(all, 'bilo-ko'), isTrue);
      expect(r.canView(all, ''), isFalse);
    });

    test('Moji pratioci: samo ko prati autora', () {
      final r = repo(edges: {'bob_ana'});
      expect(r.canView(followers, 'bob'), isTrue);
      expect(r.canView(followers, 'carol'), isFalse);
      // Direction matters: ana following carol does not help carol here.
      expect(repo(edges: {'ana_carol'}).canView(followers, 'carol'), isFalse);
    });

    test('Osobe koje ja pratim: samo koje autor prati', () {
      final r = repo(edges: {'ana_carol', 'bob_ana'});
      expect(r.canView(following, 'carol'), isTrue);
      expect(r.canView(following, 'bob'), isFalse);
    });

    test('autor uvek vidi svoje; blokirani ne vidi ništa', () async {
      final r = repo(edges: {'bob_ana'}, blocks: {'ana:bob'});
      expect(r.canView(followers, 'ana'), isTrue);
      expect(r.canView(all, 'bob'), isFalse);
      expect(r.canView(followers, 'bob'), isFalse);
      r.currentUserId = 'bob';
      expect(await r.fetchStory('all'), isNull);
      await expectLater(r.loadMedia(all), throwsA(isA<StoryAccessException>()));
      await expectLater(r.like(all, 'bob'), throwsA(isA<StoryAccessException>()));
    });

    test('nedozvoljena priča se ne dobija ni po id-ju', () async {
      final r = repo()..currentUserId = 'carol';
      expect(await r.fetchStory('fol'), isNull);
      expect(await r.fetchStory('all'), isNotNull);
      await expectLater(
        r.loadMedia(followers),
        throwsA(isA<StoryAccessException>()),
      );
    });

    test('istekla priča nije aktivna', () async {
      final old = _story('old', 'ana', age: const Duration(hours: 25));
      final r = LocalStoryRepository(seed: [old])..currentUserId = 'bob';
      expect(old.isActive(DateTime.now()), isFalse);
      expect(r.canView(old, 'bob'), isFalse);
      expect(await r.fetchStory('old'), isNull);
    });

    test('odjava praćenja odmah uskraćuje priče za pratioce', () async {
      final h = _Harness(
        follows: const [(me, 'ana')],
        stories: [_story('fol', 'ana', audience: StoryAudience.followers)],
      );
      expect(h.storyRepo.canView(followers, me), isTrue);
      await h.followRepo.unfollow(followerUserId: me, followedUserId: 'ana');
      expect(h.storyRepo.canView(followers, me), isFalse);
    });
  });

  group('sviđanja, odgovori i brisanje', () {
    test('sviđanje se ne duplira, obaveštenje stiže jednom', () async {
      final story = _story('a1', 'ana');
      final h = _Harness(follows: const [(me, 'ana')], stories: [story]);
      final c = h.container();
      final actions = c.read(storyActionsProvider);
      await actions.setLiked(story, liked: true);
      await actions.setLiked(story, liked: true);
      expect(h.storyRepo.likesOf('a1'), {me});
      await actions.setLiked(story, liked: false);
      expect(h.storyRepo.likesOf('a1'), isEmpty);
      await actions.setLiked(story, liked: true);
      expect(h.notifications.sent.keys, ['storylike_a1_me']);
    });

    test('blokirani autor: nema sviđanja ni odgovora', () async {
      final story = _story('a1', 'ana');
      final h = _Harness(stories: [story], blockedByMe: {'ana'});
      final actions = h.container().read(storyActionsProvider);
      await expectLater(
        actions.setLiked(story, liked: true),
        throwsA(isA<StoryAccessException>()),
      );
      await expectLater(
        actions.reply(story, 'Ćao', nonce: 'n1'),
        throwsA(isA<StoryAccessException>()),
      );
      expect(h.notifications.sent, isEmpty);
    });

    test('odgovor stiže u postojeće Poruke sa kontekstom priče', () async {
      final story = _story('a1', 'ana');
      final h = _Harness(follows: const [(me, 'ana')], stories: [story]);
      final c = h.container();
      // Let the (signed-out) auth stream settle so the inbox is not rebuilt.
      final inboxSub = c.listen(chatInboxProvider, (_, _) {});
      addTearDown(inboxSub.close);
      await pumpEventQueue();
      final actions = c.read(storyActionsProvider);
      final chatId = await actions.reply(story, 'Divan pas!', nonce: 'n1');
      final chat = c.read(chatInboxProvider.notifier).byId(chatId);
      expect(chat, isNotNull);
      final message = chat!.messages.last;
      expect(message.text, 'Divan pas!');
      expect(message.storyId, 'a1');
      expect(message.storyAuthorId, 'ana');
      final note = h.notifications.sent.values.single;
      expect(note.type, SocialNotificationType.storyReply);
      expect(note.conversationId, chatId);
      expect(note.storyId, 'a1');
      // Retry with the same nonce: one notification, never to myself.
      await actions.reply(story, 'Divan pas!', nonce: 'n1');
      expect(h.notifications.sent, hasLength(1));
      final mine = _story('m1', me);
      await expectLater(
        actions.reply(mine, 'x', nonce: 'n2'),
        throwsA(isA<StoryAccessException>()),
      );
    });

    test('obrisana priča i nedostajući medij se bezbedno obrađuju', () async {
      final story = _story('m1', me);
      final h = _Harness(stories: [story]);
      final c = h.container();
      await c.read(storyActionsProvider).delete(story);
      expect(h.storyRepo.storyCount, 0);
      expect(h.storyRepo.hasMedia(story.mediaPath), isFalse);
      expect(await c.read(storyActionsProvider).fetch('m1'), isNull);
    });

    testWidgets('nedostupan medij prikazuje poruku umesto greške', (
      tester,
    ) async {
      final h = _Harness();
      final gone = _story('gone', 'ana');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...h.overrides],
          child: MaterialApp(
            home: Scaffold(
              body: ColoredBox(
                color: Colors.black,
                child: StoryMediaImage(story: gone),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(StoriesStrings.unavailable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('objavljivanje', () {
    testWidgets('publika je obavezna; neuspeli upload se ponavlja', (
      tester,
    ) async {
      final h = _Harness();
      h.storyRepo.failNextUpload = StateError('network');
      Story? published;
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...h.overrides],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      published = await showModalBottomSheet<Story>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => CreateStorySheet(
                          picker: (_) async => XFile.fromData(
                            _png,
                            name: 'pas.png',
                            mimeType: 'image/png',
                          ),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('story-pick-gallery')));
      await tester.pumpAndSettle();

      ButtonStyleButton publishButton() => tester.widget<ButtonStyleButton>(
            find.byKey(const ValueKey('story-publish')),
          );
      // No audience chosen yet → cannot publish.
      expect(publishButton().onPressed, isNull);
      for (final audience in StoryAudience.values) {
        expect(find.text(StoriesStrings.audienceLabel(audience)), findsOneWidget);
      }
      await tester.tap(find.text('Moji pratioci'));
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('story-caption')), 'Leo');
      await tester.pump();
      expect(publishButton().onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('story-publish')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-publish-error')), findsOneWidget);
      // The photo / video picker row makes the sheet taller.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('story-publish')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CreateStorySheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(StoriesStrings.retry), findsOneWidget);
      expect(h.storyRepo.storyCount, 0);

      await tester.tap(find.byKey(const ValueKey('story-publish')));
      await tester.pumpAndSettle();
      expect(h.storyRepo.storyCount, 1);
      expect(published?.audience, StoryAudience.followers);
      expect(published?.caption, 'Leo');
      expect(
        published!.expiresAt.difference(published!.createdAt),
        Story.lifetime,
      );
    });

    testWidgets('video: predug se odbija, kratak se objavljuje kao video', (
      tester,
    ) async {
      final h = _Harness();
      var length = const Duration(seconds: 40);
      await tester.binding.setSurfaceSize(const Size(360, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...h.overrides],
          child: MaterialApp(
            home: Scaffold(
              body: CreateStorySheet(
                videoPicker: (_) async => XFile.fromData(
                  Uint8List(4096),
                  name: 'leo.mp4',
                  mimeType: 'video/mp4',
                ),
                videoProbe: (_) async => length,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // Galerija and Kamera in one row (360 px wide phone).
      final gallery = tester.getRect(
        find.byKey(const ValueKey('story-pick-gallery')),
      );
      final camera = tester.getRect(
        find.byKey(const ValueKey('story-pick-camera')),
      );
      expect(gallery.top, camera.top);
      expect(gallery.width, closeTo(camera.width, 0.5));

      await tester.tap(find.byKey(const ValueKey('story-pick-mode-video')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('story-pick-gallery')));
      await tester.pump();
      await tester.pump();
      expect(
        find.text(
          VideoStrings.problem(VideoProblem.tooLong, VideoLimits.storyMaxDuration),
        ),
        findsOneWidget,
      );

      length = const Duration(seconds: 8);
      await tester.tap(find.byKey(const ValueKey('story-pick-gallery')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('story-video-preview')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-audience-all')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('story-publish')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CreateStorySheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const ValueKey('story-publish')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(h.storyRepo.storyCount, 1);
      final story = (await h.storyRepo.watchMyStories(me).first).single;
      expect(story.isVideo, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
