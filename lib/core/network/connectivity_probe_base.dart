/// Answers "is there an internet connection right now?".
abstract class ConnectivityProbe {
  /// One live check. Never throws.
  Future<bool> check();

  /// Fires when the platform itself reports a change (browser online/offline
  /// events). Mobile has none: the controller polls instead.
  Stream<void> get changes;
}
