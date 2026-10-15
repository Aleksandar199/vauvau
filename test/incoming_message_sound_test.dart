import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/services/message_sound_player.dart';
import 'package:vauvau/features/chat/domain/chat_conversation.dart';
import 'package:vauvau/features/chat/presentation/chat_inbox.dart';
import 'package:vauvau/features/chat/presentation/incoming_message_sound.dart';
import 'package:vauvau/features/chat/presentation/widgets/chat_ui.dart';
import 'package:vauvau/features/events/presentation/events_controller.dart';
import 'package:vauvau/features/groups/domain/groups_models.dart';
import 'package:vauvau/features/groups/presentation/groups_controller.dart';
import 'package:vauvau/features/profile/domain/app_settings.dart';
import 'package:vauvau/features/profile/presentation/profile_controller.dart';

class _CountingSound implements MessageSoundPlayer {
  int plays = 0;

  @override
  Future<void> play() async => plays++;

  @override
  void dispose() {}
}

class _Settings extends AppSettingsController {
  _Settings(this.value);

  final AppSettings value;

  @override
  AppSettings build() => value;
}

class _ListNotifier<T> extends Notifier<List<T>> {
  @override
  List<T> build() => <T>[];

  void set(List<T> value) => state = value;
}

final _chats = NotifierProvider<_ListNotifier<ChatConversation>,
    List<ChatConversation>>(_ListNotifier<ChatConversation>.new);
final _groups = NotifierProvider<_ListNotifier<GroupInboxThread>,
    List<GroupInboxThread>>(_ListNotifier<GroupInboxThread>.new);

ChatConversation _chat(String id, {required int unread, DateTime? at}) {
  return ChatConversation(
    id: id,
    dogId: 'dog-$id',
    dogName: 'Lola',
    ownerName: 'Jelena',
    breed: 'Labrador',
    location: 'Novi Sad',
    photoUrl: '',
    messages: const [],
    lastActivityAt: at ?? DateTime.now(),
    isNewMatch: false,
    unreadCount: unread,
  );
}

GroupInboxThread _group(String id, {required int unread}) {
  return GroupInboxThread(
    group: BreedGroup(
      id: id,
      title: 'Grupa',
      description: '',
      imageUrl: '',
      memberIds: const ['me'],
      memberCount: 1,
    ),
    lastMessage: 'Cao',
    lastActivityAt: DateTime.now(),
    unreadCount: unread,
  );
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);

({ProviderContainer container, _CountingSound sound}) _setUp({
  bool notifyMessages = true,
  bool systemAudible = false,
}) {
  final sound = _CountingSound();
  final container = ProviderContainer(
    overrides: [
      messageSoundPlayerProvider.overrideWithValue(sound),
      appSettingsProvider.overrideWith(
        () => _Settings(AppSettings(notifyMessages: notifyMessages)),
      ),
      systemMessageAlertsAudibleProvider.overrideWithValue(systemAudible),
      visibleConversationsProvider.overrideWith((ref) => ref.watch(_chats)),
      joinedGroupThreadsProvider.overrideWith((ref) => ref.watch(_groups)),
      joinedEventThreadsProvider.overrideWith((ref) => const []),
    ],
  );
  addTearDown(container.dispose);
  container.listen(incomingMessageSoundProvider, (_, _) {});
  return (container: container, sound: sound);
}

void main() {
  group('IncomingMessageDetector', () {
    final now = DateTime(2026, 10, 14, 12);

    ThreadActivity activity(int unread, {Duration ago = Duration.zero}) =>
        ThreadActivity(unreadCount: unread, lastActivityAt: now.subtract(ago));

    test('first snapshot only primes, even with unread messages', () {
      final detector = IncomingMessageDetector();
      expect(detector.update({'a': activity(3)}, now), isFalse);
    });

    test('fresh unread increase counts as an arrival', () {
      final detector = IncomingMessageDetector()..update({'a': activity(0)}, now);
      expect(detector.update({'a': activity(1)}, now), isTrue);
    });

    test('a brand new conversation with a fresh message counts', () {
      final detector = IncomingMessageDetector()..update({}, now);
      expect(detector.update({'b': activity(1)}, now), isTrue);
    });

    test('stale history loading later stays silent', () {
      final detector = IncomingMessageDetector()..update({}, now);
      expect(
        detector.update({'b': activity(4, ago: const Duration(hours: 2))}, now),
        isFalse,
      );
    });

    test('reading a conversation stays silent', () {
      final detector = IncomingMessageDetector()..update({'a': activity(2)}, now);
      expect(detector.update({'a': activity(0)}, now), isFalse);
    });
  });

  group('incomingMessageSoundProvider', () {
    test('plays when a direct message arrives', () async {
      final setup = _setUp();
      setup.container.read(_chats.notifier).set([_chat('a', unread: 0)]);
      await _tick();
      expect(setup.sound.plays, 0);

      setup.container.read(_chats.notifier).set([_chat('a', unread: 1)]);
      await _tick();
      expect(setup.sound.plays, 1);
    });

    test('stays silent when message notifications are turned off', () async {
      final setup = _setUp(notifyMessages: false);
      setup.container.read(_chats.notifier).set([_chat('a', unread: 1)]);
      await _tick();
      expect(setup.sound.plays, 0);
    });

    test('my own sends do not chime', () async {
      final setup = _setUp();
      setup.container.read(_chats.notifier).set([_chat('a', unread: 0)]);
      await _tick();
      setup.container
          .read(_chats.notifier)
          .set([_chat('a', unread: 0, at: DateTime.now())]);
      await _tick();
      expect(setup.sound.plays, 0);
    });

    test('group chime only when the OS notification is not audible', () async {
      final silentOs = _setUp();
      silentOs.container.read(_groups.notifier).set([_group('g', unread: 1)]);
      await _tick();
      expect(silentOs.sound.plays, 1);

      final audibleOs = _setUp(systemAudible: true);
      audibleOs.container.read(_groups.notifier).set([_group('g', unread: 1)]);
      await _tick();
      expect(audibleOs.sound.plays, 0);
    });
  });

  group('ChatInputBar', () {
    Future<({TextEditingController controller, List<String> sent})> pumpBar(
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatInputBar(
                controller: controller,
                hintText: 'Poruka',
                sendTooltip: 'Pošalji',
                onSend: () {
                  sent.add(controller.text);
                  controller.clear();
                },
              ),
            ),
          ),
        ),
      );
      return (controller: controller, sent: sent);
    }

    testWidgets('grows to several lines while typing', (tester) async {
      final bar = await pumpBar(tester);
      final field = find.byKey(const ValueKey('chat-input-field'));
      final single = tester.getSize(field).height;

      await tester.enterText(field, 'Prvi red\nDrugi red\nTreći red');
      await tester.pump();

      expect(tester.getSize(field).height, greaterThan(single));
      final textField = tester.widget<TextField>(field);
      expect(textField.textInputAction, TextInputAction.newline);
      expect(textField.keyboardType, TextInputType.multiline);
      expect(bar.sent, isEmpty);
    });

    testWidgets('keyboard newline action does not send on phones',
        (tester) async {
      final bar = await pumpBar(tester);
      await tester.enterText(
        find.byKey(const ValueKey('chat-input-field')),
        'Cao',
      );
      await tester.testTextInput.receiveAction(TextInputAction.newline);
      await tester.pump();
      expect(bar.sent, isEmpty);

      await tester.tap(find.byTooltip('Pošalji'));
      await tester.pump();
      expect(bar.sent, ['Cao']);
    });

    testWidgets('Enter sends on desktop, Shift+Enter does not',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final bar = await pumpBar(tester);
        final field = find.byKey(const ValueKey('chat-input-field'));
        await tester.tap(field);
        await tester.enterText(field, 'Cao');

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(bar.sent, isEmpty);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(bar.sent, ['Cao']);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
