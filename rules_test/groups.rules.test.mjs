// Pravila za nova opciona polja grupa (scope, cityId, category, locationName,
// breedKey, featured). Poseban projectId (paralelno sa ostalim fajlovima).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';

let env;
const [emuHost, emuPort] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-vauvau-groups',
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
    await setDoc(doc(db, 'users/bob'), { role: 'user' });
    await setDoc(doc(db, 'users/eve'), { role: 'user' });
    // Stari dokument bez novih polja.
    await setDoc(doc(db, 'breed_groups/old'), {
      title: 'Stara', description: 'x', memberIds: ['bob'], memberCount: 1,
      isApproved: true, createdBy: 'bob',
    });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const pending = (extra = {}) => ({
  title: 'Šetnje — Niš', description: 'x', memberIds: ['bob'], memberCount: 1,
  isApproved: false, createdBy: 'bob', ...extra,
});

describe('groups: nova opciona polja', () => {
  test('korisnik predlaže lokalnu grupu sa gradom/kategorijom/lokacijom', async () => {
    await assertSucceeds(
      setDoc(doc(as('bob'), 'breed_groups/n1'), pending({
        scope: 'local', cityId: 'nis', category: 'parks',
        locationName: 'Park', featured: false,
      })),
    );
  });

  test('korisnik predlaže grupu za rasu', async () => {
    await assertSucceeds(
      setDoc(doc(as('bob'), 'breed_groups/n2'), pending({
        scope: 'breed', breedKey: 'Labrador', category: 'general',
      })),
    );
  });

  test('korisnik ne može da se proglasi istaknutim pri kreiranju', async () => {
    await assertFails(
      setDoc(doc(as('bob'), 'breed_groups/n3'), pending({ featured: true })),
    );
  });

  test('korisnik i dalje ne sme odobrenu grupu sa novim poljima', async () => {
    await assertFails(
      setDoc(doc(as('bob'), 'breed_groups/n4'), pending({
        isApproved: true, scope: 'global',
      })),
    );
  });

  test('admin pravi odobrenu istaknutu globalnu grupu', async () => {
    await assertSucceeds(
      setDoc(doc(as('admin'), 'breed_groups/n5'), {
        title: 'Šetnje pasa — Srbija', description: 'x', memberIds: [],
        memberCount: 0, isApproved: true, createdBy: '',
        scope: 'global', category: 'general', featured: true,
      }),
    );
  });

  test('kreator menja opis i grad, ali ne featured', async () => {
    await assertSucceeds(
      updateDoc(doc(as('bob'), 'breed_groups/old'), {
        description: 'Novi opis', cityId: 'novi_sad', category: 'parks',
      }),
    );
    await assertFails(
      updateDoc(doc(as('bob'), 'breed_groups/old'), { featured: true }),
    );
  });

  test('tuđi korisnik ne menja klasifikaciju niti featured', async () => {
    await assertFails(
      updateDoc(doc(as('eve'), 'breed_groups/old'), { cityId: 'nis' }),
    );
    await assertFails(
      updateDoc(doc(as('eve'), 'breed_groups/old'), { featured: true }),
    );
  });

  test('admin menja featured; stari dokument ostaje čitljiv i član ulazi', async () => {
    await assertSucceeds(
      updateDoc(doc(as('admin'), 'breed_groups/old'), { featured: true }),
    );
    await assertSucceeds(
      updateDoc(doc(as('eve'), 'breed_groups/old'), {
        memberIds: ['bob', 'eve'], memberCount: 2,
      }),
    );
  });
});
