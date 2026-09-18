class AppSettings {
  const AppSettings({
    this.notifyWalkRequests = true,
    this.notifyMessages = true,
    this.notifyNewMatches = true,
    this.radiusKm = 20,
    this.showLocationOnMap = true,
  });

  final bool notifyWalkRequests;
  final bool notifyMessages;
  final bool notifyNewMatches;
  final double radiusKm;
  final bool showLocationOnMap;

  AppSettings copyWith({
    bool? notifyWalkRequests,
    bool? notifyMessages,
    bool? notifyNewMatches,
    double? radiusKm,
    bool? showLocationOnMap,
  }) {
    return AppSettings(
      notifyWalkRequests: notifyWalkRequests ?? this.notifyWalkRequests,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyNewMatches: notifyNewMatches ?? this.notifyNewMatches,
      radiusKm: radiusKm ?? this.radiusKm,
      showLocationOnMap: showLocationOnMap ?? this.showLocationOnMap,
    );
  }
}
