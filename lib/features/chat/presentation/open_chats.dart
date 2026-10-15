import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1:1 conversations currently on screen in a ChatDetailScreen.
///
/// Used to keep notifications of a chat the user is reading out of the
/// notification list and the phone tray.
class OpenChatsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void open(String conversationId) {
    final id = conversationId.trim();
    if (id.isEmpty || state.contains(id)) {
      return;
    }
    state = {...state, id};
  }

  void close(String conversationId) {
    final id = conversationId.trim();
    if (!state.contains(id)) {
      return;
    }
    state = {...state}..remove(id);
  }
}

final openChatsProvider =
    NotifierProvider<OpenChatsController, Set<String>>(OpenChatsController.new);
