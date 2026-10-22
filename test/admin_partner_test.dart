import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/admin/data/batched_loader.dart';
import 'package:vauvau/features/admin/data/local_admin_repository.dart';
import 'package:vauvau/features/admin/domain/admin_models.dart';
import 'package:vauvau/features/admin/presentation/admin_controller.dart';
import 'package:vauvau/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:vauvau/features/admin/presentation/admin_strings.dart';
import 'package:vauvau/features/admin/presentation/tabs/admin_reports_tab.dart';
import 'package:vauvau/features/admin/presentation/tabs/admin_rewards_tab.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/map/domain/completed_walk.dart';
import 'package:vauvau/features/moderation/data/local_report_repository.dart';
import 'package:vauvau/features/moderation/domain/content_report.dart';
import 'package:vauvau/features/moderation/presentation/report_controller.dart';
import 'package:vauvau/features/partners/data/local_partners_repository.dart';
import 'package:vauvau/features/partners/domain/partner.dart';
import 'package:vauvau/features/partners/domain/partner_coupon_check.dart';
import 'package:vauvau/features/partners/presentation/partner_coupons_screen.dart';
import 'package:vauvau/features/partners/presentation/partner_providers.dart';
import 'package:vauvau/features/partners/presentation/partner_strings.dart';
import 'package:vauvau/features/rewards/data/local_rewards_repository.dart';
import 'package:vauvau/features/rewards/domain/rewards_models.dart';
import 'package:vauvau/features/rewards/domain/rewards_repository.dart';
import 'package:vauvau/features/rewards/presentation/rewards_controller.dart';

final DateTime _now = DateTime.utc(2026, 10, 16, 10);

Coupon _coupon(String id, {String partnerId = 'p1'}) => Coupon(
  id: id,
  partnerName: 'Pet shop Šapa',
  title: 'Hrana',
  description: '',
  discountLabel: '15% popusta',
  pointsCost: 10,
  startsAt: _now.subtract(const Duration(days: 1)),
  expiresAt: _now.add(const Duration(days: 10)),
  maxQuantity: 5,
  isActive: true,
  partnerId: partnerId,
);

/// u1 earns points with one 6 km walk, then claims both coupons.
Future<(LocalRewardsRepository, CouponClaim, CouponClaim)> _claimed() async {
  final repo = LocalRewardsRepository(
    challenges: const [],
    coupons: [
      _coupon('c1'),
      _coupon('c2', partnerId: 'p2'),
    ],
  );
  final end = _now.subtract(const Duration(hours: 1));
  await repo.saveWalk(
    CompletedWalk(
      id: 'w1',
      userId: 'u1',
      dogId: 'dog',
      startedAt: end.subtract(const Duration(minutes: 60)),
      endedAt: end,
      durationSeconds: 3600,
      recognizedMeters: 6000,
    ),
    now: end.add(const Duration(minutes: 1)),
  );
  final mine = await repo.claimCoupon('u1', 'c1', now: _now);
  final other = await repo.claimCoupon('u1', 'c2', now: _now);
  return (repo, mine, other);
}

void main() {
  group('Uloga partnera – model', () {
    test('AppUser čita ulogu partnera, partnerId i suspenziju', () {
      final partner = AppUser.fromAuthAndDocument(
        uid: 'shop',
        data: {'role': 'partner', 'partnerId': 'p1', 'isSuspended': true},
      );
      expect(partner.role, UserRole.partner);
      expect(partner.isPartner, isTrue);
      expect(partner.isSuspended, isTrue);
      expect(partner.isAdmin, isFalse);

      // Uloga bez partnera ne otvara ekran kupona.
      final broken = AppUser.fromAuthAndDocument(
        uid: 'x',
        data: {'role': 'partner'},
      );
      expect(broken.isPartner, isFalse);
      expect(
        AppUser.fromAuthAndDocument(uid: 'u', data: {'role': 'nesto'}).role,
        UserRole.user,
      );
    });

    test('CouponCode.normalize prihvata unos sa razmacima i malim slovima', () {
      expect(CouponCode.normalize(' vv-7kq2 mz4p '), 'VV-7KQ2MZ4P');
      expect(CouponCode.normalize('7KQ2MZ4P'), 'VV-7KQ2MZ4P');
      expect(CouponCode.normalize('VV-0000'), isNull);
      expect(CouponCode.normalize('VV-ABCDEFGO'), isNull); // O nije u kodu
    });
  });

  group('Partner proverava i označava kupon', () {
    test('važeći, tuđi, neispravan i već iskorišćen kod', () async {
      final (repo, mine, other) = await _claimed();
      Future<PartnerCheckStatus> check(String input) async =>
          (await checkPartnerCoupon(
            repository: repo,
            partnerId: 'p1',
            input: input,
            now: _now,
          )).status;

      expect(await check(mine.code.toLowerCase()), PartnerCheckStatus.valid);
      // Kupon drugog partnera izgleda kao nepostojeći.
      expect(await check(other.code), PartnerCheckStatus.notFound);
      expect(await check('abc'), PartnerCheckStatus.invalidFormat);

      await repo.partnerRedeem(mine.id, byUid: 'shop', now: _now);
      expect(await check(mine.code), PartnerCheckStatus.alreadyRedeemed);
      expect(
        await checkPartnerCoupon(
          repository: repo,
          partnerId: 'p1',
          input: other.code,
          now: _now,
        ).then((r) => r.claim),
        isNull,
      );
      // Istekao kupon se ne označava.
      final p2 = await checkPartnerCoupon(
        repository: repo,
        partnerId: 'p2',
        input: other.code,
        now: _now.add(const Duration(days: 30)),
      );
      expect(p2.status, PartnerCheckStatus.expired);
      await expectLater(
        repo.partnerRedeem(
          other.id,
          byUid: 'shop2',
          now: _now.add(const Duration(days: 30)),
        ),
        throwsA(isA<RewardsException>()),
      );
    });

    testWidgets('ekran Kuponi: unos koda → važeći → označi iskorišćen', (
      tester,
    ) async {
      final (repo, mine, _) =
          await tester.runAsync(_claimed) ?? (throw StateError('no repo'));
      final partners = LocalPartnersRepository(
        partners: const [Partner(id: 'p1', name: 'Pet shop Šapa')],
      );
      addTearDown(partners.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(
                const AppUser(
                  uid: 'shop',
                  role: UserRole.partner,
                  partnerId: 'p1',
                ),
              ),
            ),
            rewardsRepositoryProvider.overrideWithValue(repo),
            rewardsClockProvider.overrideWithValue(() => _now),
            partnersRepositoryProvider.overrideWithValue(partners),
          ],
          child: const MaterialApp(home: PartnerCouponsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Pet shop Šapa'), findsWidgets);

      await tester.enterText(
        find.byKey(const ValueKey('partner-code-field')),
        mine.code.toLowerCase(),
      );
      await tester.tap(find.text(PartnerStrings.check));
      await tester.pumpAndSettle();
      expect(
        find.text(PartnerStrings.result(PartnerCheckStatus.valid)),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(FilledButton, PartnerStrings.redeem),
      );
      await tester.pumpAndSettle();
      // Potvrda u dijalogu.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(PartnerStrings.redeem),
        ),
      );
      await tester.pumpAndSettle();

      final stored = (await repo.watchClaims('u1').first).firstWhere(
        (c) => c.id == mine.id,
      );
      expect(stored.status, ClaimStatus.redeemed);
      expect(stored.redeemedBy, 'shop');
      expect(
        find.text(PartnerStrings.result(PartnerCheckStatus.alreadyRedeemed)),
        findsOneWidget,
      );
    });

    testWidgets('običan korisnik ne vidi ekran Kuponi', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AppUser(uid: 'u1')),
            ),
          ],
          child: const MaterialApp(home: PartnerCouponsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(PartnerStrings.denied), findsOneWidget);
      expect(find.text(PartnerStrings.check), findsNothing);
    });
  });

  group('Admin – imena umesto ID-jeva', () {
    test('BatchedLoader spaja zahteve u jedan poziv i kešira', () async {
      final calls = <Set<String>>[];
      final loader = BatchedLoader<String>((ids) async {
        calls.add(ids);
        return {for (final id in ids) id: 'ime-$id'};
      });
      final names = await Future.wait([
        loader.load('a'),
        loader.load('b'),
        loader.load('a'),
      ]);
      expect(names, ['ime-a', 'ime-b', 'ime-a']);
      expect(calls, [
        {'a', 'b'},
      ]);
      expect(await loader.load('b'), 'ime-b');
      expect(calls, hasLength(1));
    });

    testWidgets('prijava prikazuje imena, pregled psa i fallback', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final admin = LocalAdminRepository(
        dogs: const [AdminDogRef(id: 'dog1', name: 'Žuća', breed: 'Mešanac')],
      );
      addTearDown(admin.dispose);
      final report = ContentReport(
        id: 'r1',
        reporterId: 'local-user',
        reportedUserId: 'izbrisan-uid-123',
        targetType: ReportContentType.dog,
        targetId: 'dog1',
        reason: 'Neprikladan sadržaj',
        timestamp: DateTime(2026, 10, 18, 12),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            adminRepositoryProvider.overrideWithValue(admin),
          ],
          child: MaterialApp(
            home: Scaffold(body: AdminReportCard(report: report)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('${AdminStrings.reporterLabel}: Milica'),
        findsOneWidget,
      );
      expect(
        find.text(
          '${AdminStrings.reportedUserLabel}: ${AdminStrings.unknownUserName}',
        ),
        findsOneWidget,
      );
      expect(find.text('Žuća'), findsOneWidget);
      expect(find.textContaining('izbrisan-uid-123'), findsNothing);
      expect(find.textContaining('dog1'), findsNothing);
      // Oba korisnika su učitana jednim upitom.
      expect(admin.userLookups, [
        {'local-user', 'izbrisan-uid-123'},
      ]);

      await tester.tap(find.text(AdminStrings.deleteDog));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AdminStrings.confirm));
      await tester.pumpAndSettle();
      expect(admin.hasDog('dog1'), isFalse);
    });

    testWidgets('prijava poruke: brisanje tačne poruke iz četa', (
      tester,
    ) async {
      final admin = LocalAdminRepository(
        messages: const [
          AdminMessageRef(
            chatId: 'a_b',
            id: 'm1',
            text: 'Uvredljiva poruka',
            senderId: 'seed-nikola',
          ),
        ],
      );
      addTearDown(admin.dispose);
      final report = ContentReport(
        id: 'r2',
        reporterId: 'local-user',
        reportedUserId: 'seed-nikola',
        targetType: ReportContentType.message,
        targetId: 'm1',
        contextId: 'a_b',
        reason: 'Uznemiravanje',
        timestamp: DateTime(2026, 10, 18, 12),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            adminRepositoryProvider.overrideWithValue(admin),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminReportCard(report: report),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('„Uvredljiva poruka“'), findsOneWidget);
      expect(find.text(AdminStrings.suspendUser), findsOneWidget);

      await tester.tap(find.text(AdminStrings.deleteMessage));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AdminStrings.confirm));
      await tester.pumpAndSettle();
      expect(admin.hasMessage('a_b', 'm1'), isFalse);
    });
  });

  group('Admin panel – početna, korisnici, uloga partnera', () {
    Future<LocalAdminRepository> pumpPanel(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final admin = LocalAdminRepository(
        stats: const AdminStats(users: 42, newUsers7: 5, dogs: 37),
      );
      addTearDown(admin.dispose);
      final partners = LocalPartnersRepository(
        partners: const [Partner(id: 'p1', name: 'Pet shop Šapa')],
      );
      addTearDown(partners.dispose);
      final reports = LocalReportRepository();
      addTearDown(reports.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            adminRepositoryProvider.overrideWithValue(admin),
            partnersRepositoryProvider.overrideWithValue(partners),
            reportRepositoryProvider.overrideWithValue(reports),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return admin;
    }

    testWidgets('početna prikazuje statistiku; nedostupno = –', (tester) async {
      await pumpPanel(tester);
      expect(find.text(AdminStrings.attention), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('37'), findsOneWidget);
      expect(find.text('–'), findsWidgets);
    });

    testWidgets('pretraga korisnika, dodela uloge partnera i suspenzija', (
      tester,
    ) async {
      final admin = await pumpPanel(tester);
      await tester.tap(find.text(AdminStrings.usersTab));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'nik');
      await tester.pumpAndSettle();
      expect(find.text('Nikola'), findsOneWidget);
      expect(find.text('Milica'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milica'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('admin-make-partner')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pet shop Šapa'));
      await tester.pumpAndSettle();
      final milica = admin.users.firstWhere((u) => u.uid == 'local-user');
      expect(milica.role, AdminRoles.partner);
      expect(milica.partnerId, 'p1');
      expect(
        find.text(AdminStrings.roleCurrentPartner('Pet shop Šapa')),
        findsOneWidget,
      );

      await tester.tap(find.text(AdminStrings.removePartner));
      await tester.pumpAndSettle();
      expect(
        admin.users.firstWhere((u) => u.uid == 'local-user').role,
        AdminRoles.user,
      );

      await tester.ensureVisible(find.text(AdminStrings.suspendUser));
      await tester.tap(find.text(AdminStrings.suspendUser));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Spam',
      );
      await tester.tap(find.text(AdminStrings.suspendConfirm));
      await tester.pumpAndSettle();
      final suspended = admin.users.firstWhere((u) => u.uid == 'local-user');
      expect(suspended.isSuspended, isTrue);
      expect(suspended.suspendedReason, 'Spam');
      expect(find.text(AdminStrings.unsuspendUser), findsOneWidget);
    });
  });

  group('Admin – broj preostalih kupona', () {
    test('preostalo = maxQuantity − preuzeto; 0 = rasprodato', () async {
      final (repo, _, _) = await _claimed();
      // c1: max 5, 1 preuzet → preostalo 4.
      Future<Coupon> c1() async =>
          (await repo.watchCoupons(activeOnly: false).first).firstWhere(
            (c) => c.id == 'c1',
          );
      expect((await c1()).remaining, 4);
      await repo.setCouponRemaining('c1', 20);
      expect((await c1()).maxQuantity, 21);
      expect((await c1()).remaining, 20);
      await repo.setCouponRemaining('c1', 0);
      expect((await c1()).availability(_now), CouponAvailability.soldOut);
      await expectLater(
        repo.setCouponRemaining('c1', -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('admin menja preostali broj iz kartice kupona', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = LocalRewardsRepository(
        challenges: const [],
        coupons: [_coupon('c1')],
      );
      final partners = LocalPartnersRepository();
      addTearDown(partners.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            rewardsRepositoryProvider.overrideWithValue(repo),
            partnersRepositoryProvider.overrideWithValue(partners),
          ],
          child: const MaterialApp(home: Scaffold(body: AdminRewardsTab())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AdminStrings.rewardsCoupons));
      await tester.pumpAndSettle();
      expect(find.text(AdminStrings.rewardsRemaining(5, 0)), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('coupon-remaining-c1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('coupon-remaining-field')),
        '120',
      );
      await tester.tap(find.text('+10'));
      await tester.pump();
      await tester.tap(find.text(AdminStrings.save));
      await tester.pumpAndSettle();

      expect(find.text(AdminStrings.rewardsRemaining(130, 0)), findsOneWidget);
      expect(
        (await repo.watchCoupons(activeOnly: false).first).single.maxQuantity,
        130,
      );
    });
  });

  group('rođendanski poklon', () {
    late LocalRewardsRepository birthdayRewards;
    setUp(() {
      birthdayRewards = LocalRewardsRepository(
        challenges: const [],
        coupons: [_coupon('rodjendan')],
      );
    });
    Future<LocalAdminRepository> pumpBirthday(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final admin = LocalAdminRepository();
      addTearDown(admin.dispose);
      final partners = LocalPartnersRepository();
      addTearDown(partners.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            adminRepositoryProvider.overrideWithValue(admin),
            rewardsRepositoryProvider.overrideWithValue(birthdayRewards),
            partnersRepositoryProvider.overrideWithValue(partners),
          ],
          child: const MaterialApp(home: Scaffold(body: AdminRewardsTab())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AdminStrings.birthdayTab));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AdminStrings.birthdayTab));
      await tester.pumpAndSettle();
      return admin;
    }

    testWidgets('bez kupona ne može da se uključi', (tester) async {
      final admin = await pumpBirthday(tester);

      await tester.tap(find.byKey(const ValueKey('admin-birthday-enabled')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-birthday-save')));
      await tester.pumpAndSettle();

      expect(find.text(AdminStrings.birthdayNeedsCoupon), findsOneWidget);
      expect(admin.birthdayReward.enabled, isFalse);
    });

    testWidgets('izbor kupona + uključivanje upisuje app_config/birthday', (
      tester,
    ) async {
      final admin = await pumpBirthday(tester);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hrana · Pet shop Šapa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-birthday-enabled')));
      await tester.pumpAndSettle();

      // Pregled čestitke već najavljuje poklon.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('admin-birthday-preview')),
          matching: find.textContaining('Pet shop Šapa'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('admin-birthday-save')));
      await tester.pumpAndSettle();

      expect(admin.birthdayReward.enabled, isTrue);
      expect(admin.birthdayReward.couponId, 'rodjendan');
      expect(admin.birthdayReward.partnerName, 'Pet shop Šapa');
      expect(admin.birthdayReward.isActive, isTrue);
      // Kupon je postao rođendanski i besplatan.
      final coupon = (await birthdayRewards.watchCoupons(activeOnly: false).first)
          .single;
      expect(coupon.isBirthday, isTrue);
      expect(coupon.pointsCost, 0);
    });
  });
}
