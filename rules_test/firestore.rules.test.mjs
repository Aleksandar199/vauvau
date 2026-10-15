// Testovi Firestore pravila nad emulatorom.
// Pokretanje (iz rules_test/): npm test  → firebase emulators:exec + node --test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayRemove,
  Timestamp,
  arrayUnion,
  collection,
  collectionGroup,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  increment,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

let env;

const [emuHost, emuPort] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-vauvau',
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
    for (const uid of ['alice', 'bob', 'carol']) {
      await setDoc(doc(db, `users/${uid}`), { role: 'user' });
    }
    await setDoc(doc(db, 'chats/alice_bob'), {
      participantIds: ['alice', 'bob'],
      lastMessage: '',
      unreadByUser: { alice: 0, bob: 0 },
    });
    await setDoc(doc(db, 'chats/alice_bob/messages/m1'), {
      senderId: 'alice',
      text: 'Ćao',
    });
    await setDoc(doc(db, 'events/e1'), {
      title: 'Šetnja',
      organizerUserId: 'alice',
      participantUserIds: ['alice'],
      lastMessage: '',
    });
    await setDoc(doc(db, 'breed_groups/g1'), {
      title: 'Labradori',
      description: 'Opis',
      memberIds: ['alice'],
      memberCount: 1,
      isApproved: false,
      createdBy: 'alice',
      lastMessage: '',
    });
    await setDoc(doc(db, 'breed_groups/seed'), {
      title: 'Seed',
      description: 'Opis',
      imageUrl: '',
      memberIds: [],
      memberCount: 120,
      isApproved: true,
      createdBy: '',
      sortOrder: 1,
    });
    await setDoc(doc(db, 'dogs/rex'), { ownerId: 'bob', name: 'Rex', likesCount: 3 });
    await setDoc(doc(db, 'users/bob/private/account'), { email: 'bob@example.com' });
    await setDoc(doc(db, 'lost_dogs/l1'), {
      uploaderUserId: 'carol',
      dogName: 'Žuća',
      comments: [{ id: 'c1', authorUserId: 'bob', authorName: 'Bob', text: 'Video sam je', likes: [] }],
      commentsCount: 1,
      commentLikes: { c1: ['bob'] },
    });
    await setDoc(doc(db, 'moments/mo1'), { authorUserId: 'carol', likes: ['bob'], commentsCount: 2 });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();

// ---------------------------------------------------------------- 1. chats
describe('1. chats', () => {
  test('učesnik pravi čet sa sortiranim id-jem', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'chats/alice_carol'), {
        participantIds: ['carol', 'alice'],
      }),
    );
  });

  test('create: pozivalac nije učesnik', async () => {
    await assertFails(
      setDoc(doc(as('carol'), 'chats/alice_dave'), {
        participantIds: ['alice', 'dave'],
      }),
    );
  });

  test('create: nesortiran id, 3 učesnika ili isti uid dvaput', async () => {
    const db = as('alice');
    await assertFails(setDoc(doc(db, 'chats/carol_alice'), { participantIds: ['alice', 'carol'] }));
    await assertFails(
      setDoc(doc(db, 'chats/alice_carol'), { participantIds: ['alice', 'carol', 'bob'] }),
    );
    await assertFails(setDoc(doc(db, 'chats/alice_alice'), { participantIds: ['alice', 'alice'] }));
  });

  test('update: učesnik menja lastMessage i unread, i set-merge sa obrnutim redosledom', async () => {
    const db = as('alice');
    await assertSucceeds(
      setDoc(
        doc(db, 'chats/alice_bob'),
        { lastMessage: 'hej', unreadByUser: { alice: 0, bob: increment(1) } },
        { merge: true },
      ),
    );
    await assertSucceeds(
      setDoc(doc(db, 'chats/alice_bob'), { participantIds: ['bob', 'alice'] }, { merge: true }),
    );
  });

  test('update: učesnik napušta čet (brisanje naloga)', async () => {
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'chats/alice_bob'), {
        participantIds: ['bob'],
        unreadByUser: { bob: 0 },
      }),
    );
  });

  test('update: tuđinac ne može da se doda u čet i da čita poruke', async () => {
    const db = as('carol');
    await assertFails(
      updateDoc(doc(db, 'chats/alice_bob'), { participantIds: arrayUnion('carol') }),
    );
    await assertFails(
      updateDoc(doc(db, 'chats/alice_bob'), { participantIds: ['alice', 'bob', 'carol'] }),
    );
    await assertFails(getDoc(doc(db, 'chats/alice_bob/messages/m1')));
  });

  test('update: učesnik ne može da doda ili zameni drugog korisnika', async () => {
    const db = as('alice');
    await assertFails(
      updateDoc(doc(db, 'chats/alice_bob'), { participantIds: arrayUnion('carol') }),
    );
    await assertFails(
      updateDoc(doc(db, 'chats/alice_bob'), { participantIds: ['alice', 'carol'] }),
    );
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { participantIds: ['alice'] }));
  });
});

// ------------------------------------------------------ 2. events / groups
describe('2. events', () => {
  test('create: organizator = pozivalac, jedini učesnik', async () => {
    await assertSucceeds(
      setDoc(doc(as('bob'), 'events/e2'), {
        title: 'Nova',
        organizerUserId: 'bob',
        participantUserIds: ['bob'],
        createdAt: serverTimestamp(),
      }),
    );
  });

  test('create: tuđi organizator, dodatni učesnici ili isApproved: true', async () => {
    const db = as('bob');
    await assertFails(
      setDoc(doc(db, 'events/e2'), { organizerUserId: 'alice', participantUserIds: ['bob'] }),
    );
    await assertFails(
      setDoc(doc(db, 'events/e2'), {
        organizerUserId: 'bob',
        participantUserIds: ['bob', 'carol'],
      }),
    );
    await assertFails(
      setDoc(doc(db, 'events/e2'), {
        organizerUserId: 'bob',
        participantUserIds: ['bob'],
        isApproved: true,
      }),
    );
  });

  test('create: admin sme isApproved: true (seed)', async () => {
    await assertSucceeds(
      setDoc(doc(as('admin'), 'events/seed'), {
        organizerUserId: 'seed-user',
        participantUserIds: ['x', 'y'],
        isApproved: true,
      }),
    );
  });

  test('update: korisnik se pridružuje, šalje lastMessage i izlazi', async () => {
    const db = as('bob');
    await assertSucceeds(
      updateDoc(doc(db, 'events/e1'), { participantUserIds: ['alice', 'bob'] }),
    );
    await assertSucceeds(
      setDoc(
        doc(db, 'events/e1'),
        { lastMessage: 'Stižem', lastMessageAt: serverTimestamp() },
        { merge: true },
      ),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'events/e1'), { participantUserIds: arrayRemove('bob') }),
    );
  });

  test('update: ne-organizator ne menja naslov, tuđe članstvo ni lastMessage bez članstva', async () => {
    const db = as('bob');
    await assertFails(updateDoc(doc(db, 'events/e1'), { title: 'Hack' }));
    await assertFails(
      updateDoc(doc(db, 'events/e1'), { participantUserIds: ['alice', 'carol'] }),
    );
    await assertFails(
      updateDoc(doc(db, 'events/e1'), { participantUserIds: ['alice', 'bob', 'carol'] }),
    );
    await assertFails(updateDoc(doc(db, 'events/e1'), { participantUserIds: [] }));
    await assertFails(updateDoc(doc(db, 'events/e1'), { lastMessage: 'spam' }));
  });

  test('update: organizator menja događaj, ali ne isApproved; admin sme', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'events/e1'), { title: 'Nova šetnja' }));
    await assertFails(updateDoc(doc(as('alice'), 'events/e1'), { isApproved: true }));
    await assertFails(updateDoc(doc(as('alice'), 'events/e1'), { organizerUserId: 'bob' }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'events/e1'), { isApproved: true }));
  });
});

describe('2. breed_groups', () => {
  test('create: korisnik pravi grupu na čekanju', async () => {
    await assertSucceeds(
      setDoc(doc(as('bob'), 'breed_groups/g2'), {
        title: 'Pudle',
        description: 'Opis',
        memberIds: ['bob'],
        memberCount: 1,
        isApproved: false,
        createdBy: 'bob',
      }),
    );
  });

  test('create: korisnik ne sme odobrenu grupu ni seed (createdBy prazan)', async () => {
    const base = { title: 'X', description: 'Y', memberIds: ['bob'], memberCount: 1 };
    await assertFails(
      setDoc(doc(as('bob'), 'breed_groups/g2'), { ...base, isApproved: true, createdBy: 'bob' }),
    );
    await assertFails(
      setDoc(doc(as('bob'), 'breed_groups/g2'), {
        ...base,
        memberIds: [],
        isApproved: true,
        createdBy: '',
      }),
    );
    await assertSucceeds(
      setDoc(doc(as('admin'), 'breed_groups/g2'), {
        ...base,
        memberIds: [],
        isApproved: true,
        createdBy: '',
      }),
    );
  });

  test('update: pridruživanje (memberCount +1), lastMessage, izlazak (-1)', async () => {
    const db = as('bob');
    await assertSucceeds(
      updateDoc(doc(db, 'breed_groups/g1'), { memberIds: ['alice', 'bob'], memberCount: 2 }),
    );
    await assertSucceeds(
      setDoc(
        doc(db, 'breed_groups/g1'),
        {
          lastMessage: 'Zdravo',
          lastMessageAt: serverTimestamp(),
          lastMessageSenderId: 'bob',
        },
        { merge: true },
      ),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'breed_groups/g1'), {
        memberIds: arrayRemove('bob'),
        memberCount: increment(-1),
      }),
    );
  });

  test('update: pridruživanje seed grupi sa lažnim memberCount', async () => {
    await assertSucceeds(
      updateDoc(doc(as('bob'), 'breed_groups/seed'), { memberIds: ['bob'], memberCount: 121 }),
    );
  });

  test('update: pogrešan brojač, tuđi uid, naslov, lastMessageSenderId', async () => {
    const db = as('bob');
    await assertFails(
      updateDoc(doc(db, 'breed_groups/g1'), { memberIds: ['alice', 'bob'], memberCount: 5 }),
    );
    await assertFails(
      updateDoc(doc(db, 'breed_groups/g1'), { memberIds: ['alice', 'bob'] }),
    );
    await assertFails(
      updateDoc(doc(db, 'breed_groups/g1'), { memberIds: ['alice', 'carol'], memberCount: 2 }),
    );
    await assertFails(updateDoc(doc(db, 'breed_groups/g1'), { memberCount: 1000 }));
    await assertFails(updateDoc(doc(db, 'breed_groups/g1'), { title: 'Hack' }));
    await assertFails(updateDoc(doc(db, 'breed_groups/seed'), { isApproved: false }));
    // Nečlan ne piše lastMessage; član ne lažira lastMessageSenderId.
    await assertFails(updateDoc(doc(as('carol'), 'breed_groups/g1'), { lastMessage: 'spam' }));
    await assertSucceeds(
      updateDoc(doc(db, 'breed_groups/g1'), { memberIds: ['alice', 'bob'], memberCount: 2 }),
    );
    await assertFails(
      updateDoc(doc(db, 'breed_groups/g1'), {
        lastMessage: 'x',
        lastMessageSenderId: 'alice',
      }),
    );
  });

  test('update: kreator menja grupu ali ne odobrava sebe; admin odobrava', async () => {
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'breed_groups/g1'), { description: 'Novi opis' }),
    );
    await assertFails(updateDoc(doc(as('alice'), 'breed_groups/g1'), { isApproved: true }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'breed_groups/g1'), { isApproved: true }));
  });

  test('seed patch bez promena (ensureSeeded) prolazi, sa promenom pada', async () => {
    const unchanged = {
      title: 'Seed',
      description: 'Opis',
      imageUrl: '',
      isApproved: true,
      sortOrder: 1,
      createdBy: '',
      memberCount: 120,
      memberIds: [],
    };
    await assertSucceeds(
      setDoc(doc(as('bob'), 'breed_groups/seed'), unchanged, { merge: true }),
    );
    await assertFails(
      setDoc(doc(as('bob'), 'breed_groups/seed'), { ...unchanged, title: 'Novo' }, { merge: true }),
    );
  });
});

// ------------------------------------------------- 3. notifications / fcmInbox
describe('3. notifications i fcmInbox', () => {
  const payload = (from) => ({
    fromUserId: from,
    toUserId: 'bob',
    type: 'like',
    title: 'Novi lajk',
    body: 'Alice je lajkovala Rexa',
    isRead: false,
    createdAt: serverTimestamp(),
  });

  test('blokirani pošiljalac, predugačak tekst, isRead, lažno vreme, drugi primalac', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users/bob/blocked_users/alice'), { blockedAt: 1 }),
    );
    const db = as('alice');
    await assertFails(setDoc(doc(db, 'notifications/n1'), payload('alice')));
    await assertFails(setDoc(doc(db, 'users/bob/fcmInbox/f1'), payload('alice')));
    const db2 = as('carol');
    await assertFails(
      setDoc(doc(db2, 'notifications/n2'), { ...payload('carol'), body: 'x'.repeat(1001) }),
    );
    await assertFails(setDoc(doc(db2, 'notifications/n3'), { ...payload('carol'), isRead: true }));
    await assertFails(
      setDoc(doc(db2, 'notifications/n4'), {
        ...payload('carol'),
        createdAt: Timestamp.fromDate(new Date('2099-01-01')),
      }),
    );
    await assertFails(
      setDoc(doc(db2, 'notifications/n5'), { ...payload('carol'), recipientId: 'alice' }),
    );
    await assertSucceeds(setDoc(doc(db2, 'notifications/n6'), payload('carol')));
  });

  test('notifications: fromUserId == pozivalac', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'notifications/n1'), payload('alice')));
  });

  test('notifications: lažni ili prazan pošiljalac', async () => {
    await assertFails(setDoc(doc(as('alice'), 'notifications/n1'), payload('carol')));
    const { fromUserId: _ignored, ...noSender } = payload('alice');
    await assertFails(setDoc(doc(as('alice'), 'notifications/n2'), noSender));
  });

  test('fcmInbox: fromUserId == pozivalac', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'users/bob/fcmInbox/f1'), payload('alice')));
  });

  test('fcmInbox: lažni pošiljalac', async () => {
    await assertFails(setDoc(doc(as('alice'), 'users/bob/fcmInbox/f1'), payload('carol')));
  });

  test('pročitan čet: primalac upitom nalazi svoja obaveštenja razgovora i označava ih', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'notifications/walk'), {
        ...payload('alice'),
        type: 'walk',
        conversationId: 'alice_bob',
        createdAt: Timestamp.now(),
      }),
    );
    const mine = query(
      collection(as('bob'), 'notifications'),
      where('toUserId', '==', 'bob'),
      where('conversationId', '==', 'alice_bob'),
    );
    await assertSucceeds(getDocs(mine));
    await assertSucceeds(updateDoc(doc(as('bob'), 'notifications/walk'), { isRead: true }));
    // Tuđa obaveštenja: ni upit ni označavanje.
    await assertFails(
      getDocs(
        query(
          collection(as('carol'), 'notifications'),
          where('conversationId', '==', 'alice_bob'),
        ),
      ),
    );
    await assertFails(updateDoc(doc(as('carol'), 'notifications/walk'), { isRead: true }));
  });
});

// ------------------------------------------------------ 4. matches / swipes
describe('4. matches i swipes', () => {
  test('matches: pozivalac je u userIds, id je sortiran par', async () => {
    await assertSucceeds(
      setDoc(doc(as('bob'), 'matches/alice_bob'), {
        userIds: ['bob', 'alice'],
        dogIds: ['rex', 'max'],
      }),
    );
  });

  test('matches: tuđi meč ili pogrešan id', async () => {
    await assertFails(
      setDoc(doc(as('carol'), 'matches/alice_bob'), { userIds: ['alice', 'bob'] }),
    );
    await assertFails(
      setDoc(doc(as('bob'), 'matches/bob_alice'), { userIds: ['alice', 'bob'] }),
    );
  });

  test('matches: ponovni set-merge postojećeg meča od strane učesnika', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'matches/alice_bob'), { userIds: ['alice', 'bob'] }),
    );
    await assertSucceeds(
      setDoc(doc(as('bob'), 'matches/alice_bob'), { userIds: ['bob', 'alice'] }, { merge: true }),
    );
    await assertFails(
      setDoc(doc(as('bob'), 'matches/alice_bob'), { userIds: ['bob', 'carol'] }, { merge: true }),
    );
    await assertFails(
      setDoc(doc(as('carol'), 'matches/alice_bob'), { note: 'x' }, { merge: true }),
    );
  });

  test('swipes: fromUserId == pozivalac', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'swipes/alice_rex'), {
        fromUserId: 'alice',
        toDogId: 'rex',
        type: 'like',
      }),
    );
  });

  test('swipes: lažni fromUserId', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'swipes/carol_rex'), {
        fromUserId: 'carol',
        toDogId: 'rex',
        type: 'like',
      }),
    );
  });
});

// ------------------------------------------------- 5. dogs brojači lajkova
describe('5. dogs brojači lajkova', () => {
  const likeOf = (db, uid) => doc(db, `dogs/rex/likes/${uid}`);
  const like = (type) => ({ userId: 'alice', type, createdAt: serverTimestamp() });
  const marker = (db) => doc(db, 'super_likes/alice_rex');
  const markerData = () => ({
    fromUserId: 'alice',
    targetDogId: 'rex',
    targetOwnerId: 'bob',
    createdAt: serverTimestamp(),
  });

  // Postojeći lajk (i opciono super lajk marker) od alice, uračunat u brojače.
  const seedLike = ({ superLike = false } = {}) =>
    env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(likeOf(db, 'alice'), { userId: 'alice', type: superLike ? 'superLike' : 'like' });
      if (superLike) {
        await setDoc(marker(db), { fromUserId: 'alice', targetDogId: 'rex' });
      }
      await setDoc(
        doc(db, 'dogs/rex'),
        { likesCount: 4, superLikesCount: superLike ? 1 : 0 },
        { merge: true },
      );
    });

  test('lajk: like doc + likesCount +1 u istom batch-u', async () => {
    const db = as('alice');
    const batch = writeBatch(db);
    batch.set(likeOf(db, 'alice'), like('like'), { merge: true });
    batch.set(doc(db, 'dogs/rex'), { likesCount: increment(1) }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  test('brojač bez like doc-a, like doc bez brojača, ili skok +5', async () => {
    const db = as('alice');
    await assertFails(updateDoc(doc(db, 'dogs/rex'), { likesCount: increment(1) }));
    await assertFails(setDoc(likeOf(db, 'alice'), like('like')));
    const batch = writeBatch(db);
    batch.set(likeOf(db, 'alice'), like('like'));
    batch.set(doc(db, 'dogs/rex'), { likesCount: increment(5) }, { merge: true });
    await assertFails(batch.commit());
  });

  test('ponovni lajk postojećeg lajka ne povećava brojač', async () => {
    await seedLike();
    const db = as('alice');
    const batch = writeBatch(db);
    batch.set(likeOf(db, 'alice'), like('like'), { merge: true });
    batch.set(doc(db, 'dogs/rex'), { likesCount: increment(1) }, { merge: true });
    await assertFails(batch.commit());
    // Bez brojača (osvežen createdAt / tip) prolazi.
    await assertSucceeds(setDoc(likeOf(db, 'alice'), like('superLike'), { merge: true }));
  });

  test('unlike: brisanje like doc-a + likesCount -1; bez brojača pada', async () => {
    await seedLike();
    const db = as('alice');
    await assertFails(deleteDoc(likeOf(db, 'alice')));
    const batch = writeBatch(db);
    batch.delete(likeOf(db, 'alice'));
    batch.set(doc(db, 'dogs/rex'), { likesCount: increment(-1) }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  test('super lajk: marker {uid}_{dog} + superLikesCount +1 (polje ne postoji)', async () => {
    const db = as('alice');
    const batch = writeBatch(db);
    batch.set(marker(db), markerData());
    batch.set(doc(db, 'dogs/rex'), { superLikesCount: increment(1) }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  test('super lajk: brojač bez markera, marker bez brojača, pogrešan id markera', async () => {
    const db = as('alice');
    await assertFails(updateDoc(doc(db, 'dogs/rex'), { superLikesCount: increment(1) }));
    await assertFails(setDoc(marker(db), markerData()));
    const batch = writeBatch(db);
    batch.set(doc(db, 'super_likes/random-id'), markerData());
    batch.set(doc(db, 'dogs/rex'), { superLikesCount: increment(1) }, { merge: true });
    await assertFails(batch.commit());
  });

  test('super lajk se broji jednom: unlike + ponovni super lajk ne povećava brojač', async () => {
    await seedLike({ superLike: true });
    const db = as('alice');
    let batch = writeBatch(db);
    batch.delete(likeOf(db, 'alice'));
    batch.set(doc(db, 'dogs/rex'), { likesCount: increment(-1) }, { merge: true });
    await assertSucceeds(batch.commit());
    batch = writeBatch(db);
    batch.set(marker(db), markerData());
    batch.set(doc(db, 'dogs/rex'), { superLikesCount: increment(1) }, { merge: true });
    await assertFails(batch.commit());
  });

  test('brisanje markera traži superLikesCount -1; stari auto-id dokument se briše slobodno', async () => {
    await seedLike({ superLike: true });
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'super_likes/legacy1'), {
        fromUserId: 'alice',
        targetDogId: 'rex',
      }),
    );
    const db = as('alice');
    await assertFails(deleteDoc(marker(db)));
    await assertSucceeds(deleteDoc(doc(db, 'super_likes/legacy1')));
    const batch = writeBatch(db);
    batch.delete(marker(db));
    batch.update(doc(db, 'dogs/rex'), { superLikesCount: increment(-1) });
    await assertSucceeds(batch.commit());
  });

  test('vlasnik menja psa ali ne brojače; briše tuđe lajkove (brisanje naloga)', async () => {
    await seedLike();
    const db = as('bob');
    await assertSucceeds(updateDoc(doc(db, 'dogs/rex'), { name: 'Rex II' }));
    await assertFails(updateDoc(doc(db, 'dogs/rex'), { likesCount: 1000 }));
    await assertSucceeds(deleteDoc(likeOf(db, 'alice')));
  });

  test('treći korisnik ne briše tuđi lajk i ne menja druga polja', async () => {
    await seedLike();
    const db = as('carol');
    await assertFails(deleteDoc(likeOf(db, 'alice')));
    await assertFails(updateDoc(doc(db, 'dogs/rex'), { name: 'Hack' }));
  });
});

// ------------------------------------------ 6. lastMessage i članstvo (dopuna)
describe('6. lastMessage i članstvo', () => {
  test('čet: dugačak lastMessage ili lažno vreme padaju', async () => {
    const db = as('alice');
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { lastMessage: 'x'.repeat(1001) }));
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { lastMessage: 42 }));
    await assertFails(
      updateDoc(doc(db, 'chats/alice_bob'), {
        lastMessage: 'hej',
        lastMessageTimestamp: Timestamp.fromDate(new Date('2099-01-01')),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'chats/alice_bob'), {
        lastMessage: 'x'.repeat(1000),
        lastMessageTimestamp: serverTimestamp(),
      }),
    );
  });

  test('grupa/događaj: lastMessageAt mora biti serverTimestamp', async () => {
    const future = Timestamp.fromDate(new Date('2099-01-01'));
    await assertFails(
      updateDoc(doc(as('alice'), 'breed_groups/g1'), {
        lastMessage: 'hej',
        lastMessageAt: future,
        lastMessageSenderId: 'alice',
      }),
    );
    await assertFails(
      updateDoc(doc(as('alice'), 'events/e1'), { lastMessage: 'hej', lastMessageAt: future }),
    );
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'events/e1'), {
        lastMessage: 'hej',
        lastMessageAt: serverTimestamp(),
      }),
    );
  });

  test('kreator/organizator ne dodaje tuđe članove', async () => {
    await assertFails(
      updateDoc(doc(as('alice'), 'breed_groups/g1'), {
        memberIds: ['alice', 'carol'],
        memberCount: 2,
      }),
    );
    await assertFails(
      updateDoc(doc(as('alice'), 'events/e1'), { participantUserIds: ['alice', 'carol'] }),
    );
    // Kreator i dalje sme sam da izađe iz svoje grupe.
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'breed_groups/g1'), { memberIds: [], memberCount: 0 }),
    );
  });
});

// ------------------------------------------- 7. users: privatna polja
describe('7. users privatna polja', () => {
  test('novi profil bez privatnih polja prolazi, sa email/fcmToken pada', async () => {
    const db = as('dave');
    await assertFails(setDoc(doc(db, 'users/dave'), { role: 'user', email: 'd@x.rs' }));
    await assertFails(setDoc(doc(db, 'users/dave'), { role: 'user', fcmToken: 't' }));
    await assertSucceeds(setDoc(doc(db, 'users/dave'), { role: 'user', name: 'Dave' }));
  });

  test('vlasnik ne dodaje privatna polja u javni profil, ali sme da ih ukloni', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users/alice'), {
        role: 'user',
        email: 'alice@example.com',
        contentReports: [{ id: 'r1' }],
      }),
    );
    const db = as('alice');
    await assertSucceeds(updateDoc(doc(db, 'users/alice'), { name: 'Alice' }));
    await assertFails(updateDoc(doc(db, 'users/alice'), { fcmToken: 'tok' }));
    await assertFails(updateDoc(doc(db, 'users/alice'), { email: 'novi@example.com' }));
    await assertFails(
      setDoc(doc(db, 'users/alice'), { latitude: 45.25, longitude: 19.84 }, { merge: true }),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'users/alice'), { email: deleteField(), contentReports: deleteField() }),
    );
  });

  test('privatni dokument: vlasnik čita/piše, drugi ne, admin čita', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'users/bob/private/account')));
    await assertSucceeds(
      setDoc(doc(as('bob'), 'users/bob/private/account'), { fcmToken: 't' }, { merge: true }),
    );
    await assertFails(getDoc(doc(as('alice'), 'users/bob/private/account')));
    await assertFails(setDoc(doc(as('alice'), 'users/bob/private/account'), { email: 'x' }));
    await assertSucceeds(getDoc(doc(as('admin'), 'users/bob/private/account')));
  });

  test('collection group private: samo admin', async () => {
    await assertSucceeds(getDocs(collectionGroup(as('admin'), 'private')));
    await assertFails(getDocs(collectionGroup(as('alice'), 'private')));
  });
});

// ------------------------------------------- 8. chats: polja učesnika
describe('8. chats polja učesnika', () => {
  test('učesnik ne menja metapodatke sobe', async () => {
    const db = as('alice');
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { dogNames: { bob: 'Hack' } }));
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { photoUrl: 'https://x' }));
  });

  test('unread: sebi samo 0, drugom samo +1', async () => {
    const db = as('alice');
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { 'unreadByUser.bob': 99 }));
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { 'unreadByUser.alice': 5 }));
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { 'unreadByUser.carol': 1 }));
    await assertSucceeds(
      updateDoc(doc(db, 'chats/alice_bob'), { 'unreadByUser.bob': increment(1) }),
    );
    await assertSucceeds(updateDoc(doc(as('bob'), 'chats/alice_bob'), { 'unreadByUser.bob': 0 }));
  });

  test('isNewMatch samo na false, unreadCount samo 0', async () => {
    const db = as('alice');
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { isNewMatch: true }));
    await assertSucceeds(updateDoc(doc(db, 'chats/alice_bob'), { isNewMatch: false }));
    await assertFails(updateDoc(doc(db, 'chats/alice_bob'), { unreadCount: 3 }));
    await assertSucceeds(updateDoc(doc(db, 'chats/alice_bob'), { unreadCount: 0 }));
  });

  test('provera da soba ne postoji (pre kreiranja) je dozvoljena', async () => {
    await assertSucceeds(getDoc(doc(as('carol'), 'chats/carol_dave')));
    await assertFails(getDoc(doc(as('carol'), 'chats/alice_bob')));
  });
});

// ------------------------------------------- 9. lost_dogs komentari
describe('9. lost_dogs komentari', () => {
  const comment = (author, text = 'Video sam je kod Dunava') => ({
    id: `c-${author}`,
    authorUserId: author,
    authorName: author,
    text,
    likes: [],
  });

  test('dodavanje jednog svog komentara + commentsCount +1', async () => {
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'lost_dogs/l1'), {
        comments: arrayUnion(comment('alice')),
        commentsCount: increment(1),
      }),
    );
  });

  test('prepisivanje tuđeg komentara, tuđi autor, brojač +2, bez brojača', async () => {
    const db = as('alice');
    await assertFails(
      updateDoc(doc(db, 'lost_dogs/l1'), {
        comments: [{ ...comment('bob'), id: 'c1', text: 'Lažno' }, comment('alice')],
        commentsCount: 2,
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'lost_dogs/l1'), {
        comments: arrayUnion(comment('bob')),
        commentsCount: increment(1),
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'lost_dogs/l1'), {
        comments: arrayUnion(comment('alice')),
        commentsCount: increment(2),
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'lost_dogs/l1'), { comments: arrayUnion(comment('alice')) }),
    );
    await assertFails(updateDoc(doc(db, 'lost_dogs/l1'), { commentsCount: 50 }));
  });

  test('lajk komentara: samo svoj uid u jednom unosu', async () => {
    const db = as('alice');
    await assertSucceeds(
      updateDoc(doc(db, 'lost_dogs/l1'), {
        'commentLikes.c1': ['bob', 'alice'],
        commentLikeTarget: 'c1',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'lost_dogs/l1'), { 'commentLikes.c1': [], commentLikeTarget: 'c1' }),
    );
    await assertFails(
      updateDoc(doc(db, 'lost_dogs/l1'), {
        'commentLikes.c1': ['bob', 'alice', 'carol'],
        commentLikeTarget: 'c1',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'lost_dogs/l1'), {
        'commentLikes.c1': ['bob'],
        'commentLikes.c2': ['alice'],
        commentLikeTarget: 'c2',
      }),
    );
  });

  test('vlasnik oglasa i dalje menja svoj oglas', async () => {
    await assertSucceeds(updateDoc(doc(as('carol'), 'lost_dogs/l1'), { status: 'resolved' }));
  });
});

// ------------------------------------------- 10. nizovi lajkova
describe('10. lajkovi: samo svoj uid', () => {
  test('moments: svoj lajk/unlike prolazi, tuđi uid pada', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'moments/mo1'), { likes: ['bob', 'alice'] }));
    await assertSucceeds(updateDoc(doc(as('bob'), 'moments/mo1'), { likes: arrayRemove('bob') }));
    await assertFails(updateDoc(doc(as('dave'), 'moments/mo1'), { likes: [] }));
    await assertFails(updateDoc(doc(as('dave'), 'moments/mo1'), { likes: ['bob', 'x', 'y'] }));
  });

  test('moments: commentsCount samo ±1', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'moments/mo1'), { commentsCount: 3 }));
    await assertFails(updateDoc(doc(as('alice'), 'moments/mo1'), { commentsCount: 100 }));
  });

  test('poruke u četu: lajk samo svojim uid-om', async () => {
    const db = as('bob');
    await assertSucceeds(
      updateDoc(doc(db, 'chats/alice_bob/messages/m1'), { likes: arrayUnion('bob') }),
    );
    await assertFails(
      updateDoc(doc(db, 'chats/alice_bob/messages/m1'), { likes: ['bob', 'alice'] }),
    );
  });
});
