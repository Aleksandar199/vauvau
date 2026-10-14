import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
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

  static List<TipArticle> get articles => [
        // ── HITNO ──────────────────────────────────────────────
        TipArticle(
          id: 'urgent-vet',
          category: TipCategory.urgent,
          icon: Icons.emergency_outlined,
          accent: urgentAccent,
          title: L10n.tr(
            '🚨 Kada odmah kod veterinara',
            '🚨 When to see a vet immediately',
          ),
          summary: L10n.tr(
            'Znaci koji zahtevaju hitnu veterinarsku pomoć',
            'Signs that need emergency veterinary care',
          ),
          initiallyExpanded: true,
          cta: TipCtaKind.sosVets,
          ctaLabel: L10n.tr(
            '📍 DEŽURNI VETERINARI',
            '📍 ON-CALL VETS',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Hitne situacije', 'Emergencies'),
              bullets: [
                L10n.tr(
                  'Otežano ili izrazito ubrzano disanje',
                  'Difficulty breathing or very rapid breathing',
                ),
                L10n.tr(
                  'Gubitak svesti ili kolaps',
                  'Loss of consciousness or collapse',
                ),
                L10n.tr('Napad / grčevi', 'Seizure / convulsions'),
                L10n.tr(
                  'Obilno ili nekontrolisano krvarenje',
                  'Heavy or uncontrolled bleeding',
                ),
                L10n.tr('Sumnja na trovanje', 'Suspected poisoning'),
                L10n.tr('Ozbiljna povreda', 'Serious injury'),
                L10n.tr('Sumnja na prelom', 'Suspected fracture'),
                L10n.tr(
                  'Izrazita slabost ili naglo pogoršanje stanja',
                  'Extreme weakness or sudden worsening',
                ),
                L10n.tr('Znaci toplotnog udara', 'Signs of heatstroke'),
              ],
            ),
          ],
          footerNote: L10n.tr(
            'Ako se stanje psa brzo pogoršava ili niste sigurni koliko je situacija ozbiljna, kontaktirajte veterinara.',
            'If your dog’s condition is getting worse quickly or you’re unsure how serious it is, contact a vet.',
          ),
        ),
        TipArticle(
          id: 'heatstroke',
          category: TipCategory.urgent,
          icon: Icons.wb_sunny_outlined,
          accent: urgentAccent,
          title: L10n.tr('☀️ Toplotni udar', '☀️ Heatstroke'),
          summary: L10n.tr(
            'Kako prepoznati i šta uraditi odmah',
            'How to recognize it and what to do right away',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Znaci', 'Signs'),
              bullets: [
                L10n.tr(
                  'Jako i ubrzano dahtanje',
                  'Heavy, rapid panting',
                ),
                L10n.tr('Pojačano slinjenje', 'Excessive drooling'),
                L10n.tr('Slabost', 'Weakness'),
                L10n.tr('Teturanje', 'Staggering'),
                L10n.tr('Povraćanje', 'Vomiting'),
                L10n.tr('Proliv', 'Diarrhea'),
                L10n.tr('Zbunjenost', 'Confusion'),
                L10n.tr('Kolaps', 'Collapse'),
                L10n.tr('Gubitak svesti', 'Loss of consciousness'),
              ],
            ),
            TipSection(
              title: L10n.tr('Šta uraditi', 'What to do'),
              steps: [
                L10n.tr(
                  'Odmah sklonite psa sa sunca.',
                  'Move the dog out of the sun immediately.',
                ),
                L10n.tr(
                  'Prebacite ga u hladan / prozračan prostor.',
                  'Move them to a cool, well-ventilated place.',
                ),
                L10n.tr(
                  'Započnite postepeno rashlađivanje.',
                  'Start gradual cooling.',
                ),
                L10n.tr(
                  'Omogućite strujanje vazduha.',
                  'Allow air to circulate around them.',
                ),
                L10n.tr(
                  'Kontaktirajte veterinara i najavite dolazak.',
                  'Call the vet and say you’re on the way.',
                ),
              ],
              warning: L10n.tr(
                'Ne čekajte da se pas sam ohladi ako sumnjate na toplotni udar.',
                'Don’t wait for the dog to cool down on their own if you suspect heatstroke.',
              ),
            ),
            TipSection(
              title: L10n.tr('Prevencija', 'Prevention'),
              bullets: [
                L10n.tr(
                  'Izbegavajte najtopliji deo dana',
                  'Avoid the hottest part of the day',
                ),
                L10n.tr(
                  'Obezbedite svežu vodu',
                  'Provide fresh water',
                ),
                L10n.tr(
                  'Nikada ne ostavljajte psa samog u parkiranom automobilu',
                  'Never leave a dog alone in a parked car',
                ),
                L10n.tr(
                  'Posebno pazite na pse koji teže podnose toplotu',
                  'Be especially careful with dogs that struggle in heat',
                ),
              ],
            ),
          ],
        ),
        TipArticle(
          id: 'first-aid',
          category: TipCategory.urgent,
          icon: Icons.medical_services_outlined,
          accent: urgentAccent,
          title: L10n.tr('🩹 Prva pomoć', '🩹 First aid'),
          summary: L10n.tr(
            'Krvarenje i površinske rane — prvi koraci',
            'Bleeding and surface wounds — first steps',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Krvarenje', 'Bleeding'),
              bullets: [
                L10n.tr(
                  'Stavite čistu gazu ili čistu tkaninu preko rane',
                  'Place clean gauze or a clean cloth over the wound',
                ),
                L10n.tr(
                  'Izvršite kontinuiran pritisak',
                  'Apply steady pressure',
                ),
                L10n.tr(
                  'Ako krv natopi gazu, dodajte novi sloj umesto uklanjanja prvog',
                  'If blood soaks through, add another layer instead of removing the first',
                ),
                L10n.tr(
                  'Kod jakog ili nekontrolisanog krvarenja odmah kod veterinara',
                  'For heavy or uncontrolled bleeding, go to the vet immediately',
                ),
              ],
            ),
            TipSection(
              title: L10n.tr('Površinska rana', 'Surface wound'),
              bullets: [
                L10n.tr(
                  'Nežno isperite čistom vodom',
                  'Gently rinse with clean water',
                ),
                L10n.tr(
                  'Sprečite psa da liže ili grize ranu',
                  'Stop the dog from licking or biting the wound',
                ),
                L10n.tr(
                  'Duboke, velike ili ozbiljno zaprljane rane treba da pregleda veterinar',
                  'Deep, large, or badly dirty wounds should be checked by a vet',
                ),
              ],
              warning: L10n.tr(
                'Prva pomoć ne zamenjuje veterinarski pregled.',
                'First aid does not replace a veterinary exam.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'poisoning',
          category: TipCategory.urgent,
          icon: Icons.dangerous_outlined,
          accent: urgentAccent,
          title: L10n.tr(
            '☠️ Sumnja na trovanje',
            '☠️ Suspected poisoning',
          ),
          summary: L10n.tr(
            'Šta uraditi ako pas proguta opasnu supstancu',
            'What to do if a dog swallows something dangerous',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Ako sumnjate na trovanje',
                'If you suspect poisoning',
              ),
              bullets: [
                L10n.tr(
                  'Odmah kontaktirajte veterinara',
                  'Contact a vet immediately',
                ),
                L10n.tr(
                  'Sačuvajte ambalažu ili fotografišite proizvod',
                  'Keep the packaging or photograph the product',
                ),
                L10n.tr(
                  'Zapamtite približnu količinu i vreme kada je pas mogao da je proguta',
                  'Note the approximate amount and when it may have been swallowed',
                ),
                L10n.tr(
                  'Ne pokušavajte samostalno da izazovete povraćanje osim ako vam to izričito ne kaže veterinar',
                  'Don’t try to make the dog vomit unless a vet specifically tells you to',
                ),
              ],
              warning: L10n.tr(
                'Ne dajte psu lekove na svoju ruku.',
                'Don’t give your dog medication on your own.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'human-meds',
          category: TipCategory.urgent,
          icon: Icons.medication_outlined,
          accent: urgentAccent,
          title: L10n.tr(
            '💊 Lekovi koje pas ne treba da dobija na svoju ruku',
            '💊 Medicines you should not give a dog on your own',
          ),
          summary: L10n.tr(
            'Ljudski lekovi nisu automatski bezbedni za pse',
            'Human medicines are not automatically safe for dogs',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Važno znati', 'Important to know'),
              bullets: [
                L10n.tr(
                  'Ljudski lekovi nisu automatski bezbedni za pse',
                  'Human medicines are not automatically safe for dogs',
                ),
                L10n.tr(
                  'Bez saveta veterinara ne dajte ljudske lekove protiv bolova, uključujući ibuprofen, naproksen, paracetamol i aspirin',
                  'Without a vet’s advice, don’t give human painkillers, including ibuprofen, naproxen, paracetamol, and aspirin',
                ),
              ],
              warning: L10n.tr(
                'Ako je pas progutao lek namenjen ljudima, odmah kontaktirajte veterinara i navedite naziv leka, približnu količinu i vreme kada je progutan.',
                'If a dog swallowed human medication, contact a vet immediately and give the name, approximate amount, and time it was swallowed.',
              ),
            ),
          ],
        ),

        // ── PREVENCIJA ─────────────────────────────────────────
        TipArticle(
          id: 'parasites',
          category: TipCategory.prevention,
          icon: Icons.bug_report_outlined,
          accent: preventionAccent,
          title: L10n.tr(
            '🦟 Krpelji, buve i paraziti',
            '🦟 Ticks, fleas, and parasites',
          ),
          summary: L10n.tr(
            'Pregled posle šetnje i zaštita prilagođena psu',
            'Check after walks and protection suited to your dog',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Nakon šetnje pregledajte',
                'After a walk, check',
              ),
              bullets: [
                L10n.tr('Uši', 'Ears'),
                L10n.tr('Vrat', 'Neck'),
                L10n.tr('Pazuhe', 'Armpits'),
                L10n.tr('Prepone', 'Groin'),
                L10n.tr(
                  'Prostor između prstiju',
                  'Between the toes',
                ),
                L10n.tr(
                  'Područje oko repa',
                  'Around the tail',
                ),
              ],
            ),
            TipSection(
              title: L10n.tr('Zaštita', 'Protection'),
              bullets: [
                L10n.tr(
                  'Zaštita od parazita treba da bude prilagođena psu, načinu života i rizicima u vašem području',
                  'Parasite protection should match your dog, lifestyle, and local risks',
                ),
              ],
              warning: L10n.tr(
                'Ako niste sigurni koji preparat ili raspored zaštite odgovara vašem psu, pitajte veterinara.',
                'If you’re unsure which product or schedule suits your dog, ask a vet.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'vaccines',
          category: TipCategory.prevention,
          icon: Icons.vaccines_outlined,
          accent: preventionAccent,
          title: L10n.tr(
            '💉 Vakcine i redovni pregledi',
            '💉 Vaccines and regular check-ups',
          ),
          summary: L10n.tr(
            'Zašto su redovne kontrole važne',
            'Why regular check-ups matter',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Redovni pregledi služe za',
                'Regular check-ups help with',
              ),
              bullets: [
                L10n.tr(
                  'Praćenje opšteg zdravlja',
                  'Monitoring overall health',
                ),
                L10n.tr(
                  'Proveru vakcinacije',
                  'Checking vaccination status',
                ),
                L10n.tr(
                  'Zaštitu od parazita',
                  'Parasite protection',
                ),
                L10n.tr(
                  'Kontrolu telesne težine',
                  'Weight monitoring',
                ),
                L10n.tr(
                  'Pregled zuba i desni',
                  'Teeth and gum checks',
                ),
                L10n.tr(
                  'Rano otkrivanje problema',
                  'Early problem detection',
                ),
              ],
              warning: L10n.tr(
                'Raspored pregleda i vakcinacije zavisi od uzrasta, zdravstvenog stanja i načina života psa. Za individualni raspored konsultujte veterinara.',
                'Check-up and vaccine schedules depend on age, health, and lifestyle. Ask a vet for a plan tailored to your dog.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'teeth',
          category: TipCategory.prevention,
          icon: Icons.health_and_safety_outlined,
          accent: preventionAccent,
          title: L10n.tr(
            '🦷 Zubi i oralna higijena',
            '🦷 Teeth and oral care',
          ),
          summary: L10n.tr(
            'Na šta obratiti pažnju kod zuba i desni',
            'What to watch for with teeth and gums',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Obratite pažnju na',
                'Watch for',
              ),
              bullets: [
                L10n.tr('Neprijatan zadah', 'Bad breath'),
                L10n.tr('Kamenac', 'Tartar'),
                L10n.tr(
                  'Crvene ili otečene desni',
                  'Red or swollen gums',
                ),
                L10n.tr('Krvarenje', 'Bleeding'),
                L10n.tr(
                  'Otežano žvakanje',
                  'Difficulty chewing',
                ),
                L10n.tr(
                  'Klimave ili oštećene zube',
                  'Loose or damaged teeth',
                ),
              ],
            ),
            TipSection(
              title: L10n.tr('Briga', 'Care'),
              bullets: [
                L10n.tr(
                  'Redovna oralna higijena i kontrola kod veterinara su važne',
                  'Regular oral care and vet check-ups matter',
                ),
                L10n.tr(
                  'Izbegavajte ekstremne ili neproverene metode čišćenja zuba',
                  'Avoid extreme or unproven teeth-cleaning methods',
                ),
              ],
            ),
          ],
        ),
        TipArticle(
          id: 'weight',
          category: TipCategory.prevention,
          icon: Icons.monitor_weight_outlined,
          accent: preventionAccent,
          title: L10n.tr(
            '⚖️ Telesna težina i ishrana',
            '⚖️ Weight and nutrition',
          ),
          summary: L10n.tr(
            'Više od broja na vagi — kondicija i navike',
            'More than a number on the scale — condition and habits',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Pratite', 'Track'),
              bullets: [
                L10n.tr('Telesnu težinu', 'Body weight'),
                L10n.tr(
                  'Izgled i kondiciju tela',
                  'Body shape and condition',
                ),
                L10n.tr('Količinu hrane', 'Food amount'),
                L10n.tr(
                  'Količinu poslastica',
                  'Treat amount',
                ),
                L10n.tr('Nivo aktivnosti', 'Activity level'),
              ],
              warning: L10n.tr(
                'Potrebe za hranom razlikuju se od psa do psa. Ako niste sigurni da li pas ima odgovarajuću težinu ili količinu hrane, konsultujte veterinara.',
                'Food needs differ from dog to dog. If you’re unsure about weight or portions, ask a vet.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'checklist',
          category: TipCategory.prevention,
          icon: Icons.checklist_outlined,
          accent: preventionAccent,
          title: L10n.tr(
            '🐕 Preventivna briga',
            '🐕 Preventive care',
          ),
          summary: L10n.tr(
            'Praktična checklista za redovnu brigu',
            'A practical checklist for regular care',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Checklist', 'Checklist'),
              isChecklist: true,
              bullets: [
                L10n.tr(
                  'Redovni veterinarski pregled',
                  'Regular vet check-ups',
                ),
                L10n.tr(
                  'Vakcinacija prema preporuci veterinara',
                  'Vaccination as recommended by your vet',
                ),
                L10n.tr(
                  'Zaštita od parazita',
                  'Parasite protection',
                ),
                L10n.tr(
                  'Kontrola telesne težine',
                  'Weight monitoring',
                ),
                L10n.tr('Briga o zubima', 'Dental care'),
                L10n.tr(
                  'Redovna fizička aktivnost',
                  'Regular exercise',
                ),
                L10n.tr(
                  'Bezbedna i odgovarajuća ishrana',
                  'Safe, suitable nutrition',
                ),
                L10n.tr(
                  'Identifikacija psa i ažurni podaci vlasnika',
                  'Dog ID and up-to-date owner details',
                ),
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
          title: L10n.tr(
            '🐕 Šetnja i fizička aktivnost',
            '🐕 Walks and exercise',
          ),
          summary: L10n.tr(
            'Aktivnost prilagođena vašem psu',
            'Activity suited to your dog',
          ),
          cta: TipCtaKind.findWalk,
          ctaLabel: L10n.tr(
            '🐕 Pronađi psa za šetnju',
            '🐕 Find a dog to walk with',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Potrebe zavise od',
                'Needs depend on',
              ),
              bullets: [
                L10n.tr('Uzrasta', 'Age'),
                L10n.tr('Rase', 'Breed'),
                L10n.tr('Veličine', 'Size'),
                L10n.tr(
                  'Zdravstvenog stanja',
                  'Health',
                ),
                L10n.tr('Kondicije', 'Fitness'),
                L10n.tr('Temperamenta', 'Temperament'),
              ],
              warning: L10n.tr(
                'Ne postoji ista količina aktivnosti koja odgovara svakom psu. Ako pas nije navikao na duže šetnje, povećavajte aktivnost postepeno.',
                'There is no one amount of activity that suits every dog. If your dog isn’t used to longer walks, increase activity gradually.',
              ),
            ),
            TipSection(
              title: L10n.tr(
                'Tokom toplog vremena',
                'In hot weather',
              ),
              bullets: [
                L10n.tr(
                  'Birajte hladnije delove dana',
                  'Choose cooler parts of the day',
                ),
                L10n.tr('Pravite pauze', 'Take breaks'),
                L10n.tr('Obezbedite vodu', 'Provide water'),
              ],
            ),
          ],
        ),
        TipArticle(
          id: 'car',
          category: TipCategory.daily,
          icon: Icons.directions_car_outlined,
          accent: dailyAccent,
          title: L10n.tr(
            '🚗 Pas u automobilu',
            '🚗 Dogs in the car',
          ),
          summary: L10n.tr(
            'Bezbednost tokom vožnje i parkiranja',
            'Safety while driving and parked',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Pravila bezbednosti',
                'Safety rules',
              ),
              bullets: [
                L10n.tr(
                  'Ne ostavljajte psa samog u parkiranom automobilu',
                  'Never leave a dog alone in a parked car',
                ),
                L10n.tr(
                  'Tokom vožnje koristite odgovarajući sistem za bezbedno vezivanje ili transporter',
                  'Use a proper restraint or crate while driving',
                ),
                L10n.tr(
                  'Tokom dužih putovanja pravite pauze',
                  'Take breaks on longer trips',
                ),
                L10n.tr(
                  'Obezbedite vodu kada je potrebno',
                  'Provide water when needed',
                ),
                L10n.tr(
                  'Posebno pazite na temperaturu tokom toplih dana',
                  'Watch temperature carefully on hot days',
                ),
              ],
            ),
          ],
        ),
        TipArticle(
          id: 'behavior',
          category: TipCategory.daily,
          icon: Icons.psychology_outlined,
          accent: dailyAccent,
          title: L10n.tr(
            '🐶 Promene u ponašanju',
            '🐶 Behavior changes',
          ),
          summary: L10n.tr(
            'Nagla promena može biti znak da nešto nije u redu',
            'A sudden change can mean something is wrong',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Obratite pažnju ako pas iznenada',
                'Pay attention if your dog suddenly',
              ),
              bullets: [
                L10n.tr(
                  'Postane neuobičajeno povučen',
                  'Becomes unusually withdrawn',
                ),
                L10n.tr(
                  'Postane neuobičajeno agresivan',
                  'Becomes unusually aggressive',
                ),
                L10n.tr(
                  'Prestane da jede',
                  'Stops eating',
                ),
                L10n.tr(
                  'Ne želi da ustaje',
                  'Won’t get up',
                ),
                L10n.tr(
                  'Ne želi kontakt',
                  'Avoids contact',
                ),
                L10n.tr(
                  'Iznenada promeni navike',
                  'Suddenly changes habits',
                ),
              ],
              warning: L10n.tr(
                'Ako je promena nagla, izražena ili traje, razgovarajte sa veterinarom.',
                'If the change is sudden, strong, or lasting, talk to a vet.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'home-safety',
          category: TipCategory.daily,
          icon: Icons.home_outlined,
          accent: dailyAccent,
          title: L10n.tr(
            '🏠 Bezbednost kod kuće',
            '🏠 Home safety',
          ),
          summary: L10n.tr(
            'Šta držati van domašaja psa',
            'What to keep out of your dog’s reach',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Držite van domašaja',
                'Keep out of reach',
              ),
              bullets: [
                L10n.tr('Lekove', 'Medications'),
                L10n.tr(
                  'Sredstva za čišćenje',
                  'Cleaning products',
                ),
                L10n.tr('Hemikalije', 'Chemicals'),
                L10n.tr(
                  'Proizvode koji mogu biti toksični za pse',
                  'Products that may be toxic to dogs',
                ),
                L10n.tr(
                  'Sitne predmete koje pas može progutati',
                  'Small items a dog could swallow',
                ),
                L10n.tr(
                  'Opasne kablove i predmete',
                  'Dangerous cords and objects',
                ),
              ],
              warning: L10n.tr(
                'Ako niste sigurni da li je neka supstanca ili predmet bezbedan za vašeg psa, proverite sa veterinarom pre nego što mu ga date.',
                'If you’re unsure whether something is safe for your dog, check with a vet before offering it.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'id',
          category: TipCategory.daily,
          icon: Icons.badge_outlined,
          accent: dailyAccent,
          title: L10n.tr(
            '🐾 Identifikacija psa',
            '🐾 Dog identification',
          ),
          summary: L10n.tr(
            'Ažurni podaci pomažu ako se pas izgubi',
            'Up-to-date details help if a dog gets lost',
          ),
          cta: TipCtaKind.dogProfile,
          ctaLabel: L10n.tr(
            '🐶 Proveri profil svog psa',
            '🐶 Check your dog’s profile',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Neka budu ažurni',
                'Keep these up to date',
              ),
              bullets: [
                L10n.tr('Ime psa', 'Dog’s name'),
                L10n.tr(
                  'Kontakt vlasnika',
                  'Owner contact',
                ),
                L10n.tr(
                  'Fotografija psa',
                  'Photo of the dog',
                ),
                L10n.tr(
                  'Relevantni podaci o psu',
                  'Relevant dog details',
                ),
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
