import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vauvau/features/auth/data/auth_repository_impl.dart';
import 'package:vauvau/features/auth/data/firebase_auth_datasource.dart';
import 'package:vauvau/features/auth/data/user_document.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/domain/owner_details.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';
import 'package:vauvau/features/discover/presentation/widgets/swipe_dog_card.dart';
import 'package:vauvau/features/profile/data/owner_public_profile.dart';
import 'package:vauvau/features/profile/domain/user_profile.dart';
import 'package:vauvau/features/profile/presentation/edit_owner_profile_screen.dart';
import 'package:vauvau/features/profile/presentation/owner_profile_sheet.dart';
import 'package:vauvau/features/profile/presentation/profile_controller.dart';
import 'package:vauvau/features/profile/presentation/profile_strings.dart';

class _NoAuth extends Fake implements FirebaseAuth {}

AuthRepositoryImpl _repo(FirebaseFirestore firestore) => AuthRepositoryImpl(
  FirebaseAuthDatasource(_NoAuth(), googleSignIn: GoogleSignIn()),
  firestore: firestore,
);

const _fullDetails = OwnerDetails(
  ageGroup: '25_34',
  occupation: 'Grafički dizajner',
  interests: ['nature', 'photography'],
  languages: ['sr', 'en'],
  lookingFor: ['walk_buddy', 'dog_playdates'],
  favoriteActivities: ['parks', 'hiking'],
  walkTimes: ['morning', 'weekend'],
  walkPace: 'moderate',
  groupWalks: true,
  dogExperience: 'experienced',
  sharesAdvice: true,
  volunteerInterest: true,
  favoriteBreed: 'Border koli',
  favoriteWalkSpot: 'Kej uz Dunav',
  instagram: 'jelena.vau',
);

Future<Map<String, dynamic>> _doc(FirebaseFirestore db, String uid) async =>
    (await db.collection('users').doc(uid).get()).data()!;

void main() {
  group('OwnerDetails model', () {
    test('old profile without the new fields reads as empty', () {
      final user = AppUser.fromAuthAndDocument(
        uid: 'old',
        data: {'name': 'Stari', 'cityName': 'Novi Sad', 'bio': 'Zdravo'},
      );
      expect(user.details.isEmpty, isTrue);
      expect(OwnerDetails.fromMap(null).isEmpty, isTrue);
    });

    test('null, wrong types and unknown keys never throw', () {
      final details = OwnerDetails.fromMap({
        'ageGroup': 42,
        'occupation': null,
        'interests': 'nature',
        'languages': ['en', 7, null, 'klingon', 'sr', 'en'],
        'walkPace': 'sprint',
        'groupWalks': 'yes',
        'instagram': 'https://evil.example/x',
        'favoriteBreed': 'x' * 500,
      });
      expect(details.ageGroup, '');
      expect(details.occupation, '');
      expect(details.interests, isEmpty);
      // Stable keys, option order, no duplicates.
      expect(details.languages, ['sr', 'en']);
      expect(details.walkPace, '');
      expect(details.groupWalks, isFalse);
      expect(details.instagram, '');
      expect(
        details.favoriteBreed.length,
        OwnerDetails.favoriteBreedMaxLength,
      );
    });

    test('instagram accepts @name, name and profile links only', () {
      expect(OwnerDetails.normalizeInstagram(''), '');
      expect(OwnerDetails.normalizeInstagram('  @Jelena.Vau '), 'jelena.vau');
      expect(OwnerDetails.normalizeInstagram('jelena_vau'), 'jelena_vau');
      expect(
        OwnerDetails.normalizeInstagram('https://www.instagram.com/jelena.vau/'),
        'jelena.vau',
      );
      expect(
        OwnerDetails.normalizeInstagram('instagram.com/jelena?igsh=abc'),
        'jelena',
      );
      expect(OwnerDetails.normalizeInstagram('https://evil.example/x'), isNull);
      expect(OwnerDetails.normalizeInstagram('ime sa razmakom'), isNull);
      expect(OwnerDetails.normalizeInstagram('a..b'), isNull);
      expect(
        OwnerDetails.normalizeInstagram('https://instagram.com/p/abc'),
        isNull,
      );
    });

    test('no new field is a private user field', () {
      expect(
        OwnerDetails.fields.toSet().intersection(userPrivateFields.toSet()),
        isEmpty,
      );
    });
  });

  group('saving owner details', () {
    late FakeFirebaseFirestore db;
    late AppUser user;

    setUp(() async {
      db = FakeFirebaseFirestore();
      await db.collection('users').doc('u1').set({
        'uid': 'u1',
        'name': 'Jelena',
        'role': 'admin',
        'customPhotoUrl': 'https://example.com/j.jpg',
        'walkHistory': ['w1'],
        'dog': {'id': 'd1', 'name': 'Lola'},
      });
      user = AppUser.fromAuthAndDocument(uid: 'u1', data: await _doc(db, 'u1'));
    });

    test('saves without any new field', () async {
      await _repo(db).saveUserProfile(
        user: user,
        name: 'Jelena',
        bio: 'Volim šetnje',
        writeDog: false,
        details: const OwnerDetails(),
      );
      final data = await _doc(db, 'u1');
      expect(data['bio'], 'Volim šetnje');
      for (final field in OwnerDetails.fields) {
        expect(data.containsKey(field), isFalse, reason: field);
      }
    });

    test('saves, reloads and keeps the other fields', () async {
      await _repo(
        db,
      ).saveUserProfile(user: user, writeDog: false, details: _fullDetails);
      final data = await _doc(db, 'u1');
      expect(data['interests'], ['nature', 'photography']);
      expect(data['groupWalks'], isTrue);
      expect(data['instagram'], 'jelena.vau');
      // Untouched fields stay.
      expect(data['role'], 'admin');
      expect(data['customPhotoUrl'], 'https://example.com/j.jpg');
      expect(data['walkHistory'], ['w1']);
      expect((data['dog'] as Map)['name'], 'Lola');

      final reloaded = AppUser.fromAuthAndDocument(uid: 'u1', data: data);
      final d = reloaded.details;
      expect(d.ageGroup, '25_34');
      expect(d.occupation, 'Grafički dizajner');
      expect(d.languages, ['sr', 'en']);
      expect(d.lookingFor, ['walk_buddy', 'dog_playdates']);
      expect(d.favoriteActivities, ['parks', 'hiking']);
      expect(d.walkTimes, ['morning', 'weekend']);
      expect(d.walkPace, 'moderate');
      expect(d.dogExperience, 'experienced');
      expect(d.sharesAdvice && d.volunteerInterest, isTrue);
      expect(d.favoriteBreed, 'Border koli');
      expect(d.favoriteWalkSpot, 'Kej uz Dunav');
    });

    test('editing changes values and clearing deletes the fields', () async {
      final repo = _repo(db);
      await repo.saveUserProfile(
        user: user,
        writeDog: false,
        details: _fullDetails,
      );
      await repo.saveUserProfile(
        user: user,
        writeDog: false,
        details: _fullDetails.copyWith(
          interests: ['music'],
          occupation: '',
          instagram: '',
          groupWalks: false,
          walkTimes: const [],
        ),
      );
      final data = await _doc(db, 'u1');
      expect(data['interests'], ['music']);
      expect(data.containsKey('occupation'), isFalse);
      expect(data.containsKey('instagram'), isFalse);
      expect(data.containsKey('groupWalks'), isFalse);
      expect(data.containsKey('walkTimes'), isFalse);
      expect(data['walkPace'], 'moderate');
    });

    test('a save without details leaves them untouched', () async {
      final repo = _repo(db);
      await repo.saveUserProfile(
        user: user,
        writeDog: false,
        details: _fullDetails,
      );
      await repo.saveUserProfile(user: user, bio: 'Novo', writeDog: false);
      final data = await _doc(db, 'u1');
      expect(data['bio'], 'Novo');
      expect(data['occupation'], 'Grafički dizajner');
    });
  });

  group('edit profile screen', () {
    Future<ProviderContainer> pumpEdit(
      WidgetTester tester,
      OwnerDetails details,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(profileControllerProvider.notifier)
          .save(mockUserProfile.copyWith(ownerDetails: details));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: EditOwnerProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> openSection(WidgetTester tester, String key) async {
      final section = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(
        section,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.descendant(of: section, matching: find.byType(ListTile)).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('loads saved values and saves multi-select changes', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(520, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = await pumpEdit(tester, _fullDetails);

      await openSection(tester, 'owner-section-about');
      expect(find.text('Grafički dizajner'), findsOneWidget);
      FilterChip chip(String label) => tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, label),
      );
      expect(chip(ProfileStrings.ownerOption('nature')).selected, isTrue);
      expect(chip(ProfileStrings.ownerOption('music')).selected, isFalse);

      // Multi-select: add one, remove one; clear a text field.
      await tester.ensureVisible(
        find.widgetWithText(FilterChip, ProfileStrings.ownerOption('music')),
      );
      await tester.tap(
        find.widgetWithText(FilterChip, ProfileStrings.ownerOption('music')),
      );
      await tester.tap(
        find.widgetWithText(FilterChip, ProfileStrings.ownerOption('nature')),
      );
      await tester.enterText(
        find.widgetWithText(TextField, ProfileStrings.occupation),
        '',
      );
      await tester.pump();

      await tester.tap(find.text(ProfileStrings.saveChanges));
      await tester.pumpAndSettle();

      final saved = container.read(profileControllerProvider).ownerDetails;
      expect(saved.interests, ['photography', 'music']);
      expect(saved.occupation, '');
      expect(saved.walkPace, 'moderate');
      expect(saved.instagram, 'jelena.vau');
    });

    testWidgets('rejects an invalid Instagram value', (tester) async {
      await tester.binding.setSurfaceSize(const Size(520, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = await pumpEdit(tester, const OwnerDetails());

      await openSection(tester, 'owner-section-extra');
      final field = find.byKey(const ValueKey('owner-instagram-field'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'https://evil.example/x');
      await tester.tap(find.text(ProfileStrings.saveChanges));
      await tester.pump();

      expect(find.text(ProfileStrings.instagramInvalid), findsWidgets);
      expect(find.byType(EditOwnerProfileScreen), findsOneWidget);
      expect(
        container.read(profileControllerProvider).ownerDetails.instagram,
        '',
      );
    });
  });

  group('owner popup', () {
    Widget sheetApp(OwnerProfileLoader loader, {String fallbackName = ''}) {
      return MaterialApp(
        home: Scaffold(
          body: OwnerProfileSheet(
            userId: 'owner-1',
            fallbackName: fallbackName,
            loader: loader,
          ),
        ),
      );
    }

    OwnerPublicProfile profile({
      String bio = '',
      String photoUrl = '',
      OwnerDetails details = const OwnerDetails(),
    }) => OwnerPublicProfile(
      userId: 'owner-1',
      name: 'Jelena',
      photoUrl: photoUrl,
      location: 'Novi Sad, Liman',
      bio: bio,
      dogs: const [],
      details: details,
    );

    testWidgets('basic profile only: no empty sections, placeholder photo', (
      tester,
    ) async {
      await tester.pumpWidget(sheetApp((_) async => profile()));
      await tester.pumpAndSettle();

      expect(find.text('Jelena'), findsOneWidget);
      expect(find.text('Novi Sad, Liman'), findsOneWidget);
      expect(find.byKey(const ValueKey('owner-photo-placeholder')), findsOne);
      for (final key in [
        'owner-info-about',
        'owner-info-social',
        'owner-info-experience',
        'owner-info-extra',
      ]) {
        expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
      }
      expect(find.text(ProfileStrings.aboutMeSection), findsNothing);
      expect(find.byKey(const ValueKey('owner-profile-message')), findsNothing);
    });

    testWidgets('shows only filled fields', (tester) async {
      await tester.pumpWidget(
        sheetApp(
          (_) async => profile(
            bio: 'Volim duge šetnje.',
            details: const OwnerDetails(
              interests: ['music'],
              walkPace: 'active',
              sharesAdvice: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Volim duge šetnje.'), findsOneWidget);
      expect(find.byKey(const ValueKey('owner-info-about')), findsOneWidget);
      expect(find.text(ProfileStrings.ownerOption('music')), findsOneWidget);
      expect(find.text(ProfileStrings.languages), findsNothing);
      expect(
        find.textContaining(ProfileStrings.occupation, findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining(ProfileStrings.walkPace, findRichText: true),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('owner-info-social')), findsOneWidget);
      expect(find.text(ProfileStrings.groupWalks), findsNothing);
      expect(find.text(ProfileStrings.sharesAdvice), findsOneWidget);
      expect(find.byKey(const ValueKey('owner-info-extra')), findsNothing);
    });

    testWidgets('loading indicator, then error with retry', (tester) async {
      var calls = 0;
      final first = Completer<OwnerPublicProfile?>();
      await tester.pumpWidget(
        sheetApp((_) {
          calls++;
          return calls == 1 ? first.future : Future.value(profile());
        }, fallbackName: 'J.'),
      );
      expect(find.byKey(const ValueKey('owner-profile-loading')), findsOne);
      expect(find.text('J.'), findsOneWidget);

      first.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text(ProfileStrings.ownerProfileLoadFailed), findsOneWidget);
      expect(find.byKey(const ValueKey('owner-profile-loading')), findsNothing);

      await tester.tap(find.text(ProfileStrings.retry));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Jelena'), findsOneWidget);
      expect(find.text(ProfileStrings.ownerProfileLoadFailed), findsNothing);
    });

    testWidgets('missing profile shows a polite message', (tester) async {
      await tester.pumpWidget(sheetApp((_) async => null));
      await tester.pumpAndSettle();
      expect(find.text(ProfileStrings.ownerProfileUnavailable), findsOneWidget);
      expect(find.text(ProfileStrings.ownerUnknown), findsOneWidget);
    });

    testWidgets('fits and scrolls on a small screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        sheetApp((_) async => profile(bio: 'Opis ' * 40, details: _fullDetails)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('@jelena.vau'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('@jelena.vau'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('close button and system back close the popup', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showOwnerProfileSheet(
                  context,
                  userId: 'owner-1',
                  loader: (_) async => profile(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(OwnerProfileSheet), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('owner-profile-close')));
      await tester.pumpAndSettle();
      expect(find.byType(OwnerProfileSheet), findsNothing);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(OwnerProfileSheet), findsNothing);
    });
  });

  group('Discover owner name', () {
    testWidgets('tap opens the popup loaded by ownerId', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final requested = <String>[];
      const dog = DiscoverProfile(
        id: 'dog-luna',
        name: 'Luna',
        ownerName: 'Ana',
        ownerId: 'owner-42',
        breed: 'Zlatni retriver',
        ageYears: 5,
        gender: 'ženka',
        size: 'veliki',
        location: 'Novi Sad',
        bio: 'Voli vodu.',
        photoUrls: [],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ownerProfileLoaderProvider.overrideWithValue((id) async {
              requested.add(id);
              return const OwnerPublicProfile(
                userId: 'owner-42',
                name: 'Ana Petrović',
                photoUrl: '',
                location: 'Novi Sad, Grbavica',
                bio: '',
                dogs: [],
                details: OwnerDetails(dogExperience: 'beginner'),
              );
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DogDetailSheet(profile: dog)),
          ),
        ),
      );
      await tester.pump();

      final name = find.byKey(const ValueKey('discover-owner-name'));
      await tester.scrollUntilVisible(
        name,
        300,
        scrollable: find
            .descendant(
              of: find.byType(DogDetailSheet),
              matching: find.byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              ),
            )
            .first,
      );
      await tester.tap(name);
      await tester.pumpAndSettle();

      expect(requested, ['owner-42']);
      expect(find.byType(OwnerProfileSheet), findsOneWidget);
      final sheet = find.byType(OwnerProfileSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Ana Petrović')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.textContaining(
            ProfileStrings.ownerOption('beginner'),
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.byKey(const ValueKey('owner-info-experience')),
        ),
        findsOneWidget,
      );
    });
  });
}
