import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/utils/external_link_launcher.dart';
import 'package:vauvau/features/app_update/domain/app_update.dart';
import 'package:vauvau/features/profile/domain/user_profile.dart';
import 'package:vauvau/features/profile/presentation/profile_strings.dart';
import 'package:vauvau/features/profile/presentation/share_profile_sheet.dart';

class _FakeLauncher extends ExternalLinkLauncher {
  _FakeLauncher({this.result = true});

  final bool result;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return result;
  }
}

Future<void> _pumpSheet(WidgetTester tester, _FakeLauncher launcher) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [externalLinkLauncherProvider.overrideWithValue(launcher)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showShareTextSheet(
                context,
                title: ProfileStrings.inviteFriends,
                text: inviteFriendsText(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('tekst profila ima ime, pse i link aplikacije, bez email-a', () {
    final text = profileShareText(mockUserProfile);
    expect(text, contains('Aleksandar'));
    expect(text, contains('Luna'));
    expect(text, contains(kPlayStoreWebUrl));
    expect(text, isNot(contains(mockUserProfile.ownerEmail)));
    expect(inviteFriendsText(), contains(kPlayStoreWebUrl));
  });

  testWidgets('Kopiraj stavlja tekst u clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpSheet(tester, _FakeLauncher());

    expect(find.byKey(const ValueKey('share-preview')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('share-copy')));
    await tester.pumpAndSettle();

    expect(copied, inviteFriendsText());
    expect(find.text(ProfileStrings.shareCopied), findsOneWidget);
    expect(find.byType(ShareTextSheet), findsNothing);
  });

  testWidgets('WhatsApp otvara wa.me sa tekstom', (tester) async {
    final launcher = _FakeLauncher();
    await _pumpSheet(tester, launcher);

    await tester.tap(find.byKey(const ValueKey('share-whatsapp')));
    await tester.pumpAndSettle();

    expect(launcher.opened.single.host, 'wa.me');
    expect(
      launcher.opened.single.queryParameters['text'],
      inviteFriendsText(),
    );
  });

  testWidgets('nedostupna aplikacija: poruka, sheet ostaje', (tester) async {
    await _pumpSheet(tester, _FakeLauncher(result: false));

    await tester.tap(find.byKey(const ValueKey('share-viber')));
    await tester.pumpAndSettle();

    expect(find.text(ProfileStrings.shareAppMissing), findsOneWidget);
    expect(find.byType(ShareTextSheet), findsOneWidget);
  });
}
