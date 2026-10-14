import '../../../../core/l10n/l10n.dart';
import '../../domain/health_record.dart';

abstract final class HealthStrings {
  static String get sectionTitle => L10n.tr('Karton zdravlja', 'Health record');
  static String get sectionIntro => L10n.tr(
        'Evidencija vakcina i zaštite od parazita za tvog psa.',
        'Vaccination and parasite protection records for your dog.',
      );
  static String get addOrUpdate => L10n.tr('Dodaj / Ažuriraj zapis', 'Add / update record');
  static String get administeredDate => L10n.tr('Datum primene', 'Date given');
  static String get nextDueDate => L10n.tr('Sledeći datum / Rok', 'Next due date');
  static String get noDate => L10n.tr('Nije izabrano', 'Not selected');
  static String get clearDate => L10n.tr('Obriši rok', 'Clear due date');
  static String get reminderToggle => L10n.tr('Postavi podsetnik na telefonu', 'Set phone reminder');
  static String get reminderHint =>
      L10n.tr('Podsetnik stiže u 09:00 na dan roka.', 'Reminder arrives at 09:00 on the due date.');
  static String get notes => L10n.tr('Napomena', 'Notes');
  static String get save => L10n.tr('Sačuvaj', 'Save');
  static String get saved => L10n.tr('Zapis je sačuvan.', 'Record saved.');
  static String get saveError =>
      L10n.tr('Zapis nije sačuvan. Pokušajte ponovo.', 'Record was not saved. Try again.');
  static String get reminderSet => L10n.tr('Podsetnik je zakazan za 09:00.', 'Reminder scheduled for 09:00.');
  static String get reminderUnavailable => L10n.tr(
        'Podsetnik nije zakazan. Proverite dozvole za obaveštenja.',
        'Reminder not scheduled. Check notification permissions.',
      );
  static String get lastDate => L10n.tr('Poslednji put', 'Last time');
  static String get nextDate => L10n.tr('Sledeće', 'Next');
  static String get noRecord => L10n.tr('Nema zapisa', 'No record');
  static String get statusValid => L10n.tr('🟢 Uredu', '🟢 OK');
  static String get statusSoon => L10n.tr('🟡 Uskoro ističe', '🟡 Expiring soon');
  static String get statusExpired => L10n.tr('🔴 Isteklo', '🔴 Expired');
  static String get statusUnknown => L10n.tr('⚪ Bez roka', '⚪ No due date');
  static String get reminderBadge => L10n.tr('🔔 Podsetnik', '🔔 Reminder');
  static String get delete => L10n.tr('Obriši zapis', 'Delete record');
  static String get titleLabel => L10n.tr('Naziv / Preparat', 'Name / product');

  static String categoryLabel(HealthCategory category) {
    return switch (category) {
      HealthCategory.vaccineRabies =>
        L10n.tr('💉 Besnilo', '💉 Rabies'),
      HealthCategory.vaccineCore =>
        L10n.tr('🛡️ Zarazne bolesti', '🛡️ Core vaccines'),
      HealthCategory.deworming =>
        L10n.tr('🪱 Unutrašnji paraziti', '🪱 Internal parasites'),
      HealthCategory.tickProtection =>
        L10n.tr('🦠 Krpelji i buve', '🦠 Ticks and fleas'),
    };
  }

  static String categoryHint(HealthCategory category) {
    return switch (category) {
      HealthCategory.vaccineRabies =>
        L10n.tr('Vakcina protiv besnila', 'Rabies vaccine'),
      HealthCategory.vaccineCore =>
        L10n.tr('Vakcina protiv zaraznih bolesti', 'Core disease vaccine'),
      HealthCategory.deworming =>
        L10n.tr('Tablete protiv glista', 'Deworming tablets'),
      HealthCategory.tickProtection => L10n.tr('Bravecto / NexGard', 'Bravecto / NexGard'),
    };
  }

  static String statusLabel(HealthStatus status) {
    return switch (status) {
      HealthStatus.valid => statusValid,
      HealthStatus.expiringSoon => statusSoon,
      HealthStatus.expired => statusExpired,
      HealthStatus.unknown => statusUnknown,
    };
  }

  static String reminderTitle(String dogName) => L10n.tr(
        '🐾 $dogName — podsetnik',
        '🐾 $dogName — reminder',
      );

  static String reminderBody(String dogName, String title) => L10n.tr(
        '$dogName: danas je rok za "$title".',
        '$dogName: "$title" is due today.',
      );

  static String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}.';
  }
}
