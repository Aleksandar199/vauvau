import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/app_update/data/app_update_repository.dart';
import 'package:vauvau/features/app_update/domain/app_update.dart';
import 'package:vauvau/features/app_update/presentation/app_update_host.dart';
import 'package:vauvau/features/app_update/presentation/app_update_strings.dart';

Future<void> _pump(
  WidgetTester tester, {
  required AppUpdateConfig? config,
  int? build = 7,
  AppStorePlatform? platform = AppStorePlatform.android,
  bool? enabled = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appUpdateRepositoryProvider.overrideWithValue(
          LocalAppUpdateRepository(config),
        ),
        if (build != null) appBuildNumberProvider.overrideWithValue(build),
        appUpdatePlatformProvider.overrideWithValue(platform),
      ],
      child: MaterialApp(
        home: AppUpdateHost(
          enabled: enabled,
          child: const Scaffold(body: Text('home')),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  // Broj builda se više ne drži ručno u kodu: čita se sa telefona (+N iz
  // pubspec.yaml koji Flutter upisuje u APK/AAB).
  testWidgets('dijalog prikazuje instalirani build', (tester) async {
    await _pump(tester, config: const AppUpdateConfig(latestBuild: 8));
    expect(find.text(AppUpdateStrings.installedBuild(7)), findsOneWidget);
  });

  testWidgets('nepoznat instalirani build: nema dijaloga', (tester) async {
    await _pump(
      tester,
      config: const AppUpdateConfig(minBuild: 99, latestBuild: 99),
      build: null,
    );
    expect(find.byType(AlertDialog), findsNothing);
  });

  test('status: required beats available beats up to date', () {
    const config = AppUpdateConfig(minBuild: 5, latestBuild: 9);
    expect(config.statusFor(4), AppUpdateStatus.required);
    expect(config.statusFor(7), AppUpdateStatus.available);
    expect(config.statusFor(9), AppUpdateStatus.upToDate);
    expect(const AppUpdateConfig().statusFor(1), AppUpdateStatus.upToDate);
    expect(
      AppUpdateConfig.fromMap({'minBuild': 3, 'latestBuild': 8.0}).latestBuild,
      8,
    );
    expect(AppUpdateConfig.fromMap(null).minBuild, 0);
  });

  testWidgets('newer build available: dismissible dialog', (tester) async {
    await _pump(tester, config: const AppUpdateConfig(latestBuild: 8));
    expect(find.text(AppUpdateStrings.title), findsOneWidget);
    expect(find.text(AppUpdateStrings.later), findsOneWidget);
    await tester.tap(find.text(AppUpdateStrings.later));
    await tester.pumpAndSettle();
    expect(find.text(AppUpdateStrings.title), findsNothing);
  });

  testWidgets('required update cannot be dismissed', (tester) async {
    await _pump(tester, config: const AppUpdateConfig(minBuild: 8));
    expect(find.text(AppUpdateStrings.requiredTitle), findsOneWidget);
    expect(find.text(AppUpdateStrings.later), findsNothing);
    await tester.tapAt(const Offset(2, 2)); // barrier
    await tester.pumpAndSettle();
    expect(find.text(AppUpdateStrings.requiredTitle), findsOneWidget);
  });

  test('iOS nikad ne otvara Play; bez App Store id-ja nema linka', () {
    final ios = AppStorePlatform.ios.storeUris;
    expect(ios.any((uri) => uri.toString().contains('play.google')), isFalse);
    expect(ios.any((uri) => uri.scheme == 'market'), isFalse);
    if (kAppStoreId.isEmpty) expect(ios, isEmpty);
    expect(AppStorePlatform.ios.configDocId, 'ios');
    expect(AppStorePlatform.android.configDocId, 'android');
    expect(AppStorePlatform.android.storeUris.first.scheme, 'market');
  });

  testWidgets('iOS bez App Store id-ja: nema dijaloga', (tester) async {
    await _pump(
      tester,
      config: const AppUpdateConfig(minBuild: 99, latestBuild: 99),
      platform: AppStorePlatform.ios,
      enabled: null,
    );
    expect(find.byType(AlertDialog), findsNothing);
  }, skip: kAppStoreId.isNotEmpty);

  testWidgets('web/desktop: nema dijaloga', (tester) async {
    await _pump(
      tester,
      config: const AppUpdateConfig(minBuild: 99),
      platform: null,
      enabled: null,
    );
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('up to date or unknown config: no dialog', (tester) async {
    await _pump(tester, config: const AppUpdateConfig(latestBuild: 7));
    expect(find.byType(AlertDialog), findsNothing);
    await _pump(tester, config: null);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
