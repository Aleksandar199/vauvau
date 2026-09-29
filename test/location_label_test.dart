import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/constants/serbia_locations.dart';

void main() {
  test('sanitizes duplicated suburb in location labels', () {
    expect(
      SerbiaLocations.sanitizeLocationLabel('Novi Sad Telep Telep'),
      'Novi Sad, Telep',
    );
    expect(
      SerbiaLocations.sanitizeLocationLabel('Novi Sad · Telep · Telep'),
      'Novi Sad, Telep',
    );
    expect(
      SerbiaLocations.formatPlace('Novi Sad', 'Telep'),
      'Novi Sad, Telep',
    );
    expect(
      SerbiaLocations.formatPlace('Novi Sad Telep', 'Telep'),
      'Novi Sad, Telep',
    );
  });
}
