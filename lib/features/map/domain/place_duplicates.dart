import '../../../core/constants/serbia_locations.dart';
import '../../../core/geo/geo.dart';
import 'map_city.dart';
import 'map_place.dart';
import 'models/poi_model.dart';

/// What duplicate detection compares for a place (seed, `pois` or `places`).
class PlaceIdentity {
  const PlaceIdentity({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceIdentity.ofPoi(PoiModel poi) => PlaceIdentity(
        id: poi.id,
        name: poi.name,
        address: poi.address,
        cityId: poi.resolvedCityId,
        latitude: poi.latitude,
        longitude: poi.longitude,
      );

  factory PlaceIdentity.ofPlace(MapPlace place) => PlaceIdentity(
        id: place.id,
        name: place.name,
        address: place.neighborhood,
        cityId: place.cityId.isNotEmpty ? place.cityId : place.city.cityId,
        latitude: place.latitude,
        longitude: place.longitude,
      );

  final String id;
  final String name;
  final String address;
  final String cityId;
  final double latitude;
  final double longitude;
}

/// Duplicate detection for map places.
///
/// Two entries are the same place only when they are in the same city, have
/// the same normalized name and either the same normalized address or pins
/// within [nearbyMeters]. Different businesses at one address (e.g. shops in
/// a mall) or similar names at different addresses are NOT duplicates.
abstract final class PlaceDuplicates {
  static const double nearbyMeters = 75;

  /// Folded name without punctuation and repeated spaces.
  static String normalizeName(String value) => _clean(value);

  /// Folded address without the city name, „ulica“ and punctuation, so
  /// „Trg Paje Kujundžića 2/a, Subotica“ == „trg paje kujundzica 2a“.
  static String normalizeAddress(String value, {String cityId = ''}) {
    var text = _clean(value);
    final city = SerbiaLocations.cityById(cityId)?.name;
    if (city != null) {
      text = text.replaceAll(_clean(city), ' ');
    }
    text = text.replaceAll(RegExp(r'\bulica\b|\bul\b'), ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim().replaceAllMapped(
          RegExp(r'(\d) ([a-z])\b'),
          (m) => '${m[1]}${m[2]}',
        );
  }

  static String normalizeCityId(String cityId) =>
      cityId.trim().toLowerCase().replaceAll('_', '-');

  static bool isDuplicate(PlaceIdentity a, PlaceIdentity b) {
    if (normalizeCityId(a.cityId) != normalizeCityId(b.cityId)) {
      return false;
    }
    final nameA = normalizeName(a.name);
    if (nameA.isEmpty || nameA != normalizeName(b.name)) {
      return false;
    }
    final addressA = normalizeAddress(a.address, cityId: a.cityId);
    if (addressA.isNotEmpty &&
        addressA == normalizeAddress(b.address, cityId: b.cityId)) {
      return true;
    }
    final meters = haversineKm(
          GeoCoord(a.latitude, a.longitude),
          GeoCoord(b.latitude, b.longitude),
        ) *
        1000;
    return meters <= nearbyMeters;
  }

  /// First entry of [existing] (other id) that [candidate] duplicates.
  static PlaceIdentity? findDuplicate(
    PlaceIdentity candidate,
    Iterable<PlaceIdentity> existing,
  ) {
    for (final other in existing) {
      if (other.id != candidate.id && isDuplicate(candidate, other)) {
        return other;
      }
    }
    return null;
  }

  /// Keeps the first of each duplicate group (stable order, ids preserved).
  static List<PoiModel> dedupe(Iterable<PoiModel> pois) {
    final kept = <PoiModel>[];
    // Only same city + same name can match, so compare within that bucket.
    final buckets = <String, List<PlaceIdentity>>{};
    for (final poi in pois) {
      final identity = PlaceIdentity.ofPoi(poi);
      final key = '${normalizeCityId(identity.cityId)}|'
          '${normalizeName(identity.name)}';
      final bucket = buckets.putIfAbsent(key, () => []);
      if (findDuplicate(identity, bucket) != null) {
        continue;
      }
      kept.add(poi);
      bucket.add(identity);
    }
    return kept;
  }

  static String _clean(String value) {
    return SerbiaLocations.foldName(value)
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
