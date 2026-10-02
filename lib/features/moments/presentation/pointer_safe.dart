import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Runs [action] immediately on touch devices.
///
/// On web, waits two frames plus a short delay so the mouse tracker finishes
/// `updateAllDevices` before we push/pop routes. Opening UI mid-hover is what
/// trips `!_debugDuringDeviceUpdate` (often after a prior layout exception).
Future<void> afterPointerSettles(FutureOr<void> Function() action) async {
  if (!kIsWeb) {
    await action();
    return;
  }
  final done = Completer<void>();
  void run() {
    Future<void>.delayed(const Duration(milliseconds: 50), () async {
      try {
        await action();
        if (!done.isCompleted) {
          done.complete();
        }
      } catch (error, stack) {
        if (!done.isCompleted) {
          done.completeError(error, stack);
        }
      }
    });
  }

  SchedulerBinding.instance.addPostFrameCallback((_) {
    SchedulerBinding.instance.addPostFrameCallback((_) => run());
  });
  SchedulerBinding.instance.scheduleFrame();
  await done.future;
}

void afterPointerSettlesIfMounted(
  BuildContext context,
  VoidCallback action,
) {
  afterPointerSettles(() async {
    if (context.mounted) {
      action();
    }
  });
}
