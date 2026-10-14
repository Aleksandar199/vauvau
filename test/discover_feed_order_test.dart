import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/discover/domain/discover_profile.dart';

DiscoverProfile _profile({
  required String id,
  DateTime? createdAt,
  double distanceKm = 0,
}) {
  return DiscoverProfile(
    id: id,
    name: id,
    ownerName: 'Owner',
    breed: 'Mešanac',
    ageYears: 2,
    gender: 'mužjak',
    size: 'srednji',
    location: 'Novi Sad',
    bio: '',
    photoUrls: const [],
    createdAt: createdAt,
    distanceKm: distanceKm,
  );
}

void main() {
  test('newest profiles come first, then closer distance', () {
    final olderFar = _profile(
      id: 'older-far',
      createdAt: DateTime(2026, 1, 1),
      distanceKm: 1,
    );
    final newerFar = _profile(
      id: 'newer-far',
      createdAt: DateTime(2026, 6, 1),
      distanceKm: 10,
    );
    final newerNear = _profile(
      id: 'newer-near',
      createdAt: DateTime(2026, 6, 1),
      distanceKm: 2,
    );
    final missingDate = _profile(id: 'no-date', distanceKm: 0.5);

    final sorted = [olderFar, newerFar, newerNear, missingDate]
      ..sort(DiscoverProfile.compareFeedOrder);

    expect(sorted.map((p) => p.id).toList(), [
      'newer-near',
      'newer-far',
      'older-far',
      'no-date',
    ]);
  });
}
