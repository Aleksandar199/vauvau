// Testovi pravila za ulogu partnera (kuponi), dodelu uloga, suspenziju i
// admin čitanja za statistiku/moderaciju. Poseban projectId (paralelno).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
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

const future = () => Timestamp.fromDate(new Date(Date.now() + 10 * 86400e3));
const past = () => Timestamp.fromDate(new Date(Date.now() - 86400e3));

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-vauvau-admin',
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
    await setDoc(doc(db, 'users/admin'), { role: 'admin', name: 'Admin' });
    await setDoc(doc(db, 'users/alice'), { role: 'user', name: 'Alisa' });
    await setDoc(doc(db, 'users/bob'), { role: 'user', name: 'Bob' });
    await setDoc(doc(db, 'users/shop'), { role: 'partner', partnerId: 'p1', name: 'Šapa' });
    await setDoc(doc(db, 'users/shop2'), { role: 'partner', partnerId: 'p2', name: 'Njuška' });
    await setDoc(doc(db, 'users/offshop'), { role: 'partner', partnerId: 'p3', name: 'Zatvoren' });
    // partnerId bez uloge partnera ne daje ništa.
    await setDoc(doc(db, 'users/fake'), { role: 'user', partnerId: 'p1', name: 'Lažni' });
    await setDoc(doc(db, 'users/mute'), { role: 'user', isSuspended: true, name: 'Suspendovan' });
    await setDoc(doc(db, 'partners/p1'), { name: 'Pet shop Šapa', isActive: true });
    await setDoc(doc(db, 'partners/p2'), { name: 'Njuška', isActive: true });
    await setDoc(doc(db, 'partners/p3'), { name: 'Zatvoren', isActive: false });
    const claim = (couponId, uid, partnerId, code, patch = {}) =>
      setDoc(doc(db, `coupon_claims/${couponId}_${uid}`), {
        userId: uid, couponId, code, status: 'claimed', pointsCost: 100,
        partnerName: 'X', title: '', discountLabel: '15%', partnerId,
        expiresAt: future(), claimedAt: Timestamp.now(), ...patch,
      });
    await claim('c1', 'alice', 'p1', 'VV-AAAA2222');
    await claim('c2', 'alice', 'p2', 'VV-BBBB3333');
    await claim('c1', 'bob', 'p1', 'VV-CCCC4444', { expiresAt: past() });
    await claim('c3', 'alice', 'p3', 'VV-DDDD5555');
    await setDoc(doc(db, 'chats/alice_bob'), {
      participantIds: ['alice', 'bob'],
      lastMessage: 'zdravo',
      lastMessageTimestamp: Timestamp.now(),
    });
    await setDoc(doc(db, 'chats/alice_bob/messages/m1'), {
      senderId: 'bob', receiverId: 'alice', text: 'uvreda',
    });
    await setDoc(doc(db, 'chats/bob_mute'), { participantIds: ['bob', 'mute'] });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const redeem = (uid, claimId, patch = {}) =>
  updateDoc(doc(as(uid), `coupon_claims/${claimId}`), {
    status: 'redeemed',
    redeemedAt: serverTimestamp(),
    redeemedBy: uid,
    ...patch,
  });

describe('Uloge: korisnik ne dodeljuje sebi partnera/admina', () => {
  test('vlasnik ne menja role, partnerId ni suspenziju; admin može', async () => {
    const mine = doc(as('alice'), 'users/alice');
    await assertSucceeds(updateDoc(mine, { name: 'Alisa N.' }));
    await assertFails(updateDoc(mine, { role: 'partner' }));
    await assertFails(updateDoc(mine, { role: 'admin' }));
    await assertFails(updateDoc(mine, { partnerId: 'p1' }));
    await assertFails(updateDoc(doc(as('mute'), 'users/mute'), { isSuspended: false }));
    await assertFails(updateDoc(doc(as('shop'), 'users/shop'), { partnerId: 'p2' }));
    await assertFails(updateDoc(doc(as('alice'), 'users/bob'), { role: 'partner' }));

    await assertSucceeds(updateDoc(doc(as('admin'), 'users/bob'), {
      role: 'partner', partnerId: 'p2',
    }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'users/alice'), {
      isSuspended: true, suspendedReason: 'spam', suspendedAt: serverTimestamp(),
    }));
  });

  test('nov profil ne može da se napravi kao partner/sa partnerId/suspenzijom', async () => {
    const ref = doc(as('newbie'), 'users/newbie');
    await assertFails(setDoc(ref, { role: 'partner', name: 'N' }));
    await assertFails(setDoc(ref, { role: 'user', partnerId: 'p1', name: 'N' }));
    await assertFails(setDoc(ref, { role: 'user', isSuspended: false, name: 'N' }));
    await assertSucceeds(setDoc(ref, { role: 'user', name: 'N' }));
  });

  test('partners: čitaju svi prijavljeni, piše samo admin', async () => {
    await assertSucceeds(getDoc(doc(as('alice'), 'partners/p1')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'partners/p1')));
    await assertFails(setDoc(doc(as('shop'), 'partners/p1'), { name: 'Moj', isActive: true }));
    await assertFails(updateDoc(doc(as('offshop'), 'partners/p3'), { isActive: true }));
    await assertSucceeds(setDoc(doc(as('admin'), 'partners/p9'), { name: 'Nova', isActive: true }));
  });
});

describe('Partner vidi samo kupone svog partnera', () => {
  test('upit po partnerId (+ kod) prolazi samo za svoj partnerId', async () => {
    const claims = (uid) => collection(as(uid), 'coupon_claims');
    await assertSucceeds(getDocs(query(claims('shop'), where('partnerId', '==', 'p1'))));
    await assertSucceeds(getDocs(query(
      claims('shop'),
      where('partnerId', '==', 'p1'),
      where('code', '==', 'VV-AAAA2222'),
    )));
    await assertFails(getDocs(query(claims('shop'), where('partnerId', '==', 'p2'))));
    await assertFails(getDocs(query(claims('shop'), where('code', '==', 'VV-BBBB3333'))));
    await assertFails(getDocs(claims('shop')));
    // Bez uloge partnera, ili neaktivan partner: ništa.
    await assertFails(getDocs(query(claims('fake'), where('partnerId', '==', 'p1'))));
    await assertFails(getDocs(query(claims('alice'), where('partnerId', '==', 'p1'))));
    await assertFails(getDocs(query(claims('offshop'), where('partnerId', '==', 'p3'))));

    await assertSucceeds(getDoc(doc(as('shop'), 'coupon_claims/c1_alice')));
    await assertFails(getDoc(doc(as('shop'), 'coupon_claims/c2_alice')));
    await assertSucceeds(getDoc(doc(as('shop2'), 'coupon_claims/c2_alice')));
  });
});

describe('Partner označava kupon kao iskorišćen', () => {
  test('samo claimed → redeemed, sa redeemedAt/redeemedBy, jednom', async () => {
    await assertFails(redeem('shop', 'c1_alice', { redeemedBy: 'neko' }));
    await assertFails(redeem('shop', 'c1_alice', { pointsCost: 0 }));
    await assertFails(redeem('shop', 'c1_alice', { status: 'cancelled' }));
    await assertFails(updateDoc(doc(as('shop'), 'coupon_claims/c1_alice'), {
      status: 'redeemed', redeemedAt: Timestamp.fromDate(new Date(2020, 1, 1)),
      redeemedBy: 'shop',
    }));
    await assertSucceeds(redeem('shop', 'c1_alice'));
    await assertFails(redeem('shop', 'c1_alice'));
    await assertFails(updateDoc(doc(as('shop'), 'coupon_claims/c1_alice'), { status: 'claimed' }));
  });

  test('tuđi, istekao, neaktivan partner i lažni partner – odbijeno', async () => {
    await assertFails(redeem('shop', 'c2_alice'));
    await assertFails(redeem('shop', 'c1_bob'));
    await assertFails(redeem('offshop', 'c3_alice'));
    await assertFails(redeem('fake', 'c1_alice'));
    await assertSucceeds(redeem('shop2', 'c2_alice'));
  });

  test('korisnik više ne označava sam; admin i dalje može', async () => {
    await assertFails(updateDoc(doc(as('alice'), 'coupon_claims/c1_alice'), {
      status: 'redeemed', redeemedAt: serverTimestamp(),
    }));
    await assertFails(redeem('alice', 'c1_alice'));
    await assertSucceeds(redeem('admin', 'c1_alice'));
    await assertSucceeds(updateDoc(doc(as('admin'), 'coupon_claims/c2_alice'), {
      status: 'cancelled', cancelledAt: serverTimestamp(),
    }));
  });
});

describe('Preuzimanje kupona prepisuje partnerId sa kupona', () => {
  async function seed() {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'reward_coupons/k1'), {
        partnerName: 'Pet shop Šapa', partnerId: 'p1', discountLabel: '15%',
        pointsCost: 100, startsAt: past(), expiresAt: future(),
        maxQuantity: 5, claimedCount: 0, isActive: true,
      });
      await setDoc(doc(db, 'users/bob/reward_ledger/seed'), { type: 'walk', xp: 300, points: 300 });
      await setDoc(doc(db, 'users/bob/rewards/summary'), { xp: 300, points: 300, lastEntryId: 'seed' });
    });
  }

  function claim(partnerId) {
    const db = as('bob');
    const batch = writeBatch(db);
    const data = {
      userId: 'bob', couponId: 'k1', code: 'VV-EEEE6666', status: 'claimed',
      pointsCost: 100, partnerName: 'Pet shop Šapa', title: '', discountLabel: '15%',
      expiresAt: null, claimedAt: serverTimestamp(),
    };
    if (partnerId !== undefined) data.partnerId = partnerId;
    return getDoc(doc(db, 'reward_coupons/k1')).then((snap) => {
      data.expiresAt = snap.data().expiresAt;
      batch.set(doc(db, 'coupon_claims/k1_bob'), data);
      batch.update(doc(db, 'reward_coupons/k1'), { claimedCount: 1 });
      batch.set(doc(db, 'users/bob/reward_ledger/coupon_k1'), {
        type: 'coupon', couponId: 'k1', xp: 0, points: -100,
        reason: 'Kupon', createdAt: serverTimestamp(),
      });
      batch.set(doc(db, 'users/bob/rewards/summary'), {
        xp: 300, points: 200, lastEntryId: 'coupon_k1', updatedAt: serverTimestamp(),
      });
      return batch.commit();
    });
  }

  test('pogrešan ili izostavljen partnerId → odbijeno; tačan → prolazi', async () => {
    await seed();
    await assertFails(claim('p2'));
    await assertFails(claim(undefined));
    await assertSucceeds(claim('p1'));
  });
});

describe('Suspendovan korisnik ne objavljuje sadržaj', () => {
  test('poruka i momenat', async () => {
    await assertFails(setDoc(doc(as('mute'), 'chats/bob_mute/messages/x'), {
      senderId: 'mute', receiverId: 'bob', text: 'hej',
    }));
    await assertSucceeds(setDoc(doc(as('bob'), 'chats/bob_mute/messages/y'), {
      senderId: 'bob', receiverId: 'mute', text: 'hej',
    }));
    await assertFails(setDoc(doc(as('mute'), 'moments/m1'), {
      authorUserId: 'mute', caption: 'x', momentPhotoUrl: 'https://x/m.jpg',
      likes: [], commentsCount: 0, createdAt: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(as('alice'), 'moments/m2'), {
      authorUserId: 'alice', caption: 'x', momentPhotoUrl: 'https://x/m.jpg',
      likes: [], commentsCount: 0, createdAt: serverTimestamp(),
    }));
    // Bez profila (tek registrovan) nije suspendovan.
    await assertSucceeds(setDoc(doc(as('newbie'), 'moments/m3'), {
      authorUserId: 'newbie', caption: 'x', momentPhotoUrl: 'https://x/m.jpg',
      likes: [], commentsCount: 0, createdAt: serverTimestamp(),
    }));
  });
});

describe('Admin čitanja za statistiku i moderaciju', () => {
  test('broj četova i jedna prijavljena poruka; poruke se ne listaju', async () => {
    const adminDb = as('admin');
    await assertSucceeds(getCountFromServer(collection(adminDb, 'chats')));
    await assertSucceeds(getCountFromServer(query(
      collection(adminDb, 'chats'),
      where('lastMessageTimestamp', '>=', past()),
    )));
    await assertSucceeds(getDoc(doc(adminDb, 'chats/alice_bob/messages/m1')));
    await assertFails(getDocs(collection(adminDb, 'chats/alice_bob/messages')));
    await assertFails(getCountFromServer(collection(as('alice'), 'chats')));
    await assertFails(getDoc(doc(as('shop'), 'chats/alice_bob/messages/m1')));
    await assertSucceeds(getCountFromServer(query(
      collection(adminDb, 'coupon_claims'),
      where('status', '==', 'claimed'),
    )));
    await assertSucceeds(getCountFromServer(query(
      collection(adminDb, 'stories'),
      where('expiresAt', '>', Timestamp.now()),
    )));
  });
});
