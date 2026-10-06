import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodeSuggestion {
  const GeocodeSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

/// OpenStreetMap Nominatim geocoder (no Google Places key required).
class AddressGeocoder {
  AddressGeocoder({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<GeocodeSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': trimmed,
      'format': 'json',
      'addressdetails': '0',
      'limit': '6',
      'countrycodes': 'rs',
    });

    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'VauVauApp/1.0 (map place admin)',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    final results = <GeocodeSuggestion>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final lat = double.tryParse('${item['lat']}');
      final lon = double.tryParse('${item['lon']}');
      final label = (item['display_name'] as String? ?? '').trim();
      if (lat == null || lon == null || label.isEmpty) continue;
      results.add(
        GeocodeSuggestion(label: label, latitude: lat, longitude: lon),
      );
    }
    return results;
  }
}
