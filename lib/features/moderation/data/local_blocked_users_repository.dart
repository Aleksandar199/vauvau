import 'dart:async';

import '../domain/blocked_users_repository.dart';

class LocalBlockedUsersRepository implements BlockedUsersRepository {
  LocalBlockedUsersRepository({Set<String>? seed}) : _blocked = {...?seed};

  final Set<String> _blocked;
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();

  void dispose() {
    _controller.close();
  }

  @override
  Stream<Set<String>> watchBlocked() async* {
    yield Set<String>.from(_blocked);
    yield* _controller.stream;
  }

  @override
  Future<void> block(String userId) async {
    if (userId.isEmpty) {
      return;
    }
    _blocked.add(userId);
    _controller.add(Set<String>.from(_blocked));
  }

  @override
  Future<void> unblock(String userId) async {
    _blocked.remove(userId);
    _controller.add(Set<String>.from(_blocked));
  }
}
