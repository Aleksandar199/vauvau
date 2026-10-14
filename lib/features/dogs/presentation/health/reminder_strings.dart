import '../../../../core/l10n/l10n.dart';
import '../../domain/dog_reminder.dart';

abstract final class ReminderStrings {
  static String get sectionTitle => L10n.tr('🩺 Zdravlje i podsetnici', '🩺 Health & reminders');
  static String get nextReminder => L10n.tr('Sledeći podsetnik', 'Next reminder');
  static String get emptyTitle => L10n.tr('Još nemaš podsetnika', 'No reminders yet');
  static String get emptyBody => L10n.tr(
        'Izaberi šta želiš da pratiš i VauVau će te podsetiti na vreme.',
        'Choose what to track and VauVau will remind you on time.',
      );
  static String get addFirst => L10n.tr('+ Dodaj prvi podsetnik', '+ Add first reminder');
  static String get addReminder => L10n.tr('+ Dodaj podsetnik', '+ Add reminder');
  static String get showAll => L10n.tr('Prikaži sve →', 'Show all →');
  static String get remindersTitle => L10n.tr('Podsetnici', 'Reminders');
  static String get chooseTypeTitle => L10n.tr('Šta želiš da pratiš?', 'What do you want to track?');
  static String get forWhichDog => L10n.tr('Za kog psa?', 'For which dog?');
  static String get titleLabel => L10n.tr('Naziv', 'Title');
  static String get dateLabel => L10n.tr('Datum obaveze', 'Due date');
  static String get dateHint => L10n.tr(
        'Kad treba da obaviš uslugu (npr. sisanje, vakcina, tablete).',
        'When the task is due (e.g. grooming, vaccine, tablets).',
      );
  static String get repeatFieldLabel => L10n.tr('Ponovi obavezu', 'Repeat');
  static String get repeatHint => L10n.tr(
        'Koliko često se ova ista obaveza ponavlja. Posle datuma VauVau '
        'automatski postavi sledeći termin.',
        'How often this task repeats. After the date VauVau automatically sets the next one.',
      );
  static String get customIntervalLabel => L10n.tr('Svakih', 'Every');
  static String get customIntervalHint => L10n.tr(
        'Unesi broj i izaberi dane, nedelje ili mesece.',
        'Enter a number and choose days, weeks, or months.',
      );
  static String get customUnitDays => L10n.tr('dana', 'days');
  static String get customUnitWeeks => L10n.tr('nedelja', 'weeks');
  static String get customUnitMonths => L10n.tr('meseci', 'months');
  static String get remindMeLabel => L10n.tr('Podseti me', 'Remind me');
  static String get remindMeHint => L10n.tr(
        'Kad želiš obaveštenje pre ili na dan obaveze.',
        'When you want a notification before or on the due date.',
      );
  static String get noteLabel => L10n.tr('Napomena', 'Note');
  static String get noteHint => L10n.tr('Opciono', 'Optional');
  static String get save => L10n.tr('Sačuvaj', 'Save');
  static String get saved => L10n.tr('Podsetnik je sačuvan.', 'Reminder saved.');
  static String get saveError =>
      L10n.tr('Podsetnik nije sačuvan. Pokušajte ponovo.', 'Reminder was not saved. Try again.');
  static String get edit => L10n.tr('Izmeni', 'Edit');
  static String get delete => L10n.tr('Obriši', 'Delete');
  static String get deleteConfirm => L10n.tr('Obrisati ovaj podsetnik?', 'Delete this reminder?');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get details => L10n.tr('Detalji podsetnika', 'Reminder details');
  static String get groupSoon => L10n.tr('SLEDEĆE', 'UP NEXT');
  static String get groupLater => L10n.tr('KASNIJE', 'LATER');
  static String get groupOverdue => L10n.tr('PROŠLO', 'OVERDUE');
  static String get healthCardTitle => L10n.tr('🩺 Karton zdravlja', '🩺 Health record');
  static String get healthCardEmpty => L10n.tr('Karton zdravlja je prazan.', 'Health record is empty.');
  static String get openHealthCard => L10n.tr('Otvori karton', 'Open record');
  static String get addHealthRecord => L10n.tr('Dodaj zdravstveni zapis', 'Add health record');
  static String get vaccines => L10n.tr('Vakcine', 'Vaccines');
  static String get protection => L10n.tr('Zaštita', 'Protection');
  static String get checkups => L10n.tr('Pregledi', 'Checkups');
  static String get records => L10n.tr('zapisa', 'records');
  static String get record => L10n.tr('zapis', 'record');
  static String get healthCardScreenTitle => L10n.tr('Karton zdravlja', 'Health record');
  static String get catHealth => L10n.tr('ZDRAVLJE', 'HEALTH');
  static String get catCare => L10n.tr('NEGA', 'CARE');
  static String get catFood => L10n.tr('ISHRANA', 'FOOD');
  static String get catOther => L10n.tr('OSTALO', 'OTHER');

  static String activeCount(int count) {
    if (L10n.isEnglish) {
      return count == 1 ? '1 active reminder' : '$count active reminders';
    }
    if (count == 1) {
      return '1 aktivan podsetnik';
    }
    if (count >= 2 && count <= 4) {
      return '$count aktivna podsetnika';
    }
    return '$count aktivnih podsetnika';
  }

  static String recordCount(int count) {
    if (L10n.isEnglish) {
      return count == 1 ? '1 $record' : '$count $records';
    }
    if (count == 1) {
      return '1 $record';
    }
    return '$count $records';
  }

  static String typeLabel(ReminderType type) {
    return switch (type) {
      ReminderType.vaccineRabies =>
        L10n.tr('💉 Vakcina protiv besnila', '💉 Rabies vaccine'),
      ReminderType.vaccineOther =>
        L10n.tr('💉 Ostale vakcine', '💉 Other vaccines'),
      ReminderType.infectiousProtection =>
        L10n.tr('🦠 Zaštita od zaraznih bolesti', '🦠 Infectious disease protection'),
      ReminderType.internalParasites =>
        L10n.tr('💊 Unutrašnji paraziti', '💊 Internal parasites'),
      ReminderType.ticksFleas =>
        L10n.tr('🪲 Krpelji i buve', '🪲 Ticks and fleas'),
      ReminderType.vetCheckup =>
        L10n.tr('🩺 Veterinarski pregled', '🩺 Vet checkup'),
      ReminderType.therapyMeds =>
        L10n.tr('💊 Terapija / lekovi', '💊 Therapy / medication'),
      ReminderType.dentalCheck =>
        L10n.tr('🦷 Kontrola zuba', '🦷 Dental check'),
      ReminderType.weightCheck =>
        L10n.tr('⚖️ Kontrola težine', '⚖️ Weight check'),
      ReminderType.grooming => L10n.tr('✂️ Grooming', '✂️ Grooming'),
      ReminderType.bathing => L10n.tr('🛁 Kupanje', '🛁 Bath'),
      ReminderType.nailTrim =>
        L10n.tr('🐾 Sečenje noktiju', '🐾 Nail trim'),
      ReminderType.teethBrushing =>
        L10n.tr('🦷 Pranje zuba', '🦷 Teeth brushing'),
      ReminderType.foodShopping =>
        L10n.tr('🍖 Kupovina hrane', '🍖 Buy food'),
      ReminderType.foodChange =>
        L10n.tr('🔄 Promena hrane', '🔄 Food change'),
      ReminderType.supplements =>
        L10n.tr('🧴 Dodaci / suplementi', '🧴 Supplements'),
      ReminderType.birthday =>
        L10n.tr('🎂 Rođendan psa', '🎂 Dog birthday'),
      ReminderType.documentation =>
        L10n.tr('📄 Dokumentacija', '📄 Documentation'),
      ReminderType.custom =>
        L10n.tr('✏️ Moj podsetnik', '✏️ Custom reminder'),
    };
  }

  static String typeShortLabel(ReminderType type) {
    return switch (type) {
      ReminderType.vaccineRabies => L10n.tr('💉 Besnilo', '💉 Rabies'),
      ReminderType.vaccineOther => L10n.tr('💉 Vakcina', '💉 Vaccine'),
      ReminderType.infectiousProtection =>
        L10n.tr('🦠 Zarazne bolesti', '🦠 Core diseases'),
      ReminderType.internalParasites => L10n.tr('💊 Paraziti', '💊 Parasites'),
      ReminderType.ticksFleas =>
        L10n.tr('🪲 Zaštita od krpelja', '🪲 Tick protection'),
      ReminderType.vetCheckup => L10n.tr('🩺 Pregled', '🩺 Checkup'),
      ReminderType.therapyMeds => L10n.tr('💊 Terapija', '💊 Therapy'),
      ReminderType.dentalCheck => L10n.tr('🦷 Zubi', '🦷 Teeth'),
      ReminderType.weightCheck => L10n.tr('⚖️ Težina', '⚖️ Weight'),
      ReminderType.grooming => L10n.tr('✂️ Grooming', '✂️ Grooming'),
      ReminderType.bathing => L10n.tr('🛁 Kupanje', '🛁 Bath'),
      ReminderType.nailTrim => L10n.tr('🐾 Nokti', '🐾 Nails'),
      ReminderType.teethBrushing =>
        L10n.tr('🦷 Pranje zuba', '🦷 Teeth brushing'),
      ReminderType.foodShopping => L10n.tr('🍖 Hrana', '🍖 Food'),
      ReminderType.foodChange =>
        L10n.tr('🔄 Promena hrane', '🔄 Food change'),
      ReminderType.supplements => L10n.tr('🧴 Suplementi', '🧴 Supplements'),
      ReminderType.birthday => L10n.tr('🎂 Rođendan', '🎂 Birthday'),
      ReminderType.documentation =>
        L10n.tr('📄 Dokumentacija', '📄 Documentation'),
      ReminderType.custom => L10n.tr('✏️ Podsetnik', '✏️ Reminder'),
    };
  }

  static String defaultTitle(ReminderType type) {
    final label = typeLabel(type);
    final space = label.indexOf(' ');
    return space == -1 ? label : label.substring(space + 1);
  }

  static String labelForRepeat(ReminderRepeat repeat) {
    return switch (repeat) {
      ReminderRepeat.once => L10n.tr('Samo jednom', 'Once'),
      ReminderRepeat.daily => L10n.tr('Svakog dana', 'Every day'),
      ReminderRepeat.weekly => L10n.tr('Svake nedelje', 'Every week'),
      ReminderRepeat.monthly => L10n.tr('Svakog meseca', 'Every month'),
      ReminderRepeat.every3Months => L10n.tr('Na 3 meseca', 'Every 3 months'),
      ReminderRepeat.every6Months => L10n.tr('Na 6 meseci', 'Every 6 months'),
      ReminderRepeat.yearly => L10n.tr('Jednom godišnje', 'Once a year'),
      ReminderRepeat.custom => L10n.tr('Prilagođeno', 'Custom'),
    };
  }

  static String labelForCustomUnit(CustomRepeatUnit unit) {
    return switch (unit) {
      CustomRepeatUnit.days => customUnitDays,
      CustomRepeatUnit.weeks => customUnitWeeks,
      CustomRepeatUnit.months => customUnitMonths,
    };
  }

  static String customIntervalSummary({
    required int count,
    required CustomRepeatUnit unit,
  }) {
    final n = count > 0 ? count : DogReminder.defaultCustomIntervalCount;
    if (L10n.isEnglish) {
      return 'Every $n ${labelForCustomUnit(unit)}';
    }
    return 'Svakih $n ${labelForCustomUnit(unit)}';
  }

  static String offsetLabel(ReminderOffset offset) {
    return switch (offset) {
      ReminderOffset.onDay => L10n.tr('Na dan događaja', 'On the day'),
      ReminderOffset.oneDayBefore => L10n.tr('1 dan ranije', '1 day before'),
      ReminderOffset.threeDaysBefore => L10n.tr('3 dana ranije', '3 days before'),
      ReminderOffset.sevenDaysBefore => L10n.tr('7 dana ranije', '7 days before'),
    };
  }

  static String urgencyLabel(ReminderUrgency urgency) {
    return switch (urgency) {
      ReminderUrgency.upcoming => L10n.tr('Predstoji', 'Upcoming'),
      ReminderUrgency.today => L10n.tr('Danas', 'Today'),
      ReminderUrgency.tomorrow => L10n.tr('Sutra', 'Tomorrow'),
      ReminderUrgency.soon => L10n.tr('Uskoro', 'Soon'),
      ReminderUrgency.overdue => L10n.tr('Prošao', 'Overdue'),
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
      if (L10n.isEnglish) {
        return past == 1 ? '1 day overdue' : '$past days overdue';
      }
      if (past == 1) {
        return 'Kasni 1 dan';
      }
      return 'Kasni $past dana';
    }
    if (days == 0) {
      return L10n.tr('Danas', 'Today');
    }
    if (days == 1) {
      return L10n.tr('Sutra', 'Tomorrow');
    }
    return L10n.tr('Za $days dana', 'In $days days');
  }

  static List<ReminderType> typesFor(ReminderCategory category) {
    return [
      for (final type in ReminderType.values)
        if (type.category == category) type,
    ];
  }
}
