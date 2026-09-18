class ScheduledWalk {
  const ScheduledWalk({
    required this.id,
    required this.conversationId,
    required this.dogName,
    required this.ownerName,
    required this.locationName,
    required this.walkTime,
  });

  final String id;
  final String conversationId;
  final String dogName;
  final String ownerName;
  final String locationName;
  final DateTime walkTime;
}
