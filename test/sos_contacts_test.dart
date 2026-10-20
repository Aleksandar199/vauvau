import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/core/utils/external_link_launcher.dart';
import 'package:vauvau/features/adoption/presentation/phone_launcher.dart';
import 'package:vauvau/features/location/presentation/home_city_provider.dart';
import 'package:vauvau/features/support/domain/sos_contacts.dart';
import 'package:vauvau/features/support/presentation/sos_tab.dart';
import 'package:vauvau/features/support/presentation/support_strings.dart';

class _FakePhoneLauncher extends PhoneLauncher {
  final calls = <String>[];

  @override
  Future<bool> call(String phone) async {
    calls.add(phone);
    return true;
  }
}

class _FakeLinkLauncher extends ExternalLinkLauncher {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

void main() {
  group('SosContacts data', () {
    test('every app city has contacts or the screen shows an empty state', () {
      for (final city in SerbiaLocations.cities) {
        expect(
          SosContacts.forCity(city.id),
          isNotEmpty,
          reason: '${city.name} nema SOS kontakt',
        );
      }
      expect(SosContacts.forCity('nepoznat'), isEmpty);
      expect(SosContacts.groupedForCity('nepoznat'), isEmpty);
    });

    test('data only uses known city ids and matching cityId', () {
      final ids = SerbiaLocations.cities.map((c) => c.id).toSet();
      for (final entry in SosContacts.byCity.entries) {
        expect(ids, contains(entry.key));
        for (final contact in entry.value) {
          expect(contact.cityId, entry.key, reason: contact.name);
        }
      }
    });

    test('phone numbers are valid tel: URIs', () {
      final telPattern = RegExp(r'^tel:\+?\d{6,13}$');
      for (final contact in SosContacts.byCity.values.expand((c) => c)) {
        expect(contact.phones, isNotEmpty, reason: contact.name);
        for (final phone in contact.phones) {
          expect(
            RegExp(r'^[0-9+][0-9 /-]+$').hasMatch(phone.number),
            isTrue,
            reason: '${contact.name}: ${phone.number}',
          );
          expect(
            telPattern.hasMatch(phone.telUri.toString()),
            isTrue,
            reason: '${contact.name}: ${phone.telUri}',
          );
        }
      }
    });

    test('every contact has a source and valid links', () {
      for (final contact in SosContacts.byCity.values.expand((c) => c)) {
        expect(Uri.parse(contact.sourceUrl).isAbsolute, isTrue);
        if (contact.website != null) {
          expect(contact.websiteUri!.isAbsolute, isTrue);
        }
        if (contact.address != null) {
          expect(contact.mapsUri!.host, 'www.google.com');
        }
      }
    });

    test('only clinics with a stated 0–24 service are 24/7', () {
      final emergency = SosContacts.byCity.values
          .expand((c) => c)
          .where((c) => c.kind == SosContactKind.emergencyVet);
      for (final contact in emergency) {
        expect(
          contact.note,
          anyOf(contains('00–24'), contains('0–24'), contains('24/7')),
          reason: contact.name,
        );
      }
      final names = SosContacts.forCity(SerbiaLocations.noviSadId)
          .where((c) => c.kind == SosContactKind.emergencyVet)
          .map((c) => c.name);
      expect(names, isNot(contains('NS VET')));
    });
  });

  group('SosTab', () {
    Future<(_FakePhoneLauncher, _FakeLinkLauncher)> pumpTab(
      WidgetTester tester, {
      HomeCity? home,
    }) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final phone = _FakePhoneLauncher();
      final links = _FakeLinkLauncher();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeCityProvider.overrideWithValue(home),
            phoneLauncherProvider.overrideWithValue(phone),
            externalLinkLauncherProvider.overrideWithValue(links),
          ],
          child: const MaterialApp(home: Scaffold(body: SosTab())),
        ),
      );
      await tester.pump();
      return (phone, links);
    }

    bool selected(WidgetTester tester, String cityId) => tester
        .widget<ChoiceChip>(find.byKey(ValueKey('sos-city-$cityId')))
        .selected;

    testWidgets('defaults to the user home city', (tester) async {
      await pumpTab(
        tester,
        home: const HomeCity(id: 'nis', name: 'Niš', coord: GeoCoord.nis),
      );

      expect(selected(tester, SerbiaLocations.nisId), isTrue);
      expect(find.text('Vet Medica'), findsOneWidget);
      expect(find.text('Milenium Vet'), findsNothing);
    });

    testWidgets('without home city the first city is shown', (tester) async {
      await pumpTab(tester);

      final first = SerbiaLocations.cities.first.id;
      expect(selected(tester, first), isTrue);
      expect(
        find.text(SosContacts.forCity(first).first.name),
        findsOneWidget,
      );
    });

    testWidgets('picking a city changes the list and groups', (tester) async {
      await pumpTab(tester);

      await tester.tap(find.byKey(const ValueKey('sos-city-zrenjanin')));
      await tester.pump();

      expect(selected(tester, SerbiaLocations.zrenjaninId), isTrue);
      expect(find.text('Veterina Dimić'), findsOneWidget);
      expect(find.text('Milenium Vet'), findsNothing);
      // No confirmed 0–24 vet in Zrenjanin → notice, no 24/7 group.
      expect(find.text(SupportStrings.sosNo24h), findsOneWidget);
      expect(find.text(SupportStrings.sosGroupEmergencyVet), findsNothing);
      expect(find.text(SupportStrings.sosGroupAnimalControl), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sos-city-kragujevac')));
      await tester.pump();
      expect(find.text('Kragujvet Pet'), findsOneWidget);
      expect(find.text(SupportStrings.sosGroupEmergencyVet), findsOneWidget);
      expect(find.text(SupportStrings.sosNo24h), findsNothing);
    });

    testWidgets('call, directions and website use the launchers', (
      tester,
    ) async {
      final (phone, links) = await pumpTab(
        tester,
        home: const HomeCity(id: 'nis', name: 'Niš', coord: GeoCoord.nis),
      );

      await tester.tap(find.byIcon(Icons.phone_in_talk).first);
      await tester.pump();
      expect(phone.calls, ['0641706470']);

      await tester.tap(find.text(SupportStrings.sosNavigate).first);
      await tester.pump();
      expect(links.opened.single.queryParameters['query'],
          'Bulevar Mediana 5, Niš');

      await tester.tap(find.text(SupportStrings.sosWebsite).first);
      await tester.pump();
      expect(links.opened.last, Uri.parse('https://vetmedica.rs/'));
    });
  });
}
