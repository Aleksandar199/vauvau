import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/push_platform.dart';
import 'push_controller.dart';

class PushBootstrap extends ConsumerStatefulWidget {
  const PushBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends ConsumerState<PushBootstrap> {
  var _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeEnablePush());
  }

  /// First launch only: request OS permission once (no custom dialog).
  /// Preference is persisted as [AppSettings.pushPrompted] so this never repeats.
  Future<void> _maybeEnablePush() async {
    if (!mounted || _asked) {
      return;
    }
    ref.read(pushControllerProvider);
    if (!isFirebaseReady || !isPushPlatform) {
      return;
    }

    // Wait for SharedPreferences — otherwise pushPrompted is still the default
    // false and the prompt would fire on every cold start.
    final settingsCtrl = ref.read(appSettingsProvider.notifier);
    await settingsCtrl.ensureReady();
    if (!mounted) {
      return;
    }

    final settings = ref.read(appSettingsProvider);
    if (settings.pushPrompted) {
      return;
    }

    _asked = true;
    // Persist immediately so a kill during the OS dialog still counts as asked.
    settingsCtrl.update(settings.copyWith(pushPrompted: true));
    await ref.read(pushControllerProvider.notifier).requestPermission();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
