// Server-side rewards (Dnevni VauVau izazov).
//
// The app only saves the finished walk (users/{uid}/walks/{walkId}). This
// code – running with admin rights – re-checks the walk, pays XP/points and
// challenge bonuses, and writes the outcome to users/{uid}/reward_results/
// {walkId}. Firestore rules do not let a client write balances, ledger
// entries (except coupon purchases) or progress any more.
//
// Constants mirror lib/features/rewards/domain/reward_rules.dart and
// lib/features/rewards/domain/belgrade_calendar.dart – change both together.
const crypto = require('crypto');
const admin = require('firebase-admin');
const { logger } = require('firebase-functions');

const RULES = {
  xpPerKm: 5,
  pointsPerKm: 5,
  minRewardKm: 1,
  dailyKmPointsCap: 30,
  maxAverageKmh: 7,
  maxWalkSeconds: 4 * 3600,
  claimWindowMs: 48 * 3600 * 1000,
  minProgressMeters: 100,
  maxMeters: 40000,
  // Route checks (server-side, from the stored route points).
  maxStepKmh: 9,
  maxAccuracyM: 30,
  maxGapSeconds: 60,
  minStepMeters: 3,
  // Client distance may exceed the route we can recompute by this factor
  // (the stored route is thinned to ≤ 600 points).
  routeTolerance: 1.1,
  // At least one stored point per this many meters.
  metersPerPoint: 60,
  // Synthetic-route signals.
  minStepsForPattern: 40,
  constantSpeedCv: 0.05,
  constantAccuracyCv: 0.2,
  // Route fingerprint: grid cell (degrees) and the shortest route compared.
  fingerprintCellDeg: 0.0003,
  fingerprintMinCells: 8,
};

// --- Europe/Belgrade calendar (same algorithm as the Dart class) ------------

function belgradeOffsetHours(ms) {
  const d = new Date(ms);
  const month = d.getUTCMonth() + 1;
  const day = d.getUTCDate();
  const lastSunday = day - d.getUTCDay();
  const pastSwitch = lastSunday >= 25 && (day > lastSunday || d.getUTCHours() >= 1);
  const summer =
    (month > 3 && month < 10) ||
    (month === 3 && pastSwitch) ||
    (month === 10 && !pastSwitch);
  return summer ? 2 : 1;
}

function belgradeLocal(ms) {
  return new Date(ms + belgradeOffsetHours(ms) * 3600 * 1000);
}

function keyOf(local) {
  return (
    local.getUTCFullYear() * 10000 +
    (local.getUTCMonth() + 1) * 100 +
    local.getUTCDate()
  );
}

function belgradeDayKey(ms) {
  return keyOf(belgradeLocal(ms));
}

/** Day key of the Monday that starts the Belgrade week. */
function belgradeWeekKey(ms) {
  const local = belgradeLocal(ms);
  const weekday = local.getUTCDay() === 0 ? 7 : local.getUTCDay();
  return keyOf(new Date(local.getTime() - (weekday - 1) * 86400 * 1000));
}

// --- Pure checks ------------------------------------------------------------

function toMillis(value) {
  if (!value) return NaN;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return typeof value === 'number' ? value : NaN;
}

function haversineMeters(a, b) {
  const rad = (deg) => (deg * Math.PI) / 180;
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371000 * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** Points paid for [meters] given what was already paid today. */
function rewardFor(meters, paidTodayPoints) {
  const km = Math.floor(meters / 1000);
  if (km < RULES.minRewardKm) return 0;
  const raw = km * RULES.pointsPerKm;
  const room = RULES.dailyKmPointsCap - paidTodayPoints;
  if (room <= 0) return 0;
  return Math.min(raw, room);
}

/**
 * Recomputes distance and pattern signals from the stored route.
 * Segments are separate runs of the app's own filter (pause, vehicle,
 * signal gap), so steps are only measured inside a segment.
 */
function analyzeRoute(route, startMs, endMs) {
  const result = {
    meters: 0,
    points: 0,
    steps: [],
    accuracies: [],
    fingerprintCells: [],
  };
  if (!Array.isArray(route)) return result;
  let lastCell = null;
  for (const segment of route) {
    const raw = segment && Array.isArray(segment.points) ? segment.points : [];
    let prev = null;
    for (const p of raw) {
      if (
        !p ||
        typeof p.lat !== 'number' ||
        typeof p.lng !== 'number' ||
        typeof p.t !== 'number' ||
        !Number.isFinite(p.lat + p.lng + p.t) ||
        Math.abs(p.lat) > 90 ||
        Math.abs(p.lng) > 180
      ) {
        continue;
      }
      if (p.t < startMs - 60000 || p.t > endMs + 60000) continue;
      if (typeof p.acc === 'number') {
        if (p.acc > RULES.maxAccuracyM) continue;
        result.accuracies.push(p.acc);
      }
      result.points += 1;
      const cell = `${Math.floor(p.lat / RULES.fingerprintCellDeg)}:${Math.floor(
        p.lng / RULES.fingerprintCellDeg,
      )}`;
      if (cell !== lastCell) {
        result.fingerprintCells.push(cell);
        lastCell = cell;
      }
      if (prev) {
        const dt = (p.t - prev.t) / 1000;
        if (dt > 0 && dt <= RULES.maxGapSeconds) {
          const d = haversineMeters(prev, p);
          const kmh = (d / dt) * 3.6;
          if (kmh <= RULES.maxStepKmh) {
            result.meters += d;
            if (d >= RULES.minStepMeters) result.steps.push(kmh);
          }
        }
      }
      prev = p;
    }
  }
  return result;
}

function coefficientOfVariation(values) {
  if (!values.length) return Infinity;
  const mean = values.reduce((a, b) => a + b, 0) / values.length;
  if (mean <= 0) return Infinity;
  const variance =
    values.reduce((a, b) => a + (b - mean) ** 2, 0) / values.length;
  return Math.sqrt(variance) / mean;
}

/** sha256 of the quantised cell sequence: replaying a route repeats it. */
function routeFingerprint(cells) {
  if (cells.length < RULES.fingerprintMinCells) return null;
  return crypto.createHash('sha256').update(cells.join('|')).digest('hex');
}

/**
 * Decides what a saved walk is worth. [createMs] is when the server got the
 * document (an offline walk may arrive late).
 *
 * Returns { status: 'rewardable' | 'ignored' | 'rejected', reason, meters,
 * km, fingerprint }.
 */
function assessWalk(walk, createMs) {
  const reject = (reason) => ({ status: 'rejected', reason, meters: 0, km: 0 });
  const ignore = (reason) => ({ status: 'ignored', reason, meters: 0, km: 0 });
  if (!walk || typeof walk !== 'object') return reject('invalid');
  const startMs = toMillis(walk.startedAt);
  const endMs = toMillis(walk.endedAt);
  const duration = walk.durationSeconds;
  const clientMeters = walk.recognizedMeters;
  if (
    !Number.isFinite(startMs) ||
    !Number.isFinite(endMs) ||
    !Number.isInteger(duration) ||
    !Number.isInteger(clientMeters) ||
    duration <= 0 ||
    clientMeters < 0 ||
    endMs <= startMs
  ) {
    return reject('invalid');
  }
  if (endMs > createMs + 5 * 60 * 1000) return reject('invalid');
  if (endMs < createMs - RULES.claimWindowMs) return reject('expired');
  if (duration > RULES.maxWalkSeconds) return reject('too_long');
  if (endMs - startMs < duration * 1000 - 5000) return reject('invalid');

  const flags = walk.flags && typeof walk.flags === 'object' ? walk.flags : {};
  if (flags.mock === true) return reject('mock_location');
  if (flags.suspicious === true) return reject('suspicious_gps');

  if (clientMeters < RULES.minProgressMeters) return ignore('too_short');
  if (clientMeters > RULES.maxMeters) return reject('invalid');

  const route = analyzeRoute(walk.route, startMs, endMs);
  if (route.points < 2 || route.meters <= 0) return reject('no_route');
  const meters = Math.min(
    clientMeters,
    Math.floor(route.meters * RULES.routeTolerance),
  );
  if (meters < RULES.minProgressMeters) return ignore('too_short');
  if (route.points < Math.max(2, meters / RULES.metersPerPoint)) {
    return reject('route_sparse');
  }
  if (meters * 3600 > duration * RULES.maxAverageKmh * 1000) {
    return reject('too_fast_average');
  }
  if (route.steps.length >= RULES.minStepsForPattern) {
    const cv = coefficientOfVariation(route.steps);
    const constantAccuracy =
      route.accuracies.length >= RULES.minStepsForPattern &&
      new Set(route.accuracies).size <= 1;
    if (
      cv < RULES.constantSpeedCv ||
      (constantAccuracy && cv < RULES.constantAccuracyCv)
    ) {
      return reject('suspicious_route');
    }
  }
  return {
    status: 'rewardable',
    reason: '',
    meters,
    km: Math.floor(meters / 1000),
    fingerprint: routeFingerprint(route.fingerprintCells),
  };
}

// --- Firestore writes -------------------------------------------------------

function walkReason(km, points) {
  if (points > 0) return `Šetnja: ${km} km`;
  return km >= 1 ? `Šetnja: ${km} km (dnevni limit dostignut)` : 'Šetnja ispod 1 km';
}

/** Challenge met by the day/week progress documents. */
function challengeMet(challenge, progress) {
  const meters = Number(progress.meters) || 0;
  const walks = Number(progress.walks) || 0;
  const target = Number(challenge.target) || 0;
  return challenge.metric === 'walks' ? walks >= target : meters >= target * 1000;
}

/**
 * Checks and pays one walk. Idempotent: a second run (retry, old client
 * that paid first) changes nothing and reports what was paid before.
 */
async function awardWalk(db, { uid, walkId, walk, createMs }) {
  const FieldValue = admin.firestore.FieldValue;
  const userRef = db.doc(`users/${uid}`);
  const resultRef = userRef.collection('reward_results').doc(walkId);
  const ledgerRef = userRef.collection('reward_ledger').doc(`walk_${walkId}`);
  const summaryRef = userRef.collection('rewards').doc('summary');
  const assessment = assessWalk(walk, createMs);

  const outcome = await db.runTransaction(async (tx) => {
    const existing = await tx.get(resultRef);
    if (existing.exists) return { duplicate: true, data: existing.data() };

    if (assessment.status !== 'rewardable') {
      const data = {
        status: assessment.status,
        reason: assessment.reason,
        createdAt: FieldValue.serverTimestamp(),
      };
      tx.set(resultRef, data);
      return { data };
    }

    const endMs = toMillis(walk.endedAt);
    const dayKey = belgradeDayKey(endMs);
    const weekKey = belgradeWeekKey(endMs);
    const dayRef = userRef.collection('rewards').doc(`d${dayKey}`);
    const weekRef = userRef.collection('rewards').doc(`w${weekKey}`);
    const fingerprintRef = assessment.fingerprint
      ? db.doc(`route_fingerprints/${assessment.fingerprint}`)
      : null;
    const reads = [ledgerRef, summaryRef, dayRef, weekRef];
    if (fingerprintRef) reads.push(fingerprintRef);
    const snaps = await tx.getAll(...reads);
    const [ledger, summary, day, week] = snaps;
    const fingerprint = fingerprintRef ? snaps[4] : null;

    const summaryData = summary.exists ? summary.data() : {};
    const xpBefore = Number(summaryData.xp) || 0;

    if (ledger.exists) {
      // An older app version paid this walk itself: just report it.
      const paid = ledger.data();
      const data = {
        status: 'rewarded',
        reason: '',
        xp: Number(paid.xp) || 0,
        points: Number(paid.points) || 0,
        capped: false,
        km: assessment.km,
        meters: assessment.meters,
        dayKey,
        weekKey,
        xpBefore: xpBefore - (Number(paid.xp) || 0),
        createdAt: FieldValue.serverTimestamp(),
      };
      tx.set(resultRef, data);
      return { data };
    }

    if (
      fingerprint &&
      fingerprint.exists &&
      fingerprint.get('walkId') !== walkId
    ) {
      const data = {
        status: 'rejected',
        reason: 'duplicate_route',
        createdAt: FieldValue.serverTimestamp(),
      };
      tx.set(resultRef, data);
      return { data };
    }

    const dayData = day.exists ? day.data() : {};
    const weekData = week.exists ? week.data() : {};
    const km = assessment.km;
    const points = rewardFor(assessment.meters, Number(dayData.walkPoints) || 0);
    const counted = km >= RULES.minRewardKm ? 1 : 0;
    const entryId = `walk_${walkId}`;

    tx.set(ledgerRef, {
      type: 'walk',
      walkId,
      km,
      dayKey,
      weekKey,
      xp: points,
      points,
      reason: walkReason(km, points),
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(
      summaryRef,
      {
        xp: FieldValue.increment(points),
        points: FieldValue.increment(points),
        lastEntryId: entryId,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    const progress = (before) => ({
      meters: (Number(before.meters) || 0) + assessment.meters,
      walks: (Number(before.walks) || 0) + counted,
      walkPoints: (Number(before.walkPoints) || 0) + points,
      lastEntryId: entryId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(dayRef, progress(dayData), { merge: true });
    tx.set(weekRef, progress(weekData), { merge: true });
    if (fingerprintRef && !fingerprint.exists) {
      tx.set(fingerprintRef, {
        uid,
        walkId,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    const data = {
      status: 'rewarded',
      reason: '',
      xp: points,
      points,
      capped: points < km * RULES.pointsPerKm,
      km,
      meters: assessment.meters,
      dayKey,
      weekKey,
      xpBefore,
      createdAt: FieldValue.serverTimestamp(),
    };
    tx.set(resultRef, data);
    return { data, dayKey, weekKey };
  });

  if (outcome.duplicate || outcome.data.status !== 'rewarded') {
    return { ...outcome, challenges: [] };
  }
  const challenges = await awardChallenges(db, {
    uid,
    dayKey: outcome.data.dayKey,
    weekKey: outcome.data.weekKey,
  });
  if (challenges.length) {
    const extraXp = challenges.reduce((sum, c) => sum + c.xp, 0);
    await resultRef.update({ challenges, challengeXp: extraXp });
  }
  return { ...outcome, challenges };
}

/** Pays every active challenge met for the given day / week (once each). */
async function awardChallenges(db, { uid, dayKey, weekKey }) {
  const FieldValue = admin.firestore.FieldValue;
  const userRef = db.doc(`users/${uid}`);
  const summaryRef = userRef.collection('rewards').doc('summary');
  const [dayDoc, weekDoc, challenges] = await Promise.all([
    userRef.collection('rewards').doc(`d${dayKey}`).get(),
    userRef.collection('rewards').doc(`w${weekKey}`).get(),
    db.collection('reward_challenges').where('isActive', '==', true).get(),
  ]);
  const progressOf = (challenge) =>
    (challenge.period === 'weekly' ? weekDoc : dayDoc).data() || {};
  const paid = [];
  for (const doc of challenges.docs) {
    const challenge = doc.data();
    if (!challengeMet(challenge, progressOf(challenge))) continue;
    const periodKey = challenge.period === 'weekly' ? weekKey : dayKey;
    const entryId = `ch_${doc.id}_${periodKey}`;
    const ledgerRef = userRef.collection('reward_ledger').doc(entryId);
    const xp = Number(challenge.rewardXp) || 0;
    const points = Number(challenge.rewardPoints) || 0;
    const created = await db.runTransaction(async (tx) => {
      if ((await tx.get(ledgerRef)).exists) return false;
      tx.set(ledgerRef, {
        type: 'challenge',
        challengeId: doc.id,
        periodKey,
        xp,
        points,
        reason: `Izazov: ${challenge.title || doc.id}`,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.set(
        summaryRef,
        {
          xp: FieldValue.increment(xp),
          points: FieldValue.increment(points),
          lastEntryId: entryId,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return true;
    });
    if (created) {
      paid.push({ id: doc.id, title: challenge.title || doc.id, xp, points });
    }
  }
  return paid;
}

/** onDocumentCreated handler for users/{uid}/walks/{walkId}. */
async function rewardWalkHandler(event) {
  const snap = event.data;
  if (!snap) return;
  const { uid, walkId } = event.params;
  const createMs = snap.createTime ? snap.createTime.toMillis() : Date.now();
  try {
    const result = await awardWalk(admin.firestore(), {
      uid,
      walkId,
      walk: snap.data(),
      createMs,
    });
    logger.info('Walk processed', {
      uid,
      walkId,
      status: result.data && result.data.status,
      reason: result.data && result.data.reason,
      points: result.data && result.data.points,
    });
  } catch (error) {
    logger.error('Walk reward failed', { uid, walkId, error: String(error) });
  }
}

module.exports = {
  RULES,
  belgradeOffsetHours,
  belgradeDayKey,
  belgradeWeekKey,
  rewardFor,
  analyzeRoute,
  assessWalk,
  routeFingerprint,
  awardWalk,
  awardChallenges,
  rewardWalkHandler,
};
