import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/app/offline_gate.dart';
import 'package:vauvau/core/network/connectivity_controller.dart';
import 'package:vauvau/core/network/connectivity_probe.dart';
import 'package:vauvau/core/network/network_strings.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/map/domain/walk_session.dart';
import 'package:vauvau/features/map/presentation/map_screen.dart';
import 'package:vauvau/features/map/presentation/map_strings.dart';
import 'package:vauvau/features/map/presentation/walk_controller.dart';
import 'package:vauvau/features/map/presentation/widgets/walk_stats_panel.dart';

class _FakeProbe implements ConnectivityProbe {
  _FakeProbe(this.online);

  bool online;
  int checks = 0;
  final events = StreamController<void>.broadcast();

  @override
  Future<bool> check() async {
    checks++;
    return online;
  }

  @override
  Stream<void> get changes => events.stream;
}

/// Short timings so tests don't wait 20 s.
const _timing = ConnectivityTiming(
  whileOnline: Duration(seconds: 20),
  whileOffline: Duration(seconds: 3),
  confirmDelay: Duration(seconds: 2),
);

class _Walk extends WalkController {
  _Walk(this.active);

  final bool active;

  @override
  WalkSession build() => WalkSession(isActive: active, now: DateTime.now());
}

class _FixedNetwork extends ConnectivityController {
  _FixedNetwork(this.offline);

  final bool offline;

  @override
  NetworkState build() => NetworkState(isOffline: offline);
}

ProviderContainer _container(_FakeProbe probe) {
  final container = ProviderContainer(
    overrides: [
      connectivityMonitoringProvider.overrideWithValue(true),
      connectivityProbeProvider.overrideWithValue(probe),
      connectivityTimingProvider.overrideWithValue(_timing),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ConnectivityController', () {
    test('bez Firebase-a nema provere (testovi, demo režim)', () async {
      final probe = _FakeProbe(false);
      final container = ProviderContainer(
        overrides: [connectivityProbeProvider.overrideWithValue(probe)],
      );
      addTearDown(container.dispose);
      container.listen(networkStateProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(networkStateProvider).isOffline, isFalse);
      expect(probe.checks, 0);
    });

    test('jedan promašaj ne izbacuje korisnika; drugi potvrđuje', () async {
      final probe = _FakeProbe(false);
      final container = _container(probe);
      container.listen(networkStateProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      // Prva provera je pala, ali čeka potvrdu: još se smatra online.
      expect(container.read(networkStateProvider).isOffline, isFalse);
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));
      expect(container.read(networkStateProvider).isOffline, isTrue);
      expect(probe.checks, 2);
    });

    test('kratak prekid veze (drugi pokušaj uspe) ostaje online', () async {
      final probe = _FakeProbe(false);
      final container = _container(probe);
      container.listen(networkStateProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      probe.online = true;
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));
      expect(container.read(networkStateProvider).isOffline, isFalse);
    });

    test('ručno „Pokušaj ponovo“ odmah odlučuje i vraća online', () async {
      final probe = _FakeProbe(false);
      final container = _container(probe);
      container.listen(networkStateProvider, (_, _) {});
      final controller = container.read(networkStateProvider.notifier);
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));
      expect(container.read(networkStateProvider).isOffline, isTrue);

      // Još offline: jedna provera, bez čekanja.
      await controller.retry();
      expect(container.read(networkStateProvider).isOffline, isTrue);
      expect(container.read(networkStateProvider).isChecking, isFalse);

      probe.online = true;
      await controller.retry();
      expect(container.read(networkStateProvider).isOffline, isFalse);
    });

    test('događaj iz browsera pokreće novu proveru', () async {
      final probe = _FakeProbe(true);
      final container = _container(probe);
      container.listen(networkStateProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      final before = probe.checks;
      probe.events.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(probe.checks, greaterThan(before));
    });
  });

  group('OfflineGate', () {
    Future<void> pumpGate(
      WidgetTester tester,
      _FakeProbe probe, {
      bool walkActive = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityMonitoringProvider.overrideWithValue(true),
            connectivityProbeProvider.overrideWithValue(probe),
            connectivityTimingProvider.overrideWithValue(_timing),
            walkControllerProvider.overrideWith(() => _Walk(walkActive)),
          ],
          child: const MaterialApp(
            home: OfflineGate(child: Scaffold(body: Text('aplikacija'))),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets('online: aplikacija se vidi, nema stranice bez interneta', (
      tester,
    ) async {
      await pumpGate(tester, _FakeProbe(true));
      expect(find.text('aplikacija'), findsOneWidget);
      expect(find.text(NetworkStrings.offlineTitle), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('offline: stranica „Nema internet veze“ umesto aplikacije', (
      tester,
    ) async {
      final probe = _FakeProbe(false);
      await pumpGate(tester, probe);
      expect(find.text(NetworkStrings.offlineTitle), findsOneWidget);
      expect(find.text(NetworkStrings.retry), findsOneWidget);
      // Aplikacija ostaje u memoriji, ali sakrivena i bez interakcije.
      expect(find.text('aplikacija'), findsNothing);
      expect(find.text('aplikacija', skipOffstage: false), findsOneWidget);

      // Veza se vrati: dugme ili automatska provera otvara aplikaciju.
      probe.online = true;
      await tester.tap(find.text(NetworkStrings.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(NetworkStrings.offlineTitle), findsNothing);
      expect(find.text('aplikacija'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('automatski se otvara kad se veza vrati', (tester) async {
      final probe = _FakeProbe(false);
      await pumpGate(tester, probe);
      expect(find.text(NetworkStrings.offlineTitle), findsOneWidget);
      probe.online = true;
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.text('aplikacija'), findsOneWidget);
      expect(find.text(NetworkStrings.offlineTitle), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('aktivna šetnja se ne prekida kad nestane interneta', (
      tester,
    ) async {
      await pumpGate(tester, _FakeProbe(false), walkActive: true);
      expect(find.text('aplikacija'), findsOneWidget);
      expect(find.text(NetworkStrings.offlineTitle), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Traka šetnje', () {
    Future<void> pumpBanner(WidgetTester tester, {required bool offline}) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkStateProvider.overrideWith(() => _FixedNetwork(offline)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: WalkGpsBanner(isPaused: false)),
          ),
        ),
      );
    }

    testWidgets('piše da rutu vidi samo korisnik, a drugi približnu lokaciju', (
      tester,
    ) async {
      await pumpBanner(tester, offline: false);
      expect(find.textContaining(MapStrings.privacyRouteOnlyYou), findsOneWidget);
      expect(find.textContaining('približnu lokaciju'), findsOneWidget);
      expect(find.text(NetworkStrings.walkOffline), findsNothing);
    });

    testWidgets('bez interneta dodaje napomenu da se šetnja i dalje meri', (
      tester,
    ) async {
      await pumpBanner(tester, offline: true);
      expect(find.text(NetworkStrings.walkOffline), findsOneWidget);
    });
  });

  group('Dijalog „Započni šetnju“', () {
    final png = Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    testWidgets('pre starta objašnjava ko šta vidi', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoverImageFactoryProvider.overrideWith(
              (ref) => (_) => MemoryImage(png),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MapScreen())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text(MapStrings.startWalk));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining(MapStrings.privacyRouteOnlyYou),
        findsOneWidget,
      );
      expect(find.textContaining('približnu lokaciju'), findsOneWidget);
    });
  });
}
