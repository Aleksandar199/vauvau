import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/discover/data/local_discover_repository.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/discover/domain/discover_repository.dart';
import 'package:vauvau/features/discover/domain/geo_query.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/discover/presentation/discover_screen.dart';
import 'package:vauvau/features/discover/presentation/discover_strings.dart';
import 'package:vauvau/features/discover/presentation/widgets/discover_skeleton.dart';
import 'package:vauvau/features/profile/domain/matching_filters.dart';
import 'package:vauvau/features/profile/presentation/profile_controller.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

DiscoverProfile _dog(int index) {
  return DiscoverProfile(
    id: 'dog-$index',
    name: 'Pas $index',
    ownerName: 'Vlasnik $index',
    ownerId: 'owner-$index',
    breed: 'Mešanac',
    ageYears: 2,
    gender: 'mužjak',
    size: 'srednji',
    location: 'Novi Sad - Liman',
    bio: '',
    photoUrls: const [],
    // Newest first: dog-0 is the newest.
    createdAt: DateTime(2026, 1, 1).subtract(Duration(days: index)),
  );
}

/// Local repository whose first-page stream the test controls.
class _ControlledRepository extends LocalDiscoverRepository {
  _ControlledRepository(List<DiscoverProfile> seed) : super(seed: seed);

  final firstPages = <StreamController<DiscoverPage>>[];
  final fetchedCursors = <Object?>[];

  @override
  Stream<DiscoverPage> watchProfiles({
    required String excludeOwnerId,
    GeoQuery? geo,
    int limit = 8,
  }) {
    final controller = StreamController<DiscoverPage>();
    firstPages.add(controller);
    return controller.stream;
  }

  @override
  Future<DiscoverPage> fetchProfilesPage({
    required String excludeOwnerId,
    GeoQuery? geo,
    Object? cursor,
    int limit = 8,
  }) {
    fetchedCursors.add(cursor);
    return super.fetchProfilesPage(
      excludeOwnerId: excludeOwnerId,
      geo: geo,
      cursor: cursor,
      limit: limit,
    );
  }

  Future<void> emitFirstPage() async {
    final page = await super.fetchProfilesPage(
      excludeOwnerId: '',
      limit: DiscoverFeedController.pageSize,
    );
    firstPages.last.add(page);
  }

  Future<void> closeAll() async {
    for (final controller in firstPages) {
      await controller.close();
    }
  }
}

Future<void> _pumpScreen(
  WidgetTester tester,
  DiscoverRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(412, 892));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverImageFactoryProvider.overrideWith((ref) {
          return (_) => MemoryImage(_transparentPng);
        }),
        discoverRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: Scaffold(body: DiscoverScreen())),
    ),
  );
  await tester.pump();
}

void main() {
  test('loads a small first page, then the rest page by page', () async {
    final seed = [for (var i = 0; i < 20; i++) _dog(i)];
    final container = ProviderContainer(
      overrides: [discoverProfilesProvider.overrideWith((ref) => seed)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(discoverFeedControllerProvider, (_, _) {});
    addTearDown(sub.close);

    expect(container.read(discoverFeedControllerProvider).isLoading, isTrue);
    await pumpEventQueue();

    var feed = container.read(discoverFeedControllerProvider);
    expect(feed.isLoading, isFalse);
    expect(feed.items, hasLength(DiscoverFeedController.pageSize));
    expect(feed.items.first.id, 'dog-0');
    expect(feed.hasMore, isTrue);

    final notifier = container.read(discoverFeedControllerProvider.notifier);
    await notifier.loadMore();
    feed = container.read(discoverFeedControllerProvider);
    expect(feed.items, hasLength(16));
    expect(feed.hasMore, isTrue);

    await notifier.loadMore();
    feed = container.read(discoverFeedControllerProvider);
    expect(feed.items, hasLength(20));
    expect(feed.hasMore, isFalse);
    expect(
      feed.items.map((dog) => dog.id).toSet(),
      {for (final dog in seed) dog.id},
    );

    // Exhausted: further calls do nothing.
    await notifier.loadMore();
    expect(container.read(discoverFeedControllerProvider).items, hasLength(20));
    expect(
      container.read(discoverControllerProvider).catalog.map((d) => d.id),
      [for (final dog in seed) dog.id],
    );
  });

  testWidgets('shows a skeleton, not the empty state, while loading', (
    tester,
  ) async {
    final repository = _ControlledRepository([
      for (var i = 0; i < 3; i++) _dog(i),
    ]);
    addTearDown(repository.closeAll);
    await _pumpScreen(tester, repository);

    expect(find.byType(DiscoverSkeletonGrid), findsOneWidget);
    expect(find.text(DiscoverStrings.emptyTitle), findsNothing);

    await repository.emitFirstPage();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Pas 0'), findsWidgets);
    expect(find.byType(DiscoverSkeletonGrid), findsNothing);
    expect(find.text(DiscoverStrings.emptyTitle), findsNothing);
  });

  testWidgets('keeps the cards while the feed reloads for a new area', (
    tester,
  ) async {
    final repository = _ControlledRepository([
      for (var i = 0; i < 3; i++) _dog(i),
    ]);
    addTearDown(repository.closeAll);
    await _pumpScreen(tester, repository);
    await repository.emitFirstPage();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Pas 0'), findsWidgets);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoverScreen)),
    );
    container
        .read(matchingFiltersProvider.notifier)
        .apply(const MatchingFilters(radiusKm: 35));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // A new first-page query is open but has not answered yet.
    expect(repository.firstPages.length, greaterThan(1));
    expect(container.read(discoverFeedControllerProvider).isLoading, isTrue);
    expect(find.textContaining('Pas 0'), findsWidgets);
    expect(find.byType(DiscoverSkeletonGrid), findsNothing);
    expect(find.text(DiscoverStrings.emptyTitle), findsNothing);
  });

  testWidgets('empty state appears only after loading really finished', (
    tester,
  ) async {
    final repository = _ControlledRepository(const []);
    addTearDown(repository.closeAll);
    await _pumpScreen(tester, repository);
    expect(find.text(DiscoverStrings.emptyTitle), findsNothing);

    repository.firstPages.last.add(const DiscoverPage(items: []));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DiscoverSkeletonGrid), findsNothing);
    expect(find.text(DiscoverStrings.emptyTitle), findsOneWidget);
  });

  testWidgets('fetches the next page when only a few cards are left', (
    tester,
  ) async {
    final repository = _ControlledRepository([
      for (var i = 0; i < 12; i++) _dog(i),
    ]);
    addTearDown(repository.closeAll);
    await _pumpScreen(tester, repository);
    await repository.emitFirstPage();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The last first-page cards are within reach: one background fetch
    // continues after the first page.
    expect(repository.fetchedCursors, [DiscoverFeedController.pageSize]);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoverScreen)),
    );
    final feed = container.read(discoverFeedControllerProvider);
    expect(feed.items, hasLength(12));
    expect(feed.hasMore, isFalse);
  });
}
