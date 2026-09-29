import 'dart:async';

import 'seed_breed_groups.dart';
import '../domain/groups_models.dart';

class LocalGroupsRepository implements GroupsRepository {
  LocalGroupsRepository({
    required this.currentUserId,
    this.senderName = 'Ti',
    this.senderAvatarUrl = '',
    List<BreedGroup>? seed,
  }) : _groups = List<BreedGroup>.from(seed ?? SeedBreedGroups.all);

  final String currentUserId;
  final String senderName;
  final String senderAvatarUrl;
  final List<BreedGroup> _groups;
  final Map<String, List<GroupMessage>> _messages = {};
  final Map<String, DateTime> _lastRead = {};
  final StreamController<List<BreedGroup>> _groupsController =
      StreamController<List<BreedGroup>>.broadcast();
  final Map<String, StreamController<List<GroupMessage>>> _messageControllers =
      {};
  final Map<String, StreamController<DateTime?>> _readControllers = {};

  void dispose() {
    _groupsController.close();
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    for (final controller in _readControllers.values) {
      controller.close();
    }
  }

  @override
  Stream<List<BreedGroup>> watchGroups() async* {
    yield _sorted();
    yield* _groupsController.stream;
  }

  @override
  Stream<List<GroupMessage>> watchMessages(String groupId) async* {
    yield List<GroupMessage>.from(_messages[groupId] ?? const []);
    yield* _messageControllerFor(groupId).stream;
  }

  @override
  Stream<DateTime?> watchLastRead(String groupId) async* {
    yield _lastRead[groupId];
    yield* _readControllerFor(groupId).stream;
  }

  @override
  Future<void> joinGroup(String groupId) async {
    if (currentUserId.isEmpty) {
      return;
    }
    for (var i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      if (group.id != groupId || group.isMember(currentUserId)) {
        continue;
      }
      _groups[i] = group.copyWith(
        memberIds: [...group.memberIds, currentUserId],
        memberCount: group.displayMemberCount + 1,
      );
    }
    _lastRead[groupId] = DateTime.now();
    _readControllerFor(groupId).add(_lastRead[groupId]);
    _groupsController.add(_sorted());
  }

  @override
  Future<void> markRead(String groupId) async {
    _lastRead[groupId] = DateTime.now();
    _readControllerFor(groupId).add(_lastRead[groupId]);
  }

  @override
  Future<void> sendMessage({
    required String groupId,
    required String text,
    String imageUrl = '',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl.trim().isEmpty) {
      return;
    }
    final message = GroupMessage(
      id: 'gmsg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: trimmed,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      isMine: true,
    );
    _append(groupId, message);
  }

  @override
  Future<void> sendPhoto({
    required String groupId,
    required String imageUrl,
  }) {
    return sendMessage(groupId: groupId, text: '', imageUrl: imageUrl);
  }

  void seedIncomingMessage({
    required String groupId,
    required GroupMessage message,
  }) {
    _append(groupId, message);
  }

  void _append(String groupId, GroupMessage message) {
    final next = [..._messages[groupId] ?? const <GroupMessage>[], message];
    _messages[groupId] = next;
    for (var i = 0; i < _groups.length; i++) {
      if (_groups[i].id != groupId) {
        continue;
      }
      _groups[i] = _groups[i].copyWith(
        lastMessage: message.preview,
        lastMessageAt: message.createdAt,
      );
    }
    _messageControllerFor(groupId).add(List<GroupMessage>.from(next));
    _groupsController.add(_sorted());
  }

  StreamController<List<GroupMessage>> _messageControllerFor(String groupId) {
    return _messageControllers.putIfAbsent(
      groupId,
      StreamController<List<GroupMessage>>.broadcast,
    );
  }

  StreamController<DateTime?> _readControllerFor(String groupId) {
    return _readControllers.putIfAbsent(
      groupId,
      StreamController<DateTime?>.broadcast,
    );
  }

  List<BreedGroup> _sorted() {
    final copy = List<BreedGroup>.from(_groups)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }
}
