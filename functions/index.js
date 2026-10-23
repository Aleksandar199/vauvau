// VauVau Cloud Functions.
//
// sendQueuedPush: the app writes every push it wants to send to
// users/{uid}/fcmInbox/{id} (see writeQueuedNotification in
// lib/features/notifications/data/push_notification_gateway.dart; the rules
// check sender, blocking, text length and server time). Without this function
// nobody delivered those, so messages never reached a phone whose app was
// closed. It sends one FCM message to the recipient's token
// (users/{uid}/private/account.fcmToken) and deletes the queue entry.
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Same channel and tag scheme as NotificationService (alertsChannelId,
// alertTagFor), so a later local alert for the same chat replaces this one.
const CHANNEL_ID = 'vauvau_alerts';
const MAX_TEXT = 200;

const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

function clip(value) {
  const text = typeof value === 'string' ? value.trim() : '';
  return text.length <= MAX_TEXT ? text : `${text.slice(0, MAX_TEXT - 1)}…`;
}

/** FCM data values must be strings; drop empty ones. */
function stringData(item) {
  const data = {};
  const merge = (source) => {
    if (!source || typeof source !== 'object') return;
    for (const [key, value] of Object.entries(source)) {
      if (value === null || value === undefined) continue;
      if (typeof value === 'object') continue;
      const text = String(value).trim();
      if (text) data[key] = text;
    }
  };
  merge(item.data);
  merge({
    type: item.type,
    title: clip(item.title),
    body: clip(item.body),
    dogId: item.dogId,
    conversationId: item.conversationId,
    groupId: item.groupId,
    eventId: item.eventId,
    fromUserId: item.fromUserId,
  });
  // For the recipient, the peer is the sender.
  if (item.fromUserId) data.peerUserId = String(item.fromUserId);
  return data;
}

function alertTag(data) {
  const type = data.type || 'alert';
  const id = data.conversationId || data.groupId || data.eventId || '';
  return id ? `vauvau_${type}_${id}` : `vauvau_${type}`;
}

exports.sendQueuedPush = onDocumentCreated(
  'users/{uid}/fcmInbox/{msgId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const uid = event.params.uid;
    const item = snap.data() || {};
    const db = admin.firestore();
    const accountRef = db.doc(`users/${uid}/private/account`);
    try {
      const account = await accountRef.get();
      const token = account.get('fcmToken');
      if (typeof token !== 'string' || !token) {
        logger.info('No FCM token', { uid });
        return;
      }
      const data = stringData(item);
      const title = clip(item.title) || 'VauVau';
      const body = clip(item.body);
      try {
        await admin.messaging().send({
          token,
          notification: { title, body },
          data,
          android: {
            priority: 'high',
            notification: {
              channelId: CHANNEL_ID,
              tag: alertTag(data),
              sound: 'default',
            },
          },
          apns: { payload: { aps: { sound: 'default' } } },
        });
      } catch (error) {
        if (INVALID_TOKEN_CODES.has(error && error.code)) {
          // Uninstalled app / rotated token: stop sending to it.
          await accountRef.update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
          logger.info('Removed invalid FCM token', { uid });
          return;
        }
        // No retry: a late duplicate push is worse than a missed one.
        logger.error('FCM send failed', { uid, code: error && error.code });
      }
    } finally {
      // The queue entry is only a hand-off; nothing else reads it.
      await snap.ref.delete().catch(() => {});
    }
  },
);

// --- Group / event chat push ------------------------------------------------
// sendGroupMessagePush / sendEventMessagePush: a new message in a group or
// event chat goes to every member except the sender, members who muted the
// chat (members/{uid}.muted == true, set in the app's chat header) and
// members who blocked the sender. One notification per chat: the Android tag
// (vauvau_group_{id} / vauvau_event_{id}) replaces the previous one.

function messagePreview(message) {
  const text = typeof message.text === 'string' ? message.text.trim() : '';
  if (message.type === 'walk_invite') {
    const place = message.walkLocationName || text;
    return place ? `Poziv na šetnju: ${place}` : 'Poziv na šetnju';
  }
  if (text) return text;
  if (message.imageUrl) return '📷 Fotografija';
  return 'Nova poruka';
}

/** Members of the thread who should get a push for [senderId]'s message. */
async function threadRecipients(parentRef, members, senderId) {
  const db = admin.firestore();
  const candidates = [
    ...new Set(
      (Array.isArray(members) ? members : []).filter(
        (uid) => typeof uid === 'string' && uid && uid !== senderId,
      ),
    ),
  ];
  if (!candidates.length) return [];
  const mutedSnap = await parentRef
    .collection('members')
    .where('muted', '==', true)
    .get();
  const muted = new Set(mutedSnap.docs.map((doc) => doc.id));
  const unmuted = candidates.filter((uid) => !muted.has(uid));
  if (!unmuted.length) return [];
  const blocks = senderId
    ? await db.getAll(
        ...unmuted.map((uid) =>
          db.doc(`users/${uid}/blocked_users/${senderId}`),
        ),
      )
    : [];
  return unmuted.filter((_, i) => !(blocks[i] && blocks[i].exists));
}

/** Sends to each recipient's token; drops tokens FCM reports as invalid. */
async function sendToUsers(uids, build) {
  if (!uids.length) return;
  const db = admin.firestore();
  const accounts = await db.getAll(
    ...uids.map((uid) => db.doc(`users/${uid}/private/account`)),
  );
  const targets = [];
  accounts.forEach((account, i) => {
    const token = account.exists ? account.get('fcmToken') : null;
    if (typeof token === 'string' && token) {
      targets.push({ uid: uids[i], token, ref: account.ref });
    }
  });
  for (let start = 0; start < targets.length; start += 500) {
    const chunk = targets.slice(start, start + 500);
    const result = await admin
      .messaging()
      .sendEach(chunk.map((target) => build(target.token)));
    await Promise.all(
      result.responses.map(async (response, i) => {
        if (response.success) return;
        const code = response.error && response.error.code;
        if (INVALID_TOKEN_CODES.has(code)) {
          await chunk[i].ref
            .update({ fcmToken: admin.firestore.FieldValue.delete() })
            .catch(() => {});
        } else {
          logger.error('FCM send failed', { uid: chunk[i].uid, code });
        }
      }),
    );
  }
}

async function pushThreadMessage(event, { kind, membersField }) {
  const snap = event.data;
  if (!snap) return;
  const message = snap.data() || {};
  const threadId = event.params.threadId;
  const parentRef = snap.ref.parent.parent;
  const parent = await parentRef.get();
  if (!parent.exists) return;
  const thread = parent.data() || {};
  const senderId =
    typeof message.senderId === 'string' ? message.senderId : '';
  const recipients = await threadRecipients(
    parentRef,
    thread[membersField],
    senderId,
  );
  if (!recipients.length) return;
  const title = clip(thread.title) || 'VauVau';
  const sender =
    typeof message.senderName === 'string' && message.senderName.trim()
      ? message.senderName.trim()
      : 'Neko';
  const body = clip(`${sender}: ${messagePreview(message)}`);
  const idKey = kind === 'group' ? 'groupId' : 'eventId';
  const data = {
    type: kind,
    title,
    body,
    [idKey]: threadId,
    ...(senderId ? { fromUserId: senderId } : {}),
  };
  logger.info('Thread push', {
    kind,
    threadId,
    recipients: recipients.join(','),
  });
  await sendToUsers(recipients, (token) => ({
    token,
    notification: { title, body },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: CHANNEL_ID,
        tag: alertTag(data),
        sound: 'default',
      },
    },
    apns: { payload: { aps: { sound: 'default' } } },
  }));
}

exports.sendGroupMessagePush = onDocumentCreated(
  'breed_groups/{threadId}/messages/{messageId}',
  (event) =>
    pushThreadMessage(event, { kind: 'group', membersField: 'memberIds' }),
);

exports.sendEventMessagePush = onDocumentCreated(
  'events/{threadId}/messages/{messageId}',
  (event) =>
    pushThreadMessage(event, {
      kind: 'event',
      membersField: 'participantUserIds',
    }),
);

// --- Rewards (Dnevni VauVau izazov) ------------------------------------------
// rewardWalk: the app only saves the finished walk; this re-checks it (route,
// speed, duplicates), pays XP / points / challenge bonuses with admin rights
// and writes the outcome to users/{uid}/reward_results/{walkId}. See
// rewards.js. The rules no longer let clients write balances.
const { rewardWalkHandler } = require('./rewards');

exports.rewardWalk = onDocumentCreated(
  'users/{uid}/walks/{walkId}',
  rewardWalkHandler,
);

// cleanupDeletedUser: when an Auth account disappears (the user deleted it in
// the app, or an admin did in the console) everything that still belongs to
// the uid is removed – dogs, posts, stories, chat messages, files. See
// account.js. 1st-gen trigger: Auth events do not exist in 2nd gen.
const functionsV1 = require('firebase-functions/v1');
const { onUserDeleted } = require('./account');

exports.cleanupDeletedUser = functionsV1.auth.user().onDelete(onUserDeleted);
