import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/dog_reminder.dart';
import '../domain/reminder_repository.dart';

class FirestoreReminderRepository implements ReminderRepository {
  FirestoreReminderRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _col(String dogId) {
    return firestore.collection('dogs').doc(dogId).collection('reminders');
  }

  @override
  Stream<List<DogReminder>> watchReminders(String dogId) {
    if (dogId.isEmpty) {
      return Stream.value(const []);
    }
    return _col(dogId).snapshots().map((snapshot) {
      final items = [
        for (final doc in snapshot.docs) _fromDoc(dogId, doc),
      ]..sort((a, b) => a.date.compareTo(b.date));
      return items;
    });
  }

  @override
  Future<String> saveReminder(DogReminder reminder) async {
    final ref = reminder.id.isEmpty
        ? _col(reminder.dogId).doc()
        : _col(reminder.dogId).doc(reminder.id);
    try {
      await ref.set({
        'id': ref.id,
        'dogId': reminder.dogId,
        'title': reminder.title.trim(),
        'type': reminder.type.firestoreValue,
        'category': reminder.category.name,
        'date': Timestamp.fromDate(reminder.date),
        'repeatType': reminder.repeatType.firestoreValue,
        'reminderOffset': reminder.reminderOffset.firestoreValue,
        'note': reminder.note?.trim() ?? '',
        'isCompleted': reminder.isCompleted,
        'notificationId': reminder.notificationId,
        'repeatDayOfMonth':
            reminder.repeatDayOfMonth ?? reminder.date.day,
        'customIntervalCount': reminder.customIntervalCount > 0
            ? reminder.customIntervalCount
            : DogReminder.defaultCustomIntervalCount,
        'customIntervalUnit': reminder.customIntervalUnit.firestoreValue,
        'lastCompletedDate': reminder.lastCompletedDate == null
            ? null
            : Timestamp.fromDate(reminder.lastCompletedDate!),
        'updatedAt': FieldValue.serverTimestamp(),
        if (reminder.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return ref.id;
    } catch (error, stack) {
      debugPrint('Reminder save FAILED: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  @override
  Future<void> deleteReminder({
    required String dogId,
    required String reminderId,
  }) {
    return _col(dogId).doc(reminderId).delete();
  }

  DogReminder _fromDoc(
    String dogId,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final note = (data['note'] as String? ?? '').trim();
    return DogReminder(
      id: doc.id,
      dogId: data['dogId'] as String? ?? dogId,
      title: (data['title'] as String? ?? '').trim(),
      type: ReminderTypeX.fromString(data['type'] as String?) ??
          ReminderType.custom,
      date: _date(data['date']) ?? DateTime.now(),
      repeatType: ReminderRepeatX.fromString(data['repeatType'] as String?) ??
          ReminderRepeat.once,
      reminderOffset:
          ReminderOffsetX.fromString(data['reminderOffset'] as String?) ??
              ReminderOffset.threeDaysBefore,
      note: note.isEmpty ? null : note,
      isCompleted: data['isCompleted'] as bool? ?? false,
      notificationId: (data['notificationId'] as num?)?.toInt(),
      repeatDayOfMonth: (data['repeatDayOfMonth'] as num?)?.toInt(),
      customIntervalCount: _customCount(data),
      customIntervalUnit: _customUnit(data),
      lastCompletedDate: _date(data['lastCompletedDate']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  /// Prefers count+unit; falls back to legacy `customIntervalDays` as days.
  int _customCount(Map<String, dynamic> data) {
    final count = (data['customIntervalCount'] as num?)?.toInt();
    if (count != null && count > 0) {
      return count;
    }
    final legacyDays = (data['customIntervalDays'] as num?)?.toInt();
    if (legacyDays != null && legacyDays > 0) {
      return legacyDays;
    }
    return DogReminder.defaultCustomIntervalCount;
  }

  CustomRepeatUnit _customUnit(Map<String, dynamic> data) {
    final unit = CustomRepeatUnitX.fromString(
      data['customIntervalUnit'] as String?,
    );
    if (unit != null) {
      return unit;
    }
    // Legacy docs only stored days.
    if (data['customIntervalDays'] != null) {
      return CustomRepeatUnit.days;
    }
    return DogReminder.defaultCustomIntervalUnit;
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
