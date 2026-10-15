import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/message_sound_player.dart';
import '../../../core/services/notification_service.dart';
import '../../events/presentation/events_controller.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../notifications/presentation/push_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import 'chat_inbox.dart';

/// Unread state of one conversation, used to spot freshly arrived messages.
class ThreadActivity {
  const ThreadActivity({
    required this.unreadCount,
    required this.lastActivityAt,
  });

  final int unreadCount;
  final DateTime lastActivityAt;
}

/// Decides whether a new inbox snapshot contains a message that just arrived.
class IncomingMessageDetector {
  IncomingMessageDetector({this.freshness = const Duration(minutes: 1)});

  final Duration freshness;
  final Map<String, int> _unread = <String, int>{};
  bool _primed = false;

  bool update(Map<String, ThreadActivity> threads, DateTime now) {
    var arrived = false;
    for (final entry in threads.entries) {
      final previous = _unread[entry.key] ?? 0;
      final thread = entry.value;
      if (_primed &&
          thread.unreadCount > previous &&
          now.difference(thread.lastActivityAt) <= freshness) {
        arrived = true;
      }
      _unread[entry.key] = thread.unreadCount;
    }
    _primed = true;
    return arrived;
  }
}

/// True when the OS notification (with its own sound) already announces
/// group and event messages, so the in-app chime would double it.
final systemMessageAlertsAudibleProvider = Provider<bool>((ref) {
  return ref.watch(notificationServiceProvider).isSupported &&
      ref.watch(pushControllerProvider);
});

/// Plays a short chime whenever a new message arrives in any conversation.
final incomingMessageSoundProvider = Provider<void>((ref) {
  const minGap = Duration(milliseconds: 1500);
  final chats = IncomingMessageDetector();
  final groups = IncomingMessageDetector();
  final events = IncomingMessageDetector();
  DateTime? lastPlayed;

  void play() {
    if (!ref.read(appSettingsProvider).notifyMessages) {
      return;
    }
    final now = DateTime.now();
    final last = lastPlayed;
    if (last != null && now.difference(last) < minGap) {
      return;
    }
    lastPlayed = now;
    unawaited(ref.read(messageSoundPlayerProvider).play());
  }

  ref.listen(
    visibleConversationsProvider,
    (_, next) {
      final arrived = chats.update(
        {
          for (final chat in next)
            chat.id: ThreadActivity(
              unreadCount: chat.unreadCount,
              lastActivityAt: chat.lastActivityAt,
            ),
        },
        DateTime.now(),
      );
      if (arrived) {
        play();
      }
    },
    fireImmediately: true,
  );

  ref.listen(
    joinedGroupThreadsProvider,
    (_, next) {
      final arrived = groups.update(
        {
          for (final thread in next)
            thread.group.id: ThreadActivity(
              unreadCount: thread.unreadCount,
              lastActivityAt: thread.lastActivityAt,
            ),
        },
        DateTime.now(),
      );
      if (arrived && !ref.read(systemMessageAlertsAudibleProvider)) {
        play();
      }
    },
    fireImmediately: true,
  );

  ref.listen(
    joinedEventThreadsProvider,
    (_, next) {
      final arrived = events.update(
        {
          for (final thread in next)
            thread.event.id: ThreadActivity(
              unreadCount: thread.unreadCount,
              lastActivityAt: thread.lastActivityAt,
            ),
        },
        DateTime.now(),
      );
      if (arrived && !ref.read(systemMessageAlertsAudibleProvider)) {
        play();
      }
    },
    fireImmediately: true,
  );
});
