import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/dog_breeds.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/features/groups/data/firestore_groups_repository.dart';
import 'package:vauvau/features/groups/data/local_groups_repository.dart';
import 'package:vauvau/features/groups/data/seed_breed_groups.dart';
import 'package:vauvau/features/groups/domain/group_ranking.dart';
import 'package:vauvau/features/groups/domain/groups_models.dart';
import 'package:vauvau/features/groups/presentation/groups_controller.dart';
import 'package:vauvau/features/groups/presentation/groups_list_screen.dart';
import 'package:vauvau/features/groups/presentation/groups_strings.dart';

BreedGroup g(
  String id, {
  GroupScope scope = GroupScope.global,
  String cityId = '',
  GroupCategory category = GroupCategory.general,
  String locationName = '',
  String breedKey = '',
  bool featured = false,
  int sortOrder = 0,
  DateTime? lastMessageAt,
  bool approved = true,
  String? title,
}) {
  return BreedGroup(
    id: id,
    title: title ?? id,
    description: '',
    imageUrl: '',
    memberIds: const [],
    memberCount: 0,
    scope: scope,
    cityId: cityId,
    category: category,
    locationName: locationName,
    breedKey: breedKey,
    featured: featured,
    sortOrder: sortOrder,
    lastMessageAt: lastMessageAt,
    isApproved: approved,
  );
}

List<String> ids(Iterable<BreedGroup> groups) =>
    groups.map((group) => group.id).toList();

void main() {
  final groups = [
    g('global-plain', sortOrder: 5),
    g('global-featured', featured: true, sortOrder: 9),
    g('ns-general', scope: GroupScope.local, cityId: 'novi_sad'),
    g(
      'ns-park',
      scope: GroupScope.local,
      cityId: 'novi_sad',
      category: GroupCategory.parks,
      locationName: 'Liman',
    ),
    g(
      'bg-park',
      scope: GroupScope.local,
      cityId: 'beograd',
      category: GroupCategory.parks,
      locationName: 'Ada',
    ),
    g('pending', approved: false),
    g(
      'lab-ns',
      scope: GroupScope.breed,
      cityId: 'novi_sad',
      breedKey: 'Labrador',
    ),
  ];

  group('sorting', () {
    test('Cela Srbija: featured global, global, location, other local', () {
      final sorted = GroupRanking.sort(
        groups.where((x) => x.isApproved && x.scope != GroupScope.breed),
      );
      expect(ids(sorted), [
        'global-featured',
        'global-plain',
        'bg-park',
        'ns-park',
        'ns-general',
      ]);
    });

    test('city: location groups, general city group, then global', () {
      final result = GroupRanking.walkGroups(
        groups,
        const GroupFilter(cityId: 'novi_sad'),
      );
      expect(ids(result), [
        'ns-park',
        'ns-general',
        'global-featured',
        'global-plain',
      ]);
    });

    test('real activity wins inside a tier; empty groups are not promoted', () {
      final older = g('a', lastMessageAt: DateTime(2026, 1, 1));
      final newer = g('b', lastMessageAt: DateTime(2026, 2, 1));
      final silent = g('c', sortOrder: -5);
      expect(ids(GroupRanking.sort([silent, older, newer])), ['b', 'a', 'c']);
    });

    test('member count never changes the order; ties are stable', () {
      final big = BreedGroup(
        id: 'big',
        title: 'Zeta',
        description: '',
        imageUrl: '',
        memberIds: List.generate(50, (i) => 'u$i'),
        memberCount: 50,
      );
      final small = g('small', title: 'Alfa');
      expect(ids(GroupRanking.sort([big, small])), ['small', 'big']);
      expect(
        ids(GroupRanking.sort([small, big])),
        ids(GroupRanking.sort([big, small])),
      );
    });
  });

  group('filters', () {
    test('city and type combine; breed and pending groups never listed', () {
      expect(
        ids(
          GroupRanking.walkGroups(
            groups,
            const GroupFilter(
              cityId: 'novi_sad',
              category: GroupCategory.parks,
            ),
          ),
        ),
        ['ns-park'],
      );
      expect(
        ids(
          GroupRanking.walkGroups(
            groups,
            const GroupFilter(cityId: 'nis', category: GroupCategory.parks),
          ),
        ),
        isEmpty,
      );
      final all = ids(GroupRanking.walkGroups(groups, const GroupFilter()));
      expect(all, isNot(contains('pending')));
      expect(all, isNot(contains('lab-ns')));
    });
  });

  group('old documents', () {
    test('document without new fields is global/general and still parses', () {
      final parsed = BreedGroup.tryFromMap('legacy-user-group', {
        'title': 'Stara grupa',
        'description': 'x',
        'memberIds': ['a'],
        'memberCount': 1,
        'isApproved': true,
      })!;
      expect(parsed.scope, GroupScope.global);
      expect(parsed.cityId, isEmpty);
      expect(parsed.category, GroupCategory.general);
      expect(parsed.featured, isFalse);
    });

    test('preset documents are classified without a migration', () {
      final park = BreedGroup.tryFromMap('limanski-park', {
        'title': '🌳 Limanski park',
        'description': '',
        'memberCount': 38,
        'isApproved': true,
      })!;
      expect(park.scope, GroupScope.local);
      expect(park.cityId, 'novi_sad');
      expect(park.hasLocation, isTrue);
      expect(park.verifiedMemberCount, 0);
      final lab = BreedGroup.tryFromMap('labradori-novi-sad', {
        'title': 'x',
        'description': '',
      })!;
      expect(lab.scope, GroupScope.breed);
      expect(lab.breedKey, 'Labrador');
    });

    test('stored fields override and bad values fall back', () {
      final parsed = BreedGroup.tryFromMap('x', {
        'title': 'x',
        'description': '',
        'scope': 'local',
        'cityId': 'nis',
        'category': 'nonsense',
        'featured': 'yes',
      })!;
      expect(parsed.scope, GroupScope.local);
      expect(parsed.cityId, 'nis');
      expect(parsed.category, GroupCategory.general);
      expect(parsed.featured, isFalse);
    });
  });

  group('breeds', () {
    test('featured breeds all exist in the canonical registry', () {
      for (final breed in GroupRanking.featuredBreeds) {
        expect(DogBreeds.isSuggested(breed), isTrue, reason: breed);
      }
    });

    test('search ignores diacritics and matches display labels', () {
      expect(GroupRanking.searchBreeds('nemacki'), contains('Nemački ovčar'));
      expect(GroupRanking.searchBreeds('PUDLE'), contains('Pudlica'));
      expect(GroupRanking.searchBreeds('zzzz'), isEmpty);
      expect(GroupRanking.searchBreeds(''), DogBreeds.suggested);
    });

    test('local group beats global, global beats nothing, offer otherwise', () {
      final list = [
        g(
          'lab-ns',
          scope: GroupScope.breed,
          cityId: 'novi_sad',
          breedKey: 'Labrador',
        ),
        g('lab-all', scope: GroupScope.breed, breedKey: 'Labrador'),
      ];
      expect(
        GroupRanking.groupForBreed(list, 'Labrador', cityId: 'novi_sad')?.id,
        'lab-ns',
      );
      expect(
        GroupRanking.groupForBreed(list, 'Labrador', cityId: 'nis')?.id,
        'lab-all',
      );
      expect(GroupRanking.groupForBreed(list, 'Labrador')?.id, 'lab-all');
      expect(GroupRanking.groupForBreed(list, 'Doberman'), isNull);
      expect(
        GroupRanking.groupForBreed([list.first], 'Labrador', cityId: 'nis'),
        isNull,
      );
    });
  });

  group('seed', () {
    test('ids and titles are unique, counts are not invented', () {
      final seedIds = ids(SeedBreedGroups.all);
      expect(seedIds.toSet().length, seedIds.length);
      final titles = SeedBreedGroups.all
          .map((x) => SerbiaLocations.foldName(x.title))
          .toList();
      expect(titles.toSet().length, titles.length);
      expect(SeedBreedGroups.all.every((x) => x.memberCount == 0), isTrue);
      expect(seedIds, contains('setnje-pasa-srbija'));
      // Existing active-walks preset is reused, not duplicated.
      expect(
        SeedBreedGroups.all
            .where((x) => x.category == GroupCategory.active)
            .length,
        1,
      );
    });

    test('seeding twice writes each document once', () async {
      final firestore = FakeFirebaseFirestore();
      Future<void> run() => FirestoreGroupsRepository(
        firestore: firestore,
        currentUserId: 'admin',
        senderName: 'A',
        senderAvatarUrl: '',
      ).ensureSeeded();
      await run();
      await run();
      final snap = await firestore.collection('breed_groups').get();
      expect(snap.docs.length, SeedBreedGroups.all.length);
      final doc = snap.docs.firstWhere((d) => d.id == 'limanski-park');
      expect(doc.data()['cityId'], 'novi_sad');
      expect(doc.data()['memberCount'], 0);
    });

    test(
      'existing seed documents keep members and gain classification',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('breed_groups').doc('limanski-park').set({
          'title': '🌳 Limanski park',
          'description': 'x',
          'memberIds': ['u1'],
          'memberCount': 38,
          'isApproved': true,
        });
        await FirestoreGroupsRepository(
          firestore: firestore,
          currentUserId: 'admin',
          senderName: 'A',
          senderAvatarUrl: '',
        ).ensureSeeded();
        final data =
            (await firestore
                    .collection('breed_groups')
                    .doc('limanski-park')
                    .get())
                .data()!;
        expect(data['memberIds'], ['u1']);
        expect(data['memberCount'], 38);
        expect(data['scope'], 'local');
        expect(data['locationName'], 'Limanski park');
      },
    );
  });

  test('user group keeps its classification and stays pending', () async {
    final repo = LocalGroupsRepository(currentUserId: 'u');
    addTearDown(repo.dispose);
    final created = await repo.createGroup(
      title: 'Šetnje — Niš',
      description: '',
      cityId: 'nis',
      category: GroupCategory.parks,
      locationName: 'Park Svetog Save',
    );
    expect(created.isApproved, isFalse);
    expect(created.scope, GroupScope.local);
    expect(created.cityId, 'nis');
    expect(created.category, GroupCategory.parks);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = LocalGroupsRepository(currentUserId: 'local-user');
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [groupsRepositoryProvider.overrideWith((ref) => repo)],
        child: const MaterialApp(home: GroupsListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('city filter changes the list, empty city offers to start', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text(GroupsStrings.tabWalks), findsOneWidget);
    expect(find.text(GroupsStrings.tabBreeds), findsOneWidget);

    await tester.tap(find.text('Novi Sad').first);
    await tester.pump();
    expect(find.text('🌊 Kej / Žeželjev most'), findsOneWidget);
    await tester.tap(find.text('Beograd').first);
    await tester.pump();
    expect(find.text('🌊 Kej / Žeželjev most'), findsNothing);
    // Global groups still apply; a type with no group shows the empty state.
    await tester.tap(
      find.text(GroupsStrings.category(GroupCategory.parks)).first,
    );
    await tester.pump();
    expect(find.text(GroupsStrings.startGroup), findsOneWidget);
    expect(find.text(GroupsStrings.noGroupsFilter), findsOneWidget);
  });

  testWidgets('breed tab: featured view, search, suggestion', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text(GroupsStrings.tabBreeds));
    await tester.pumpAndSettle();
    expect(find.text('Pudle'), findsOneWidget);
    await tester.drag(
      find
          .ancestor(of: find.text('Pudle'), matching: find.byType(ListView))
          .first,
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    expect(find.text(GroupsStrings.showAllBreeds), findsOneWidget);
    await tester.drag(
      find.text(GroupsStrings.showAllBreeds),
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'dober');
    await tester.pump();
    expect(find.text('Dobermani'), findsOneWidget);
    expect(find.text('Pudle'), findsNothing);
    expect(find.text(GroupsStrings.suggestGroup), findsOneWidget);

    await tester.tap(find.text(GroupsStrings.suggestGroup));
    await tester.pumpAndSettle();
    expect(find.text(GroupsStrings.submitGroup), findsOneWidget);
  });
}
