class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.locationName,
    required this.dateTime,
    required this.description,
    required this.imageUrl,
    required this.organizerUserId,
    required this.organizerName,
    required this.participantUserIds,
    required this.createdAt,
    this.lastMessage = '',
    this.lastMessageAt,
    this.cityId = '',
  });

  final String id;
  /// [SerbiaLocations] id (`novi_sad`, `beograd`, `nis`, `kragujevac`).
  /// Empty on events created before city support.
  final String cityId;
  final String title;
  final String locationName;
  final DateTime dateTime;
  final String description;
  final String imageUrl;
  final String organizerUserId;
  final String organizerName;
  final List<String> participantUserIds;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime? lastMessageAt;

  int get participantCount => participantUserIds.length;

  bool isJoined(String uid) =>
      uid.isNotEmpty && participantUserIds.contains(uid);

  /// Keep listing for a few hours after start so late joiners still see it.
  static const Duration listGrace = Duration(hours: 6);

  /// Whether this event should appear in the Events & walks list.
  bool isListed([DateTime? now]) {
    final reference = now ?? DateTime.now();
    return dateTime.add(listGrace).isAfter(reference);
  }

  EventModel copyWith({
    String? title,
    String? locationName,
    DateTime? dateTime,
    String? description,
    String? imageUrl,
    List<String>? participantUserIds,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? cityId,
  }) {
    return EventModel(
      id: id,
      cityId: cityId ?? this.cityId,
      title: title ?? this.title,
      locationName: locationName ?? this.locationName,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerUserId: organizerUserId,
      organizerName: organizerName,
      participantUserIds: participantUserIds ?? this.participantUserIds,
      createdAt: createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

class EventInboxThread {
  const EventInboxThread({
    required this.event,
    required this.lastMessage,
    required this.lastActivityAt,
    required this.unreadCount,
  });

  final EventModel event;
  final String lastMessage;
  final DateTime lastActivityAt;
  final int unreadCount;
}
