// Testovi Storage pravila nad emulatorom.
// Pokretanje (iz rules_test/): npm test  → firebase emulators:exec + node --test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { getMetadata, listAll, ref, uploadBytes } from 'firebase/storage';

let env;

const [emuHost, emuPort] = (
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199'
).split(':');

const image = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
const jpeg = { contentType: 'image/jpeg' };

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-vauvau',
    storage: {
      rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8'),
      host: emuHost,
      port: Number(emuPort),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const storage = ctx.storage();
    await uploadBytes(ref(storage, 'pets/alice/1.jpg'), image, jpeg);
    await uploadBytes(ref(storage, 'chats/alice/1.jpg'), image, jpeg);
  });
});

const as = (uid) => env.authenticatedContext(uid).storage();
const anon = () => env.unauthenticatedContext().storage();

describe('storage: javni folderi', () => {
  test('pojedinačan fajl je čitljiv svima', async () => {
    await assertSucceeds(getMetadata(ref(anon(), 'pets/alice/1.jpg')));
    await assertSucceeds(getMetadata(ref(as('bob'), 'pets/alice/1.jpg')));
  });

  test('listanje tuđeg foldera je zabranjeno, svog dozvoljeno', async () => {
    await assertFails(listAll(ref(anon(), 'pets/alice')));
    await assertFails(listAll(ref(as('bob'), 'pets/alice')));
    await assertSucceeds(listAll(ref(as('alice'), 'pets/alice')));
  });

  test('upload samo u svoj folder i samo slike', async () => {
    await assertSucceeds(uploadBytes(ref(as('alice'), 'pets/alice/2.jpg'), image, jpeg));
    await assertFails(uploadBytes(ref(as('bob'), 'pets/alice/2.jpg'), image, jpeg));
    await assertFails(
      uploadBytes(ref(as('alice'), 'pets/alice/x.txt'), image, { contentType: 'text/plain' }),
    );
  });
});

describe('storage: video', () => {
  const mp4 = { contentType: 'video/mp4' };
  const mov = { contentType: 'video/quicktime' };
  test('video ide samo u moments/ i samo do 20 MB', async () => {
    await assertSucceeds(uploadBytes(ref(as('alice'), 'moments/alice/d1.mp4'),
      new Uint8Array(12 * 1024 * 1024), mp4));
    await assertSucceeds(uploadBytes(ref(as('alice'), 'moments/alice/d2.mov'), image, mov));
    await assertFails(uploadBytes(ref(as('alice'), 'moments/alice/d3.mp4'),
      new Uint8Array(20 * 1024 * 1024), mp4));
    await assertFails(uploadBytes(ref(as('bob'), 'moments/alice/d4.mp4'), image, mp4));
    // Ostali folderi i dalje samo slike.
    await assertFails(uploadBytes(ref(as('alice'), 'pets/alice/v.mp4'), image, mp4));
    await assertFails(uploadBytes(ref(as('alice'), 'chats/alice/v.mp4'), image, mp4));
    // Slike u moments/ i dalje do 8 MB.
    await assertFails(uploadBytes(ref(as('alice'), 'moments/alice/big.jpg'),
      new Uint8Array(9 * 1024 * 1024), jpeg));
  });
});

describe('storage: slike iz četa', () => {
  test('neprijavljen korisnik ne čita sliku iz četa', async () => {
    await assertFails(getMetadata(ref(anon(), 'chats/alice/1.jpg')));
  });

  test('po putanji sliku čita samo onaj ko ju je poslao (putanje su pogodive)', async () => {
    await assertFails(getMetadata(ref(as('bob'), 'chats/alice/1.jpg')));
    await assertSucceeds(getMetadata(ref(as('alice'), 'chats/alice/1.jpg')));
  });

  test('niko osim vlasnika ne lista slike iz četa', async () => {
    await assertFails(listAll(ref(anon(), 'chats/alice')));
    await assertFails(listAll(ref(as('bob'), 'chats/alice')));
    await assertSucceeds(listAll(ref(as('alice'), 'chats/alice')));
  });
});
