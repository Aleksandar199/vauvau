// Walk documents for the rewards tests (shared by the logic and the
// emulator tests).
const START = Date.UTC(2026, 9, 22, 8, 0, 0); // 22.10.2026 08:00 UTC
const M = 1 / 111195; // 1 m of latitude in degrees

/** A tiny deterministic pseudo-random generator (no flaky tests). */
function rng(seed) {
  let s = seed >>> 0;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

/**
 * A route like a real phone records it: step length (speed) and accuracy
 * vary. [meters] walked north in one segment, one point every 5 s.
 */
function naturalRoute({
  meters,
  seed = 1,
  startMs = START,
  lat = 45.25,
  lng = 19.84,
  stepMs = 5000,
  accuracy = (rand) => 3 + rand() * 6,
}) {
  const rand = rng(seed);
  const points = [];
  let north = 0;
  let t = startMs;
  points.push({ lat, lng, t, acc: accuracy(rand) });
  while (north < meters) {
    // 4–9 m per 5 s = 2.9–6.5 km/h
    north += 4 + rand() * 5;
    t += stepMs;
    points.push({
      lat: lat + north * M,
      lng: lng + (rand() - 0.5) * 2 * M,
      t,
      acc: accuracy(rand),
    });
  }
  return { points, meters: Math.round(north), endMs: t };
}

/** A walk document as the app saves it. */
function walkDoc({ route, meters, durationSeconds, flags = {}, endMs }) {
  const end = endMs ?? route.endMs;
  return {
    recognizedMeters: meters ?? route.meters,
    durationSeconds: durationSeconds ?? Math.ceil((end - route.points[0].t) / 1000),
    startedAt: new Date(route.points[0].t),
    endedAt: new Date(end),
    route: [{ points: route.points }],
    flags: { vehicle: false, mock: false, approximate: false, recovered: false, ...flags },
  };
}

module.exports = { START, M, rng, naturalRoute, walkDoc };
