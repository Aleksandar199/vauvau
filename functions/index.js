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
