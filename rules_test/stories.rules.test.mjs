// Testovi pravila za praćenje (follows) i priče (stories) — Firestore + Storage.
// Pokretanje (iz rules_test/): npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';

let env;
let active; // expiresAt of the seeded active stories

const [fsHost, fsPort] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');
const [stHost, stPort] = (
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199'
).split(':');

const hours = (h) => Timestamp.fromMillis(Date.now() + h * 3600e3);
const jpeg = { contentType: 'image/jpeg' };
const image = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-vauvau',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: fsHost,
      port: Number(fsPort),
    },
    storage: {
      rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8'),
      host: stHost,
      port: Number(stPort),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

const story = (audience, expiresAt = active) => ({
  authorUserId: 'alice',
  authorName: 'Alisa',
  audience,
  mediaType: 'image',
  caption: '',
  status: 'published',
  createdAt: Timestamp.now(),
  expiresAt,
});

beforeEach(async () => {
  active = hours(20);
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const uid of ['alice', 'bob', 'carol', 'dave']) {
      await setDoc(doc(db, `users/${uid}`), { role: 'user' });
    }
    await setDoc(doc(db, 'users/admin'), { role: 'admin' });
    // bob → alice (bob is alice's follower); alice → carol.
    await setDoc(doc(db, 'follows/bob_alice'), {
      followerUserId: 'bob', followedUserId: 'alice', createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'follows/alice_carol'), {
      followerUserId: 'alice', followedUserId: 'carol', createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'users/alice/blocked_users/dave'), { blockedAt: Timestamp.now() });
    await setDoc(doc(db, 'stories/sAll'), story('all'));
    await setDoc(doc(db, 'stories/sFollowers'), story('followers'));
    await setDoc(doc(db, 'stories/sFollowing'), story('following'));
    await setDoc(doc(db, 'stories/sExpired'), story('all', hours(-1)));
    await setDoc(doc(db, 'stories/sAll/story_likes/carol'), {
      userId: 'carol', createdAt: Timestamp.now(), expiresAt: hours(20),
    });
    const st = ctx.storage();
    for (const id of ['sAll', 'sFollowers', 'sFollowing', 'sExpired']) {
      await uploadBytes(ref(st, `stories/alice/${id}/media`), image, jpeg);
    }
  });
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const st = (uid) => env.authenticatedContext(uid).storage();

describe('app_config', () => {
  test('prijavljeni čitaju, samo admin piše', async () => {
    await assertSucceeds(getDoc(doc(db('bob'), 'app_config/android')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'app_config/android')));
    await assertFails(setDoc(doc(db('bob'), 'app_config/android'), { minBuild: 99 }));
    await assertSucceeds(setDoc(doc(db('admin'), 'app_config/android'), {
      minBuild: 7, latestBuild: 8,
    }));
  });
});

describe('follows', () => {
  test('praćenje: kreira se jednom, sa ispravnim id-jem', async () => {
    await assertSucceeds(setDoc(doc(db('carol'), 'follows/carol_alice'), {
      followerUserId: 'carol', followedUserId: 'alice', createdAt: serverTimestamp(),
    }));
    // Second write = update → denied (no duplicate, no rewrite).
    await assertFails(setDoc(doc(db('carol'), 'follows/carol_alice'), {
      followerUserId: 'carol', followedUserId: 'alice', createdAt: serverTimestamp(),
    }));
  });

  test('ne može se pratiti sebe, u tuđe ime, ni pod pogrešnim id-jem', async () => {
    await assertFails(setDoc(doc(db('bob'), 'follows/bob_bob'), {
      followerUserId: 'bob', followedUserId: 'bob', createdAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(db('bob'), 'follows/carol_dave'), {
      followerUserId: 'carol', followedUserId: 'dave', createdAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(db('bob'), 'follows/xyz'), {
      followerUserId: 'bob', followedUserId: 'carol', createdAt: serverTimestamp(),
    }));
  });

  test('blokirani ne može da zaprati onoga ko ga je blokirao', async () => {
    await assertFails(setDoc(doc(db('dave'), 'follows/dave_alice'), {
      followerUserId: 'dave', followedUserId: 'alice', createdAt: serverTimestamp(),
    }));
  });

  test('ne može se zapratiti neko koga sam blokirao', async () => {
    await assertFails(setDoc(doc(db('alice'), 'follows/alice_dave'), {
      followerUserId: 'alice', followedUserId: 'dave', createdAt: serverTimestamp(),
    }));
  });

  test('liste pratilaca vide samo učesnici', async () => {
    await assertSucceeds(getDocs(query(collection(db('alice'), 'follows'),
      where('followedUserId', '==', 'alice'))));
    await assertSucceeds(getDocs(query(collection(db('bob'), 'follows'),
      where('followerUserId', '==', 'bob'))));
    await assertFails(getDocs(query(collection(db('carol'), 'follows'),
      where('followedUserId', '==', 'alice'))));
    await assertSucceeds(getDoc(doc(db('carol'), 'follows/carol_alice')));
    await assertFails(getDoc(doc(db('carol'), 'follows/bob_alice')));
  });

  test('obaveštenje sa determinističkim id-jem se ne duplira pri ponovnom slanju', async () => {
    const n = {
      type: 'FOLLOW',
      fromUserId: 'carol',
      toUserId: 'alice',
      recipientId: 'alice',
      title: 'Novi pratilac',
      body: 'Karolina vas sada prati.',
      isRead: false,
      createdAt: serverTimestamp(),
    };
    await assertSucceeds(setDoc(doc(db('carol'), 'notifications/follow_carol_alice'), n));
    await assertFails(setDoc(doc(db('carol'), 'notifications/follow_carol_alice'), n));
    // Blocked sender cannot notify at all.
    await assertFails(setDoc(doc(db('dave'), 'notifications/follow_dave_alice'),
      { ...n, fromUserId: 'dave' }));
  });

  test('otpraćivanje i uklanjanje pratioca', async () => {
    await assertFails(deleteDoc(doc(db('carol'), 'follows/bob_alice')));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'follows/bob_alice')));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'follows/alice_carol')));
  });
});

describe('stories: objavljivanje', () => {
  const valid = (id, overrides = {}) => ({
    authorUserId: 'alice',
    authorName: 'Alisa',
    authorPhotoUrl: '',
    dogId: 'd1',
    dogName: 'Leo',
    dogPhotoUrl: '',
    mediaType: 'image',
    mediaPath: `stories/alice/${id}/media`,
    caption: 'Šetnja',
    audience: 'followers',
    status: 'published',
    createdAt: serverTimestamp(),
    expiresAt: hours(24),
    ...overrides,
  });

  test('autor objavljuje ispravnu priču', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'stories/n1'), valid('n1')));
  });

  test('odbija tuđe ime, tuđu putanju, dug rok, nepoznatu publiku i višak polja', async () => {
    await assertFails(setDoc(doc(db('bob'), 'stories/n2'), valid('n2')));
    await assertFails(setDoc(doc(db('alice'), 'stories/n3'),
      valid('n3', { mediaPath: 'stories/bob/x/media' })));
    await assertFails(setDoc(doc(db('alice'), 'stories/n4'),
      valid('n4', { expiresAt: hours(48) })));
    await assertFails(setDoc(doc(db('alice'), 'stories/n5'),
      valid('n5', { audience: 'friends' })));
    await assertFails(setDoc(doc(db('alice'), 'stories/n6'),
      valid('n6', { latitude: 45.2 })));
  });

  test('priča se ne menja; briše je samo autor', async () => {
    await assertFails(updateDoc(doc(db('alice'), 'stories/sAll'), { caption: 'x' }));
    await assertFails(deleteDoc(doc(db('bob'), 'stories/sAll')));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'stories/sAll')));
  });
});

describe('stories: publika', () => {
  test('Svi korisnici: svako osim blokiranog', async () => {
    await assertSucceeds(getDoc(doc(db('carol'), 'stories/sAll')));
    await assertFails(getDoc(doc(db('dave'), 'stories/sAll')));
    await assertFails(getDocs(query(collection(db('dave'), 'stories'),
      where('authorUserId', '==', 'alice'), where('audience', '==', 'all'))));
  });

  test('Moji pratioci: samo ko prati autora', async () => {
    await assertSucceeds(getDoc(doc(db('bob'), 'stories/sFollowers')));
    await assertFails(getDoc(doc(db('carol'), 'stories/sFollowers')));
    await assertSucceeds(getDocs(query(collection(db('bob'), 'stories'),
      where('authorUserId', 'in', ['alice']), where('audience', '==', 'followers'),
      where('expiresAt', '>', Timestamp.now()))));
    await assertFails(getDocs(query(collection(db('carol'), 'stories'),
      where('authorUserId', '==', 'alice'), where('audience', '==', 'followers'))));
  });

  test('Osobe koje ja pratim: samo oni koje autor prati', async () => {
    await assertSucceeds(getDoc(doc(db('carol'), 'stories/sFollowing')));
    await assertFails(getDoc(doc(db('bob'), 'stories/sFollowing')));
    await assertFails(getDocs(query(collection(db('bob'), 'stories'),
      where('authorUserId', '==', 'alice'), where('audience', '==', 'following'))));
  });

  test('bez filtera publike tuđe priče se ne mogu listati', async () => {
    await assertFails(getDocs(query(collection(db('bob'), 'stories'),
      where('authorUserId', '==', 'alice'))));
    await assertSucceeds(getDocs(query(collection(db('alice'), 'stories'),
      where('authorUserId', '==', 'alice'))));
  });

  test('istekla priča nije dostupna (osim autoru)', async () => {
    await assertFails(getDoc(doc(db('carol'), 'stories/sExpired')));
    await assertSucceeds(getDoc(doc(db('alice'), 'stories/sExpired')));
  });

  test('pogađanje id-ja ne daje pristup', async () => {
    await assertFails(getDoc(doc(db('carol'), 'stories/sFollowers')));
    await assertFails(getDoc(doc(db('dave'), 'stories/sFollowing')));
  });
});

describe('stories: sviđanja i pregledi', () => {
  const like = (uid) => ({
    userId: uid, createdAt: serverTimestamp(), expiresAt: hours(20),
  });

  test('gledalac lajkuje jednom; duplikat se odbija', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'stories/sLike'), story('followers'));
    });
    const sLike = active;
    const data = { userId: 'bob', createdAt: serverTimestamp(), expiresAt: sLike };
    await assertSucceeds(setDoc(doc(db('bob'), 'stories/sLike/story_likes/bob'), data));
    await assertFails(setDoc(doc(db('bob'), 'stories/sLike/story_likes/bob'), data));
  });

  test('lajk mora da odgovara priči, gledaocu i publici', async () => {
    const exp = active;
    // carol does not follow alice.
    await assertFails(setDoc(doc(db('carol'), 'stories/sFollowers/story_likes/carol'),
      { userId: 'carol', createdAt: serverTimestamp(), expiresAt: exp }));
    // In someone else's name.
    await assertFails(setDoc(doc(db('bob'), 'stories/sFollowers/story_likes/carol'),
      { userId: 'carol', createdAt: serverTimestamp(), expiresAt: exp }));
    // Author cannot like own story.
    await assertFails(setDoc(doc(db('alice'), 'stories/sFollowers/story_likes/alice'),
      { userId: 'alice', createdAt: serverTimestamp(), expiresAt: exp }));
    // Expired story.
    await assertFails(setDoc(doc(db('bob'), 'stories/sExpired/story_likes/bob'), like('bob')));
  });

  test('listu sviđanja i pregleda vidi samo autor', async () => {
    await assertSucceeds(getDocs(collection(db('alice'), 'stories/sAll/story_likes')));
    await assertFails(getDocs(collection(db('bob'), 'stories/sAll/story_likes')));
    await assertSucceeds(getDoc(doc(db('carol'), 'stories/sAll/story_likes/carol')));
    await assertFails(getDoc(doc(db('bob'), 'stories/sAll/story_likes/carol')));
    await assertFails(getDocs(collection(db('bob'), 'stories/sAll/story_views')));
  });

  test('pregled beleži sam gledalac, jednom', async () => {
    const exp = active;
    const view = { viewerUserId: 'carol', viewedAt: serverTimestamp(), expiresAt: exp };
    await assertSucceeds(setDoc(doc(db('carol'), 'stories/sAll/story_views/carol'), view));
    await assertFails(setDoc(doc(db('carol'), 'stories/sAll/story_views/carol'), view));
    await assertFails(setDoc(doc(db('dave'), 'stories/sAll/story_views/dave'),
      { viewerUserId: 'dave', viewedAt: serverTimestamp(), expiresAt: exp }));
    await assertSucceeds(deleteDoc(doc(db('carol'), 'stories/sAll/story_likes/carol')));
  });
});

describe('storage: mediji priča', () => {
  test('autor i dozvoljena publika čitaju; ostali ne', async () => {
    await assertSucceeds(getBytes(ref(st('alice'), 'stories/alice/sFollowers/media')));
    await assertSucceeds(getBytes(ref(st('bob'), 'stories/alice/sFollowers/media')));
    await assertFails(getBytes(ref(st('carol'), 'stories/alice/sFollowers/media')));
    await assertSucceeds(getBytes(ref(st('carol'), 'stories/alice/sFollowing/media')));
    await assertFails(getBytes(ref(st('bob'), 'stories/alice/sFollowing/media')));
  });

  test('blokirani, istekla priča i neprijavljeni nemaju pristup', async () => {
    await assertFails(getBytes(ref(st('dave'), 'stories/alice/sAll/media')));
    await assertFails(getBytes(ref(st('carol'), 'stories/alice/sExpired/media')));
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(),
      'stories/alice/sAll/media')));
  });

  test('upload samo u svoj folder, bez prepisivanja', async () => {
    await assertSucceeds(uploadBytes(ref(st('bob'), 'stories/bob/new/media'), image, jpeg));
    await assertFails(uploadBytes(ref(st('bob'), 'stories/alice/new/media'), image, jpeg));
    await assertFails(uploadBytes(ref(st('alice'), 'stories/alice/sAll/media'), image, jpeg));
  });
});
