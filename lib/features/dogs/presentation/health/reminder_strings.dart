import '../../domain/dog_reminder.dart';

abstract final class ReminderStrings {
  static const String sectionTitle = '🩺 Zdravlje i podsetnici';
  static const String nextReminder = 'Sledeći podsetnik';
  static const String emptyTitle = 'Još nemaš podsetnika';
  static const String emptyBody =
      'Izaberi šta želiš da pratiš i VauVau će te podsetiti na vreme.';
  static const String addFirst = '+ Dodaj prvi podsetnik';
  static const String addReminder = '+ Dodaj podsetnik';
  static const String showAll = 'Prikaži sve →';
  static const String remindersTitle = 'Podsetnici';
  static const String chooseTypeTitle = 'Šta želiš da pratiš?';
  static const String forWhichDog = 'Za kog psa?';
  static const String titleLabel = 'Naziv';
  static const String dateLabel = 'Datum obaveze';
  static const String dateHint =
      'Kad treba da obaviš uslugu (npr. sisanje, vakcina, tablete).';
  static const String repeatFieldLabel = 'Ponovi obavezu';
  static const String repeatHint =
      'Koliko često se ova ista obaveza ponavlja. Posle datuma VauVau '
      'automatski postavi sledeći termin.';
  static const String customIntervalLabel = 'Na koliko dana?';
  static const String customIntervalHint =
      'Podrazumevano 14 dana ako ne uneseš drugu vrednost.';
  static const String remindMeLabel = 'Podseti me';
  static const String remindMeHint =
      'Kad želiš obaveštenje pre ili na dan obaveze.';
  static const String noteLabel = 'Napomena';
  static const String noteHint = 'Opciono';
  static const String save = 'Sačuvaj';
  static const String saved = 'Podsetnik je sačuvan.';
  static const String saveError = 'Podsetnik nije sačuvan. Pokušajte ponovo.';
  static const String edit = 'Izmeni';
  static const String delete = 'Obriši';
  static const String deleteConfirm = 'Obrisati ovaj podsetnik?';
  static const String cancel = 'Otkaži';
  static const String details = 'Detalji podsetnika';
  static const String groupSoon = 'SLEDEĆE';
  static const String groupLater = 'KASNIJE';
  static const String groupOverdue = 'PROŠLO';
  static const String healthCardTitle = '🩺 Karton zdravlja';
  static const String healthCardEmpty = 'Karton zdravlja je prazan.';
  static const String openHealthCard = 'Otvori karton';
  static const String addHealthRecord = 'Dodaj zdravstveni zapis';
  static const String vaccines = 'Vakcine';
  static const String protection = 'Zaštita';
  static const String checkups = 'Pregledi';
  static const String records = 'zapisa';
  static const String record = 'zapis';
  static const String healthCardScreenTitle = 'Karton zdravlja';
  static const String catHealth = 'ZDRAVLJE';
  static const String catCare = 'NEGA';
  static const String catFood = 'ISHRANA';
  static const String catOther = 'OSTALO';

  static String activeCount(int count) {
    if (count == 1) {
      return '1 aktivan podsetnik';
    }
    if (count >= 2 && count <= 4) {
      return '$count aktivna podsetnika';
    }
    return '$count aktivnih podsetnika';
  }

  static String recordCount(int count) {
    if (count == 1) {
      return '1 $record';
    }
    return '$count $records';
  }

  static String typeLabel(ReminderType type) {
    return switch (type) {
      ReminderType.vaccineRabies => '💉 Vakcina protiv besnila',
      ReminderType.vaccineOther => '💉 Ostale vakcine',
      ReminderType.infectiousProtection => '🦠 Zaštita od zaraznih bolesti',
      ReminderType.internalParasites => '💊 Unutrašnji paraziti',
      ReminderType.ticksFleas => '🪲 Krpelji i buve',
      ReminderType.vetCheckup => '🩺 Veterinarski pregled',
      ReminderType.therapyMeds => '💊 Terapija / lekovi',
      ReminderType.dentalCheck => '🦷 Kontrola zuba',
      ReminderType.weightCheck => '⚖️ Kontrola težine',
      ReminderType.grooming => '✂️ Grooming',
      ReminderType.bathing => '🛁 Kupanje',
      ReminderType.nailTrim => '🐾 Sečenje noktiju',
      ReminderType.teethBrushing => '🦷 Pranje zuba',
      ReminderType.foodShopping => '🍖 Kupovina hrane',
      ReminderType.foodChange => '🔄 Promena hrane',
      ReminderType.supplements => '🧴 Dodaci / suplementi',
      ReminderType.birthday => '🎂 Rođendan psa',
      ReminderType.documentation => '📄 Dokumentacija',
      ReminderType.custom => '✏️ Moj podsetnik',
    };
  }

  static String typeShortLabel(ReminderType type) {
    return switch (type) {
      ReminderType.vaccineRabies => '💉 Besnilo',
      ReminderType.vaccineOther => '💉 Vakcina',
      ReminderType.infectiousProtection => '🦠 Zarazne bolesti',
      ReminderType.internalParasites => '💊 Paraziti',
      ReminderType.ticksFleas => '🪲 Zaštita od krpelja',
      ReminderType.vetCheckup => '🩺 Pregled',
      ReminderType.therapyMeds => '💊 Terapija',
      ReminderType.dentalCheck => '🦷 Zubi',
      ReminderType.weightCheck => '⚖️ Težina',
      ReminderType.grooming => '✂️ Grooming',
      ReminderType.bathing => '🛁 Kupanje',
      ReminderType.nailTrim => '🐾 Nokti',
      ReminderType.teethBrushing => '🦷 Pranje zuba',
      ReminderType.foodShopping => '🍖 Hrana',
      ReminderType.foodChange => '🔄 Promena hrane',
      ReminderType.supplements => '🧴 Suplementi',
      ReminderType.birthday => '🎂 Rođendan',
      ReminderType.documentation => '📄 Dokumentacija',
      ReminderType.custom => '✏️ Podsetnik',
    };
  }

  static String defaultTitle(ReminderType type) {
    final label = typeLabel(type);
    // Strip leading emoji + space for editable title defaults.
    final space = label.indexOf(' ');
    return space == -1 ? label : label.substring(space + 1);
  }

  static String labelForRepeat(ReminderRepeat repeat) {
    return switch (repeat) {
      ReminderRepeat.once => 'Samo jednom',
      ReminderRepeat.daily => 'Svakog dana',
      ReminderRepeat.weekly => 'Svake nedelje',
      ReminderRepeat.monthly => 'Svakog meseca',
      ReminderRepeat.every3Months => 'Na 3 meseca',
      ReminderRepeat.every6Months => 'Na 6 meseci',
      ReminderRepeat.yearly => 'Jednom godišnje',
      ReminderRepeat.custom => 'Prilagođeno (na N dana)',
    };
  }

  static String offsetLabel(ReminderOffset offset) {
    return switch (offset) {
      ReminderOffset.onDay => 'Na dan događaja',
      ReminderOffset.oneDayBefore => '1 dan ranije',
      ReminderOffset.threeDaysBefore => '3 dana ranije',
      ReminderOffset.sevenDaysBefore => '7 dana ranije',
    };
  }

  static String urgencyLabel(ReminderUrgency urgency) {
    return switch (urgency) {
      ReminderUrgency.upcoming => 'Predstoji',
      ReminderUrgency.today => 'Danas',
      ReminderUrgency.tomorrow => 'Sutra',
      ReminderUrgency.soon => 'Uskoro',
      ReminderUrgency.overdue => 'Prošao',
    };
  }

  static String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}.';
  }

  static String daysUntil(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final days = due.difference(today).inDays;
    if (days < 0) {
      final past = -days;
      if (past == 1) {
        return 'Kasni 1 dan';
      }
      return 'Kasni $past dana';
    }
    if (days == 0) {
      return 'Danas';
    }
    if (days == 1) {
      return 'Sutra';
    }
    return 'Za $days dana';
  }

  static List<ReminderType> typesFor(ReminderCategory category) {
    return [
      for (final type in ReminderType.values)
        if (type.category == category) type,
    ];
  }
}
