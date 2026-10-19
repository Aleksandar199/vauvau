// Testovi pravila za „Dnevni VauVau izazov“ (XP, poeni, izazovi, kuponi).
// Poseban projectId da se ne meša sa firestore.rules.test.mjs (paralelno).
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let env;

const [emuHost, emuPort] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-vauvau-rewards',
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

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/admin'), { role: 'admin' });
    for (const uid of ['alice', 'bob']) {
      await setDoc(doc(db, `users/${uid}`), { role: 'user' });
    }
    await setDoc(doc(db, 'reward_challenges/daily_2km'), {
      title: '2 km danas', period: 'daily', metric: 'distance', target: 2,
      rewardXp: 10, rewardPoints: 10, isActive: true,
    });
    await setDoc(doc(db, 'reward_challenges/weekly_3walks'), {
      title: '3 šetnje', period: 'weekly', metric: 'walks', target: 3,
      rewardXp: 20, rewardPoints: 20, isActive: true,
    });
    await setDoc(doc(db, 'reward_challenges/off'), {
      title: 'Neaktivan', period: 'daily', metric: 'distance', target: 0,
      rewardXp: 10, rewardPoints: 10, isActive: false,
    });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();

// JS kopija BelgradeCalendar (lib/features/rewards/domain/belgrade_calendar.dart).
function belgradeOffsetH(d) {
  const m = d.getUTCMonth() + 1;
  const day = d.getUTCDate();
  const s = day - d.getUTCDay();
  const past = s >= 25 && (day > s || d.getUTCHours() >= 1);
  return (m > 3 && m < 10) || (m === 3 && past) || (m === 10 && !past) ? 2 : 1;
}
const localOf = (d) => new Date(d.getTime() + belgradeOffsetH(d) * 3600e3);
const keyOf = (l) =>
  l.getUTCFullYear() * 10000 + (l.getUTCMonth() + 1) * 100 + l.getUTCDate();
const dayKeyOf = (d) => keyOf(localOf(d));
const weekKeyOf = (d) => {
  const l = localOf(d);
  const wd = l.getUTCDay() === 0 ? 7 : l.getUTCDay();
  return keyOf(new Date(l.getTime() - (wd - 1) * 86400e3));
};

const MIN = 60e3;
const walkDoc = ({ meters, minutes, endedAt = new Date(Date.now() - MIN) }) => ({
  id: 'w',
  userId: 'alice',
  recognizedMeters: meters,
  durationSeconds: minutes * 60,
  startedAt: Timestamp.fromDate(new Date(endedAt.getTime() - minutes * MIN - 5000)),
  endedAt: Timestamp.fromDate(endedAt),
});

const summaryOf = async (uid) =>
  (await getDoc(doc(as(uid), `users/${uid}/rewards/summary`))).data() ?? {};

// Isto kao klijent (FirestoreRewardsRepository._payWalk); `tamper` kvari payload.
async function payWalk(uid, walkId, walk, tamper = {}) {
  const db = as(uid);
  const endedAt = walk.endedAt.toDate();
  const day = tamper.dayKey ?? dayKeyOf(endedAt);
  const week = weekKeyOf(endedAt);
  const read = async (id) =>
    (await getDoc(doc(db, `users/${uid}/rewards/${id}`))).data() ?? {};
  const summary = await read('summary');
  const d = await read(`d${day}`);
  const w = await read(`w${week}`);
  const km = Math.floor(walk.recognizedMeters / 1000);
  const room = 30 - (d.walkPoints ?? 0);
  const pts = tamper.points ?? Math.max(0, Math.min(km * 5, room));
  const counted = km >= 1 ? 1 : 0;
  const entryId = `walk_${walkId}`;
  const batch = writeBatch(db);
  if (!tamper.skipWalk) batch.set(doc(db, `users/${uid}/walks/${walkId}`), walk);
  if (!tamper.skipLedger) {
    batch.set(doc(db, `users/${uid}/reward_ledger/${entryId}`), {
      type: 'walk', walkId, km, dayKey: day, weekKey: week,
      xp: pts, points: pts, reason: 'Šetnja', createdAt: serverTimestamp(),
    });
  }
  if (!tamper.skipSummary) {
    batch.set(doc(db, `users/${uid}/rewards/summary`), {
      xp: (summary.xp ?? 0) + pts + (tamper.extraXp ?? 0),
      points: (summary.points ?? 0) + pts,
      lastEntryId: entryId,
      updatedAt: serverTimestamp(),
    });
  }
  const progress = (p) => ({
    meters: (p.meters ?? 0) + walk.recognizedMeters,
    walks: (p.walks ?? 0) + counted,
    walkPoints: (p.walkPoints ?? 0) + pts,
    lastEntryId: entryId,
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, `users/${uid}/rewards/d${day}`), progress(d));
  batch.set(doc(db, `users/${uid}/rewards/w${week}`), progress(w));
  return batch.commit();
}

async function claimChallenge(uid, challengeId, periodKey, { xp = 10, points = 10 } = {}) {
  const db = as(uid);
  const summary = await summaryOf(uid);
  const entryId = `ch_${challengeId}_${periodKey}`;
  const batch = writeBatch(db);
  batch.set(doc(db, `users/${uid}/reward_ledger/${entryId}`), {
    type: 'challenge', challengeId, periodKey, xp, points,
    reason: 'Izazov', createdAt: serverTimestamp(),
  });
  batch.set(doc(db, `users/${uid}/rewards/summary`), {
    xp: (summary.xp ?? 0) + xp,
    points: (summary.points ?? 0) + points,
    lastEntryId: entryId,
    updatedAt: serverTimestamp(),
  });
  return batch.commit();
}

// Isto kao klijent (FirestoreRewardsRepository.claimCoupon), bez transakcije
// da bi se videlo da pravila sama čuvaju saldo i količinu.
async function claimCoupon(uid, couponId, { code = 'VV-ABCD2345', count, cost, coupon: known } = {}) {
  const db = as(uid);
  const coupon = known ?? (await getDoc(doc(db, `reward_coupons/${couponId}`))).data();
  const summary = await summaryOf(uid);
  const price = cost ?? coupon.pointsCost;
  const entryId = `coupon_${couponId}`;
  const batch = writeBatch(db);
  batch.set(doc(db, `coupon_claims/${couponId}_${uid}`), {
    userId: uid, couponId, code, status: 'claimed', pointsCost: price,
    partnerName: coupon.partnerName, title: '', discountLabel: coupon.discountLabel,
    expiresAt: coupon.expiresAt, claimedAt: serverTimestamp(),
  });
  batch.update(doc(db, `reward_coupons/${couponId}`), {
    claimedCount: count ?? (coupon.claimedCount ?? 0) + 1,
  });
  batch.set(doc(db, `users/${uid}/reward_ledger/${entryId}`), {
    type: 'coupon', couponId, xp: 0, points: -price,
    reason: 'Kupon', createdAt: serverTimestamp(),
  });
  batch.set(doc(db, `users/${uid}/rewards/summary`), {
    xp: summary.xp ?? 0,
    points: (summary.points ?? 0) - price,
    lastEntryId: entryId,
    updatedAt: serverTimestamp(),
  });
  return batch.commit();
}

async function seedCoupon(id, patch = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `reward_coupons/${id}`), {
      partnerName: 'Pet shop', discountLabel: '15% popusta', pointsCost: 100,
      startsAt: Timestamp.fromDate(new Date(Date.now() - 86400e3)),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 86400e3)),
      maxQuantity: 5, claimedCount: 0, isActive: true, ...patch,
    });
  });
}

// Saldo „kao da“ je zarađen ranije (sa evidencijom).
async function seedPoints(uid, points) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `users/${uid}/reward_ledger/seed`), { type: 'walk', xp: points, points });
    await setDoc(doc(db, `users/${uid}/rewards/summary`), { xp: points, points, lastEntryId: 'seed' });
  });
}

describe('nagrade: šetnje', () => {
  test('2,5 km: tačan obračun prolazi, ponovni zahtev za istu šetnju pada', async () => {
    const walk = walkDoc({ meters: 2500, minutes: 30 });
    await assertSucceeds(payWalk('alice', 'w1', walk));
    const summary = await summaryOf('alice');
    assert.equal(summary.xp, 10);
    assert.equal(summary.points, 10);
    // Ista šetnja još jednom (pauza / restart / ponovljen zahtev).
    await assertFails(payWalk('alice', 'w1', walk, { skipWalk: true }));
  });

  test('lažni iznosi, bez evidencije, bez salda ili pogrešan dan – pada', async () => {
    const walk = walkDoc({ meters: 2500, minutes: 30 });
    await assertFails(payWalk('alice', 'w1', walk, { points: 15 }));
    await assertFails(payWalk('alice', 'w1', walk, { extraXp: 50 }));
    await assertFails(payWalk('alice', 'w1', walk, { skipLedger: true }));
    await assertFails(payWalk('alice', 'w1', walk, { skipSummary: true }));
    await assertFails(payWalk('alice', 'w1', walk, { dayKey: 20200101 }));
    // Direktna izmena salda bez evidencije.
    await assertFails(setDoc(doc(as('alice'), 'users/alice/rewards/summary'), {
      xp: 999, points: 999, lastEntryId: 'nema', updatedAt: serverTimestamp(),
    }));
  });

  test('vožnja (prosek > 7 km/h), stara i predugačka šetnja – pada', async () => {
    await assertFails(payWalk('alice', 'car', walkDoc({ meters: 10000, minutes: 20 })));
    await assertFails(payWalk('alice', 'old', walkDoc({
      meters: 2000, minutes: 30, endedAt: new Date(Date.now() - 49 * 3600e3),
    })));
    await assertFails(payWalk('alice', 'long', walkDoc({ meters: 20000, minutes: 300 })));
    // Granica: tačno 7 km/h prolazi.
    await assertSucceeds(payWalk('alice', 'edge', walkDoc({ meters: 3500, minutes: 30 })));
  });

  test('dnevni limit 30 poena od kilometara', async () => {
    await assertSucceeds(payWalk('alice', 'a', walkDoc({ meters: 4200, minutes: 50 })));
    // Drugi put 4 km: do limita je ostalo 10, 20 pada.
    await assertFails(payWalk('alice', 'b', walkDoc({ meters: 4000, minutes: 45 }), { points: 20 }));
    await assertSucceeds(payWalk('alice', 'b', walkDoc({ meters: 4000, minutes: 45 })));
    // Treća: 0 poena, ali se računa u kilometre izazova.
    await assertSucceeds(payWalk('alice', 'c', walkDoc({ meters: 1500, minutes: 20 })));
    assert.equal((await summaryOf('alice')).points, 30);
  });

  test('šetnja i evidencija su privatne i nepromenljive', async () => {
    await assertSucceeds(payWalk('alice', 'w1', walkDoc({ meters: 2000, minutes: 25 })));
    await assertFails(getDoc(doc(as('bob'), 'users/alice/walks/w1')));
    await assertFails(getDoc(doc(as('bob'), 'users/alice/rewards/summary')));
    await assertFails(getDoc(doc(as('bob'), 'users/alice/reward_ledger/walk_w1')));
    await assertFails(updateDoc(doc(as('alice'), 'users/alice/walks/w1'), { recognizedMeters: 9000 }));
    await assertFails(deleteDoc(doc(as('alice'), 'users/alice/reward_ledger/walk_w1')));
    await assertFails(deleteDoc(doc(as('alice'), 'users/alice/rewards/summary')));
    // Admin vidi evidenciju svih (collection group), korisnik ne.
    await assertSucceeds(getDocs(query(collectionGroup(as('admin'), 'reward_ledger'))));
    await assertFails(getDocs(query(collectionGroup(as('bob'), 'reward_ledger'))));
  });

  test('brisanje naloga: evidencija se briše tek posle javnog profila', async () => {
    await assertSucceeds(payWalk('alice', 'w1', walkDoc({ meters: 2000, minutes: 25 })));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'users/alice')));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'users/alice/reward_ledger/walk_w1')));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'users/alice/rewards/summary')));
  });
});

describe('nagrade: izazovi', () => {
  test('dnevni: jednom po danu, samo kad je cilj ispunjen i izazov aktivan', async () => {
    const today = dayKeyOf(new Date());
    await assertSucceeds(payWalk('alice', 'w1', walkDoc({ meters: 1200, minutes: 15 })));
    await assertFails(claimChallenge('alice', 'daily_2km', today));
    await assertSucceeds(payWalk('alice', 'w2', walkDoc({ meters: 1000, minutes: 12 })));
    await assertFails(claimChallenge('alice', 'daily_2km', today, { xp: 50 }));
    await assertSucceeds(claimChallenge('alice', 'daily_2km', today));
    await assertFails(claimChallenge('alice', 'daily_2km', today));
    await assertFails(claimChallenge('alice', 'off', today));
    // Stari period (van 48 h) pada.
    await assertFails(claimChallenge('alice', 'daily_2km', 20200101));
  });

  test('nedeljni cilj: 3 šetnje od najmanje 1 km', async () => {
    const week = weekKeyOf(new Date());
    const bonus = { xp: 20, points: 20 };
    await assertSucceeds(payWalk('alice', 'a', walkDoc({ meters: 1100, minutes: 15 })));
    await assertSucceeds(payWalk('alice', 'b', walkDoc({ meters: 800, minutes: 10 })));
    await assertSucceeds(payWalk('alice', 'c', walkDoc({ meters: 1300, minutes: 15 })));
    await assertFails(claimChallenge('alice', 'weekly_3walks', week, bonus));
    await assertSucceeds(payWalk('alice', 'd', walkDoc({ meters: 1000, minutes: 12 })));
    await assertSucceeds(claimChallenge('alice', 'weekly_3walks', week, bonus));
    await assertFails(claimChallenge('alice', 'weekly_3walks', week, bonus));
  });

  test('izazove i kupone menja samo admin', async () => {
    await seedCoupon('c1');
    await assertFails(updateDoc(doc(as('alice'), 'reward_challenges/daily_2km'), { rewardXp: 500 }));
    await assertFails(setDoc(doc(as('alice'), 'reward_coupons/mine'), { pointsCost: 0 }));
    await assertFails(updateDoc(doc(as('alice'), 'reward_coupons/c1'), { pointsCost: 1 }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'reward_challenges/daily_2km'), { isActive: false }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'reward_coupons/c1'), { maxQuantity: 50 }));
    await assertSucceeds(getDoc(doc(as('bob'), 'reward_coupons/c1')));
  });
});

describe('nagrade: kuponi', () => {
  test('nedovoljno poena pada bez oduzimanja; dovoljno prolazi jednom', async () => {
    await seedCoupon('c1');
    await seedPoints('alice', 60);
    await assertFails(claimCoupon('alice', 'c1'));
    assert.equal((await summaryOf('alice')).points, 60);

    await seedPoints('alice', 160);
    await assertFails(claimCoupon('alice', 'c1', { cost: 1 }));
    await assertFails(claimCoupon('alice', 'c1', { code: 'kod123' }));
    await assertFails(claimCoupon('alice', 'c1', { count: 3 }));
    await assertSucceeds(claimCoupon('alice', 'c1'));
    const after = await summaryOf('alice');
    assert.equal(after.points, 60);
    assert.equal(after.xp, 160, 'XP (nivo) se ne troši');
    // Isti kupon drugi put.
    await assertFails(claimCoupon('alice', 'c1', { code: 'VV-ZZZZ2345' }));
  });

  test('rasprodat, istekao, nije počeo ili neaktivan', async () => {
    await seedCoupon('c1', { maxQuantity: 1 });
    await seedPoints('alice', 300);
    await seedPoints('bob', 300);
    await assertSucceeds(claimCoupon('alice', 'c1'));
    // Količina potrošena: claimedCount 1 → 2 > max.
    await assertFails(claimCoupon('bob', 'c1'));
    // Zastareo zahtev (izračunat pre alice-inog preuzimanja): ostaje 1.
    await assertFails(claimCoupon('bob', 'c1', { count: 1 }));

    for (const patch of [
      { expiresAt: Timestamp.fromDate(new Date(Date.now() - 1000)) },
      { startsAt: Timestamp.fromDate(new Date(Date.now() + 86400e3)) },
      { isActive: false },
    ]) {
      await seedCoupon('c2', { pointsCost: 50, ...patch });
      await assertFails(claimCoupon('bob', 'c2'));
    }
    assert.equal((await summaryOf('bob')).points, 300);
  });

  test('istovremena preuzimanja ne prelaze količinu', async () => {
    await seedCoupon('c1', { maxQuantity: 1 });
    await seedPoints('alice', 300);
    await seedPoints('bob', 300);
    const coupon = (await getDoc(doc(as('alice'), 'reward_coupons/c1'))).data();
    // Oba zahteva su izračunata iz istog stanja (claimedCount 0).
    const results = await Promise.allSettled([
      claimCoupon('alice', 'c1', { coupon }),
      claimCoupon('bob', 'c1', { coupon }),
    ]);
    assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
    const stored = (await getDoc(doc(as('alice'), 'reward_coupons/c1'))).data();
    assert.equal(stored.claimedCount, 1);
  });

  test('korisnik ne označava sam (to radi partner/admin), admin otkazuje', async () => {
    await seedCoupon('c1');
    await seedPoints('alice', 300);
    await seedPoints('bob', 300);
    await assertSucceeds(claimCoupon('alice', 'c1'));
    const ref = (uid) => doc(as(uid), 'coupon_claims/c1_alice');
    await assertFails(getDoc(ref('bob')));
    await assertSucceeds(getDoc(ref('alice')));
    await assertFails(updateDoc(ref('alice'), { status: 'cancelled' }));
    // Od 2026-10-19 kupon označava partner ili admin, ne korisnik.
    await assertFails(updateDoc(ref('alice'), { status: 'redeemed', redeemedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref('alice'), { status: 'claimed' }));
    await assertFails(deleteDoc(ref('alice')));

    await assertSucceeds(claimCoupon('bob', 'c1'));
    await assertSucceeds(updateDoc(doc(as('admin'), 'coupon_claims/c1_bob'), {
      status: 'cancelled', cancelledAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(as('bob'), 'coupon_claims/c1_bob'), {
      status: 'redeemed', redeemedAt: serverTimestamp(),
    }));
  });
});
