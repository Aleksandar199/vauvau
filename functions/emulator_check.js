// Ručna provera u emulatoru: firebase emulators:exec --only functions,firestore "node functions/emulator_check.js"
process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
const admin = require('firebase-admin');
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-vauvau' });
const db = admin.firestore();
(async () => {
  await db.doc('users/nina/private/account').set({ fcmToken: 'not-a-real-token' });
  const ref = await db.collection('users/nina/fcmInbox').add({
    type: 'message', title: 'Nova poruka', body: 'Marko: Ćao',
    fromUserId: 'marko', toUserId: 'nina', conversationId: 'marko_nina',
    data: { type: 'message', conversationId: 'marko_nina', peerUserId: 'nina' },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  for (let i = 0; i < 60; i++) {
    await new Promise((r) => setTimeout(r, 500));
    if (!(await ref.get()).exists) {
      const account = (await db.doc('users/nina/private/account').get()).data();
      console.log('OK: fcmInbox entry handled; token after send:', account.fcmToken ?? '(removed)');
      process.exit(0);
    }
  }
  console.error('FAIL: function did not handle the fcmInbox entry');
  process.exit(1);
})();
