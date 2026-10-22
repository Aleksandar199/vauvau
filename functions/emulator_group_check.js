// Ručna provera u emulatoru:
// firebase emulators:exec --only functions,firestore "node functions/emulator_group_check.js"
// Očekivano u logu funkcije: recipients "dina,ema" (bez pošiljaoca, utišanog i onoga ko je blokirao).
process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
const admin = require('firebase-admin');
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-vauvau' });
const db = admin.firestore();
(async () => {
  await db.doc('breed_groups/g1').set({
    title: 'Labradori',
    memberIds: ['ana', 'bojan', 'ceca', 'dina', 'ema'],
  });
  await db.doc('breed_groups/g1/members/bojan').set({ muted: true });
  await db.doc('users/ceca/blocked_users/ana').set({ blockedAt: 1 });
  for (const uid of ['bojan', 'ceca', 'dina', 'ema']) {
    await db.doc(`users/${uid}/private/account`).set({ fcmToken: `token-${uid}` });
  }
  await db.collection('breed_groups/g1/messages').add({
    senderId: 'ana',
    senderName: 'Ana',
    text: 'Ko je za šetnju?',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await new Promise((r) => setTimeout(r, 8000));
  process.exit(0);
})();
