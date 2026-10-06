/// User-chosen reminder for a dog (vaccines, care, custom, etc.).
enum ReminderCategory {
  health,
  care,
  food,
  other,
}

enum ReminderType {
  vaccineRabies,
  vaccineOther,
  infectiousProtection,
  internalParasites,
  ticksFleas,
  vetCheckup,
  therapyMeds,
  dentalCheck,
  weightCheck,
  grooming,
  bathing,
  nailTrim,
  teethBrushing,
  foodShopping,
  foodChange,
  supplements,
  birthday,
  documentation,
  custom,
}

enum ReminderRepeat {
  once,
  daily,
  weekly,
  monthly,
  every3Months,
  every6Months,
  yearly,
  custom,
}

/// Unit for [ReminderRepeat.custom] intervals (count + unit).
enum CustomRepeatUnit {
  days,
  weeks,
  months,
}

extension CustomRepeatUnitX on CustomRepeatUnit {
  String get firestoreValue => name;

  static CustomRepeatUnit? fromString(String? value) {
    for (final item in CustomRepeatUnit.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }
}

/// Days before the event date to fire a local notification.
enum ReminderOffset {
  onDay,
  oneDayBefore,
  threeDaysBefore,
  sevenDaysBefore,
}

enum ReminderUrgency {
  upcoming,
  today,
  tomorrow,
  soon,
  overdue,
}

extension ReminderTypeX on ReminderType {
  String get firestoreValue => name;

  ReminderCategory get category => switch (this) {
        ReminderType.vaccineRabies ||
        ReminderType.vaccineOther ||
        ReminderType.infectiousProtection ||
        ReminderType.internalParasites ||
        ReminderType.ticksFleas ||
        ReminderType.vetCheckup ||
        ReminderType.therapyMeds ||
        ReminderType.dentalCheck ||
        ReminderType.weightCheck =>
          ReminderCategory.health,
        ReminderType.grooming ||
        ReminderType.bathing ||
        ReminderType.nailTrim ||
        ReminderType.teethBrushing =>
          ReminderCategory.care,
        ReminderType.foodShopping ||
        ReminderType.foodChange ||
        ReminderType.supplements =>
          ReminderCategory.food,
        ReminderType.birthday ||
        ReminderType.documentation ||
        ReminderType.custom =>
          ReminderCategory.other,
      };

  static ReminderType? fromString(String? value) {
    for (final type in ReminderType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }
}

extension ReminderRepeatX on ReminderRepeat {
  String get firestoreValue => name;

  static ReminderRepeat? fromString(String? value) {
    for (final item in ReminderRepeat.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }
}

extension ReminderOffsetX on ReminderOffset {
  String get firestoreValue => name;

  int get daysBefore => switch (this) {
        ReminderOffset.onDay => 0,
        ReminderOffset.oneDayBefore => 1,
        ReminderOffset.threeDaysBefore => 3,
        ReminderOffset.sevenDaysBefore => 7,
      };

  static ReminderOffset? fromString(String? value) {
    for (final item in ReminderOffset.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }
}

class DogReminder {
  const DogReminder({
    required this.id,
    required this.dogId,
    required this.title,
    required this.type,
    required this.date,
    this.repeatType = ReminderRepeat.once,
    this.reminderOffset = ReminderOffset.threeDaysBefore,
    this.note,
    this.isCompleted = false,
    this.notificationId,
    /// Preferred day-of-month for monthly/quarterly/yearly schedules (1–31).
    /// Preserves "31st of month" semantics across shorter months.
    this.repeatDayOfMonth,
    /// Count for [ReminderRepeat.custom] (paired with [customIntervalUnit]).
    this.customIntervalCount = defaultCustomIntervalCount,
    this.customIntervalUnit = CustomRepeatUnit.weeks,
    /// Most recent occurrence that already passed for a repeating reminder.
    this.lastCompletedDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Default custom cadence: every 2 weeks (same as former 14-day default).
  static const int defaultCustomIntervalCount = 2;
  static const CustomRepeatUnit defaultCustomIntervalUnit =
      CustomRepeatUnit.weeks;

  /// Legacy default expressed in days (for older docs that only stored days).
  static const int defaultCustomIntervalDays = 14;

  final String id;
  final String dogId;
  final String title;
  final ReminderType type;
  final DateTime date;
  final ReminderRepeat repeatType;
  final ReminderOffset reminderOffset;
  final String? note;
  final bool isCompleted;
  final int? notificationId;
  final int? repeatDayOfMonth;
  final int customIntervalCount;
  final CustomRepeatUnit customIntervalUnit;
  final DateTime? lastCompletedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReminderCategory get category => type.category;

  /// Date when a local notification should fire (date minus offset).
  DateTime get notifyDate {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: reminderOffset.daysBefore));
  }

  ReminderUrgency urgencyAt(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final days = due.difference(today).inDays;
    if (days < 0) {
      return ReminderUrgency.overdue;
    }
    if (days == 0) {
      return ReminderUrgency.today;
    }
    if (days == 1) {
      return ReminderUrgency.tomorrow;
    }
    if (days <= 14) {
      return ReminderUrgency.soon;
    }
    return ReminderUrgency.upcoming;
  }

  bool get isActive => !isCompleted;

  DogReminder copyWith({
    String? id,
    String? dogId,
    String? title,
    ReminderType? type,
    DateTime? date,
    ReminderRepeat? repeatType,
    ReminderOffset? reminderOffset,
    String? note,
    bool clearNote = false,
    bool? isCompleted,
    int? notificationId,
    bool clearNotificationId = false,
    int? repeatDayOfMonth,
    int? customIntervalCount,
    CustomRepeatUnit? customIntervalUnit,
    DateTime? lastCompletedDate,
    bool clearLastCompletedDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DogReminder(
      id: id ?? this.id,
      dogId: dogId ?? this.dogId,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      repeatType: repeatType ?? this.repeatType,
      reminderOffset: reminderOffset ?? this.reminderOffset,
      note: clearNote ? null : (note ?? this.note),
      isCompleted: isCompleted ?? this.isCompleted,
      notificationId: clearNotificationId
          ? null
          : (notificationId ?? this.notificationId),
      repeatDayOfMonth: repeatDayOfMonth ?? this.repeatDayOfMonth,
      customIntervalCount: customIntervalCount ?? this.customIntervalCount,
      customIntervalUnit: customIntervalUnit ?? this.customIntervalUnit,
      lastCompletedDate: clearLastCompletedDate
          ? null
          : (lastCompletedDate ?? this.lastCompletedDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int notificationIdFor(String reminderId) {
    return ('reminder_$reminderId'.hashCode) & 0x7fffffff;
  }
}
