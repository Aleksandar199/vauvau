import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/message_sound_player.dart';
import '../../../core/services/notification_service.dart';
import '../../events/presentation/events_controller.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../notifications/presentation/push_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/chat_conversation.dart';
import 'chat_inbox.dart';
import 'open_chats.dart';

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

  bool update(Map<String, ThreadActivity> threads, DateTime now) =>
      arrivals(threads, now).isNotEmpty;

  /// Ids of the threads in which a message just arrived.
  Set<String> arrivals(Map<String, ThreadActivity> threads, DateTime now) {
    final arrived = <String>{};
    for (final entry in threads.entries) {
      final previous = _unread[entry.key] ?? 0;
      final thread = entry.value;
      if (_primed &&
          thread.unreadCount > previous &&
          now.difference(thread.lastActivityAt) <= freshness) {
        arrived.add(entry.key);
      }
      _unread[entry.key] = thread.unreadCount;
    }
    _primed = true;
    return arrived;
  }
}

/// Phone notification for a 1:1 message that arrived in [chat]. New chat
/// messages are not written to the in-app notifications list (only the
/// sender's push via fcmInbox), so this is how the recipient hears of them
/// while the app runs.
final incomingChatAlertProvider =
    Provider<void Function(ChatConversation chat)>((ref) {
  return (chat) {
    final owner = chat.ownerName.trim();
    final sender = owner.isNotEmpty ? owner : chat.dogName.trim();
    unawaited(
      ref.read(pushControllerProvider.notifier).alertIncomingMessage(
            senderName: sender.isEmpty ? 'Neko' : sender,
            preview: chat.lastSnippet,
            dogId: chat.dogId,
            senderUserId: chat.peerUserId,
            conversationId: chat.id,
          ),
    );
  };
});

bool get _appInForeground {
  final lifecycle = WidgetsBinding.instance.lifecycleState;
  return lifecycle == null || lifecycle == AppLifecycleState.resumed;
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
      final arrived = chats.arrivals(
        {
          for (final chat in next)
            chat.id: ThreadActivity(
              unreadCount: chat.unreadCount,
              lastActivityAt: chat.lastActivityAt,
            ),
        },
        DateTime.now(),
      );
      if (arrived.isEmpty) {
        return;
      }
      // A chat on screen needs no phone notification, only the chime.
      final viewing =
          _appInForeground ? ref.read(openChatsProvider) : const <String>{};
      var alerted = 0;
      if (ref.read(appSettingsProvider).notifyMessages) {
        final alert = ref.read(incomingChatAlertProvider);
        for (final chat in next) {
          if (arrived.contains(chat.id) && !viewing.contains(chat.id)) {
            alert(chat);
            alerted++;
          }
        }
      }
      if (alerted < arrived.length ||
          !ref.read(systemMessageAlertsAudibleProvider)) {
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
