import 'geo.dart';

/// What other users get to see of a walking user's position.
///
/// The precise GPS point and the route stay on the owner's account
/// (`users/{uid}/walks`, owner-only). Presence on the map (`dogs` documents,
/// readable by every signed-in user) only ever carries the centre of a
/// coarse grid cell, so nobody can follow someone street by street.
abstract final class SharedLocation {
  /// Cell size in degrees: ≈ 220 m north–south, ≈ 160 m east–west at 45°N.
  static const double gridDegrees = 0.002;

  /// Centre of the grid cell that contains [location].
  static GeoCoord approximate(GeoCoord location) {
    double snap(double value) {
      final cell = (value / gridDegrees).floorToDouble();
      final centre = (cell + 0.5) * gridDegrees;
      // Drop floating point noise (…0000000001) so equal cells compare equal.
      return double.parse(centre.toStringAsFixed(6));
    }

    return GeoCoord(snap(location.latitude), snap(location.longitude));
  }
}
