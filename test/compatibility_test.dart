import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/discover/data/mock_discover_profiles.dart';
import 'package:vauvau/features/discover/domain/compatibility.dart';

void main() {
  test('builds shared energy and walk compatibility copy', () {
    final insight = describeCompatibility(
      mine: mockMyDog,
      other: mockDiscoverProfiles.first,
    );
    expect(insight.similarEnergy, isTrue);
    expect(insight.sharedLikes, contains('Šetnje'));
    expect(insight.headline, contains('Luna'));
    expect(insight.headline, contains('Bobi'));
    expect(insight.headline, contains('duge šetnje'));
  });
}
