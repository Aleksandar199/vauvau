import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/presentation/events_controller.dart';
import '../../notifications/presentation/push_controller.dart';
import 'groups_controller.dart';

final groupUnreadAlertsProvider = Provider<void>((ref) {
  var primed = false;
  final previous = <String, int>{};
  var eventsPrimed = false;
  final previousEvents = <String, int>{};
  ref.listen(joinedGroupThreadsProvider, (prev, next) {
    if (!primed) {
      for (final thread in next) {
        previous[thread.group.id] = thread.unreadCount;
      }
      primed = true;
      return;
    }
    for (final thread in next) {
      final oldCount = previous[thread.group.id] ?? 0;
      if (thread.unreadCount > oldCount) {
        unawaited(
          ref.read(pushControllerProvider.notifier).notifyGroupThread(
                groupTitle: thread.group.title,
                count: thread.unreadCount,
              ),
        );
      }
      previous[thread.group.id] = thread.unreadCount;
    }
  });
  ref.listen(joinedEventThreadsProvider, (prev, next) {
    if (!eventsPrimed) {
      for (final thread in next) {
        previousEvents[thread.event.id] = thread.unreadCount;
      }
      eventsPrimed = true;
      return;
    }
    for (final thread in next) {
      final oldCount = previousEvents[thread.event.id] ?? 0;
      if (thread.unreadCount > oldCount) {
        unawaited(
          ref.read(pushControllerProvider.notifier).notifyGroupThread(
                groupTitle: thread.event.title,
                count: thread.unreadCount,
              ),
        );
      }
      previousEvents[thread.event.id] = thread.unreadCount;
    }
  });
});
