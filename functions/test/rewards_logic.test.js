// node --test test/rewards_logic.test.js  (no emulator needed)
const { describe, test } = require('node:test');
const assert = require('node:assert/strict');
const {
  RULES,
  belgradeDayKey,
  belgradeOffsetHours,
  belgradeWeekKey,
  assessWalk,
  rewardFor,
  effectiveRules,
  routeFingerprint,
} = require('../rewards');
const { START, M, naturalRoute, walkDoc } = require('./route_fixtures');

const at = (iso) => Date.parse(iso);

describe('Belgrade calendar (same cases as the Dart tests)', () => {
  test('summer and winter time', () => {
    assert.equal(belgradeOffsetHours(at('2026-07-01T00:00:00Z')), 2);
    assert.equal(belgradeOffsetHours(at('2026-01-15T00:00:00Z')), 1);
    assert.equal(belgradeOffsetHours(at('2026-03-29T00:59:00Z')), 1);
    assert.equal(belgradeOffsetHours(at('2026-03-29T01:00:00Z')), 2);
    assert.equal(belgradeOffsetHours(at('2026-10-25T00:59:00Z')), 2);
    assert.equal(belgradeOffsetHours(at('2026-10-25T01:00:00Z')), 1);
  });

  test('the day changes at Belgrade midnight', () => {
    assert.equal(belgradeDayKey(at('2026-10-16T22:30:00Z')), 20261017);
    assert.equal(belgradeDayKey(at('2026-10-16T21:59:00Z')), 20261016);
    assert.equal(belgradeDayKey(at('2026-12-01T22:30:00Z')), 20261201);
    assert.equal(belgradeDayKey(at('2026-12-01T23:30:00Z')), 20261202);
  });

  test('the week starts on Monday', () => {
    assert.equal(belgradeWeekKey(at('2026-10-16T10:00:00Z')), 20261012);
    assert.equal(belgradeWeekKey(at('2026-10-18T21:30:00Z')), 20261012);
    assert.equal(belgradeWeekKey(at('2026-10-18T22:30:00Z')), 20261019);
  });
});

describe('rewardFor', () => {
  test('5 points per whole km, floored, daily cap 30', () => {
    assert.equal(rewardFor(999, 0), 0);
    assert.equal(rewardFor(1000, 0), 5);
    assert.equal(rewardFor(2999, 0), 10);
    assert.equal(rewardFor(9000, 0), 30);
    assert.equal(rewardFor(4000, 20), 10);
    assert.equal(rewardFor(4000, 30), 0);
  });
});

describe('assessWalk', () => {
  const route = naturalRoute({ meters: 2600, seed: 7 });
  const createMs = route.endMs + 1000;

  test('an honest walk is rewardable and keeps its distance', () => {
    const result = assessWalk(walkDoc({ route }), createMs);
    assert.equal(result.status, 'rewardable');
    assert.equal(result.km, 2);
    assert.ok(result.meters >= 2500 && result.meters <= route.meters);
    assert.ok(result.fingerprint);
  });

  test('a claimed distance above the route is cut to the route', () => {
    const result = assessWalk(walkDoc({ route, meters: 9000 }), createMs);
    assert.equal(result.status, 'rewardable');
    // The app claimed 9 km; the route supports about 2.6 km.
    assert.ok(result.meters <= Math.floor(route.meters * 1.2));
    assert.ok(result.km <= 3);
  });

  test('flags from the app: mock location and suspicious GPS', () => {
    assert.equal(
      assessWalk(walkDoc({ route, flags: { mock: true } }), createMs).reason,
      'mock_location',
    );
    assert.equal(
      assessWalk(walkDoc({ route, flags: { suspicious: true } }), createMs).reason,
      'suspicious_gps',
    );
  });

  test('a forged route with a constant speed is rejected', () => {
    const points = [];
    for (let i = 0; i <= 500; i++) {
      points.push({
        lat: 45.25 + i * 6 * M,
        lng: 19.84,
        t: START + i * 5000,
        acc: 4 + (i % 5),
      });
    }
    const forged = { points, meters: 3000, endMs: START + 500 * 5000 };
    const result = assessWalk(walkDoc({ route: forged }), forged.endMs + 1000);
    assert.equal(result.status, 'rejected');
    assert.equal(result.reason, 'suspicious_route');
  });

  test('constant accuracy plus a very regular speed is rejected', () => {
    const regular = naturalRoute({
      meters: 3000,
      seed: 3,
      accuracy: () => 5,
    });
    // Make the speed regular too (6 m every 5 s with tiny noise).
    regular.points.forEach((p, i) => {
      p.lat = 45.25 + (i * 6 + (i % 2) * 0.5) * M;
      p.lng = 19.84;
    });
    const result = assessWalk(walkDoc({ route: regular }), regular.endMs + 1000);
    assert.equal(result.reason, 'suspicious_route');
  });

  test('no route, or a route that is far too sparse', () => {
    const none = walkDoc({ route });
    none.route = [];
    assert.equal(assessWalk(none, createMs).reason, 'no_route');

    // 40 points 90 m apart a minute apart: plausible speed, but 3.5 km
    // would need about 58 stored points.
    const points = [];
    for (let i = 0; i < 40; i++) {
      points.push({ lat: 45.25 + i * 90 * M, lng: 19.84, t: START + i * 60000, acc: 5 + (i % 6) });
    }
    const sparse = { points, meters: 3510, endMs: START + 39 * 60000 };
    assert.equal(assessWalk(walkDoc({ route: sparse }), sparse.endMs + 1000).reason, 'route_sparse');
  });

  test('average faster than 7 km/h and walks longer than 4 h', () => {
    const fastPoints = [];
    let north = 0;
    for (let i = 0; i <= 120; i++) {
      north += i % 2 ? 11 : 12.5; // 7.9â€“9 km/h: fast, but not a vehicle
      fastPoints.push({
        lat: 45.25 + north * M,
        lng: 19.84,
        t: START + i * 5000,
        acc: 4 + (i % 7),
      });
    }
    const fast = { points: fastPoints, meters: 1440, endMs: START + 600000 };
    assert.equal(assessWalk(walkDoc({ route: fast }), fast.endMs + 1000).reason, 'too_fast_average');

    const long = walkDoc({ route, durationSeconds: 5 * 3600 });
    assert.equal(assessWalk(long, createMs).reason, 'too_long');
  });

  test('timing: late offline upload, expired, future and inconsistent', () => {
    assert.equal(assessWalk(walkDoc({ route }), route.endMs + 20 * 3600e3).status, 'rewardable');
    assert.equal(assessWalk(walkDoc({ route }), route.endMs + 49 * 3600e3).reason, 'expired');
    assert.equal(assessWalk(walkDoc({ route }), route.endMs - 20 * 60e3).reason, 'invalid');
    const lying = walkDoc({ route, durationSeconds: 99999 });
    assert.equal(assessWalk(lying, createMs).status, 'rejected');
  });

  test('under 100 m is ignored, not punished', () => {
    const tiny = naturalRoute({ meters: 60, seed: 5 });
    const result = assessWalk(walkDoc({ route: tiny }), tiny.endMs + 1000);
    assert.equal(result.status, 'ignored');
    assert.equal(result.reason, 'too_short');
  });

  test('garbage input never throws', () => {
    for (const bad of [null, undefined, {}, { route: 5 }, { recognizedMeters: 'x' }]) {
      assert.equal(assessWalk(bad, createMs).status, 'rejected');
    }
  });
});

describe('route fingerprint', () => {
  test('same route â†’ same hash, other route â†’ other hash, short â†’ none', () => {
    const a = naturalRoute({ meters: 2000, seed: 1 });
    const same = naturalRoute({ meters: 2000, seed: 1 });
    const other = naturalRoute({ meters: 2000, seed: 1, lat: 45.30 });
    const cells = (r) => {
      const result = assessWalk(walkDoc({ route: r }), r.endMs + 1000);
      return result.fingerprint;
    };
    assert.equal(cells(a), cells(same));
    assert.notEqual(cells(a), cells(other));
    assert.equal(routeFingerprint(['1:1', '1:2']), null);
  });
});

describe('server-driven rules (app_config/rewards)', () => {
  test('missing config keeps the built-in rules and rewards stay on', () => {
    const cfg = effectiveRules(null);
    assert.equal(cfg.enabled, true);
    assert.equal(cfg.rules.pointsPerKm, RULES.pointsPerKm);
  });

  test('admin overrides apply and are clamped', () => {
    const cfg = effectiveRules({ pointsPerKm: 8, dailyKmPointsCap: 99999, minRewardKm: 0 });
    assert.equal(cfg.rules.pointsPerKm, 8);
    assert.equal(cfg.rules.dailyKmPointsCap, 500);
    assert.equal(cfg.rules.minRewardKm, 1);
    assert.equal(rewardFor(2000, 0, cfg.rules), 16);
  });

  test('kill switch and garbage values', () => {
    assert.equal(effectiveRules({ enabled: false }).enabled, false);
    assert.equal(effectiveRules({ pointsPerKm: 'abc' }).rules.pointsPerKm, RULES.pointsPerKm);
  });
});
