import '../../groups/domain/groups_models.dart';
import 'event_model.dart';

abstract class EventsRepository {
  Stream<List<EventModel>> watchEvents();

  Stream<List<GroupMessage>> watchMessages(String eventId);

  Stream<DateTime?> watchLastRead(String eventId);

  Future<void> joinEvent(String eventId);

  Future<void> markRead(String eventId);

  Future<void> sendMessage({
    required String eventId,
    required String text,
    String imageUrl = '',
    String? senderId,
    String? senderName,
    GroupMessage? replyTo,
  });

  Future<void> sendPhoto({
    required String eventId,
    required String imageUrl,
    GroupMessage? replyTo,
  });

  Future<void> sendWalkInvite({
    required String eventId,
    required DateTime walkTime,
    required String walkLocationName,
  });

  Future<void> respondToWalkInvite({
    required String eventId,
    required String messageId,
    required GroupWalkInviteStatus status,
  });

  Future<void> toggleMessageLike({
    required String eventId,
    required String messageId,
  });

  Future<String> createEvent(EventModel event);
}
