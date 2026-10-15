import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firebase_status.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/utils/content_validation_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../dogs/domain/dogs_exception.dart';
import '../../groups/domain/groups_models.dart';
import '../../location/presentation/home_city_provider.dart';
import '../../map/presentation/walk_controller.dart';
import '../data/firestore_events_repository.dart';
import '../data/local_events_repository.dart';
import '../data/seed_events.dart';
import '../domain/event_model.dart';
import '../domain/events_repository.dart';

class EventsController extends Notifier<List<EventModel>> {
  @override
  List<EventModel> build() {
    final repo = ref.watch(eventsRepositoryProvider);
    final sub = repo.watchEvents().listen(
      (events) => state = events,
      onError: (Object error) => debugPrint('Events stream: $error'),
    );
    ref.onDispose(sub.cancel);
    return const [];
  }

  Future<void> join(String eventId) {
    return ref.read(eventsRepositoryProvider).joinEvent(eventId);
  }

  Future<void> markRead(String eventId) {
    return ref.read(eventsRepositoryProvider).markRead(eventId);
  }

  Future<void> sendText(
    String eventId,
    String text, {
    GroupMessage? replyTo,
  }) {
    return ref.read(eventsRepositoryProvider).sendMessage(
          eventId: eventId,
          text: text,
          replyTo: replyTo,
        );
  }

  Future<void> sendPhoto(
    String eventId,
    XFile file, {
    GroupMessage? replyTo,
  }) async {
    final error = await ContentValidationService.validateImage(file);
    if (error != null) {
      throw DogsException(error);
    }
    final url = await ImageUploadService.uploadFile(
      file,
      folderName: 'events',
    );
    await ref.read(eventsRepositoryProvider).sendPhoto(
          eventId: eventId,
          imageUrl: url,
          replyTo: replyTo,
        );
  }

  Future<void> sendWalkInvite({
    required String eventId,
    required DateTime walkTime,
    required String walkLocationName,
  }) {
    return ref.read(eventsRepositoryProvider).sendWalkInvite(
          eventId: eventId,
          walkTime: walkTime,
          walkLocationName: walkLocationName,
        );
  }

  Future<void> respondToWalkInvite({
    required String eventId,
    required String messageId,
    required GroupWalkInviteStatus status,
  }) {
    return ref.read(eventsRepositoryProvider).respondToWalkInvite(
          eventId: eventId,
          messageId: messageId,
          status: status,
        );
  }

  Future<void> toggleMessageLike({
    required String eventId,
    required String messageId,
  }) {
    return ref.read(eventsRepositoryProvider).toggleMessageLike(
          eventId: eventId,
          messageId: messageId,
        );
  }

  Future<void> setMessageReaction({
    required String eventId,
    required String messageId,
    String? emoji,
  }) {
    return ref.read(eventsRepositoryProvider).setMessageReaction(
          eventId: eventId,
          messageId: messageId,
          emoji: emoji,
        );
  }

  Future<String> create({
    required String title,
    required String locationName,
    required DateTime dateTime,
    required String description,
    String cityId = '',
    XFile? photo,
  }) async {
    try {
      var imageUrl = kFallbackDogPhotoUrl;
      if (photo != null) {
        final error = await ContentValidationService.validateImage(photo);
        if (error != null) {
          throw DogsException(error);
        }
        imageUrl = await ImageUploadService.uploadFile(
          photo,
          folderName: 'events',
        );
      }
      final user = ref.read(authStateProvider).asData?.value;
      var uid = (user?.uid ?? '').trim();
      var organizerName = (user?.displayName ?? '').trim();
      if (isFirebaseReady) {
        final auth = FirebaseAuth.instance.currentUser;
        if (uid.isEmpty) {
          uid = (auth?.uid ?? '').trim();
        }
        final authName = (auth?.displayName ?? '').trim();
        if (authName.isNotEmpty) {
          organizerName = authName;
        }
      }
      if (organizerName.isEmpty) {
        organizerName = 'Korisnik';
      }
      return await ref.read(eventsRepositoryProvider).createEvent(
            EventModel(
              id: '',
              title: title.trim(),
              locationName: locationName.trim(),
              dateTime: dateTime,
              description: description.trim(),
              imageUrl: imageUrl,
              organizerUserId: uid,
              organizerName: organizerName,
              participantUserIds: uid.isEmpty ? const [] : [uid],
              createdAt: DateTime.now(),
              cityId: cityId.trim(),
            ),
          );
    } catch (error, stack) {
      debugPrint('Event create failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  final uid = user?.uid ?? '';
  final name = (user?.displayName ?? '').trim().isEmpty
      ? 'Korisnik'
      : user!.displayName!.trim();
  final avatar = user?.ownerAvatarUrl ?? '';
  if (isFirebaseReady) {
    return FirestoreEventsRepository(
      firestore: FirebaseFirestore.instance,
      currentUserId: uid,
      senderName: name,
      senderAvatarUrl: avatar,
    );
  }
  final repo = LocalEventsRepository(
    currentUserId: uid.isEmpty ? 'local-user' : uid,
    senderName: name == 'Korisnik' ? 'Ti' : name,
    senderAvatarUrl: avatar,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final eventsControllerProvider =
    NotifierProvider<EventsController, List<EventModel>>(EventsController.new);

/// City shown on the events screen; `null` means all cities.
/// Defaults to the user's home city.
class EventsCityFilter extends Notifier<String?> {
  @override
  String? build() => ref.watch(homeCityProvider)?.id;

  void select(String? cityId) => state = cityId;
}

final eventsCityFilterProvider =
    NotifierProvider<EventsCityFilter, String?>(EventsCityFilter.new);

/// Walk locations offered in the create form for a [SerbiaLocations] city id.
final eventVenuesProvider = Provider.family<List<String>, String>((ref, cityId) {
  return EventVenues.forCity(cityId, ref.watch(mapPlacesProvider));
});

final eventMessagesProvider =
    StreamProvider.family<List<GroupMessage>, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).watchMessages(eventId);
});

final eventLastReadProvider =
    StreamProvider.family<DateTime?, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).watchLastRead(eventId);
});

final eventsMemberIdProvider = Provider<String>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
  if (uid.isNotEmpty) {
    return uid;
  }
  return isFirebaseReady ? '' : 'local-user';
});

final eventByIdProvider = Provider.family<EventModel?, String>((ref, eventId) {
  for (final event in ref.watch(eventsControllerProvider)) {
    if (event.id == eventId) {
      return event;
    }
  }
  return null;
});

final joinedEventThreadsProvider = Provider<List<EventInboxThread>>((ref) {
  final memberId = ref.watch(eventsMemberIdProvider);
  final threads = [
    for (final event in ref.watch(eventsControllerProvider))
      if (event.isJoined(memberId))
        _threadFor(
          event,
          ref.watch(eventMessagesProvider(event.id)).asData?.value ?? const [],
          ref.watch(eventLastReadProvider(event.id)).asData?.value,
        ),
  ]..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
  return threads;
});

EventInboxThread _threadFor(
  EventModel event,
  List<GroupMessage> messages,
  DateTime? lastRead,
) {
  final mapped = GroupInboxThread.fromMessages(
    group: BreedGroup(
      id: event.id,
      title: event.title,
      description: event.description,
      imageUrl: event.imageUrl,
      memberIds: event.participantUserIds,
      memberCount: event.participantCount,
      lastMessage: event.lastMessage,
      lastMessageAt: event.lastMessageAt ?? event.dateTime,
    ),
    messages: messages,
    lastRead: lastRead,
  );
  return EventInboxThread(
    event: event,
    lastMessage: mapped.lastMessage,
    lastActivityAt: mapped.lastActivityAt,
    unreadCount: mapped.unreadCount,
  );
}
