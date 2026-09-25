enum LocationAccess {
  granted,
  denied,
  permanentlyDenied,
  servicesDisabled,
  unavailable,
}

extension LocationAccessX on LocationAccess {
  bool get canTrack => this == LocationAccess.granted;
}
