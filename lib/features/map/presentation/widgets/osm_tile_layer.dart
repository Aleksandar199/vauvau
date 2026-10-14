import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// Shared OSM client — limits concurrent opens so offline / flaky networks
/// do not flood the isolate with unhandled [SocketException]s.
final http.Client _osmHttpClient = RetryClient(
  http.Client(),
  retries: 1,
  when: (response) => response.statusCode >= 500,
);

/// Shared OSM raster layer: built-in disk cache + soft-fail offline tiles.
TileLayer buildOsmTileLayer({
  double maxZoom = 19,
  int maxNativeZoom = 19,
}) {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.vauvau.app',
    maxZoom: maxZoom,
    maxNativeZoom: maxNativeZoom,
    // Built-in flutter_map cache (fm_cache under the OS cache dir).
    tileProvider: NetworkTileProvider(
      httpClient: _osmHttpClient,
      silenceExceptions: true,
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 256 * 1000 * 1000, // 256 MB
        overrideFreshAge: const Duration(days: 7),
      ),
    ),
    // Swallow tile fetch errors (offline / OSM rate limit) — never crash.
    errorTileCallback: (tile, error, stackTrace) {
      if (kDebugMode) {
        debugPrint('OSM tile error ${tile.coordinates}: $error');
      }
    },
  );
}
