String formatChatTimestamp(DateTime time, DateTime now) {
  final local = time.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(local.year, local.month, local.day);
  final timeLabel =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

  if (messageDay == today) {
    return timeLabel;
  }
  if (messageDay == today.subtract(const Duration(days: 1))) {
    return 'Juče';
  }
  return '${local.day}.${local.month}.';
}

String formatWalkStamp(DateTime time) {
  final local = time.toLocal();
  final clock =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '${local.day}.${local.month}. $clock';
}
