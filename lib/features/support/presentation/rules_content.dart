import 'package:flutter/material.dart';

import 'tips_content.dart';

abstract final class RulesContent {
  static const Color dailyAccent = TipsContent.dailyAccent;
  static const Color communityAccent = TipsContent.preventionAccent;
  static const Color importantAccent = TipsContent.urgentAccent;

  static const List<TipArticle> daily = [
    TipArticle(
      id: 'rule-clean-up',
      category: TipCategory.daily,
      icon: Icons.cleaning_services_outlined,
      accent: dailyAccent,
      title: 'Počisti za svojim psom',
      summary: 'Uvek ponesi kesicu i pokupi izmet svog psa.',
      sections: [
        TipSection(
          title: 'Zapamti',
          bullets: [
            'Ponesi dovoljno kesica pre šetnje.',
            'Ne ostavljaj izmet na ulici, travi, stazi ili prostoru koji koriste drugi ljudi.',
            'Ako je moguće, baci kesicu u odgovarajuću kantu.',
          ],
        ),
      ],
      footerNote: 'Čist prostor je prijatniji za sve — i za pse i za ljude.',
    ),
    TipArticle(
      id: 'rule-leash',
      category: TipCategory.daily,
      icon: Icons.pets_outlined,
      accent: dailyAccent,
      title: 'Povodac i bezbednost',
      summary:
          'Poštuj druge pse, ljude i lokalna pravila o korišćenju povoca.',
      sections: [
        TipSection(
          title: 'Zapamti',
          bullets: [
            'Koristi povodac kada je to potrebno ili kada lokalna pravila to zahtevaju.',
            'Ne puštaj psa bez provere da li je prostor bezbedan i dozvoljen za to.',
            'Ne dozvoli psu da sam prilazi drugim psima ili ljudima bez njihove saglasnosti.',
            'Obrati pažnju na saobraćaj, decu, bicikliste i druge potencijalne opasnosti.',
          ],
          warning:
              'Ako nisi siguran da li je puštanje psa dozvoljeno, proveri pravila konkretnog prostora.',
        ),
      ],
    ),
    TipArticle(
      id: 'rule-park',
      category: TipCategory.daily,
      icon: Icons.park_outlined,
      accent: dailyAccent,
      title: 'Ponašanje u parku',
      summary: 'Park je zajednički prostor za ljude i pse.',
      sections: [
        TipSection(
          title: 'Zapamti',
          bullets: [
            'Poštuj druge vlasnike i njihove pse.',
            'Ne pretpostavljaj da svaki pas želi da se igra.',
            'Pitaj vlasnika pre nego što dozvoliš svom psu da priđe njegovom psu.',
            'Prati svog psa i ne dozvoli mu da uznemirava druge.',
            'Poštuj prostor namenjen deci i druge korisnike parka.',
            'Ako primetiš problematičnu situaciju, udalji psa i smiri situaciju.',
          ],
          warning:
              'Ne forsiraj kontakt između pasa. Neki psi su plašljivi, stariji, bolesni ili jednostavno ne žele druženje.',
        ),
      ],
    ),
    TipArticle(
      id: 'rule-other-dogs',
      category: TipCategory.daily,
      icon: Icons.front_hand_outlined,
      accent: dailyAccent,
      title: 'Poštuj tuđe pse',
      summary: 'Ne prilazi tuđem psu bez dozvole vlasnika.',
      sections: [
        TipSection(
          title: 'Zapamti',
          bullets: [
            'Nemoj hraniti tuđeg psa bez pitanja.',
            'Nemoj ga dodirivati bez dozvole vlasnika.',
            'Ne puštaj svog psa da skače na druge pse.',
            'Ako vlasnik kaže da njegov pas ne želi kontakt, poštuj to.',
            'Posebno obrati pažnju na pse koji nose oznake da su plašljivi, reaktivni ili da ne žele kontakt.',
          ],
        ),
      ],
    ),
  ];

  static const List<TipArticle> community = [
    TipArticle(
      id: 'rule-owners',
      category: TipCategory.prevention,
      icon: Icons.handshake_outlined,
      accent: communityAccent,
      title: 'Poštuj druge vlasnike',
      summary: 'Budi ljubazan i poštuj tuđe granice.',
      sections: [
        TipSection(
          title: 'Zapamti',
          bullets: [
            'Budi ljubazan prema drugim korisnicima.',
            'Ne vređaj, ne provociraj i ne uznemiravaj druge.',
            'Poštuj tuđe granice.',
            'Ne fotografiši ili objavljuj druge ljude bez odgovarajuće saglasnosti kada je to potrebno.',
            'Ako se ne slažeš sa nekim, razgovaraj normalno ili prijavi problem administratoru.',
          ],
        ),
      ],
    ),
    TipArticle(
      id: 'rule-app-culture',
      category: TipCategory.prevention,
      icon: Icons.forum_outlined,
      accent: communityAccent,
      title: 'Kultura na VauVau',
      summary: 'Poruke, grupe i komentari — uvek pristojno.',
      sections: [
        TipSection(
          title: 'Zapamti',
          bullets: [
            'Komuniciraj pristojno.',
            'Ne vređaj druge korisnike.',
            'Ne uznemiravaj druge korisnike porukama.',
            'Ne šalji neželjen ili neprikladan sadržaj.',
            'Ne spamuj grupe, komentare ili objave.',
            'Ne koristi VauVau za prevare ili obmanjivanje drugih korisnika.',
            'Ne objavljuj tuđe privatne podatke.',
            'Prijavi sadržaj koji krši pravila.',
          ],
        ),
      ],
    ),
    TipArticle(
      id: 'rule-posts',
      category: TipCategory.prevention,
      icon: Icons.photo_camera_outlined,
      accent: communityAccent,
      title: 'Objave i sadržaj',
      summary: 'Objavljuj ono što je vezano za pse i zajednicu.',
      sections: [
        TipSection(
          title: 'Zapamti',
          bullets: [
            'Objavljuj sadržaj koji je povezan sa temom aplikacije.',
            'Ne objavljuj uvredljiv, uznemirujući ili neprikladan sadržaj.',
            'Ne objavljuj tuđe fotografije bez odgovarajuće dozvole.',
            'Ne predstavljaj tuđe fotografije ili informacije kao svoje.',
            'Ne spamuj.',
            'Ne objavljuj sadržaj koji može ugroziti druge korisnike ili životinje.',
          ],
        ),
      ],
    ),
    TipArticle(
      id: 'rule-not-allowed',
      category: TipCategory.prevention,
      icon: Icons.block_outlined,
      accent: communityAccent,
      title: 'Šta nije dozvoljeno',
      summary: 'Kratak spisak stvari koje ne tolerišemo.',
      sections: [
        TipSection(
          title: 'Nije dozvoljeno',
          bullets: [
            'Uznemiravanje drugih korisnika',
            'Pretnje i vređanje',
            'Spam',
            'Prevare',
            'Lažno predstavljanje',
            'Zloupotreba tuđih podataka',
            'Objavljivanje privatnih podataka drugih osoba',
            'Seksualno eksplicitan ili neprikladan sadržaj',
            'Sadržaj koji promoviše nasilje ili ugrožavanje životinja',
            'Namerno širenje lažnih informacija',
            'Korišćenje aplikacije za aktivnosti koje nisu povezane sa njenom svrhom ili mogu ugroziti druge korisnike',
          ],
        ),
      ],
    ),
  ];

  static const List<TipArticle> important = [
    TipArticle(
      id: 'rule-lost-found',
      category: TipCategory.urgent,
      icon: Icons.campaign_outlined,
      accent: importantAccent,
      title: 'Izgubljeni i pronađeni psi',
      summary:
          'Ako objavljuješ izgubljenog ili pronađenog psa, unesi što više tačnih informacija.',
      sections: [
        TipSection(
          title: 'Šta da navedeš',
          bullets: [
            'Jasnu fotografiju psa',
            'Mesto gde je poslednji put viđen',
            'Datum i približno vreme',
            'Kontakt podatke koji su namenjeni za kontakt',
            'Informacije o ogrlici ili drugim prepoznatljivim detaljima',
          ],
          warning: 'Ne objavljuj tuđe privatne podatke bez dozvole.',
        ),
        TipSection(
          title: 'Ako pronađeš psa',
          bullets: [
            'Ako je moguće, pokušaj bezbedno da ga zadržiš na sigurnom mestu i kontaktiraj vlasnika ili nadležne službe.',
            'Ne izlaži sebe opasnosti — tvoja bezbednost je na prvom mestu.',
          ],
        ),
      ],
    ),
    TipArticle(
      id: 'rule-adoption',
      category: TipCategory.urgent,
      icon: Icons.home_outlined,
      accent: importantAccent,
      title: 'Odgovorno udomljavanje',
      summary: 'Udomljavanje je dugoročna odgovornost.',
      sections: [
        TipSection(
          title: 'Zapamti',
          bullets: [
            'Ne objavljuj lažne oglase.',
            'Navedi što tačnije informacije o psu.',
            'Nemoj skrivati poznate važne informacije o zdravlju ili ponašanju psa.',
            'Dobro proveri kome poveravaš psa.',
            'Ne donosi odluku o udomljavanju impulsivno.',
            'Razmisli o prostoru, vremenu, troškovima i obavezama koje pas zahteva.',
          ],
        ),
      ],
      footerNote:
          'VauVau je platforma za povezivanje korisnika i ne može garantovati ponašanje ili namere drugih korisnika.',
    ),
    TipArticle(
      id: 'rule-report',
      category: TipCategory.urgent,
      icon: Icons.shield_outlined,
      accent: importantAccent,
      title: 'Vidiš nešto što krši pravila?',
      summary: 'Prijavi problem administratoru.',
      sections: [
        TipSection(
          title: 'Prijavi problem',
          bullets: [
            'Ako primetiš sadržaj ili ponašanje koje nije u skladu sa VauVau pravilima, prijavi ga administratoru.',
          ],
        ),
      ],
      cta: TipCtaKind.writeAdmin,
      ctaLabel: '✉️ Piši Adminu',
    ),
  ];
}
