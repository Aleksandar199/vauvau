import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/push_platform.dart';
import 'notification_strings.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  Future<void> _maybePrompt() async {
    if (!mounted || _asked) {
      return;
    }
    ref.read(pushControllerProvider);
    if (!isFirebaseReady || !isPushPlatform) {
      return;
    }
    final settings = ref.read(appSettingsProvider);
    if (settings.pushPrompted) {
      return;
    }
    _asked = true;
    final enable = await showEnableNotificationsDialog(context);
    if (!mounted) {
      return;
    }
    ref.read(appSettingsProvider.notifier).update(
          settings.copyWith(pushPrompted: true),
        );
    if (enable == true) {
      await ref.read(pushControllerProvider.notifier).requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<bool?> showEnableNotificationsDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(NotificationStrings.enableTitle),
        content: const Text(NotificationStrings.enableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(NotificationStrings.later),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(NotificationStrings.enableConfirm),
          ),
        ],
      );
    },
  );
}
