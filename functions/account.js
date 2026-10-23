// Server-side clean-up after an account is deleted (Auth trigger).
//
// The app still removes what it can before `user.delete()`, but a client can
// be killed half way, lose the network or be blocked by rules, which left
// orphans (dogs, moments, stories, chat messages, files). When the Auth user
// disappears this sweeps everything that belongs to the uid, with admin
// rights. Every step is independent: one failure is logged and the rest runs,
// and the whole sweep is safe to repeat.
const admin = require('firebase-admin');
const { logger } = require('firebase-functions');

/** Top-level collections whose documents carry the owner in one field. */
const OWNED = [
  ['dogs', 'ownerId'],
  ['moments', 'authorUserId'],
  ['stories', 'authorUserId'],
  ['events', 'organizerUserId'],
  ['adoption_dogs', 'uploaderUserId'],
  ['lost_dogs', 'uploaderUserId'],
  ['swipes', 'fromUserId'],
  ['super_likes', 'fromUserId'],
  ['follows', 'followerUserId'],
  ['follows', 'followedUserId'],
  ['notifications', 'toUserId'],
  ['notifications', 'recipientId'],
  ['notifications', 'fromUserId'],
  ['highlights', 'ownerId'],
];

/** Collection-group documents written by the user inside other documents. */
const AUTHORED = [
  ['comments', 'authorUserId'],
  ['messages', 'senderId'],
];

/** Storage roots are `{root}/{uid}/…` (see storage.rules). */
const STORAGE_ROOTS = [
  'pets',
  'users',
  'moments',
  'events',
  'groups',
  'adoption',
  'lost_dogs',
  'uploads',
  'chats',
  'stories',
];

async function step(name, work) {
  try {
    return await work();
  } catch (error) {
    logger.warn('Account clean-up step failed', { step: name, error: String(error) });
    return null;
  }
}

async function deleteQueryDocs(db, query) {
  const snap = await query.get();
  // recursiveDelete also removes subcollections (likes, comments, members…).
  for (const doc of snap.docs) await db.recursiveDelete(doc.ref);
  return snap.size;
}

/** Removes [uid] from array-membership documents (events, groups, chats). */
async function leaveMemberships(db, uid) {
  const FieldValue = admin.firestore.FieldValue;
  const events = await db
    .collection('events')
    .where('participantUserIds', 'array-contains', uid)
    .get();
  for (const doc of events.docs) {
    await doc.ref.update({ participantUserIds: FieldValue.arrayRemove(uid) });
    await doc.ref.collection('members').doc(uid).delete();
  }
  const groups = await db
    .collection('breed_groups')
    .where('memberIds', 'array-contains', uid)
    .get();
  for (const doc of groups.docs) {
    await doc.ref.update({
      memberIds: FieldValue.arrayRemove(uid),
      memberCount: FieldValue.increment(-1),
    });
    await doc.ref.collection('members').doc(uid).delete();
  }
  const chats = await db
    .collection('chats')
    .where('participantIds', 'array-contains', uid)
    .get();
  for (const doc of chats.docs) {
    await doc.ref.update({
      participantIds: FieldValue.arrayRemove(uid),
      [`unreadByUser.${uid}`]: FieldValue.delete(),
    });
  }
}

/**
 * Deletes everything owned by [uid]. [bucket] is a Storage bucket (or null in
 * tests). Returns a small report for logging.
 */
async function cleanupUserData(db, bucket, uid) {
  if (!uid || typeof uid !== 'string') return { skipped: true };
  const report = {};

  for (const [collection, field] of OWNED) {
    report[`${collection}.${field}`] = await step(`${collection}.${field}`, () =>
      deleteQueryDocs(db, db.collection(collection).where(field, '==', uid)),
    );
  }
  for (const [group, field] of AUTHORED) {
    report[`group:${group}.${field}`] = await step(`group:${group}`, async () => {
      const snap = await db.collectionGroup(group).where(field, '==', uid).get();
      for (const doc of snap.docs) await doc.ref.delete();
      return snap.size;
    });
  }
  // Matches have no single owner field: both users are in `userIds`.
  report.matches = await step('matches', () =>
    deleteQueryDocs(db, db.collection('matches').where('userIds', 'array-contains', uid)),
  );
  await step('memberships', () => leaveMemberships(db, uid));
  // Profile with every subcollection (private, walks, rewards, ledger…).
  await step('user', () => db.recursiveDelete(db.doc(`users/${uid}`)));

  if (bucket) {
    for (const root of STORAGE_ROOTS) {
      await step(`storage:${root}`, () => bucket.deleteFiles({ prefix: `${root}/${uid}/` }));
    }
  }
  return report;
}

/** v1 `auth.user().onDelete` handler. */
async function onUserDeleted(user) {
  const report = await cleanupUserData(
    admin.firestore(),
    admin.storage().bucket(),
    user.uid,
  );
  logger.info('Account data removed', { uid: user.uid, report });
}

module.exports = { cleanupUserData, onUserDeleted, OWNED, AUTHORED, STORAGE_ROOTS };
