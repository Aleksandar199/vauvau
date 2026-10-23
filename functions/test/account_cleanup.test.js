// Needs the Firestore emulator:
//   firebase emulators:exec --only firestore --project demo-vauvau-fn "node --test test/account_cleanup.test.js"
process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
const { beforeEach, describe, test } = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');

admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-vauvau-fn' });
const db = admin.firestore();
const { cleanupUserData } = require('../account');
const { awardWalk } = require('../rewards');
const { naturalRoute, walkDoc } = require('./route_fixtures');

async function clear() {
  const url = `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${
    process.env.GCLOUD_PROJECT || 'demo-vauvau-fn'
  }/databases/(default)/documents`;
  assert.ok((await fetch(url, { method: 'DELETE' })).ok);
}

const exists = async (path) => (await db.doc(path).get()).exists;

describe('cleanupUserData', () => {
  beforeEach(clear);

  test('removes what belongs to the user and keeps everyone else', async () => {
    await db.doc('users/ana').set({ name: 'Ana' });
    await db.doc('users/ana/private/account').set({ email: 'a@b.c' });
    await db.doc('users/ana/rewards/summary').set({ points: 5 });
    await db.doc('users/bob').set({ name: 'Bob' });
    await db.doc('dogs/d1').set({ ownerId: 'ana' });
    await db.doc('dogs/d1/likes/bob').set({ type: 'like' });
    await db.doc('dogs/d2').set({ ownerId: 'bob' });
    await db.doc('moments/m1').set({ authorUserId: 'ana' });
    await db.doc('moments/m1/comments/c1').set({ authorUserId: 'bob' });
    await db.doc('moments/m2').set({ authorUserId: 'bob' });
    await db.doc('moments/m2/comments/c2').set({ authorUserId: 'ana' });
    await db.doc('moments/m2/comments/c3').set({ authorUserId: 'bob' });
    await db.doc('follows/ana_bob').set({ followerUserId: 'ana', followedUserId: 'bob' });
    await db.doc('follows/bob_ana').set({ followerUserId: 'bob', followedUserId: 'ana' });
    await db.doc('matches/ana_bob').set({ userIds: ['ana', 'bob'] });
    await db.doc('chats/ana_bob').set({
      participantIds: ['ana', 'bob'],
      unreadByUser: { ana: 0, bob: 2 },
    });
    await db.doc('chats/ana_bob/messages/x').set({ senderId: 'ana', text: 'hi' });
    await db.doc('chats/ana_bob/messages/y').set({ senderId: 'bob', text: 'yo' });
    await db.doc('breed_groups/g1').set({ memberIds: ['ana', 'bob'], memberCount: 2 });
    await db.doc('breed_groups/g1/members/ana').set({ muted: true });
    await db.doc('events/e1').set({ organizerUserId: 'bob', participantUserIds: ['ana', 'bob'] });

    await cleanupUserData(db, null, 'ana');

    for (const gone of [
      'users/ana',
      'users/ana/private/account',
      'users/ana/rewards/summary',
      'dogs/d1',
      'dogs/d1/likes/bob',
      'moments/m1',
      'moments/m1/comments/c1',
      'moments/m2/comments/c2',
      'follows/ana_bob',
      'follows/bob_ana',
      'matches/ana_bob',
      'chats/ana_bob/messages/x',
      'breed_groups/g1/members/ana',
    ]) {
      assert.equal(await exists(gone), false, `${gone} should be gone`);
    }
    for (const kept of [
      'users/bob',
      'dogs/d2',
      'moments/m2',
      'moments/m2/comments/c3',
      'chats/ana_bob',
      'chats/ana_bob/messages/y',
      'events/e1',
    ]) {
      assert.equal(await exists(kept), true, `${kept} should stay`);
    }
    const chat = (await db.doc('chats/ana_bob').get()).data();
    assert.deepEqual(chat.participantIds, ['bob']);
    assert.deepEqual(chat.unreadByUser, { bob: 2 });
    const group = (await db.doc('breed_groups/g1').get()).data();
    assert.deepEqual(group.memberIds, ['bob']);
    assert.equal(group.memberCount, 1);
    const event = (await db.doc('events/e1').get()).data();
    assert.deepEqual(event.participantUserIds, ['bob']);
  });

  test('is safe to run twice and ignores an empty uid', async () => {
    await db.doc('dogs/d1').set({ ownerId: 'ana' });
    await cleanupUserData(db, null, 'ana');
    await cleanupUserData(db, null, 'ana');
    assert.deepEqual(await cleanupUserData(db, null, ''), { skipped: true });
    assert.equal(await exists('dogs/d1'), false);
  });
});

describe('reward kill switch (app_config/rewards)', () => {
  beforeEach(clear);

  const award = (uid, walkId, route) =>
    awardWalk(db, {
      uid,
      walkId,
      walk: walkDoc({ route }),
      createMs: route.endMs + 2000,
    });

  test('enabled:false saves the walk without paying', async () => {
    await db.doc('app_config/rewards').set({ enabled: false });
    const { data } = await award('ana', 'w1', naturalRoute({ meters: 2600, seed: 3 }));
    assert.equal(data.status, 'ignored');
    assert.equal(data.reason, 'rewards_disabled');
    assert.equal(await exists('users/ana/reward_ledger/walk_w1'), false);
  });

  test('admin can change points per km without an app update', async () => {
    await db.doc('app_config/rewards').set({ pointsPerKm: 10 });
    const { data } = await award('ana', 'w2', naturalRoute({ meters: 2600, seed: 4 }));
    assert.equal(data.status, 'rewarded');
    assert.equal(data.points, 20);
  });
});
