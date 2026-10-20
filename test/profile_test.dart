import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vauvau/features/discover/presentation/discover_controller.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/profile/domain/matching_filters.dart';
import 'package:vauvau/features/profile/presentation/profile_controller.dart';
import 'package:vauvau/features/profile/presentation/profile_screen.dart';
import 'package:vauvau/features/profile/presentation/profile_strings.dart';
import 'package:vauvau/features/profile/presentation/profile_system_sheet.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<ProviderContainer> _pumpProfile(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      discoverImageFactoryProvider.overrideWith((ref) {
        return (_) => MemoryImage(_transparentPng);
      }),
    ],
  );
  addTearDown(container.dispose);
  container.read(discoverControllerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text(ProfileStrings.title),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  return IconButton(
                    tooltip: ProfileStrings.moreActions,
                    onPressed: () => showProfileSystemSheet(context, ref),
                    icon: const Icon(Icons.settings_outlined),
                  );
                },
              ),
            ],
          ),
          body: const ProfileScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  testWidgets('loads profile info', (tester) async {
    await _pumpProfile(tester);

    expect(find.text('Luna'), findsWidgets);
    expect(find.text('Maks'), findsOneWidget);
    expect(find.text('Zlatni retriver · 3 god.'), findsOneWidget);
    expect(find.text('Ženka'), findsWidgets);
    expect(find.text('Veliki'), findsWidgets);
    expect(find.text(ProfileStrings.badgeChipped), findsOneWidget);
    expect(find.text(ProfileStrings.badgeVaccinated), findsOneWidget);
    expect(find.text('Novi Sad · Liman 3'), findsWidgets);
    expect(find.text('Aleksandar'), findsOneWidget);
    expect(
      find.text('Šetač iz Limana. Tražim druženje za Lunu uz Dunav.'),
      findsOneWidget,
    );
    expect(find.text(ProfileStrings.editProfile), findsOneWidget);
    expect(find.text(ProfileStrings.addDog), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(ProfileStrings.settings), findsOneWidget);
    expect(find.text(ProfileStrings.signOut), findsOneWidget);
    expect(find.text(ProfileStrings.deleteAccount), findsOneWidget);
    Navigator.of(tester.element(find.text(ProfileStrings.settings))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.add_a_photo).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(ProfileStrings.setOwnerPhoto), findsOneWidget);
    expect(find.text(ProfileStrings.ownerPhotoCamera), findsOneWidget);
  });

  testWidgets('edits dog details and saves', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    final container = await _pumpProfile(tester);

    await tester.ensureVisible(find.text(ProfileStrings.editDog));
    await tester.tap(find.text(ProfileStrings.editDog));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(ProfileStrings.saveChanges), findsOneWidget);
    expect(find.text(ProfileStrings.vaccines), findsOneWidget);
    expect(find.text(ProfileStrings.sterilized), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Luna'),
      'Luna Nova',
    );
    await tester.ensureVisible(find.text(ProfileStrings.saveChanges));
    await tester.tap(find.text(ProfileStrings.saveChanges));
    await tester.pumpAndSettle();

    expect(find.text(ProfileStrings.saved), findsOneWidget);
    expect(find.text('Luna Nova'), findsWidgets);
    expect(container.read(profileControllerProvider).dog.name, 'Luna Nova');
  });

  testWidgets('switches selected dog', (tester) async {
    final container = await _pumpProfile(tester);

    // Stories and posts are above the dogs now: scroll to the chip.
    await tester.scrollUntilVisible(
      find.text('Maks'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 150));
    await tester.pump();
    await tester.tap(find.text('Maks'));
    await tester.pump();

    expect(container.read(profileControllerProvider).dog.name, 'Maks');
    expect(find.textContaining('Mešanac'), findsWidgets);
  });

  testWidgets('opens settings and search filters', (tester) async {
    final container = await _pumpProfile(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ProfileStrings.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(ProfileStrings.notifyWalks), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(ProfileStrings.appVersion),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text(ProfileStrings.searchFilters));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ProfileStrings.searchFilters));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(ProfileStrings.sizeFilter), findsOneWidget);

    await tester.tap(find.text(ProfileStrings.cityBeograd));
    await tester.pump();
    await tester.tap(find.text(ProfileStrings.applyFilters));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(matchingFiltersProvider).city, FilterCity.beograd);
    final visible = container.read(discoverControllerProvider).visible;
    expect(visible, isNotEmpty);
    expect(
      visible.every((profile) => profile.location.startsWith('Beograd')),
      isTrue,
    );
  });
}
