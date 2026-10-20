// Testovi pravila za VauVau Moments (trajne objave, lajkovi, komentari).
// Pokretanje (iz rules_test/): npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayRemove,
  arrayUnion,
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

let env;

const [fsHost, fsPort] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-vauvau',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: fsHost,
      port: Number(fsPort),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

const as = (uid) => env.authenticatedContext(uid).firestore();

// Payload the new app writes (kind: 'post').
const post = (uid, extra = {}) => ({
  kind: 'post',
  authorUserId: uid,
  authorName: 'Ime',
  authorPhotoUrl: '',
  dogId: '',
  dogName: '',
  dogBreed: '',
  dogPhotoUrl: '',
  momentPhotoUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/m.jpg',
  mediaType: 'image',
  caption: 'Šetnja na Limanu',
  locationName: 'Limanski park',
  cityId: 'novi_sad',
  likes: [],
  commentsCount: 0,
  createdAt: serverTimestamp(),
  ...extra,
});

// Payload of the old app (no kind / cityId / mediaType) – must keep working.
const legacy = (uid) => ({
  authorUserId: uid,
  authorName: 'Ime',
  dogId: 'rex',
  dogName: 'Reks',
  dogBreed: 'Mešanac',
  dogPhotoUrl: '',
  momentPhotoUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/old.jpg',
  caption: '',
  locationName: 'Novi Sad',
  likes: [],
  commentsCount: 0,
  createdAt: serverTimestamp(),
});

const comment = (uid, extra = {}) => ({
  authorUserId: uid,
  authorName: 'Ime',
  text: 'Divno! 🐾',
  likes: [],
  createdAt: serverTimestamp(),
  ...extra,
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const uid of ['alice', 'bob', 'carol']) {
      await setDoc(doc(db, `users/${uid}`), { role: 'user' });
    }
    await setDoc(doc(db, 'users/admin'), { role: 'admin' });
    await setDoc(doc(db, 'users/mute'), { role: 'user', isSuspended: true });
    // carol blocked bob.
    await setDoc(doc(db, 'users/carol/blocked_users/bob'), { blockedAt: Timestamp.now() });
    await setDoc(doc(db, 'dogs/rex'), { ownerId: 'alice', name: 'Reks' });
    await setDoc(doc(db, 'dogs/luna'), { ownerId: 'bob', name: 'Luna' });
    await setDoc(doc(db, 'moments/p1'), {
      ...post('alice'),
      likes: ['carol'],
      commentsCount: 1,
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'moments/p1/comments/c1'), {
      ...comment('carol'),
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'moments/pc'), { ...post('carol'), createdAt: Timestamp.now() });
    await setDoc(doc(db, 'moments/old1'), { ...legacy('bob'), dogId: 'luna', createdAt: Timestamp.now() });
  });
});

describe('Moments – kreiranje objave', () => {
  test('nova objava i stari oblik (stara verzija aplikacije) prolaze', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'moments/n1'), post('alice')));
    await assertSucceeds(setDoc(doc(as('alice'), 'moments/n2'), post('alice', { dogId: 'rex', dogName: 'Reks' })));
    await assertSucceeds(setDoc(doc(as('alice'), 'moments/n3'), legacy('alice')));
  });

  test('tuđe ime autora, tuđi pas i lažni brojevi padaju', async () => {
    await assertFails(setDoc(doc(as('bob'), 'moments/x1'), post('alice')));
    await assertFails(setDoc(doc(as('alice'), 'moments/x2'), post('alice', { dogId: 'luna' })));
    await assertFails(setDoc(doc(as('alice'), 'moments/x3'), post('alice', { likes: ['bob', 'carol'] })));
    await assertFails(setDoc(doc(as('alice'), 'moments/x4'), post('alice', { commentsCount: 40 })));
    await assertFails(setDoc(doc(as('alice'), 'moments/x5'), post('alice', { createdAt: Timestamp.fromMillis(0) })));
  });

  test('nepoznata polja, pogrešna vrsta, predug opis i bez slike padaju', async () => {
    await assertFails(setDoc(doc(as('alice'), 'moments/y1'), post('alice', { isPinned: true })));
    await assertFails(setDoc(doc(as('alice'), 'moments/y2'), post('alice', { kind: 'story' })));
    await assertFails(setDoc(doc(as('alice'), 'moments/y3'), post('alice', { mediaType: 'gif' })));
    await assertFails(setDoc(doc(as('alice'), 'moments/y4'), post('alice', { caption: 'a'.repeat(2201) })));
    await assertFails(setDoc(doc(as('alice'), 'moments/y5'), post('alice', { momentPhotoUrl: '' })));
  });

  test('video objava (mediaType video) prolazi; bez mediaType = slika', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'moments/v1'), post('alice', { mediaType: 'video' })));
    const { mediaType, ...noType } = post('alice');
    await assertSucceeds(setDoc(doc(as('alice'), 'moments/v2'), noType));
    await assertFails(setDoc(doc(as('alice'), 'moments/v3'), post('alice', { mediaType: 'audio' })));
  });

  test('suspendovan korisnik i neprijavljen ne objavljuju', async () => {
    await assertFails(setDoc(doc(as('mute'), 'moments/z1'), post('mute')));
    await assertFails(
      setDoc(doc(env.unauthenticatedContext().firestore(), 'moments/z2'), post('alice')),
    );
  });

  test('ponovni upis istog id-a ne prepisuje objavu (ni brojače)', async () => {
    await assertFails(setDoc(doc(as('alice'), 'moments/p1'), post('alice')));
    await assertFails(setDoc(doc(as('bob'), 'moments/p1'), post('bob')));
  });
});

describe('Moments – izmena i brisanje', () => {
  test('autor menja samo opis', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'moments/p1'), { caption: 'Novi opis' }));
    await assertFails(updateDoc(doc(as('alice'), 'moments/p1'), { likes: ['a', 'b', 'c'] }));
    await assertFails(updateDoc(doc(as('alice'), 'moments/p1'), { commentsCount: 50 }));
    await assertFails(updateDoc(doc(as('alice'), 'moments/p1'), { momentPhotoUrl: 'https://evil/x.jpg' }));
    await assertFails(updateDoc(doc(as('alice'), 'moments/p1'), { authorUserId: 'bob' }));
  });

  test('drugi ne menjaju tuđu objavu', async () => {
    await assertFails(updateDoc(doc(as('bob'), 'moments/p1'), { caption: 'hakovano' }));
    await assertFails(updateDoc(doc(as('bob'), 'moments/p1'), { kind: 'legacy' }));
  });

  test('brisanje: autor i admin da, drugi ne', async () => {
    await assertFails(deleteDoc(doc(as('bob'), 'moments/p1')));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'moments/p1')));
    await assertSucceeds(deleteDoc(doc(as('admin'), 'moments/pc')));
  });
});

describe('Moments – lajkovi', () => {
  test('svoj lajk i unlajk prolaze', async () => {
    await assertSucceeds(updateDoc(doc(as('bob'), 'moments/p1'), { likes: arrayUnion('bob') }));
    await assertSucceeds(updateDoc(doc(as('bob'), 'moments/p1'), { likes: arrayRemove('bob') }));
    await assertSucceeds(updateDoc(doc(as('alice'), 'moments/p1'), { likes: arrayUnion('alice') }));
  });

  test('dupli lajk, tuđi uid i brisanje tuđih lajkova padaju', async () => {
    await assertFails(updateDoc(doc(as('carol'), 'moments/p1'), { likes: arrayUnion('carol') }));
    await assertFails(updateDoc(doc(as('bob'), 'moments/p1'), { likes: ['carol', 'bob', 'bob'] }));
    await assertFails(updateDoc(doc(as('bob'), 'moments/p1'), { likes: ['carol', 'dave'] }));
    await assertFails(updateDoc(doc(as('bob'), 'moments/p1'), { likes: [] }));
  });
});

describe('Moments – komentari', () => {
  test('komentar + brojač u istom batch-u; odgovor na komentar', async () => {
    const db = as('bob');
    const batch = writeBatch(db);
    batch.set(doc(db, 'moments/p1/comments/k1'), comment('bob'));
    batch.update(doc(db, 'moments/p1'), { commentsCount: increment(1) });
    await assertSucceeds(batch.commit());
    await assertSucceeds(setDoc(doc(db, 'moments/p1/comments/k2'), comment('bob', {
      replyToCommentId: 'c1',
      replyToAuthorName: 'Karolina',
    })));
  });

  test('tuđe ime, prazan/predug tekst, lajkovi i nepoznata polja padaju', async () => {
    await assertFails(setDoc(doc(as('bob'), 'moments/p1/comments/b1'), comment('alice')));
    await assertFails(setDoc(doc(as('bob'), 'moments/p1/comments/b2'), comment('bob', { text: '' })));
    await assertFails(setDoc(doc(as('bob'), 'moments/p1/comments/b3'), comment('bob', { text: 'a'.repeat(2001) })));
    await assertFails(setDoc(doc(as('bob'), 'moments/p1/comments/b4'), comment('bob', { likes: ['x'] })));
    await assertFails(setDoc(doc(as('bob'), 'moments/p1/comments/b5'), comment('bob', { pinned: true })));
    await assertFails(setDoc(doc(as('bob'), 'moments/p1/comments/b6'), comment('bob', { createdAt: Timestamp.fromMillis(0) })));
  });

  test('nema komentara na nepostojećoj objavi, od blokiranog ni suspendovanog', async () => {
    await assertFails(setDoc(doc(as('bob'), 'moments/nema/comments/q1'), comment('bob')));
    // carol je blokirala bob-a.
    await assertFails(setDoc(doc(as('bob'), 'moments/pc/comments/q2'), comment('bob')));
    await assertSucceeds(setDoc(doc(as('alice'), 'moments/pc/comments/q3'), comment('alice')));
    await assertFails(setDoc(doc(as('mute'), 'moments/p1/comments/q4'), comment('mute')));
  });

  test('brisanje komentara: autor komentara, autor objave i admin; drugi ne', async () => {
    await assertFails(deleteDoc(doc(as('bob'), 'moments/p1/comments/c1')));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'moments/p1/comments/c1')));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'moments/p1/comments/c2'), { ...comment('carol'), createdAt: Timestamp.now() });
      await setDoc(doc(ctx.firestore(), 'moments/p1/comments/c3'), { ...comment('carol'), createdAt: Timestamp.now() });
    });
    await assertSucceeds(deleteDoc(doc(as('carol'), 'moments/p1/comments/c2')));
    await assertSucceeds(deleteDoc(doc(as('admin'), 'moments/p1/comments/c3')));
  });

  test('lajk komentara samo svoj; tekst menja samo autor', async () => {
    await assertSucceeds(updateDoc(doc(as('bob'), 'moments/p1/comments/c1'), { likes: arrayUnion('bob') }));
    await assertFails(updateDoc(doc(as('bob'), 'moments/p1/comments/c1'), { likes: ['bob', 'x'] }));
    await assertFails(updateDoc(doc(as('bob'), 'moments/p1/comments/c1'), { text: 'promenjeno' }));
    await assertSucceeds(updateDoc(doc(as('carol'), 'moments/p1/comments/c1'), { text: 'ispravka' }));
    await assertFails(updateDoc(doc(as('carol'), 'moments/p1/comments/c1'), { authorUserId: 'bob' }));
  });
});

describe('Moments – čitanje', () => {
  test('prijavljeni čitaju feed (kind == post) i komentare po stranama', async () => {
    const db = as('bob');
    await assertSucceeds(getDocs(query(
      collection(db, 'moments'),
      where('kind', '==', 'post'),
      orderBy('createdAt', 'desc'),
      limit(10),
    )));
    await assertSucceeds(getDocs(query(
      collection(db, 'moments'),
      where('kind', '==', 'post'),
      where('authorUserId', 'in', ['alice', 'carol']),
      orderBy('createdAt', 'desc'),
      limit(10),
    )));
    await assertSucceeds(getDocs(query(
      collection(db, 'moments/p1/comments'),
      orderBy('createdAt', 'desc'),
      limit(30),
    )));
    await assertSucceeds(getDoc(doc(db, 'moments/old1')));
  });

  test('neprijavljen ne čita', async () => {
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'moments/p1')));
  });

  test('collection group komentara: samo svoji (brisanje naloga)', async () => {
    await assertSucceeds(getDocs(query(
      collectionGroup(as('carol'), 'comments'),
      where('authorUserId', '==', 'carol'),
    )));
    await assertFails(getDocs(query(
      collectionGroup(as('bob'), 'comments'),
      where('authorUserId', '==', 'carol'),
    )));
  });
});
