import 'dart:math' as math;

import '../constants/serbia_locations.dart';

class GeoCoord {
  const GeoCoord(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    return other is GeoCoord &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  static const noviSad = GeoCoord(45.2551, 19.8451);
  static const belgrade = GeoCoord(44.8176, 20.4569);
  static const nis = GeoCoord(43.3209, 21.8958);
  static const kragujevac = GeoCoord(44.0128, 20.9114);
  // OSM/Nominatim center of the city (see SeedCities).
  static const zrenjanin = GeoCoord(45.3803, 20.3908);
  static const subotica = GeoCoord(46.1002, 19.6653);

  static GeoCoord forCityName(String location) {
    final known = SerbiaLocations.cityIdForLabel(location);
    if (known == SerbiaLocations.zrenjaninId ||
        known == SerbiaLocations.suboticaId) {
      return forCityId(known!);
    }
    final lower = location.trim().toLowerCase();
    if (lower.startsWith('beograd')) {
      return belgrade;
    }
    if (lower.startsWith('niš') || lower.startsWith('nis')) {
      return nis;
    }
    if (lower.startsWith('kragujevac')) {
      return kragujevac;
    }
    return noviSad;
  }

  static GeoCoord forCityId(String cityId) {
    return switch (cityId.trim().toLowerCase()) {
      'beograd' || 'belgrade' => belgrade,
      'nis' || 'niš' => nis,
      'kragujevac' => kragujevac,
      'zrenjanin' => zrenjanin,
      'subotica' => subotica,
      _ => noviSad,
    };
  }
}

double haversineKm(GeoCoord a, GeoCoord b) {
  const earthKm = 6371.0;
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h = sinLat * sinLat +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          sinLng *
          sinLng;
  return 2 * earthKm * math.asin(math.min(1, math.sqrt(h)));
}

double _rad(double degrees) => degrees * math.pi / 180;

abstract final class GeoHash {
  static const alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';

  static const _neighbor = {
    'n': ['p0r21436x8zb9dcf5h7kjnmqesgutwvy', 'bc01fg45238967deuvhjyznpkmstqrwx'],
    's': ['14365h7k9dcfesgujnmqp0r2twvyx8zb', '238967debc01fg45kmstqrwxuvhjyznp'],
    'e': ['bc01fg45238967deuvhjyznpkmstqrwx', 'p0r21436x8zb9dcf5h7kjnmqesgutwvy'],
    'w': ['238967debc01fg45kmstqrwxuvhjyznp', '14365h7k9dcfesgujnmqp0r2twvyx8zb'],
  };

  static const _border = {
    'n': ['prxz', 'bcfguvyz'],
    's': ['028b', '0145hjnp'],
    'e': ['bcfguvyz', 'prxz'],
    'w': ['0145hjnp', '028b'],
  };

  static String encode(double latitude, double longitude, [int precision = 7]) {
    var minLat = -90.0;
    var maxLat = 90.0;
    var minLng = -180.0;
    var maxLng = 180.0;
    final buffer = StringBuffer();
    var bit = 0;
    var ch = 0;
    var lngBit = true;
    while (buffer.length < precision) {
      if (lngBit) {
        final mid = (minLng + maxLng) / 2;
        if (longitude >= mid) {
          ch = (ch << 1) + 1;
          minLng = mid;
        } else {
          ch <<= 1;
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (latitude >= mid) {
          ch = (ch << 1) + 1;
          minLat = mid;
        } else {
          ch <<= 1;
          maxLat = mid;
        }
      }
      lngBit = !lngBit;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(alphabet[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return buffer.toString();
  }

  static int precisionForRadiusKm(double radiusKm) {
    if (radiusKm <= 1) {
      return 6;
    }
    if (radiusKm <= 5) {
      return 5;
    }
    if (radiusKm <= 20) {
      return 4;
    }
    return 3;
  }

  static List<String> coveragePrefixes({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    final precision = precisionForRadiusKm(radiusKm);
    final hash = encode(latitude, longitude, precision);
    return {
      hash,
      adjacent(hash, 'n'),
      adjacent(hash, 's'),
      adjacent(hash, 'e'),
      adjacent(hash, 'w'),
      adjacent(adjacent(hash, 'n'), 'e'),
      adjacent(adjacent(hash, 'n'), 'w'),
      adjacent(adjacent(hash, 's'), 'e'),
      adjacent(adjacent(hash, 's'), 'w'),
    }.where((value) => value.isNotEmpty).toList();
  }

  static String adjacent(String hash, String direction) {
    if (hash.isEmpty) {
      return '';
    }
    final last = hash[hash.length - 1];
    final type = hash.length % 2;
    var parent = hash.substring(0, hash.length - 1);
    if (_border[direction]![type].contains(last) && parent.isNotEmpty) {
      parent = adjacent(parent, direction);
      if (parent.isEmpty) {
        return '';
      }
    }
    final neighborIndex = _neighbor[direction]![type].indexOf(last);
    if (neighborIndex < 0) {
      return hash;
    }
    return '$parent${alphabet[neighborIndex]}';
  }
}
