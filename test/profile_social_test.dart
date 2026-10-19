import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/follows/data/local_follow_repository.dart';
import 'package:vauvau/features/follows/presentation/follow_controller.dart';
import 'package:vauvau/features/follows/presentation/follow_list_sheet.dart';
import 'package:vauvau/features/moments/data/firestore_moments_repository.dart';
import 'package:vauvau/features/moments/data/local_moments_repository.dart';
import 'package:vauvau/features/moments/domain/moment_model.dart';
import 'package:vauvau/features/moments/presentation/moments_controller.dart';
import 'package:vauvau/features/moments/presentation/moments_strings.dart';
import 'package:vauvau/features/profile/data/owner_public_profile.dart';
import 'package:vauvau/features/profile/presentation/profile_screen.dart';
import 'package:vauvau/features/profile/presentation/profile_strings.dart';
import 'package:vauvau/features/stories/data/local_story_repository.dart';
import 'package:vauvau/features/stories/domain/story.dart';
import 'package:vauvau/features/stories/presentation/story_highlight.dart';
import 'package:vauvau/features/stories/presentation/story_player_screen.dart';
import 'package:vauvau/features/stories/presentation/story_providers.dart';

const _me = 'local-user';

final Uint8List _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Story _myStory({String id = 's1', String dogId = 'my-dog'}) {
  final created = DateTime.now().subtract(const Duration(hours: 2));
  return Story(
    id: id,
    authorUserId: _me,
    authorName: 'Aleksandar',
    mediaPath: Story.mediaPathFor(_me, id),
    audience: StoryAudience.followers,
    createdAt: created,
    expiresAt: created.add(Story.lifetime),
    dogId: dogId,
    caption: 'Kej',
  );
}

MomentModel _post(String id) => MomentModel(
  id: id,
  authorUserId: _me,
  authorName: 'Aleksandar',
  dogId: 'my-dog',
  dogName: 'Luna',
  dogBreed: '',
  dogPhotoUrl: '',
  momentPhotoUrl: 'https://example.com/$id.jpg',
  caption: '',
  locationName: '',
  likes: const [],
  commentsCount: 0,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('story → istaknuto', () {
    late LocalMomentsRepository moments;
    late List<String> uploads;
    late ProviderContainer c;

    setUp(() {
      moments = LocalMomentsRepository(currentUserId: _me, seed: [_post('p1')]);
      uploads = [];
      c = ProviderContainer(
        overrides: [
          storyRepositoryProvider.overrideWithValue(
            _PngStoryRepository(seed: [_myStory(), _myStory(id: 's2', dogId: '')])
              ..currentUserId = _me,
          ),
          momentsRepositoryProvider.overrideWithValue(moments),
          storyArchiveUploaderProvider.overrideWithValue((bytes, stem) async {
            expect(bytes, isNotEmpty);
            uploads.add(stem);
            return 'https://example.com/$stem.jpg';
          }),
        ],
      );
      addTearDown(c.dispose);
    });

    test('kopija priče je trajna, van feeda i ne broji se kao objava', () async {
      final archiver = c.read(storyHighlightArchiverProvider);
      final moment = await archiver.archive(_myStory());

      expect(moment.id, 'story_s1');
      expect(moment.kind, MomentKind.legacy);
      expect(moment.dogId, 'my-dog');
      expect(moment.momentPhotoUrl, 'https://example.com/story_s1.jpg');
      expect(moment.caption, 'Kej');

      final stored = await moments.fetchByIds(['story_s1']);
      expect(stored.single.isPost, isFalse);
      expect(await moments.countByAuthor(_me), 1); // only the real post

      // Retrying the same story: same file, no second moment.
      await archiver.archive(_myStory());
      expect(uploads, ['story_s1', 'story_s1']);
      expect(await moments.fetchByIds(['story_s1']), hasLength(1));
    });

    testWidgets('moja priča u plejeru ima „Dodaj u istaknuto“', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: StoryPlayerScreen(groups: [StoryAuthorGroup.of([_myStory()])]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final button = find.byKey(const ValueKey('story-add-to-highlight'));
      expect(button, findsOneWidget);
      await tester.tap(button);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(MomentsStrings.addToHighlight), findsWidgets);
      expect(await moments.fetchByIds(['story_s1']), hasLength(1));
    });

    test('priča bez psa ide na izabranog psa sa profila', () async {
      final moment = await c
          .read(storyHighlightArchiverProvider)
          .archive(_myStory(id: 's2', dogId: ''));
      expect(moment.dogId, isNotEmpty);
    });

    test('Firestore: kopija se upisuje bez kind, brojač broji samo objave',
        () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreMomentsRepository(
        firestore: db,
        currentUserId: _me,
        authorName: 'Aleksandar',
      );
      await repo.createMoment(_post('p1'));
      final copy = MomentModel(
        id: 'story_s1',
        kind: MomentKind.legacy,
        authorUserId: _me,
        authorName: 'Aleksandar',
        dogId: '',
        dogName: '',
        dogBreed: '',
        dogPhotoUrl: '',
        momentPhotoUrl: 'https://example.com/story_s1.jpg',
        caption: '',
        locationName: '',
        likes: const [],
        commentsCount: 0,
        createdAt: DateTime(2026, 10, 1),
      );
      await repo.createMoment(copy);

      final data = (await db.collection('moments').doc('story_s1').get())
          .data()!;
      expect(data.containsKey('kind'), isFalse);
      expect(
        (await db.collection('moments').doc('p1').get()).data()!['kind'],
        'post',
      );
      expect(await repo.countByAuthor(_me), 1);
    });
  });

  group('profil: objave, pratioci, pratim', () {
    Future<void> pumpProfile(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderContainer(
        overrides: [
          discoverImageFactoryProvider.overrideWith(
            (ref) => (_) => MemoryImage(_png),
          ),
          socialUserIdProvider.overrideWithValue(_me),
          followRepositoryProvider.overrideWithValue(
            LocalFollowRepository(
              seed: const [('ana', _me), ('ivan', _me), (_me, 'mila')],
            ),
          ),
          ownerProfileLoaderProvider.overrideWithValue(
            (id) async => OwnerPublicProfile(
              userId: id,
              name: 'Osoba $id',
              photoUrl: '',
              location: '',
              bio: '',
              dogs: const [],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(discoverControllerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
        ),
      );
      await tester.pumpAndSettle();
    }

    String countOf(WidgetTester tester, String key) {
      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      return texts.first!;
    }

    testWidgets('brojke pored slike i „Objave“ umesto „Momenti“', (
      tester,
    ) async {
      await pumpProfile(tester);

      expect(find.text(ProfileStrings.metricPosts), findsOneWidget);
      expect(find.text('Momenti'), findsNothing);
      expect(countOf(tester, 'profile-count-followers'), '2');
      expect(countOf(tester, 'profile-count-following'), '1');
      expect(find.text(ProfileStrings.followers), findsOneWidget);
      expect(find.text(ProfileStrings.followingCount), findsOneWidget);
    });

    testWidgets('tap na Pratioci otvara listu osoba', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.byKey(const ValueKey('profile-count-followers')));
      await tester.pumpAndSettle();

      expect(find.byType(FollowListSheet), findsOneWidget);
      expect(find.text('Osoba ana'), findsOneWidget);
      expect(find.text('Osoba ivan'), findsOneWidget);
      expect(find.text('Osoba mila'), findsNothing);
    });
  });
}

/// Local stories whose media decodes as a real (1×1 PNG) image.
class _PngStoryRepository extends LocalStoryRepository {
  _PngStoryRepository({super.seed});

  @override
  Future<Uint8List> loadMedia(Story story) async => _png;
}
