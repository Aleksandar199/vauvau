enum HealthCategory {
  vaccineRabies,
  vaccineCore,
  deworming,
  tickProtection,
}

extension HealthCategoryX on HealthCategory {
  String get firestoreValue => name;

  static HealthCategory? fromString(String? value) {
    for (final category in HealthCategory.values) {
      if (category.name == value) {
        return category;
      }
    }
    return null;
  }
}

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.dogId,
    required this.category,
    required this.title,
    required this.administeredDate,
    this.nextDueDate,
    this.notes,
    this.notificationId,
  });

  /// Number of days before [nextDueDate] where the record counts as expiring.
  static const int expiringSoonDays = 30;

  final String id;
  final String dogId;
  final HealthCategory category;
  final String title;
  final DateTime administeredDate;
  final DateTime? nextDueDate;
  final String? notes;
  final int? notificationId;

  HealthStatus statusAt(DateTime now) {
    final due = nextDueDate;
    if (due == null) {
      return HealthStatus.unknown;
    }
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    if (dueDay.isBefore(today)) {
      return HealthStatus.expired;
    }
    if (dueDay.difference(today).inDays <= expiringSoonDays) {
      return HealthStatus.expiringSoon;
    }
    return HealthStatus.valid;
  }

  HealthRecord copyWith({
    String? id,
    String? title,
    DateTime? administeredDate,
    DateTime? nextDueDate,
    bool clearNextDueDate = false,
    String? notes,
    int? notificationId,
    bool clearNotificationId = false,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      dogId: dogId,
      category: category,
      title: title ?? this.title,
      administeredDate: administeredDate ?? this.administeredDate,
      nextDueDate: clearNextDueDate ? null : (nextDueDate ?? this.nextDueDate),
      notes: notes ?? this.notes,
      notificationId:
          clearNotificationId ? null : (notificationId ?? this.notificationId),
    );
  }

  /// Stable notification id derived from the record id, kept inside the 32-bit
  /// range required by the Android alarm manager.
  static int notificationIdFor(String recordId) {
    return recordId.hashCode & 0x7fffffff;
  }
}

enum HealthStatus { valid, expiringSoon, expired, unknown }
