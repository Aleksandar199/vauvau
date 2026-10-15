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
  deleteDoc,
  doc,
  getDoc,
  increment,
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
    isRead: false,
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

  // Postojeći lajk/super lajk od alice, sa brojačima koji ga već uključuju.
  const seedLike = (type) =>
    env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(likeOf(db, 'alice'), { userId: 'alice', type });
      await setDoc(
        doc(db, 'dogs/rex'),
        { likesCount: 4, superLikesCount: type === 'superLike' ? 1 : 0 },
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

  test('super lajk na novom psu: oba brojača +1 (polje superLikesCount ne postoji)', async () => {
    const db = as('alice');
    const batch = writeBatch(db);
    batch.set(likeOf(db, 'alice'), like('superLike'), { merge: true });
    batch.set(
      doc(db, 'dogs/rex'),
      { likesCount: increment(1), superLikesCount: increment(1) },
      { merge: true },
    );
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

  test('ponovni lajk postojećeg lajka ne sme da poveća brojač', async () => {
    await seedLike('like');
    const db = as('alice');
    const batch = writeBatch(db);
    batch.set(likeOf(db, 'alice'), like('like'), { merge: true });
    batch.set(doc(db, 'dogs/rex'), { likesCount: increment(1) }, { merge: true });
    await assertFails(batch.commit());
    // Bez brojača (samo osvežen createdAt) prolazi.
    await assertSucceeds(setDoc(likeOf(db, 'alice'), like('like'), { merge: true }));
  });

  test('unlike: brisanje like doc-a + likesCount -1; bez brojača pada', async () => {
    await seedLike('like');
    const db = as('alice');
    await assertFails(deleteDoc(likeOf(db, 'alice')));
    const batch = writeBatch(db);
    batch.delete(likeOf(db, 'alice'));
    batch.set(doc(db, 'dogs/rex'), { likesCount: increment(-1) }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  test('like → superLike: superLikesCount +1; superLike → like zabranjeno', async () => {
    await seedLike('like');
    const db = as('alice');
    let batch = writeBatch(db);
    batch.set(likeOf(db, 'alice'), like('superLike'), { merge: true });
    batch.set(doc(db, 'dogs/rex'), { superLikesCount: increment(1) }, { merge: true });
    await assertSucceeds(batch.commit());
    await assertFails(setDoc(likeOf(db, 'alice'), like('like'), { merge: true }));
    batch = writeBatch(db);
    batch.set(likeOf(db, 'alice'), like('like'), { merge: true });
    batch.set(doc(db, 'dogs/rex'), { superLikesCount: increment(-1) }, { merge: true });
    await assertFails(batch.commit());
  });

  test('superLike → ništa: oba brojača -1', async () => {
    await seedLike('superLike');
    const db = as('alice');
    const batch = writeBatch(db);
    batch.delete(likeOf(db, 'alice'));
    batch.set(
      doc(db, 'dogs/rex'),
      { likesCount: increment(-1), superLikesCount: increment(-1) },
      { merge: true },
    );
    await assertSucceeds(batch.commit());
  });

  test('vlasnik menja psa ali ne brojače; briše tuđe lajkove (brisanje naloga)', async () => {
    await seedLike('like');
    const db = as('bob');
    await assertSucceeds(updateDoc(doc(db, 'dogs/rex'), { name: 'Rex II' }));
    await assertFails(updateDoc(doc(db, 'dogs/rex'), { likesCount: 1000 }));
    await assertSucceeds(deleteDoc(likeOf(db, 'alice')));
  });

  test('treći korisnik ne briše tuđi lajk i ne menja druga polja', async () => {
    await seedLike('like');
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
