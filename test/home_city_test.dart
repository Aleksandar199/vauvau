import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/geo/geo.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/location/presentation/home_city_provider.dart';
import 'package:vauvau/features/map/presentation/cities_controller.dart';

ProviderContainer _containerFor(AppUser user) {
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _waitForAuth(ProviderContainer container) async {
  container.listen(authStateProvider, (_, _) {});
  await container.read(authStateProvider.future);
}

void main() {
  test('Niš user gets Niš as home city and map region', () async {
    final container = _containerFor(
      const AppUser(uid: 'u1', city: 'Niš', cityId: 'nis'),
    );
    await _waitForAuth(container);

    final home = container.read(homeCityProvider);
    expect(home?.id, 'nis');
    expect(home?.coord, GeoCoord.nis);

    final region = container.read(mapRegionProvider);
    expect(region.isMyLocation, isFalse);
    expect(region.cityId, 'nis');
    expect(region.city!.latitude, 43.3209);
  });

  test('Beograd user gets Beograd on the map', () async {
    final container = _containerFor(
      const AppUser(uid: 'u2', city: 'Beograd', cityId: 'beograd'),
    );
    await _waitForAuth(container);
    expect(container.read(mapRegionProvider).cityId, 'beograd');
  });

  test('Novi Sad id maps to the novi-sad map city', () async {
    final container = _containerFor(
      const AppUser(uid: 'u3', city: 'Novi Sad', cityId: 'novi_sad'),
    );
    await _waitForAuth(container);
    expect(container.read(mapRegionProvider).cityId, 'novi-sad');
  });

  test('user without a city falls back to "my location"', () async {
    final container = _containerFor(const AppUser(uid: 'u4'));
    await _waitForAuth(container);
    expect(container.read(homeCityProvider), isNull);
    expect(container.read(mapRegionProvider).isMyLocation, isTrue);
  });
}
