// Needs the Firestore emulator:
//   firebase emulators:exec --only firestore --project demo-vauvau-fn "node --test test/rewards_award.test.js"
process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
const { before, beforeEach, describe, test } = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');

admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-vauvau-fn' });
const db = admin.firestore();
const { awardWalk, belgradeDayKey, belgradeWeekKey } = require('../rewards');
const { naturalRoute, walkDoc, START } = require('./route_fixtures');

async function clear() {
  const url = `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${
    process.env.GCLOUD_PROJECT || 'demo-vauvau-fn'
  }/databases/(default)/documents`;
  const response = await fetch(url, { method: 'DELETE' });
  assert.ok(response.ok);
}

const get = async (path) => (await db.doc(path).get()).data();

/** Process a walk like the trigger does. */
function award(uid, walkId, route, extra = {}) {
  const walk = walkDoc({ route, ...extra });
  return awardWalk(db, {
    uid,
    walkId,
    walk,
    createMs: route.endMs + 2000,
  });
}

describe('awardWalk (Firestore emulator)', () => {
  beforeEach(clear);

  test('pays a walk: ledger, balance, day/week progress, result', async () => {
    const route = naturalRoute({ meters: 2600, seed: 11 });
    const { data } = await award('ana', 'w1', route);
    assert.equal(data.status, 'rewarded');
    assert.equal(data.points, 10);
    assert.equal(data.xpBefore, 0);

    const dayKey = belgradeDayKey(route.endMs);
    const weekKey = belgradeWeekKey(route.endMs);
    assert.deepEqual(
      [(await get('users/ana/rewards/summary')).xp, (await get('users/ana/rewards/summary')).points],
      [10, 10],
    );
    const ledger = await get('users/ana/reward_ledger/walk_w1');
    assert.equal(ledger.type, 'walk');
    assert.equal(ledger.points, 10);
    assert.equal(ledger.dayKey, dayKey);
    const day = await get(`users/ana/rewards/d${dayKey}`);
    assert.equal(day.walks, 1);
    assert.equal(day.walkPoints, 10);
    assert.ok(day.meters >= 2500);
    assert.equal((await get(`users/ana/rewards/w${weekKey}`)).walks, 1);
    assert.equal((await get('users/ana/reward_results/w1')).status, 'rewarded');
  });

  test('is idempotent: the same walk never pays twice', async () => {
    const route = naturalRoute({ meters: 2600, seed: 12 });
    await award('ana', 'w1', route);
    const again = await award('ana', 'w1', route);
    assert.equal(again.duplicate, true);
    assert.equal((await get('users/ana/rewards/summary')).points, 10);
  });

  test('two parallel runs for the same walk pay once', async () => {
    const route = naturalRoute({ meters: 2600, seed: 13 });
    await Promise.all([award('ana', 'w1', route), award('ana', 'w1', route)]);
    assert.equal((await get('users/ana/rewards/summary')).points, 10);
  });

  test('daily limit of 30 points across walks', async () => {
    const a = naturalRoute({ meters: 4300, seed: 21, startMs: START });
    const b = naturalRoute({ meters: 4200, seed: 22, startMs: a.endMs + 600000, lat: 45.28 });
    const c = naturalRoute({ meters: 3100, seed: 23, startMs: b.endMs + 600000, lat: 45.31 });
    assert.equal((await award('ana', 'a', a)).data.points, 20);
    const second = await award('ana', 'b', b);
    assert.equal(second.data.points, 10);
    assert.equal(second.data.capped, true);
    assert.equal((await award('ana', 'c', c)).data.points, 0);
    assert.equal((await get('users/ana/rewards/summary')).points, 30);
    // The km still count toward challenges.
    const day = await get(`users/ana/rewards/d${belgradeDayKey(a.endMs)}`);
    assert.equal(day.walks, 3);
  });

  test('rejected walks pay nothing but leave a reason', async () => {
    const route = naturalRoute({ meters: 2600, seed: 31 });
    const mock = await award('ana', 'm', route, { flags: { mock: true } });
    assert.equal(mock.data.reason, 'mock_location');
    const lying = await award('ana', 'l', naturalRoute({ meters: 2600, seed: 32 }), {
      meters: 2600,
      durationSeconds: 99999,
    });
    assert.equal(lying.data.status, 'rejected');
    assert.equal(await get('users/ana/rewards/summary'), undefined);
    assert.equal((await get('users/ana/reward_results/m')).status, 'rejected');
  });

  test('a replayed route (also from another account) is rejected', async () => {
    const route = naturalRoute({ meters: 2600, seed: 41 });
    assert.equal((await award('ana', 'w1', route)).data.status, 'rewarded');
    const copy = await award('bob', 'w9', route);
    assert.equal(copy.data.status, 'rejected');
    assert.equal(copy.data.reason, 'duplicate_route');
    assert.equal(await get('users/bob/rewards/summary'), undefined);
  });

  test('a walk an older app already paid is not paid again', async () => {
    const route = naturalRoute({ meters: 2600, seed: 51 });
    const dayKey = belgradeDayKey(route.endMs);
    await db.doc('users/ana/reward_ledger/walk_w1').set({
      type: 'walk', walkId: 'w1', km: 2, dayKey, weekKey: belgradeWeekKey(route.endMs),
      xp: 10, points: 10, reason: 'Šetnja: 2 km',
    });
    await db.doc('users/ana/rewards/summary').set({ xp: 10, points: 10, lastEntryId: 'walk_w1' });
    const { data } = await award('ana', 'w1', route);
    assert.equal(data.status, 'rewarded');
    assert.equal(data.points, 10);
    assert.equal((await get('users/ana/rewards/summary')).points, 10);
  });

  describe('challenges', () => {
    beforeEach(async () => {
      await db.doc('reward_challenges/daily_2km').set({
        title: '2 km danas', period: 'daily', metric: 'distance', target: 2,
        rewardXp: 10, rewardPoints: 10, isActive: true,
      });
      await db.doc('reward_challenges/weekly_3walks').set({
        title: '3 šetnje', period: 'weekly', metric: 'walks', target: 3,
        rewardXp: 20, rewardPoints: 20, isActive: true,
      });
      await db.doc('reward_challenges/off').set({
        title: 'Neaktivan', period: 'daily', metric: 'distance', target: 0.1,
        rewardXp: 99, rewardPoints: 99, isActive: false,
      });
    });

    test('daily challenge is paid once, when the target is met', async () => {
      const a = naturalRoute({ meters: 1200, seed: 61, startMs: START });
      const first = await award('ana', 'a', a);
      assert.deepEqual(first.challenges, []);
      const b = naturalRoute({ meters: 1100, seed: 62, startMs: a.endMs + 600000, lat: 45.28 });
      const second = await award('ana', 'b', b);
      assert.deepEqual(second.challenges.map((c) => c.id), ['daily_2km']);
      // 5 + 5 from km, +10 bonus; the inactive one never pays.
      assert.equal((await get('users/ana/rewards/summary')).points, 20);
      const result = await get('users/ana/reward_results/b');
      assert.equal(result.challenges[0].points, 10);
      const c = naturalRoute({ meters: 1100, seed: 63, startMs: b.endMs + 600000, lat: 45.31 });
      // The third walk of the week completes the weekly goal – the daily
      // challenge is not paid a second time.
      const third = await award('ana', 'c', c);
      assert.deepEqual(third.challenges.map((x) => x.id), ['weekly_3walks']);
      // 5+5+5 km, +10 daily, +20 weekly.
      assert.equal((await get('users/ana/rewards/summary')).points, 45);
    });

    test('weekly goal: three walks of at least 1 km', async () => {
      let start = START;
      let paid = [];
      for (let i = 0; i < 3; i++) {
        const r = naturalRoute({ meters: 1100, seed: 70 + i, startMs: start, lat: 45.2 + i * 0.03 });
        start = r.endMs + 600000;
        paid = (await award('ana', `w${i}`, r)).challenges;
      }
      assert.ok(paid.some((c) => c.id === 'weekly_3walks'));
      assert.equal((await get('users/ana/reward_ledger/ch_weekly_3walks_' + belgradeWeekKey(START))).points, 20);
    });
  });
});
