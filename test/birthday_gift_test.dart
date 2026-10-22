import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/dogs/data/local_reminder_repository.dart';
import 'package:vauvau/features/dogs/domain/dog_reminder.dart';
import 'package:vauvau/features/dogs/presentation/dog_providers.dart';
import 'package:vauvau/features/dogs/presentation/health/reminder_controller.dart';
import 'package:vauvau/features/rewards/data/birthday_reward_source.dart';
import 'package:vauvau/features/rewards/data/local_rewards_repository.dart';
import 'package:vauvau/features/rewards/domain/birthday_reward.dart';
import 'package:vauvau/features/rewards/domain/rewards_models.dart';
import 'package:vauvau/features/rewards/presentation/challenge_hub_screen.dart';
import 'package:vauvau/features/rewards/presentation/rewards_controller.dart';
import 'package:vauvau/features/rewards/presentation/rewards_strings.dart';

import 'fakes/fake_dogs_repository.dart';

final DateTime _now = DateTime(2026, 10, 22, 12);
final DateTime _birthday = DateTime(2026, 10, 20);

Coupon _coupon({bool birthday = true, int cost = 0, bool active = true}) =>
    Coupon(
      id: 'bday',
      partnerName: 'Pet shop Šapa',
      title: 'Rođendanski poklon',
      description: '',
      discountLabel: 'Poslastica gratis',
      pointsCost: cost,
      startsAt: _now.subtract(const Duration(days: 100)),
      expiresAt: _now.add(const Duration(days: 100)),
      maxQuantity: 50,
      isActive: active,
      isBirthday: birthday,
    );

BirthdayReminderRef _ref(DateTime date) =>
    BirthdayReminderRef(dogId: 'dog-1', reminderId: 'r1', date: date);

BirthdayEligibility _eligibility() =>
    BirthdayEligibility.find([_ref(_birthday)], _now)!;

void main() {
  group('pravo na poklon (30 dana od rođendana)', () {
    test('u roku: dan rođendana i do 30 dana posle', () {
      expect(BirthdayEligibility.find([_ref(_birthday)], _birthday), isNotNull);
      final e = BirthdayEligibility.find([_ref(_birthday)], _now)!;
      expect(e.birthday, _birthday);
      expect(e.deadline, _birthday.add(const Duration(days: 30)));
      expect(
        BirthdayEligibility.find(
          [_ref(_birthday)],
          _birthday.add(const Duration(days: 29, hours: 23)),
        ),
        isNotNull,
      );
    });

    test('van roka: posle 30 dana ili pre rođendana', () {
      expect(
        BirthdayEligibility.find(
          [_ref(_birthday)],
          _birthday.add(const Duration(days: 30)),
        ),
        isNull,
      );
      expect(
        BirthdayEligibility.find(
          [_ref(_birthday)],
          _birthday.subtract(const Duration(hours: 1)),
        ),
        isNull,
      );
    });

    test('godišnji podsetnik već pomeren na sledeću godinu', () {
      final rolled = _birthday.add(const Duration(days: 365));
      final e = BirthdayEligibility.find([_ref(rolled)], _now)!;
      expect(e.birthday, _birthday);
      expect(e.year, _birthday.toUtc().year);
    });
  });

  group('preuzimanje', () {
    test('besplatno, jednom godišnje; obično preuzimanje ne prolazi', () async {
      final repo = LocalRewardsRepository(
        challenges: const [],
        coupons: [_coupon()],
      );
      await expectLater(
        repo.claimCoupon('u1', 'bday', now: _now),
        throwsA(isA<RewardsException>()),
      );

      final claim = await repo.claimBirthdayCoupon(
        'u1',
        'bday',
        _eligibility(),
        now: _now,
      );
      expect(claim.pointsCost, 0);
      expect(claim.id, CouponClaim.birthdayDocId('bday', 'u1', 2026));
      expect(await repo.hasBirthdayClaim('u1', 2026), isTrue);

      await expectLater(
        repo.claimBirthdayCoupon('u1', 'bday', _eligibility(), now: _now),
        throwsA(
          isA<RewardsException>().having(
            (e) => e.code,
            'code',
            RewardsErrorCode.alreadyClaimed,
          ),
        ),
      );
    });

    test('van roka, običan ili plaćen kupon – odbijeno', () async {
      final late = _birthday.add(const Duration(days: 31));
      final repo = LocalRewardsRepository(
        challenges: const [],
        coupons: [_coupon()],
      );
      await expectLater(
        repo.claimBirthdayCoupon('u1', 'bday', _eligibility(), now: late),
        throwsA(isA<RewardsException>()),
      );

      for (final coupon in [_coupon(birthday: false), _coupon(cost: 10)]) {
        final other = LocalRewardsRepository(
          challenges: const [],
          coupons: [coupon],
        );
        await expectLater(
          other.claimBirthdayCoupon('u1', 'bday', _eligibility(), now: _now),
          throwsA(isA<RewardsException>()),
        );
      }
    });

    test('admin: označen kupon postaje besplatan i rođendanski', () async {
      final repo = LocalRewardsRepository(
        challenges: const [],
        coupons: [_coupon(birthday: false, cost: 50)],
      );
      await repo.setBirthdayCoupon('bday', birthday: true);
      final stored = (await repo.watchCoupons(activeOnly: false).first).single;
      expect(stored.isBirthday, isTrue);
      expect(stored.pointsCost, 0);
    });
  });

  group('Nagrade', () {
    Future<(ProviderContainer, LocalRewardsRepository)> setup({
      BirthdayRewardConfig config = const BirthdayRewardConfig(
        enabled: true,
        couponId: 'bday',
        partnerName: 'Pet shop Šapa',
      ),
      DateTime? reminderDate,
    }) async {
      final rewards = LocalRewardsRepository(
        challenges: const [],
        coupons: [_coupon()],
      );
      final reminders = LocalReminderRepository();
      addTearDown(reminders.dispose);
      await reminders.saveReminder(
        DogReminder(
          id: 'r1',
          dogId: 'dog-1',
          title: 'Rođendan',
          type: ReminderType.birthday,
          date: reminderDate ?? _birthday,
          repeatType: ReminderRepeat.yearly,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          rewardsUidProvider.overrideWithValue('u1'),
          rewardsClockProvider.overrideWithValue(() => _now),
          rewardsRepositoryProvider.overrideWithValue(rewards),
          birthdayRewardConfigProvider.overrideWith((ref) async => config),
          ownerDogsProvider.overrideWith(
            (ref) => Stream.value([fakeDog(ownerId: 'u1')]),
          ),
          reminderRepositoryProvider.overrideWith((ref) => reminders),
        ],
      );
      addTearDown(container.dispose);
      return (container, rewards);
    }

    test('slavljenik vidi poklon; posle preuzimanja nestaje', () async {
      final (c, _) = await setup();
      final sub = c.listen(birthdayGiftProvider, (_, _) {});
      addTearDown(sub.close);
      final gift = await c.read(birthdayGiftProvider.future);
      expect(gift, isNotNull);
      expect(gift!.eligibility.dogName, 'Luna');

      await c.read(walkRewardsServiceProvider).claimBirthdayGift(gift);
      expect(await c.read(birthdayGiftProvider.future), isNull);
    });

    test('bez rođendana u roku ili isključen poklon – ništa', () async {
      final (old, _) = await setup(
        reminderDate: _birthday.subtract(const Duration(days: 40)),
      );
      expect(await old.read(birthdayGiftProvider.future), isNull);

      final (off, _) = await setup(config: BirthdayRewardConfig.disabled);
      expect(await off.read(birthdayGiftProvider.future), isNull);
    });

    testWidgets('kartica poklona: preuzimanje prikazuje kod', (tester) async {
      final rewards = LocalRewardsRepository(
        challenges: const [],
        coupons: [_coupon()],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rewardsUidProvider.overrideWithValue('u1'),
            rewardsClockProvider.overrideWithValue(() => _now),
            rewardsRepositoryProvider.overrideWithValue(rewards),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BirthdayGiftCard(
                gift: BirthdayGift(
                  coupon: _coupon(),
                  eligibility: BirthdayEligibility(
                    dogId: 'dog-1',
                    reminderId: 'r1',
                    birthday: _birthday,
                    dogName: 'Luna',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text(RewardsStrings.birthdayGiftTitle('Luna')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('birthday-gift-claim')));
      await tester.pumpAndSettle();
      expect(await rewards.hasBirthdayClaim('u1', 2026), isTrue);
      expect(find.textContaining('VV-'), findsOneWidget);
    });
  });
}
