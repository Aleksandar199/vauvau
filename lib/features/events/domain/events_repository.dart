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
  });

  Future<void> sendPhoto({
    required String eventId,
    required String imageUrl,
  });

  Future<String> createEvent(EventModel event);
}
