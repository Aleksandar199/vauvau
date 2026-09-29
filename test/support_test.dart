import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/utils/external_link_launcher.dart';
import 'package:vauvau/features/support/data/local_support_repository.dart';
import 'package:vauvau/features/support/domain/admin_feedback.dart';
import 'package:vauvau/features/support/domain/official_contacts.dart';
import 'package:vauvau/features/support/presentation/rules_and_support_screen.dart';
import 'package:vauvau/features/support/presentation/support_content.dart';
import 'package:vauvau/features/support/presentation/support_controller.dart';
import 'package:vauvau/features/support/presentation/support_strings.dart';

class _FakeLinkLauncher extends ExternalLinkLauncher {
  Uri? lastUri;

  @override
  Future<bool> open(Uri uri) async {
    lastUri = uri;
    return true;
  }
}

void main() {
  test('builds official mailto and social URIs', () {
    expect(OfficialContacts.emailUri.scheme, 'mailto');
    expect(OfficialContacts.emailUri.path, OfficialContacts.emailAddress);
    expect(
      OfficialContacts.instagramUri.toString(),
      'https://instagram.com/vauvau.app',
    );
    expect(
      OfficialContacts.facebookUri.toString(),
      'https://facebook.com/VauVau',
    );
  });

  Future<LocalSupportRepository> pumpScreen(
    WidgetTester tester, {
    ExternalLinkLauncher? launcher,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    final repo = LocalSupportRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWith((ref) => repo),
          if (launcher != null)
            externalLinkLauncherProvider.overrideWith((ref) => launcher),
        ],
        child: const MaterialApp(home: RulesAndSupportScreen()),
      ),
    );
    await tester.pump();
    return repo;
  }

  testWidgets('shows rules and tips tabs', (tester) async {
    await pumpScreen(tester);

    expect(find.text(SupportStrings.title), findsOneWidget);
    expect(find.text(SupportContent.rules.first.title), findsOneWidget);

    await tester.tap(find.text(SupportStrings.tipsTab));
    await tester.pumpAndSettle();
    expect(find.text(SupportContent.tips.first.title), findsOneWidget);
  });

  testWidgets('shows official contact links and opens them', (tester) async {
    final launcher = _FakeLinkLauncher();
    await pumpScreen(tester, launcher: launcher);

    await tester.tap(find.text(SupportStrings.contactTab));
    await tester.pumpAndSettle();

    expect(find.text(SupportStrings.followUs), findsOneWidget);
    expect(find.text(OfficialContacts.emailAddress), findsOneWidget);
    expect(find.text(OfficialContacts.instagramHandle), findsOneWidget);
    expect(find.text(OfficialContacts.facebookName), findsOneWidget);

    await tester.tap(find.text(OfficialContacts.instagramHandle));
    await tester.pump();
    expect(launcher.lastUri, OfficialContacts.instagramUri);

    await tester.tap(find.text(OfficialContacts.emailAddress));
    await tester.pump();
    expect(launcher.lastUri, OfficialContacts.emailUri);

    await tester.tap(find.text(OfficialContacts.facebookName));
    await tester.pump();
    expect(launcher.lastUri, OfficialContacts.facebookUri);
  });

  testWidgets('validates and sends admin feedback', (tester) async {
    final repo = await pumpScreen(tester);

    await tester.tap(find.text(SupportStrings.contactTab));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.text(SupportStrings.send, skipOffstage: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(SupportStrings.send));
    await tester.pump();
    expect(find.text(SupportStrings.subjectRequired), findsOneWidget);
    expect(find.text(SupportStrings.messageRequired), findsOneWidget);
    expect(repo.submitted, isEmpty);

    await tester.tap(find.text(AdminFeedback.categories.first));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AdminFeedback.categories[1]).last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, SupportStrings.subject),
      'Mapa se ne učitava',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, SupportStrings.message),
      'Kada otvorim mapu, ekran ostane prazan.',
    );
    await tester.ensureVisible(
      find.text(SupportStrings.send, skipOffstage: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(SupportStrings.send));
    await tester.pumpAndSettle();

    expect(find.text(SupportStrings.sentTitle), findsOneWidget);
    expect(repo.submitted, hasLength(1));
    final sent = repo.submitted.single;
    expect(sent.category, AdminFeedback.categories[1]);
    expect(sent.subject, 'Mapa se ne učitava');
    expect(sent.message, 'Kada otvorim mapu, ekran ostane prazan.');
    expect(sent.status, AdminFeedback.statusNew);
    expect(sent.userId, isNotEmpty);
  });
}
