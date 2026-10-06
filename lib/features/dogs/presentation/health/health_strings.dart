import '../../domain/health_record.dart';

abstract final class HealthStrings {
  static const String sectionTitle = 'Karton zdravlja';
  static const String sectionIntro =
      'Evidencija vakcina i zaštite od parazita za tvog psa.';
  static const String addOrUpdate = 'Dodaj / Ažuriraj zapis';
  static const String administeredDate = 'Datum primene';
  static const String nextDueDate = 'Sledeći datum / Rok';
  static const String noDate = 'Nije izabrano';
  static const String clearDate = 'Obriši rok';
  static const String reminderToggle = 'Postavi podsetnik na telefonu';
  static const String reminderHint = 'Podsetnik stiže u 09:00 na dan roka.';
  static const String notes = 'Napomena';
  static const String save = 'Sačuvaj';
  static const String saved = 'Zapis je sačuvan.';
  static const String saveError = 'Zapis nije sačuvan. Pokušajte ponovo.';
  static const String reminderSet = 'Podsetnik je zakazan za 09:00.';
  static const String reminderUnavailable =
      'Podsetnik nije zakazan. Proverite dozvole za obaveštenja.';
  static const String lastDate = 'Poslednji put';
  static const String nextDate = 'Sledeće';
  static const String noRecord = 'Nema zapisa';
  static const String statusValid = '🟢 Uredu';
  static const String statusSoon = '🟡 Uskoro ističe';
  static const String statusExpired = '🔴 Isteklo';
  static const String statusUnknown = '⚪ Bez roka';
  static const String reminderBadge = '🔔 Podsetnik';
  static const String delete = 'Obriši zapis';
  static const String titleLabel = 'Naziv / Preparat';

  static String categoryLabel(HealthCategory category) {
    return switch (category) {
      HealthCategory.vaccineRabies => '💉 Besnilo',
      HealthCategory.vaccineCore => '🛡️ Zarazne bolesti',
      HealthCategory.deworming => '🪱 Unutrašnji paraziti',
      HealthCategory.tickProtection => '🦠 Krpelji i buve',
    };
  }

  static String categoryHint(HealthCategory category) {
    return switch (category) {
      HealthCategory.vaccineRabies => 'Vakcina protiv besnila',
      HealthCategory.vaccineCore => 'Vakcina protiv zaraznih bolesti',
      HealthCategory.deworming => 'Tablete protiv glista',
      HealthCategory.tickProtection => 'Bravecto / NexGard',
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

  static String reminderTitle(String dogName) => '🐾 $dogName — podsetnik';

  static String reminderBody(String dogName, String title) {
    return '$dogName: danas je rok za "$title".';
  }

  static String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}.';
  }
}
