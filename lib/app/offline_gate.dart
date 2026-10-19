import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/connectivity_controller.dart';
import '../core/widgets/offline_screen.dart';
import '../features/map/presentation/walk_controller.dart';

/// Puts [OfflineScreen] over the whole app while there is no internet.
///
/// The app underneath stays mounted (hidden), so nothing is lost: when the
/// connection returns, the user is exactly where they were. An ACTIVE walk
/// is never interrupted – GPS keeps measuring offline and the map shows a
/// note instead (`WalkGpsBanner`); the walk is saved when it ends.
class OfflineGate extends ConsumerStatefulWidget {
  const OfflineGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfflineGate> createState() => _OfflineGateState();
}

class _OfflineGateState extends ConsumerState<OfflineGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Coming back from the background: check right away, not in 20 s.
      ref.read(networkStateProvider.notifier).recheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    final network = ref.watch(networkStateProvider);
    final walkActive = ref.watch(
      walkControllerProvider.select((session) => session.isActive),
    );
    final blocked = network.isOffline && !walkActive;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: blocked,
          child: ExcludeFocus(
            excluding: blocked,
            child: TickerMode(enabled: !blocked, child: widget.child),
          ),
        ),
        if (blocked)
          OfflineScreen(
            isChecking: network.isChecking,
            onRetry: () => ref.read(networkStateProvider.notifier).retry(),
          ),
      ],
    );
  }
}
