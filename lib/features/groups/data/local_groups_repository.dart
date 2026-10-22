import 'dart:async';

import '../../../core/utils/message_reactions.dart';

import 'seed_breed_groups.dart';
import '../domain/group_ranking.dart';
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
    _mutedChanges.close();
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
    yield _approvedSorted();
    yield* _groupsController.stream.map((_) => _approvedSorted());
  }

  @override
  Stream<List<BreedGroup>> watchPendingGroups() async* {
    yield _pendingSorted();
    yield* _groupsController.stream.map((_) => _pendingSorted());
  }

  @override
  Stream<List<GroupMessage>> watchMessages(String groupId) async* {
    yield List<GroupMessage>.from(_messages[groupId] ?? const []);
    yield* _messageControllerFor(groupId).stream;
  }

  final Map<String, bool> _muted = {};
  final StreamController<String> _mutedChanges =
      StreamController<String>.broadcast();

  @override
  Stream<bool> watchMuted(String groupId) async* {
    yield _muted[groupId] ?? false;
    yield* _mutedChanges.stream
        .where((changed) => changed == groupId)
        .map((_) => _muted[groupId] ?? false);
  }

  @override
  Future<void> setMuted(String groupId, bool muted) async {
    _muted[groupId] = muted;
    _mutedChanges.add(groupId);
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
    _emitGroups();
  }

  @override
  Future<void> markRead(String groupId) async {
    _lastRead[groupId] = DateTime.now();
    _readControllerFor(groupId).add(_lastRead[groupId]);
  }

  @override
  Future<BreedGroup> createGroup({
    required String title,
    required String description,
    bool approveImmediately = false,
    GroupScope? scope,
    String cityId = '',
    GroupCategory category = GroupCategory.general,
    String locationName = '',
    String breedKey = '',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw StateError('Naziv grupe je obavezan.');
    }
    final id = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final group = BreedGroup(
      id: id,
      title: trimmedTitle,
      description: description.trim().isEmpty
          ? SeedBreedGroups.defaultDescription
          : description.trim(),
      imageUrl: '',
      memberIds: currentUserId.isEmpty ? const [] : [currentUserId],
      memberCount: currentUserId.isEmpty ? 1 : 1,
      sortOrder: 999,
      isApproved: approveImmediately,
      createdBy: currentUserId,
      createdAt: DateTime.now(),
      scope:
          scope ??
          (breedKey.isNotEmpty
              ? GroupScope.breed
              : cityId.isNotEmpty
              ? GroupScope.local
              : GroupScope.global),
      cityId: cityId,
      category: category,
      locationName: locationName.trim(),
      breedKey: breedKey,
    );
    _groups.add(group);
    _emitGroups();
    return group;
  }

  @override
  Future<void> approveGroup(String groupId) async {
    for (var i = 0; i < _groups.length; i++) {
      if (_groups[i].id != groupId) {
        continue;
      }
      _groups[i] = _groups[i].copyWith(isApproved: true);
    }
    _emitGroups();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((group) => group.id == groupId);
    _messages.remove(groupId);
    _lastRead.remove(groupId);
    _emitGroups();
  }

  @override
  Future<void> sendMessage({
    required String groupId,
    required String text,
    String imageUrl = '',
    GroupMessage? replyTo,
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
      replyToMessageId: replyTo?.id ?? '',
      replyToText: replyTo == null ? '' : replyTo.preview,
      replyToSenderName: replyTo?.senderName ?? '',
    );
    _append(groupId, message);
  }

  @override
  Future<void> sendPhoto({
    required String groupId,
    required String imageUrl,
    GroupMessage? replyTo,
  }) {
    return sendMessage(
      groupId: groupId,
      text: '',
      imageUrl: imageUrl,
      replyTo: replyTo,
    );
  }

  @override
  Future<void> sendWalkInvite({
    required String groupId,
    required DateTime walkTime,
    required String walkLocationName,
  }) async {
    final place = walkLocationName.trim();
    final preview = place.isEmpty
        ? 'Poziv na šetnju'
        : 'Poziv na šetnju: $place';
    _append(
      groupId,
      GroupMessage(
        id: 'gmsg-${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUserId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        text: preview,
        imageUrl: '',
        createdAt: DateTime.now(),
        isMine: true,
        type: GroupMessageType.walkInvite,
        status: GroupWalkInviteStatus.pending,
        walkTime: walkTime,
        walkLocationName: place,
      ),
    );
  }

  @override
  Future<void> respondToWalkInvite({
    required String groupId,
    required String messageId,
    required GroupWalkInviteStatus status,
  }) async {
    final current = _messages[groupId] ?? const <GroupMessage>[];
    final next = [
      for (final message in current)
        if (message.id == messageId)
          message.copyWith(
            status: GroupWalkInviteStatus.pending,
            acceptedByUserIds: status == GroupWalkInviteStatus.accepted
                ? {...message.acceptedByUserIds, currentUserId}.toList()
                : [
                    for (final id in message.acceptedByUserIds)
                      if (id != currentUserId) id,
                  ],
            declinedByUserIds: status == GroupWalkInviteStatus.declined
                ? {...message.declinedByUserIds, currentUserId}.toList()
                : [
                    for (final id in message.declinedByUserIds)
                      if (id != currentUserId) id,
                  ],
          )
        else
          message,
    ];
    _messages[groupId] = next;
    _messageControllerFor(groupId).add(List<GroupMessage>.from(next));
  }

  @override
  Future<void> toggleMessageLike({
    required String groupId,
    required String messageId,
  }) {
    String? mine;
    for (final message in _messages[groupId] ?? const <GroupMessage>[]) {
      if (message.id == messageId) {
        mine = MessageReactions.reactionOf(message.likes, currentUserId);
      }
    }
    return setMessageReaction(
      groupId: groupId,
      messageId: messageId,
      emoji: mine == '❤️' ? null : '❤️',
    );
  }

  @override
  Future<void> setMessageReaction({
    required String groupId,
    required String messageId,
    String? emoji,
  }) async {
    final current = _messages[groupId] ?? const <GroupMessage>[];
    final next = [
      for (final message in current)
        if (message.id == messageId)
          message.copyWith(
            likes: MessageReactions.apply(message.likes, currentUserId, emoji),
          )
        else
          message,
    ];
    _messages[groupId] = next;
    _messageControllerFor(groupId).add(List<GroupMessage>.from(next));
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
    _emitGroups();
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

  void _emitGroups() {
    if (!_groupsController.isClosed) {
      _groupsController.add(_groups);
    }
  }

  List<BreedGroup> _approvedSorted() {
    return GroupRanking.sort(_groups.where((group) => group.isApproved));
  }

  List<BreedGroup> _pendingSorted() {
    final pending = _groups.where((group) => !group.isApproved).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return pending;
  }
}
