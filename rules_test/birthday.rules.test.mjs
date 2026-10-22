// Testovi pravila za rođendanski kupon (isBirthday): samo vlasnik psa sa
// podsetnikom „Rođendan“, od rođendana do 30 dana posle, jednom godišnje.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  writeBatch,
} from 'firebase/firestore';

let env;

const [emuHost, emuPort] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');

const DAY = 86400e3;
// Lokalna ponoć kao u aplikaciji nije bitna: pravila porede tačan Timestamp.
const midnightDaysAgo = (n) => {
  const d = new Date(Date.now() - n * DAY);
  d.setUTCHours(0, 0, 0, 0);
  return d;
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-vauvau-birthday',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: emuHost,
      port: Number(emuPort),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

async function seedReminder(id, date, patch = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `dogs/d1/reminders/${id}`), {
      dogId: 'd1', title: 'Rođendan', type: 'birthday',
      date: Timestamp.fromDate(date), ...patch,
    });
  });
}

async function seedCoupon(id, patch = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `reward_coupons/${id}`), {
      partnerName: 'Pet shop Šapa', discountLabel: 'Poklon', pointsCost: 0,
      startsAt: Timestamp.fromDate(new Date(Date.now() - 400 * DAY)),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 400 * DAY)),
      maxQuantity: 100, claimedCount: 0, isActive: true, isBirthday: true,
      ...patch,
    });
  });
}

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/admin'), { role: 'admin' });
    for (const uid of ['alice', 'bob']) {
      await setDoc(doc(db, `users/${uid}`), { role: 'user' });
    }
    await setDoc(doc(db, 'dogs/d1'), { ownerId: 'alice', name: 'Dzeki' });
  });
  await seedCoupon('bday');
});

const as = (uid) => env.authenticatedContext(uid).firestore();

// Isto kao klijent (FirestoreRewardsRepository.claimBirthdayCoupon).
async function claimBirthday(uid, {
  couponId = 'bday',
  birthday,
  year = birthday.getUTCFullYear(),
  dogId = 'd1',
  reminderId = 'r1',
  withMarker = true,
  cost = 0,
} = {}) {
  const db = as(uid);
  const coupon = (await getDoc(doc(db, `reward_coupons/${couponId}`))).data();
  const summary = (await getDoc(doc(db, `users/${uid}/rewards/summary`))).data() ?? {};
  const entryId = `coupon_${couponId}_${year}`;
  const batch = writeBatch(db);
  batch.set(doc(db, `coupon_claims/${couponId}_${uid}_${year}`), {
    userId: uid, couponId, code: 'VV-ABCD2345', status: 'claimed',
    pointsCost: cost, partnerName: coupon.partnerName, title: '',
    discountLabel: coupon.discountLabel, expiresAt: coupon.expiresAt,
    claimedAt: serverTimestamp(), birthdayYear: year,
  });
  batch.update(doc(db, `reward_coupons/${couponId}`), {
    claimedCount: (coupon.claimedCount ?? 0) + 1,
  });
  batch.set(doc(db, `users/${uid}/reward_ledger/${entryId}`), {
    // -0 bi u JS-u bio double (pravila traže int), Dart šalje 0.
    type: 'coupon', couponId, birthdayYear: year, xp: 0, points: cost === 0 ? 0 : -cost,
    reason: 'Rođendanski poklon', createdAt: serverTimestamp(),
  });
  batch.set(doc(db, `users/${uid}/rewards/summary`), {
    xp: summary.xp ?? 0,
    points: (summary.points ?? 0) - cost + 0,
    lastEntryId: entryId,
    updatedAt: serverTimestamp(),
  });
  if (withMarker) {
    batch.set(doc(db, `birthday_claims/${uid}_${year}`), {
      userId: uid, couponId, dogId, reminderId,
      birthday: Timestamp.fromDate(birthday), birthdayYear: year,
      createdAt: serverTimestamp(),
    });
  }
  return batch.commit();
}

// Obično preuzimanje (kao u rewards.rules.test.mjs).
async function claimNormal(uid, couponId) {
  const db = as(uid);
  const coupon = (await getDoc(doc(db, `reward_coupons/${couponId}`))).data();
  const entryId = `coupon_${couponId}`;
  const batch = writeBatch(db);
  batch.set(doc(db, `coupon_claims/${couponId}_${uid}`), {
    userId: uid, couponId, code: 'VV-ABCD2345', status: 'claimed',
    pointsCost: coupon.pointsCost, partnerName: coupon.partnerName, title: '',
    discountLabel: coupon.discountLabel, expiresAt: coupon.expiresAt,
    claimedAt: serverTimestamp(),
  });
  batch.update(doc(db, `reward_coupons/${couponId}`), {
    claimedCount: (coupon.claimedCount ?? 0) + 1,
  });
  batch.set(doc(db, `users/${uid}/reward_ledger/${entryId}`), {
    type: 'coupon', couponId, xp: 0, points: -coupon.pointsCost,
    reason: 'Kupon', createdAt: serverTimestamp(),
  });
  batch.set(doc(db, `users/${uid}/rewards/summary`), {
    xp: 0, points: -coupon.pointsCost, lastEntryId: entryId,
    updatedAt: serverTimestamp(),
  });
  return batch.commit();
}

describe('rođendanski kupon', () => {
  test('vlasnik u roku od 30 dana od rođendana preuzima besplatno', async () => {
    const birthday = midnightDaysAgo(2);
    await seedReminder('r1', birthday);
    await assertSucceeds(claimBirthday('alice', { birthday }));
    const marker = await getDoc(doc(as('alice'), `birthday_claims/alice_${birthday.getUTCFullYear()}`));
    if (!marker.exists()) throw new Error('marker nije upisan');
  });

  test('godišnji podsetnik već pomeren na sledeću godinu (−365 dana)', async () => {
    const birthday = midnightDaysAgo(5);
    await seedReminder('r1', new Date(birthday.getTime() + 365 * DAY));
    await assertSucceeds(claimBirthday('alice', { birthday }));
  });

  test('van roka: posle 30 dana ili pre rođendana', async () => {
    const old = midnightDaysAgo(31);
    await seedReminder('r1', old);
    await assertFails(claimBirthday('alice', { birthday: old }));

    const future = new Date(midnightDaysAgo(0).getTime() + 2 * DAY);
    await seedReminder('r2', future);
    await assertFails(claimBirthday('alice', { birthday: future, reminderId: 'r2' }));
  });

  test('datum mora da se poklapa sa podsetnikom; tip mora biti rođendan', async () => {
    const birthday = midnightDaysAgo(2);
    await seedReminder('r1', midnightDaysAgo(10));
    await assertFails(claimBirthday('alice', { birthday }));

    await seedReminder('r3', birthday, { type: 'grooming' });
    await assertFails(claimBirthday('alice', { birthday, reminderId: 'r3' }));
  });

  test('tuđi pas ne daje pravo', async () => {
    const birthday = midnightDaysAgo(2);
    await seedReminder('r1', birthday);
    await assertFails(claimBirthday('bob', { birthday }));
  });

  test('jednom godišnje, i sa drugim rođendanskim kuponom', async () => {
    const birthday = midnightDaysAgo(2);
    await seedReminder('r1', birthday);
    await assertSucceeds(claimBirthday('alice', { birthday }));
    await assertFails(claimBirthday('alice', { birthday }));

    await seedCoupon('bday2');
    await assertFails(claimBirthday('alice', { birthday, couponId: 'bday2' }));
  });

  test('bez oznake, sa cenom ili kao običan kupon – odbijeno', async () => {
    const birthday = midnightDaysAgo(2);
    await seedReminder('r1', birthday);
    await assertFails(claimBirthday('alice', { birthday, withMarker: false }));
    await assertFails(claimBirthday('alice', { birthday, cost: 10 }));
    await assertFails(claimNormal('alice', 'bday'));

    await seedCoupon('paid', { pointsCost: 10 });
    await assertFails(claimBirthday('alice', { birthday, couponId: 'paid', cost: 10 }));
  });

  test('neaktivan kupon i obični kupon preko rođendanske putanje – odbijeno', async () => {
    const birthday = midnightDaysAgo(2);
    await seedReminder('r1', birthday);
    await seedCoupon('off', { isActive: false });
    await assertFails(claimBirthday('alice', { birthday, couponId: 'off' }));

    await seedCoupon('normal', { isBirthday: false });
    await assertFails(claimBirthday('alice', { birthday, couponId: 'normal' }));
  });

  test('oznaku vidi samo vlasnik i admin; ne briše se', async () => {
    const birthday = midnightDaysAgo(2);
    await seedReminder('r1', birthday);
    await assertSucceeds(claimBirthday('alice', { birthday }));
    const path = `birthday_claims/alice_${birthday.getUTCFullYear()}`;
    await assertFails(getDoc(doc(as('bob'), path)));
    await assertSucceeds(getDoc(doc(as('admin'), path)));
    await assertFails(deleteDoc(doc(as('alice'), path)));
    // Oznaka koja još ne postoji može da se proveri (pre preuzimanja).
    await assertSucceeds(getDoc(doc(as('bob'), 'birthday_claims/bob_2020')));
  });
});
