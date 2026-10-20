import '../../../core/constants/serbia_locations.dart';

/// Group a SOS contact is listed under (order = order on screen).
enum SosContactKind {
  /// Source explicitly says the vet answers 0–24.
  emergencyVet,

  /// Vet clinic; on-call hours, if any, are in [SosContact.note].
  vetClinic,

  /// City animal control (zoohigijena) or shelter: stray / injured dogs.
  animalControl,

  other,
}

class SosPhone {
  const SosPhone(this.number, {this.label});

  /// Human-readable number as published by the source, e.g. `063 342 235`.
  final String number;

  /// Optional short label, e.g. `Hitne intervencije 0–24`.
  final String? label;

  /// Digits only (leading `+` kept) – what is dialed.
  String get dialable => number.replaceAll(RegExp(r'[^0-9+]'), '');

  Uri get telUri => Uri(scheme: 'tel', path: dialable);
}

class SosContact {
  const SosContact({
    required this.cityId,
    required this.name,
    required this.kind,
    required this.phones,
    required this.sourceUrl,
    this.note,
    this.address,
    this.website,
  });

  /// [SerbiaLocations] city id.
  final String cityId;
  final String name;
  final SosContactKind kind;

  /// First phone is the main call button.
  final List<SosPhone> phones;

  /// Hours / on-call note – only as stated by [sourceUrl].
  final String? note;
  final String? address;
  final String? website;

  /// Where the data was confirmed (on [SosContacts.checkedOn]).
  final String sourceUrl;

  SosPhone get primaryPhone => phones.first;

  Uri? get websiteUri => website == null ? null : Uri.parse(website!);

  Uri? get mapsUri => address == null
      ? null
      : Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': address!,
        });
}

/// Static SOS contacts per city. Only contacts confirmed on an official
/// page (city, JKP or the clinic's own site) are listed; everything else is
/// in `docs/sos_kontakti.md` for manual review. Never mark a clinic as 0–24
/// without a source that says so.
abstract final class SosContacts {
  static final DateTime checkedOn = DateTime(2026, 10, 20);

  static List<SosContact> forCity(String cityId) =>
      byCity[cityId] ?? const [];

  /// Contacts of [cityId] grouped by [SosContactKind] (empty groups omitted).
  static Map<SosContactKind, List<SosContact>> groupedForCity(String cityId) {
    final grouped = <SosContactKind, List<SosContact>>{};
    for (final kind in SosContactKind.values) {
      final items = [
        for (final c in forCity(cityId))
          if (c.kind == kind) c,
      ];
      if (items.isNotEmpty) {
        grouped[kind] = items;
      }
    }
    return grouped;
  }

  static const Map<String, List<SosContact>> byCity = {
    SerbiaLocations.noviSadId: _noviSad,
    'beograd': _beograd,
    SerbiaLocations.nisId: _nis,
    SerbiaLocations.kragujevacId: _kragujevac,
    SerbiaLocations.zrenjaninId: _zrenjanin,
    SerbiaLocations.suboticaId: _subotica,
  };

  static const _noviSad = <SosContact>[
    SosContact(
      cityId: SerbiaLocations.noviSadId,
      name: 'Milenium Vet',
      kind: SosContactKind.emergencyVet,
      phones: [SosPhone('065 474 9212')],
      note: 'Dežurni veterinar 00–24. Ambulanta: pon–pet 9–20, sub 10–13.',
      address: 'Subotička 55, Novi Sad',
      website: 'https://www.mileniumvet.rs/',
      sourceUrl: 'https://www.mileniumvet.rs/',
    ),
    SosContact(
      cityId: SerbiaLocations.noviSadId,
      name: 'NS VET',
      kind: SosContactKind.vetClinic,
      phones: [
        SosPhone('021 493 007'),
        SosPhone('063 590 192'),
        SosPhone('064 232 0136'),
      ],
      note: 'Pon–sub 8–20, ned 9–12. Hitne intervencije / dežurstvo u '
          'ambulanti 20–24 (nije 0–24).',
      address: 'Branislava Borote 2, Novo Naselje, Novi Sad',
      website: 'https://www.nsvet.rs/',
      sourceUrl: 'https://www.nsvet.rs/',
    ),
    SosContact(
      cityId: SerbiaLocations.noviSadId,
      name: 'Ambulanta za male životinje (JKP Zoohigijena i veterina)',
      kind: SosContactKind.vetClinic,
      phones: [SosPhone('021 403 402')],
      address: 'Futoški put 13, Novi Sad',
      website: 'https://zoohigijenans.co.rs/',
      sourceUrl: 'https://zoohigijenans.co.rs/kontakt/',
    ),
    SosContact(
      cityId: SerbiaLocations.noviSadId,
      name: 'JKP Zoohigijena i veterina – prihvatilište',
      kind: SosContactKind.animalControl,
      phones: [SosPhone('021 640 3220')],
      note: 'Prijava povređene ili napuštene životinje u radno vreme: '
          'radnim danima 7:30–19, vikendom 7:30–18.',
      address: 'Put šajkaškog odreda bb, Novi Sad',
      website: 'https://zoohigijenans.co.rs/',
      sourceUrl: 'https://zoohigijenans.co.rs/kontakt/',
    ),
  ];

  static const _beograd = <SosContact>[
    SosContact(
      cityId: 'beograd',
      name: 'Vet Planet klinika',
      kind: SosContactKind.emergencyVet,
      phones: [SosPhone('011 7707 227'), SosPhone('065 3565 664')],
      note: 'Radno vreme: ponedeljak–nedelja 00–24.',
      address: 'Tošin bunar 128, Beograd',
      website: 'https://vetplanet.rs/',
      sourceUrl: 'https://vetplanet.rs/',
    ),
    SosContact(
      cityId: 'beograd',
      name: 'Vet Urgent – VET klinika Sveti Vrači',
      kind: SosContactKind.emergencyVet,
      phones: [SosPhone('063 342 235'), SosPhone('011 2461 383')],
      note: 'Dežurstva 00–24, klinika 9–20. Pre dolaska po mogućstvu pozovite.',
      address: 'Admirala Vukovića 75, Beograd',
      website: 'https://veturgent.rs/',
      sourceUrl: 'https://veturgent.rs/',
    ),
    SosContact(
      cityId: 'beograd',
      name: 'Hitna pomoć za životinje (JKP Veterina Beograd)',
      kind: SosContactKind.vetClinic,
      phones: [SosPhone('062 80 90 333')],
      note: 'Radnim danima 8–20, vikendom 8–16.',
      address: 'Bulevar kralja Aleksandra 602, Mali Mokri Lug, Beograd',
      website: 'https://www.veterinabeograd.rs/',
      sourceUrl: 'https://www.veterinabeograd.rs/kontakt',
    ),
    SosContact(
      cityId: 'beograd',
      name: 'Veterinarska klinika za male životinje (JKP Veterina Beograd)',
      kind: SosContactKind.vetClinic,
      phones: [SosPhone('011 276 40 88')],
      note: 'Radnim danima 8–20, subotom 10–14, nedeljom 10–12.',
      address: 'Bulevar despota Stefana 119, Beograd',
      website: 'https://www.veterinabeograd.rs/',
      sourceUrl: 'https://www.veterinabeograd.rs/kontakt',
    ),
    SosContact(
      cityId: 'beograd',
      name: 'JKP Veterina Beograd – komunalna zoohigijena',
      kind: SosContactKind.animalControl,
      phones: [
        SosPhone(
          '011 329 3099',
          label: 'Radnim danima 7–20, sub 7–14, ned 7–12',
        ),
        SosPhone(
          '063 549 161',
          label: 'Noću: radnim danima 20–7, sub od 14, ned od 12',
        ),
      ],
      address: 'Bulevar despota Stefana 119, Beograd',
      website: 'https://www.veterinabeograd.rs/',
      sourceUrl: 'https://www.veterinabeograd.rs/komunalna-zoohigijena',
    ),
    SosContact(
      cityId: 'beograd',
      name: 'Prihvatilište Rakovica (JKP Veterina Beograd)',
      kind: SosContactKind.animalControl,
      phones: [SosPhone('011 715 8100'), SosPhone('062 412 436')],
      note: 'Informacije o smeštenim životinjama 10–12.',
      address: 'Slavka Miljkovića bb, Beograd',
      website: 'https://www.veterinabeograd.rs/',
      sourceUrl: 'https://www.veterinabeograd.rs/kontakt',
    ),
    SosContact(
      cityId: 'beograd',
      name: 'Izgubljene vlasničke životinje (JKP Veterina Beograd)',
      kind: SosContactKind.other,
      phones: [SosPhone('011 276 43 66', label: 'Lokal 115')],
      note: 'Lokal 115, radnim danima 7:30–15:30.',
      website: 'https://www.veterinabeograd.rs/',
      sourceUrl: 'https://www.veterinabeograd.rs/kontakt',
    ),
  ];

  static const _nis = <SosContact>[
    SosContact(
      cityId: SerbiaLocations.nisId,
      name: 'Vet Medica',
      kind: SosContactKind.emergencyVet,
      phones: [SosPhone('064 170 64 70')],
      note: 'Dežurni telefon 24/7, i vikendom i praznicima; izlazak na teren '
          'po pozivu.',
      address: 'Bulevar Mediana 5, Niš',
      website: 'https://vetmedica.rs/',
      sourceUrl: 'https://vetmedica.rs/',
    ),
    SosContact(
      cityId: SerbiaLocations.nisId,
      name: 'Veterinarska stanica Niš',
      kind: SosContactKind.vetClinic,
      phones: [
        SosPhone('018 42 41 499', label: 'U radno vreme'),
        SosPhone('063 41 85 42', label: 'Dežurni van radnog vremena'),
      ],
      note: 'Pon–pet 8–20, sub 8–14, ned 9–13. Van radnog vremena dežurni '
          'veterinar.',
      address: 'Ivana Milutinovića 64, Niš',
      website: 'https://veterinarskastanicanis.rs/',
      sourceUrl: 'https://veterinarskastanicanis.rs/kontakt/',
    ),
    SosContact(
      cityId: SerbiaLocations.nisId,
      name: 'JKP Mediana – ZOO higijena',
      kind: SosContactKind.animalControl,
      phones: [SosPhone('064 850 99 81')],
      website: 'https://jkpmediana.rs/',
      sourceUrl: 'https://jkpmediana.rs/kontakt/',
    ),
    SosContact(
      cityId: SerbiaLocations.nisId,
      name: 'JKP Mediana – kontakt centar',
      kind: SosContactKind.other,
      phones: [SosPhone('0800 018 002'), SosPhone('018 25 01 25')],
      note: 'Besplatan poziv; prijava komunalnog problema.',
      website: 'https://jkpmediana.rs/',
      sourceUrl: 'https://jkpmediana.rs/kontakt/',
    ),
  ];

  static const _kragujevac = <SosContact>[
    SosContact(
      cityId: SerbiaLocations.kragujevacId,
      name: 'Kragujvet Pet',
      kind: SosContactKind.emergencyVet,
      phones: [SosPhone('063 303 476'), SosPhone('034 258 080')],
      note: 'Hitne intervencije 0–24 na 063 303 476. Ambulanta: radnim '
          'danima 8–20, subotom 9–15.',
      address: 'Kneza Miloša 1A, Kragujevac',
      website: 'https://veterinarkragujevac.rs/',
      sourceUrl: 'https://veterinarkragujevac.rs/kontakt/',
    ),
    SosContact(
      cityId: SerbiaLocations.kragujevacId,
      name: 'Medikavet',
      kind: SosContactKind.emergencyVet,
      phones: [
        SosPhone('064 12 68 424', label: '00–24'),
        SosPhone('034 355 325', label: '08–20'),
      ],
      note: 'Mobilni 00–24, fiksni 08–20.',
      address: 'Hadži Milentijeva 3, Kragujevac',
      website: 'https://medikavet.rs/',
      sourceUrl: 'https://medikavet.rs/',
    ),
    SosContact(
      cityId: SerbiaLocations.kragujevacId,
      name: 'JKP Šumadija – služba zoohigijene',
      kind: SosContactKind.animalControl,
      phones: [SosPhone('034 350 054')],
      note: 'Hvatanje i zbrinjavanje napuštenih pasa i mačaka.',
      website: 'https://www.jkpsumadija.rs/',
      sourceUrl: 'https://jkpsumadija.rs/sr/kontakti.html',
    ),
    SosContact(
      cityId: SerbiaLocations.kragujevacId,
      name: 'JKP Šumadija – besplatan poziv',
      kind: SosContactKind.other,
      phones: [SosPhone('0800 350 034')],
      website: 'https://www.jkpsumadija.rs/',
      sourceUrl: 'https://jkpsumadija.rs/sr/kontakti.html',
    ),
  ];

  static const _zrenjanin = <SosContact>[
    SosContact(
      cityId: SerbiaLocations.zrenjaninId,
      name: 'Veterina Dimić',
      kind: SosContactKind.vetClinic,
      phones: [
        SosPhone('023 567 021'),
        SosPhone('064 66 28 977'),
        SosPhone('064 64 65 423'),
      ],
      note: 'Radnim danima 8–19, sub 9–14, ned 10–13. Dežurna služba 19–24 '
          '(nije 0–24).',
      address: 'Žarka Zrenjanina 78, Zrenjanin',
      website: 'https://vetdimic.com/',
      sourceUrl: 'https://vetdimic.com/?page_id=7',
    ),
    SosContact(
      cityId: SerbiaLocations.zrenjaninId,
      name: 'Zoohigijenska služba JKP „Čistoća i zelenilo“',
      kind: SosContactKind.animalControl,
      phones: [SosPhone('064 811 68 78')],
      note: 'Dežurni telefon i prihvatilište. Radnim danima 7–22, subotom i '
          'nedeljom 8–15.',
      address: 'Dr Tihomira Ostojića bb, Zrenjanin',
      website: 'https://www.jkpciz.co.rs/',
      sourceUrl: 'https://www.jkpciz.co.rs/index.php/usluge-zoohigijene',
    ),
  ];

  static const _subotica = <SosContact>[
    SosContact(
      cityId: SerbiaLocations.suboticaId,
      name: 'Panvet',
      kind: SosContactKind.vetClinic,
      phones: [
        SosPhone('024 571 920'),
        SosPhone('069 571 9200', label: 'Hitne intervencije'),
      ],
      address: 'Koste Racina 5, Subotica',
      website: 'http://www.panvet.info/',
      sourceUrl: 'http://www.panvet.info/kontakt',
    ),
    SosContact(
      cityId: SerbiaLocations.suboticaId,
      name: 'Veterinarska stanica Veterinar',
      kind: SosContactKind.vetClinic,
      phones: [
        SosPhone('024 671 060'),
        SosPhone('024 539 229'),
        SosPhone('060 671 0600'),
      ],
      note: 'Pon–pet 7–19. Nije 0–24.',
      address: 'Trg Paje Kujundžića 2/a, Subotica',
      website: 'https://www.veterinarsubotica.rs/',
      sourceUrl: 'https://www.veterinarsubotica.rs/kontakt',
    ),
    SosContact(
      cityId: SerbiaLocations.suboticaId,
      name: 'Prihvatilište za napuštene pse i mačke (JKP „Čistoća i zelenilo“)',
      kind: SosContactKind.animalControl,
      phones: [SosPhone('024 670 595'), SosPhone('062 248 915')],
      address: '9. Nova 249 (Ganjo šor 137), Subotica',
      website: 'https://www.cistoca-su.co.rs/',
      sourceUrl: 'https://www.cistoca-su.co.rs/kontakt/',
    ),
    SosContact(
      cityId: SerbiaLocations.suboticaId,
      name: 'JKP „Čistoća i zelenilo“ – besplatna info linija',
      kind: SosContactKind.other,
      phones: [SosPhone('0800 151 152')],
      website: 'https://www.cistoca-su.co.rs/',
      sourceUrl: 'https://www.cistoca-su.co.rs/kontakt/',
    ),
  ];
}
