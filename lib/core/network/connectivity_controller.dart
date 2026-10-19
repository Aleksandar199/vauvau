import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_status.dart';
import 'connectivity_probe.dart';

/// Internet state the whole app reacts to (see `OfflineGate`).
class NetworkState {
  const NetworkState({this.isOffline = false, this.isChecking = false});

  /// True only after the connection was confirmed lost. Until the first
  /// check finishes the app is treated as online, so a slow probe never
  /// locks anybody out.
  final bool isOffline;

  /// A manual "Pokušaj ponovo" check is running.
  final bool isChecking;

  NetworkState copyWith({bool? isOffline, bool? isChecking}) => NetworkState(
        isOffline: isOffline ?? this.isOffline,
        isChecking: isChecking ?? this.isChecking,
      );

  @override
  bool operator ==(Object other) =>
      other is NetworkState &&
      other.isOffline == isOffline &&
      other.isChecking == isChecking;

  @override
  int get hashCode => Object.hash(isOffline, isChecking);
}

class ConnectivityTiming {
  const ConnectivityTiming({
    this.whileOnline = const Duration(seconds: 20),
    this.whileOffline = const Duration(seconds: 3),
    this.confirmDelay = const Duration(seconds: 2),
  });

  /// Pause between checks while the connection works.
  final Duration whileOnline;

  /// Pause between checks while offline (the app opens by itself on return).
  final Duration whileOffline;

  /// A single failed check is repeated after this delay before the user is
  /// told they are offline (a dropped packet must not lock the app).
  final Duration confirmDelay;
}

final connectivityProbeProvider =
    Provider<ConnectivityProbe>((ref) => createConnectivityProbe());

final connectivityTimingProvider =
    Provider<ConnectivityTiming>((ref) => const ConnectivityTiming());

/// Off without Firebase (local demo mode and widget tests): no timers.
final connectivityMonitoringProvider =
    Provider<bool>((ref) => isFirebaseReady);

class ConnectivityController extends Notifier<NetworkState> {
  Timer? _timer;
  StreamSubscription<void>? _changes;
  var _running = false;
  var _disposed = false;

  @override
  NetworkState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      _changes?.cancel();
    });
    if (!ref.read(connectivityMonitoringProvider)) {
      return const NetworkState();
    }
    final probe = ref.read(connectivityProbeProvider);
    _changes = probe.changes.listen((_) => unawaited(recheck()));
    Future<void>.microtask(() => _run(manual: false));
    return const NetworkState();
  }

  /// Checks now (app resumed, browser event).
  Future<void> recheck() => _run(manual: false);

  /// "Pokušaj ponovo": one decisive check, with a spinner.
  Future<void> retry() => _run(manual: true);

  Future<void> _run({required bool manual}) async {
    if (_disposed || _running) {
      return;
    }
    _running = true;
    _timer?.cancel();
    final timing = ref.read(connectivityTimingProvider);
    if (manual) {
      state = state.copyWith(isChecking: true);
    }
    try {
      final probe = ref.read(connectivityProbeProvider);
      var online = await probe.check();
      if (!online && !manual && !state.isOffline) {
        await Future<void>.delayed(timing.confirmDelay);
        if (_disposed) return;
        online = await probe.check();
      }
      if (_disposed) return;
      state = NetworkState(isOffline: !online);
    } finally {
      _running = false;
      if (!_disposed) {
        _timer = Timer(
          state.isOffline ? timing.whileOffline : timing.whileOnline,
          () => unawaited(_run(manual: false)),
        );
      }
    }
  }
}

final networkStateProvider =
    NotifierProvider<ConnectivityController, NetworkState>(
  ConnectivityController.new,
);
