import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum TipCategory { urgent, prevention, daily }

enum TipCtaKind { sosVets, findWalk, dogProfile, writeAdmin }

class TipSection {
  const TipSection({
    required this.title,
    this.bullets = const [],
    this.steps = const [],
    this.warning,
    this.isChecklist = false,
  });

  final String title;
  final List<String> bullets;
  final List<String> steps;
  final String? warning;
  final bool isChecklist;
}

class TipArticle {
  const TipArticle({
    required this.id,
    required this.category,
    required this.icon,
    required this.accent,
    required this.title,
    required this.summary,
    required this.sections,
    this.footerNote,
    this.cta,
    this.ctaLabel,
    this.initiallyExpanded = false,
  });

  final String id;
  final TipCategory category;
  final IconData icon;
  final Color accent;
  final String title;
  final String summary;
  final List<TipSection> sections;
  final String? footerNote;
  final TipCtaKind? cta;
  final String? ctaLabel;
  final bool initiallyExpanded;
}

abstract final class TipsContent {
  static const Color urgentAccent = Color(0xFFDC2626);
  static const Color preventionAccent = Color(0xFF0D9488);
  static const Color dailyAccent = AppColors.primary;

  static const List<TipArticle> articles = [
    // ── HITNO ──────────────────────────────────────────────
    TipArticle(
      id: 'urgent-vet',
      category: TipCategory.urgent,
      icon: Icons.emergency_outlined,
      accent: urgentAccent,
      title: '🚨 Kada odmah kod veterinara',
      summary: 'Znaci koji zahtevaju hitnu veterinarsku pomoć',
      initiallyExpanded: true,
      cta: TipCtaKind.sosVets,
      ctaLabel: '📍 DEŽURNI VETERINARI',
      sections: [
        TipSection(
          title: 'Hitne situacije',
          bullets: [
            'Otežano ili izrazito ubrzano disanje',
            'Gubitak svesti ili kolaps',
            'Napad / grčevi',
            'Obilno ili nekontrolisano krvarenje',
            'Sumnja na trovanje',
            'Ozbiljna povreda',
            'Sumnja na prelom',
            'Izrazita slabost ili naglo pogoršanje stanja',
            'Znaci toplotnog udara',
          ],
        ),
      ],
      footerNote:
          'Ako se stanje psa brzo pogoršava ili niste sigurni koliko je situacija ozbiljna, kontaktirajte veterinara.',
    ),
    TipArticle(
      id: 'heatstroke',
      category: TipCategory.urgent,
      icon: Icons.wb_sunny_outlined,
      accent: urgentAccent,
      title: '☀️ Toplotni udar',
      summary: 'Kako prepoznati i šta uraditi odmah',
      sections: [
        TipSection(
          title: 'Znaci',
          bullets: [
            'Jako i ubrzano dahtanje',
            'Pojačano slinjenje',
            'Slabost',
            'Teturanje',
            'Povraćanje',
            'Proliv',
            'Zbunjenost',
            'Kolaps',
            'Gubitak svesti',
          ],
        ),
        TipSection(
          title: 'Šta uraditi',
          steps: [
            'Odmah sklonite psa sa sunca.',
            'Prebacite ga u hladan / prozračan prostor.',
            'Započnite postepeno rashlađivanje.',
            'Omogućite strujanje vazduha.',
            'Kontaktirajte veterinara i najavite dolazak.',
          ],
          warning:
              'Ne čekajte da se pas sam ohladi ako sumnjate na toplotni udar.',
        ),
        TipSection(
          title: 'Prevencija',
          bullets: [
            'Izbegavajte najtopliji deo dana',
            'Obezbedite svežu vodu',
            'Nikada ne ostavljajte psa samog u parkiranom automobilu',
            'Posebno pazite na pse koji teže podnose toplotu',
          ],
        ),
      ],
    ),
    TipArticle(
      id: 'first-aid',
      category: TipCategory.urgent,
      icon: Icons.medical_services_outlined,
      accent: urgentAccent,
      title: '🩹 Prva pomoć',
      summary: 'Krvarenje i površinske rane — prvi koraci',
      sections: [
        TipSection(
          title: 'Krvarenje',
          bullets: [
            'Stavite čistu gazu ili čistu tkaninu preko rane',
            'Izvršite kontinuiran pritisak',
            'Ako krv natopi gazu, dodajte novi sloj umesto uklanjanja prvog',
            'Kod jakog ili nekontrolisanog krvarenja odmah kod veterinara',
          ],
        ),
        TipSection(
          title: 'Površinska rana',
          bullets: [
            'Nežno isperite čistom vodom',
            'Sprečite psa da liže ili grize ranu',
            'Duboke, velike ili ozbiljno zaprljane rane treba da pregleda veterinar',
          ],
          warning: 'Prva pomoć ne zamenjuje veterinarski pregled.',
        ),
      ],
    ),
    TipArticle(
      id: 'poisoning',
      category: TipCategory.urgent,
      icon: Icons.dangerous_outlined,
      accent: urgentAccent,
      title: '☠️ Sumnja na trovanje',
      summary: 'Šta uraditi ako pas proguta opasnu supstancu',
      sections: [
        TipSection(
          title: 'Ako sumnjate na trovanje',
          bullets: [
            'Odmah kontaktirajte veterinara',
            'Sačuvajte ambalažu ili fotografišite proizvod',
            'Zapamtite približnu količinu i vreme kada je pas mogao da je proguta',
            'Ne pokušavajte samostalno da izazovete povraćanje osim ako vam to izričito ne kaže veterinar',
          ],
          warning: 'Ne dajte psu lekove na svoju ruku.',
        ),
      ],
    ),
    TipArticle(
      id: 'human-meds',
      category: TipCategory.urgent,
      icon: Icons.medication_outlined,
      accent: urgentAccent,
      title: '💊 Lekovi koje pas ne treba da dobija na svoju ruku',
      summary: 'Ljudski lekovi nisu automatski bezbedni za pse',
      sections: [
        TipSection(
          title: 'Važno znati',
          bullets: [
            'Ljudski lekovi nisu automatski bezbedni za pse',
            'Bez saveta veterinara ne dajte ljudske lekove protiv bolova, uključujući ibuprofen, naproksen, paracetamol i aspirin',
          ],
          warning:
              'Ako je pas progutao lek namenjen ljudima, odmah kontaktirajte veterinara i navedite naziv leka, približnu količinu i vreme kada je progutan.',
        ),
      ],
    ),

    // ── PREVENCIJA ─────────────────────────────────────────
    TipArticle(
      id: 'parasites',
      category: TipCategory.prevention,
      icon: Icons.bug_report_outlined,
      accent: preventionAccent,
      title: '🦟 Krpelji, buve i paraziti',
      summary: 'Pregled posle šetnje i zaštita prilagođena psu',
      sections: [
        TipSection(
          title: 'Nakon šetnje pregledajte',
          bullets: [
            'Uši',
            'Vrat',
            'Pazuhe',
            'Prepone',
            'Prostor između prstiju',
            'Područje oko repa',
          ],
        ),
        TipSection(
          title: 'Zaštita',
          bullets: [
            'Zaštita od parazita treba da bude prilagođena psu, načinu života i rizicima u vašem području',
          ],
          warning:
              'Ako niste sigurni koji preparat ili raspored zaštite odgovara vašem psu, pitajte veterinara.',
        ),
      ],
    ),
    TipArticle(
      id: 'vaccines',
      category: TipCategory.prevention,
      icon: Icons.vaccines_outlined,
      accent: preventionAccent,
      title: '💉 Vakcine i redovni pregledi',
      summary: 'Zašto su redovne kontrole važne',
      sections: [
        TipSection(
          title: 'Redovni pregledi služe za',
          bullets: [
            'Praćenje opšteg zdravlja',
            'Proveru vakcinacije',
            'Zaštitu od parazita',
            'Kontrolu telesne težine',
            'Pregled zuba i desni',
            'Rano otkrivanje problema',
          ],
          warning:
              'Raspored pregleda i vakcinacije zavisi od uzrasta, zdravstvenog stanja i načina života psa. Za individualni raspored konsultujte veterinara.',
        ),
      ],
    ),
    TipArticle(
      id: 'teeth',
      category: TipCategory.prevention,
      icon: Icons.health_and_safety_outlined,
      accent: preventionAccent,
      title: '🦷 Zubi i oralna higijena',
      summary: 'Na šta obratiti pažnju kod zuba i desni',
      sections: [
        TipSection(
          title: 'Obratite pažnju na',
          bullets: [
            'Neprijatan zadah',
            'Kamenac',
            'Crvene ili otečene desni',
            'Krvarenje',
            'Otežano žvakanje',
            'Klimave ili oštećene zube',
          ],
        ),
        TipSection(
          title: 'Briga',
          bullets: [
            'Redovna oralna higijena i kontrola kod veterinara su važne',
            'Izbegavajte ekstremne ili neproverene metode čišćenja zuba',
          ],
        ),
      ],
    ),
    TipArticle(
      id: 'weight',
      category: TipCategory.prevention,
      icon: Icons.monitor_weight_outlined,
      accent: preventionAccent,
      title: '⚖️ Telesna težina i ishrana',
      summary: 'Više od broja na vagi — kondicija i navike',
      sections: [
        TipSection(
          title: 'Pratite',
          bullets: [
            'Telesnu težinu',
            'Izgled i kondiciju tela',
            'Količinu hrane',
            'Količinu poslastica',
            'Nivo aktivnosti',
          ],
          warning:
              'Potrebe za hranom razlikuju se od psa do psa. Ako niste sigurni da li pas ima odgovarajuću težinu ili količinu hrane, konsultujte veterinara.',
        ),
      ],
    ),
    TipArticle(
      id: 'checklist',
      category: TipCategory.prevention,
      icon: Icons.checklist_outlined,
      accent: preventionAccent,
      title: '🐕 Preventivna briga',
      summary: 'Praktična checklista za redovnu brigu',
      sections: [
        TipSection(
          title: 'Checklist',
          isChecklist: true,
          bullets: [
            'Redovni veterinarski pregled',
            'Vakcinacija prema preporuci veterinara',
            'Zaštita od parazita',
            'Kontrola telesne težine',
            'Briga o zubima',
            'Redovna fizička aktivnost',
            'Bezbedna i odgovarajuća ishrana',
            'Identifikacija psa i ažurni podaci vlasnika',
          ],
        ),
      ],
    ),

    // ── SVAKODNEVNA BRIGA ──────────────────────────────────
    TipArticle(
      id: 'walk',
      category: TipCategory.daily,
      icon: Icons.directions_walk,
      accent: dailyAccent,
      title: '🐕 Šetnja i fizička aktivnost',
      summary: 'Aktivnost prilagođena vašem psu',
      cta: TipCtaKind.findWalk,
      ctaLabel: '🐕 Pronađi psa za šetnju',
      sections: [
        TipSection(
          title: 'Potrebe zavise od',
          bullets: [
            'Uzrasta',
            'Rase',
            'Veličine',
            'Zdravstvenog stanja',
            'Kondicije',
            'Temperamenta',
          ],
          warning:
              'Ne postoji ista količina aktivnosti koja odgovara svakom psu. Ako pas nije navikao na duže šetnje, povećavajte aktivnost postepeno.',
        ),
        TipSection(
          title: 'Tokom toplog vremena',
          bullets: [
            'Birajte hladnije delove dana',
            'Pravite pauze',
            'Obezbedite vodu',
          ],
        ),
      ],
    ),
    TipArticle(
      id: 'car',
      category: TipCategory.daily,
      icon: Icons.directions_car_outlined,
      accent: dailyAccent,
      title: '🚗 Pas u automobilu',
      summary: 'Bezbednost tokom vožnje i parkiranja',
      sections: [
        TipSection(
          title: 'Pravila bezbednosti',
          bullets: [
            'Ne ostavljajte psa samog u parkiranom automobilu',
            'Tokom vožnje koristite odgovarajući sistem za bezbedno vezivanje ili transporter',
            'Tokom dužih putovanja pravite pauze',
            'Obezbedite vodu kada je potrebno',
            'Posebno pazite na temperaturu tokom toplih dana',
          ],
        ),
      ],
    ),
    TipArticle(
      id: 'behavior',
      category: TipCategory.daily,
      icon: Icons.psychology_outlined,
      accent: dailyAccent,
      title: '🐶 Promene u ponašanju',
      summary: 'Nagla promena može biti znak da nešto nije u redu',
      sections: [
        TipSection(
          title: 'Obratite pažnju ako pas iznenada',
          bullets: [
            'Postane neuobičajeno povučen',
            'Postane neuobičajeno agresivan',
            'Prestane da jede',
            'Ne želi da ustaje',
            'Ne želi kontakt',
            'Iznenada promeni navike',
          ],
          warning:
              'Ako je promena nagla, izražena ili traje, razgovarajte sa veterinarom.',
        ),
      ],
    ),
    TipArticle(
      id: 'home-safety',
      category: TipCategory.daily,
      icon: Icons.home_outlined,
      accent: dailyAccent,
      title: '🏠 Bezbednost kod kuće',
      summary: 'Šta držati van domašaja psa',
      sections: [
        TipSection(
          title: 'Držite van domašaja',
          bullets: [
            'Lekove',
            'Sredstva za čišćenje',
            'Hemikalije',
            'Proizvode koji mogu biti toksični za pse',
            'Sitne predmete koje pas može progutati',
            'Opasne kablove i predmete',
          ],
          warning:
              'Ako niste sigurni da li je neka supstanca ili predmet bezbedan za vašeg psa, proverite sa veterinarom pre nego što mu ga date.',
        ),
      ],
    ),
    TipArticle(
      id: 'id',
      category: TipCategory.daily,
      icon: Icons.badge_outlined,
      accent: dailyAccent,
      title: '🐾 Identifikacija psa',
      summary: 'Ažurni podaci pomažu ako se pas izgubi',
      cta: TipCtaKind.dogProfile,
      ctaLabel: '🐶 Proveri profil svog psa',
      sections: [
        TipSection(
          title: 'Neka budu ažurni',
          bullets: [
            'Ime psa',
            'Kontakt vlasnika',
            'Fotografija psa',
            'Relevantni podaci o psu',
          ],
        ),
      ],
    ),
  ];

  static List<TipArticle> byCategory(TipCategory category) {
    return [
      for (final article in articles)
        if (article.category == category) article,
    ];
  }
}
