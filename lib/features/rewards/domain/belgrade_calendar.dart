/// Day / week keys in Europe/Belgrade time without the tz database.
///
/// The same algorithm is mirrored in `firestore.rules` (`belgradeOffsetH`,
/// `belgradeDayKey`, `belgradeWeekKey`), so the client and the rules always
/// agree which day a walk belongs to. Change both together.
///
/// EU summer time: from the last Sunday of March 01:00 UTC to the last
/// Sunday of October 01:00 UTC → UTC+2, otherwise UTC+1.
abstract final class BelgradeCalendar {
  static int offsetHours(DateTime instant) {
    final utc = instant.toUtc();
    final month = utc.month;
    final day = utc.day;
    // Day of the most recent Sunday (DateTime.sunday == 7 → 0).
    final lastSunday = day - (utc.weekday % 7);
    final pastSwitch = lastSunday >= 25 && (day > lastSunday || utc.hour >= 1);
    final summer =
        (month > 3 && month < 10) ||
        (month == 3 && pastSwitch) ||
        (month == 10 && !pastSwitch);
    return summer ? 2 : 1;
  }

  /// Wall-clock time in Belgrade, as a UTC [DateTime] (fields = local).
  static DateTime local(DateTime instant) {
    final utc = instant.toUtc();
    return utc.add(Duration(hours: offsetHours(utc)));
  }

  static int _key(DateTime local) =>
      local.year * 10000 + local.month * 100 + local.day;

  /// e.g. 20261016 for 16 Oct 2026 in Belgrade.
  static int dayKey(DateTime instant) => _key(local(instant));

  /// Day key of the Monday that starts the Belgrade week of [instant].
  static int weekKey(DateTime instant) {
    final l = local(instant);
    return _key(l.subtract(Duration(days: l.weekday - 1)));
  }

  /// Next Belgrade midnight after [instant] (daily challenge reset).
  static DateTime nextMidnight(DateTime instant) {
    final l = local(instant);
    final nextLocalMidnight = DateTime.utc(l.year, l.month, l.day + 1);
    // Convert back: the offset at the target moment may differ (DST night).
    var utc = nextLocalMidnight.subtract(Duration(hours: offsetHours(instant)));
    final fix = offsetHours(utc) - offsetHours(instant);
    if (fix != 0) utc = utc.subtract(Duration(hours: fix));
    return utc;
  }

  /// Start of the next Belgrade week (Monday 00:00) after [instant].
  static DateTime nextWeekStart(DateTime instant) {
    final l = local(instant);
    final daysLeft = 8 - l.weekday;
    var midnight = nextMidnight(instant);
    for (var i = 1; i < daysLeft; i++) {
      midnight = nextMidnight(midnight.add(const Duration(hours: 1)));
    }
    return midnight;
  }

  /// "16.10.2026." for a day key.
  static String formatDayKey(int key) {
    final year = key ~/ 10000;
    final month = (key ~/ 100) % 100;
    final day = key % 100;
    return '$day.$month.$year.';
  }
}
