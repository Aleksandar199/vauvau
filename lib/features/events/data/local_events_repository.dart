import 'dart:async';

import '../../../core/images/dog_photo_urls.dart';
import '../../../core/utils/message_reactions.dart';
import '../../groups/domain/groups_models.dart';
import '../domain/event_model.dart';
import '../domain/events_repository.dart';
import 'seed_events.dart';

class LocalEventsRepository implements EventsRepository {
  LocalEventsRepository({
    required this.currentUserId,
    this.senderName = 'Ti',
    this.senderAvatarUrl = '',
    List<EventModel>? seed,
  }) : _events = List<EventModel>.from(seed ?? SeedEvents.all);

  final String currentUserId;
  final String senderName;
  final String senderAvatarUrl;
  final List<EventModel> _events;
  final Map<String, List<GroupMessage>> _messages = {};
  final Map<String, DateTime> _lastRead = {};
  final StreamController<List<EventModel>> _eventsController =
      StreamController<List<EventModel>>.broadcast();
  final Map<String, StreamController<List<GroupMessage>>> _messageControllers =
      {};
  final Map<String, StreamController<DateTime?>> _readControllers = {};

  void dispose() {
    _eventsController.close();
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    for (final controller in _readControllers.values) {
      controller.close();
    }
  }

  @override
  Stream<List<EventModel>> watchEvents() async* {
    yield _sorted();
    yield* _eventsController.stream;
  }

  @override
  Stream<List<GroupMessage>> watchMessages(String eventId) async* {
    yield List<GroupMessage>.from(_messages[eventId] ?? const []);
    yield* _messageControllerFor(eventId).stream;
  }

  @override
  Stream<DateTime?> watchLastRead(String eventId) async* {
    yield _lastRead[eventId];
    yield* _readControllerFor(eventId).stream;
  }

  @override
  Future<void> joinEvent(String eventId) async {
    if (currentUserId.isEmpty) {
      return;
    }
    var added = false;
    for (var i = 0; i < _events.length; i++) {
      final event = _events[i];
      if (event.id != eventId || event.isJoined(currentUserId)) {
        continue;
      }
      _events[i] = event.copyWith(
        participantUserIds: [...event.participantUserIds, currentUserId],
      );
      added = true;
    }
    if (added) {
      _eventsController.add(_sorted());
      await sendMessage(
        eventId: eventId,
        text: EventsJoinCopy.joined(senderName),
        senderId: 'vauvau-system',
        senderName: 'VauVau',
      );
    }
    await markRead(eventId);
  }

  @override
  Future<void> markRead(String eventId) async {
    _lastRead[eventId] = DateTime.now();
    _readControllerFor(eventId).add(_lastRead[eventId]);
  }

  @override
  Future<void> sendMessage({
    required String eventId,
    required String text,
    String imageUrl = '',
    String? senderId,
    String? senderName,
    GroupMessage? replyTo,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl.trim().isEmpty) {
      return;
    }
    final id = senderId ?? currentUserId;
    final name = senderName ?? this.senderName;
    final message = GroupMessage(
      id: 'emsg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: id,
      senderName: name,
      senderAvatarUrl: id == currentUserId ? senderAvatarUrl : '',
      text: trimmed,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      isMine: id == currentUserId,
      replyToMessageId: replyTo?.id ?? '',
      replyToText: replyTo?.preview ?? '',
      replyToSenderName: replyTo?.senderName ?? '',
    );
    _append(eventId, message);
  }

  @override
  Future<void> sendPhoto({
    required String eventId,
    required String imageUrl,
    GroupMessage? replyTo,
  }) {
    return sendMessage(
      eventId: eventId,
      text: '',
      imageUrl: imageUrl,
      replyTo: replyTo,
    );
  }

  @override
  Future<void> sendWalkInvite({
    required String eventId,
    required DateTime walkTime,
    required String walkLocationName,
  }) async {
    final place = walkLocationName.trim();
    final preview =
        place.isEmpty ? 'Poziv na šetnju' : 'Poziv na šetnju: $place';
    _append(
      eventId,
      GroupMessage(
        id: 'emsg-${DateTime.now().millisecondsSinceEpoch}',
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
    required String eventId,
    required String messageId,
    required GroupWalkInviteStatus status,
  }) async {
    final current = _messages[eventId] ?? const <GroupMessage>[];
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
    _messages[eventId] = next;
    _messageControllerFor(eventId).add(List<GroupMessage>.from(next));
  }

  @override
  Future<void> toggleMessageLike({
    required String eventId,
    required String messageId,
  }) {
    String? mine;
    for (final message in _messages[eventId] ?? const <GroupMessage>[]) {
      if (message.id == messageId) {
        mine = MessageReactions.reactionOf(message.likes, currentUserId);
      }
    }
    return setMessageReaction(
      eventId: eventId,
      messageId: messageId,
      emoji: mine == '❤️' ? null : '❤️',
    );
  }

  @override
  Future<void> setMessageReaction({
    required String eventId,
    required String messageId,
    String? emoji,
  }) async {
    final current = _messages[eventId] ?? const <GroupMessage>[];
    final next = [
      for (final message in current)
        if (message.id == messageId)
          message.copyWith(
            likes: MessageReactions.apply(message.likes, currentUserId, emoji),
          )
        else
          message,
    ];
    _messages[eventId] = next;
    _messageControllerFor(eventId).add(List<GroupMessage>.from(next));
  }

  @override
  Future<String> createEvent(EventModel event) async {
    final id = event.id.isEmpty
        ? 'event-${DateTime.now().millisecondsSinceEpoch}'
        : event.id;
    final created = EventModel(
      id: id,
      title: event.title.trim(),
      locationName: event.locationName.trim(),
      dateTime: event.dateTime,
      description: event.description.trim(),
      imageUrl: event.imageUrl.trim().isEmpty
          ? kFallbackDogPhotoUrl
          : event.imageUrl.trim(),
      organizerUserId: currentUserId,
      organizerName: event.organizerName.trim().isEmpty
          ? (senderName.trim().isEmpty ? 'Korisnik' : senderName.trim())
          : event.organizerName.trim(),
      participantUserIds: {
        currentUserId,
        ...event.participantUserIds,
      }.where((id) => id.isNotEmpty).toList(),
      createdAt: DateTime.now(),
      cityId: event.cityId.trim(),
    );
    _events.insert(0, created);
    _lastRead[id] = DateTime.now();
    _eventsController.add(_sorted());
    return id;
  }

  void _append(String eventId, GroupMessage message) {
    final next = [..._messages[eventId] ?? const <GroupMessage>[], message];
    _messages[eventId] = next;
    for (var i = 0; i < _events.length; i++) {
      if (_events[i].id != eventId) {
        continue;
      }
      _events[i] = _events[i].copyWith(
        lastMessage: message.preview,
        lastMessageAt: message.createdAt,
      );
    }
    _messageControllerFor(eventId).add(List<GroupMessage>.from(next));
    _eventsController.add(_sorted());
  }

  StreamController<List<GroupMessage>> _messageControllerFor(String eventId) {
    return _messageControllers.putIfAbsent(
      eventId,
      StreamController<List<GroupMessage>>.broadcast,
    );
  }

  StreamController<DateTime?> _readControllerFor(String eventId) {
    return _readControllers.putIfAbsent(
      eventId,
      StreamController<DateTime?>.broadcast,
    );
  }

  List<EventModel> _sorted() {
    final copy = List<EventModel>.from(_events)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return copy;
  }
}

abstract final class EventsJoinCopy {
  static String joined(String name) => '$name se pridružio/la šetnji! 🐾';
}
