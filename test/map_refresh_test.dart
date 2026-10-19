import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/location/domain/location_access.dart';
import 'package:vauvau/features/location/domain/location_client.dart';
import 'package:vauvau/features/location/domain/location_fix.dart';
import 'package:vauvau/features/location/presentation/location_controller.dart';
import 'package:vauvau/features/map/data/walk_session_store.dart';
import 'package:vauvau/features/map/domain/city_model.dart';
import 'package:vauvau/features/map/presentation/cities_controller.dart';
import 'package:vauvau/features/map/presentation/map_screen.dart';
import 'package:vauvau/features/map/presentation/map_strings.dart';
import 'package:vauvau/features/map/presentation/walk_controller.dart';
import 'package:vauvau/features/rewards/data/local_rewards_repository.dart';
import 'package:vauvau/features/rewards/domain/rewards_models.dart';
import 'package:vauvau/features/rewards/presentation/challenge_hub_screen.dart';
import 'package:vauvau/features/rewards/presentation/rewards_controller.dart';
import 'package:vauvau/features/rewards/presentation/rewards_strings.dart';

final Uint8List _png = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _Gps implements LocationClient {
  final fixes = StreamController<LocationFix>.broadcast();

  @override
  Future<LocationAccess> checkPermission() async => LocationAccess.granted;
  @override
  Future<LocationAccess> requestPermission() async => LocationAccess.granted;
  @override
  Future<bool> isServiceEnabled() async => true;
  @override
  Future<GeoCoord?> currentPosition() async => null;
  @override
  Stream<GeoCoord> watchPosition() => const Stream.empty();
  @override
  Stream<GeoCoord> watchWalkPosition() => const Stream.empty();
  @override
  Stream<LocationFix> watchWalkFixes() => fixes.stream;
  @override
  Future<void> openAppSettings() async {}
}

void main() {
  test('isti izabrani grad je jednak (kamera se ne vraća na centar)', () {
    final a = MapRegionSelection.city(SeedCities.noviSad);
    final b = MapRegionSelection.city(SeedCities.noviSad);
    expect(a, b);
    expect(a == MapRegionSelection.city(SeedCities.belgrade), isFalse);
    expect(
      const MapRegionSelection.myLocation(),
      const MapRegionSelection.myLocation(),
    );
  });

  testWidgets(
    'mapa ne pravi markere ponovo pri GPS-u, šetnji i otkucajima tajmera',
    (tester) async {
      final gps = _Gps();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoverImageFactoryProvider.overrideWith(
              (ref) =>
                  (_) => MemoryImage(_png),
            ),
            locationClientProvider.overrideWithValue(gps),
            walkSessionStoreProvider.overrideWithValue(
              MemoryWalkSessionStore(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MapScreen())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapScreen)),
      );
      final builds = MapScreen.placeMarkerBuilds;

      // Nova GPS pozicija korisnika.
      container
          .read(userLocationProvider.notifier)
          .setCoord(const GeoCoord(45.2560, 19.8460));
      await tester.pump();

      // Aktivna šetnja: tačke rute + tajmer od 1 s.
      final walk = container.read(walkControllerProvider.notifier);
      walk.start();
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        walk.onFix(
          LocationFix(
            latitude: 45.2560 + i * 0.00006,
            longitude: 19.8460,
            timestamp: DateTime.now(),
            accuracyM: 5,
          ),
        );
        await tester.pump(const Duration(seconds: 1));
      }
      expect(container.read(walkControllerProvider).track.pointCount, 5);
      expect(MapScreen.placeMarkerBuilds, builds);

      walk.end();
      await tester.pump(const Duration(seconds: 4));

      // Kontrola: promena filtera (stvarna promena mesta) pravi markere.
      await tester.tap(find.text(MapStrings.cityBelgrade));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(MapScreen.placeMarkerBuilds, greaterThan(builds));
    },
  );

  testWidgets('Zrenjanin i Subotica su samo u listi „Izaberi grad“', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverImageFactoryProvider.overrideWith(
            (ref) =>
                (_) => MemoryImage(_png),
          ),
          locationClientProvider.overrideWithValue(_Gps()),
          walkSessionStoreProvider.overrideWithValue(MemoryWalkSessionStore()),
        ],
        child: const MaterialApp(home: Scaffold(body: MapScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MapScreen)),
    );
    // Element reda čipova (ostaje isti i kad se čip „Beograd“ odskroluje).
    final chipRowElement = find
        .ancestor(
          of: find.text(MapStrings.cityBelgrade),
          matching: find.byType(Scrollable),
        )
        .evaluate()
        .first;
    final chipRow = find.byElementPredicate(
      (element) => identical(element, chipRowElement),
    );

    // Početni red mape: brzi čipovi samo za 4 grada, bez novih gradova.
    for (final label in [MapStrings.cityZrenjanin, MapStrings.citySubotica]) {
      expect(
        find.descendant(of: chipRow, matching: find.text(label)),
        findsNothing,
        reason: label,
      );
    }

    var pickerLabel = MapStrings.chooseCity;
    for (final city in [SeedCities.zrenjanin, SeedCities.subotica]) {
      final builds = MapScreen.placeMarkerBuilds;
      final button = find.descendant(
        of: chipRow,
        matching: find.text(pickerLabel),
      );
      await tester.scrollUntilVisible(button, 120, scrollable: chipRow);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final item = find.widgetWithText(ListTile, city.name);
      await tester.scrollUntilVisible(
        item,
        80,
        scrollable: find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      await tester.ensureVisible(item);
      await tester.pump();
      expect(item, findsOneWidget, reason: city.name);
      await tester.tap(item);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(mapRegionProvider).cityId, city.id);
      expect(MapScreen.placeMarkerBuilds, greaterThan(builds), reason: city.id);
      // Dugme „Izaberi grad“ sada pokazuje izabrani grad.
      pickerLabel = city.name;
      expect(
        find.descendant(of: chipRow, matching: find.text(pickerLabel)),
        findsOneWidget,
      );
    }
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('ekran izazova: nivo, izazovi, prazni kuponi i istorija', (
    tester,
  ) async {
    final repo = LocalRewardsRepository(
      coupons: [
        Coupon(
          id: 'c1',
          partnerName: 'Test pet shop',
          title: 'Hrana',
          description: '',
          discountLabel: '15% popusta',
          pointsCost: 100,
          startsAt: DateTime.now().subtract(const Duration(days: 1)),
          expiresAt: DateTime.now().add(const Duration(days: 5)),
          maxQuantity: 10,
          isActive: true,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardsRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AppUser(uid: 'u1')),
          ),
        ],
        child: const MaterialApp(home: ChallengeHubScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nivo: Šapica'), findsOneWidget);
    expect(find.text('Prošetaj najmanje 2 km danas'), findsOneWidget);
    expect(find.text(RewardsStrings.dailySection), findsOneWidget);

    await tester.tap(find.text(RewardsStrings.tabRewards));
    await tester.pumpAndSettle();
    expect(find.text('Test pet shop'), findsOneWidget);
    expect(find.text(RewardsStrings.noMyCoupons), findsOneWidget);
    // 0 poena: dugme za preuzimanje je onemogućeno.
    final claim = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, RewardsStrings.claim),
    );
    expect(claim.onPressed, isNull);

    await tester.tap(find.text(RewardsStrings.tabHistory));
    await tester.pumpAndSettle();
    expect(find.text(RewardsStrings.noLedger), findsOneWidget);
  });
}
