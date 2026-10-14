import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import 'tips_content.dart';

abstract final class RulesContent {
  static const Color dailyAccent = TipsContent.dailyAccent;
  static const Color communityAccent = TipsContent.preventionAccent;
  static const Color importantAccent = TipsContent.urgentAccent;

  static List<TipArticle> get daily => [
        TipArticle(
          id: 'rule-clean-up',
          category: TipCategory.daily,
          icon: Icons.cleaning_services_outlined,
          accent: dailyAccent,
          title: L10n.tr(
            'Počisti za svojim psom',
            'Clean up after your dog',
          ),
          summary: L10n.tr(
            'Uvek ponesi kesicu i pokupi izmet svog psa.',
            'Always bring a bag and pick up after your dog.',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Zapamti', 'Remember'),
              bullets: [
                L10n.tr(
                  'Ponesi dovoljno kesica pre šetnje.',
                  'Bring enough bags before the walk.',
                ),
                L10n.tr(
                  'Ne ostavljaj izmet na ulici, travi, stazi ili prostoru koji koriste drugi ljudi.',
                  'Don’t leave waste on the street, grass, path, or shared spaces.',
                ),
                L10n.tr(
                  'Ako je moguće, baci kesicu u odgovarajuću kantu.',
                  'If possible, throw the bag in a proper bin.',
                ),
              ],
            ),
          ],
          footerNote: L10n.tr(
            'Čist prostor je prijatniji za sve — i za pse i za ljude.',
            'A clean space is nicer for everyone — dogs and people.',
          ),
        ),
        TipArticle(
          id: 'rule-leash',
          category: TipCategory.daily,
          icon: Icons.pets_outlined,
          accent: dailyAccent,
          title: L10n.tr(
            'Povodac i bezbednost',
            'Leash and safety',
          ),
          summary: L10n.tr(
            'Poštuj druge pse, ljude i lokalna pravila o korišćenju povoca.',
            'Respect other dogs, people, and local leash rules.',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Zapamti', 'Remember'),
              bullets: [
                L10n.tr(
                  'Koristi povodac kada je to potrebno ili kada lokalna pravila to zahtevaju.',
                  'Use a leash when needed or when local rules require it.',
                ),
                L10n.tr(
                  'Ne puštaj psa bez provere da li je prostor bezbedan i dozvoljen za to.',
                  'Don’t let your dog off-leash without checking the space is safe and allowed.',
                ),
                L10n.tr(
                  'Ne dozvoli psu da sam prilazi drugim psima ili ljudima bez njihove saglasnosti.',
                  'Don’t let your dog approach other dogs or people without their consent.',
                ),
                L10n.tr(
                  'Obrati pažnju na saobraćaj, decu, bicikliste i druge potencijalne opasnosti.',
                  'Watch for traffic, children, cyclists, and other hazards.',
                ),
              ],
              warning: L10n.tr(
                'Ako nisi siguran da li je puštanje psa dozvoljeno, proveri pravila konkretnog prostora.',
                'If you’re unsure whether off-leash is allowed, check the rules for that space.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'rule-park',
          category: TipCategory.daily,
          icon: Icons.park_outlined,
          accent: dailyAccent,
          title: L10n.tr(
            'Ponašanje u parku',
            'Park behavior',
          ),
          summary: L10n.tr(
            'Park je zajednički prostor za ljude i pse.',
            'The park is a shared space for people and dogs.',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Zapamti', 'Remember'),
              bullets: [
                L10n.tr(
                  'Poštuj druge vlasnike i njihove pse.',
                  'Respect other owners and their dogs.',
                ),
                L10n.tr(
                  'Ne pretpostavljaj da svaki pas želi da se igra.',
                  'Don’t assume every dog wants to play.',
                ),
                L10n.tr(
                  'Pitaj vlasnika pre nego što dozvoliš svom psu da priđe njegovom psu.',
                  'Ask the owner before letting your dog approach theirs.',
                ),
                L10n.tr(
                  'Prati svog psa i ne dozvoli mu da uznemirava druge.',
                  'Watch your dog and don’t let them bother others.',
                ),
                L10n.tr(
                  'Poštuj prostor namenjen deci i druge korisnike parka.',
                  'Respect children’s areas and other park users.',
                ),
                L10n.tr(
                  'Ako primetiš problematičnu situaciju, udalji psa i smiri situaciju.',
                  'If a situation turns tense, move your dog away and calm things down.',
                ),
              ],
              warning: L10n.tr(
                'Ne forsiraj kontakt između pasa. Neki psi su plašljivi, stariji, bolesni ili jednostavno ne žele druženje.',
                'Don’t force contact between dogs. Some are shy, older, unwell, or simply don’t want to socialize.',
              ),
            ),
          ],
        ),
        TipArticle(
          id: 'rule-other-dogs',
          category: TipCategory.daily,
          icon: Icons.front_hand_outlined,
          accent: dailyAccent,
          title: L10n.tr(
            'Poštuj tuđe pse',
            'Respect other people’s dogs',
          ),
          summary: L10n.tr(
            'Ne prilazi tuđem psu bez dozvole vlasnika.',
            'Don’t approach someone else’s dog without the owner’s permission.',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Zapamti', 'Remember'),
              bullets: [
                L10n.tr(
                  'Nemoj hraniti tuđeg psa bez pitanja.',
                  'Don’t feed someone else’s dog without asking.',
                ),
                L10n.tr(
                  'Nemoj ga dodirivati bez dozvole vlasnika.',
                  'Don’t touch them without the owner’s permission.',
                ),
                L10n.tr(
                  'Ne puštaj svog psa da skače na druge pse.',
                  'Don’t let your dog jump on other dogs.',
                ),
                L10n.tr(
                  'Ako vlasnik kaže da njegov pas ne želi kontakt, poštuj to.',
                  'If an owner says their dog doesn’t want contact, respect that.',
                ),
                L10n.tr(
                  'Posebno obrati pažnju na pse koji nose oznake da su plašljivi, reaktivni ili da ne žele kontakt.',
                  'Pay special attention to dogs marked as shy, reactive, or not wanting contact.',
                ),
              ],
            ),
          ],
        ),
      ];

  static List<TipArticle> get community => [
        TipArticle(
          id: 'rule-owners',
          category: TipCategory.prevention,
          icon: Icons.handshake_outlined,
          accent: communityAccent,
          title: L10n.tr(
            'Poštuj druge vlasnike',
            'Respect other owners',
          ),
          summary: L10n.tr(
            'Budi ljubazan i poštuj tuđe granice.',
            'Be kind and respect other people’s boundaries.',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Zapamti', 'Remember'),
              bullets: [
                L10n.tr(
                  'Budi ljubazan prema drugim korisnicima.',
                  'Be kind to other users.',
                ),
                L10n.tr(
                  'Ne vređaj, ne provociraj i ne uznemiravaj druge.',
                  'Don’t insult, provoke, or harass others.',
                ),
                L10n.tr(
                  'Poštuj tuđe granice.',
                  'Respect other people’s boundaries.',
                ),
                L10n.tr(
                  'Ne fotografiši ili objavljuj druge ljude bez odgovarajuće saglasnosti kada je to potrebno.',
                  'Don’t photograph or post other people without appropriate consent when needed.',
                ),
                L10n.tr(
                  'Ako se ne slažeš sa nekim, razgovaraj normalno ili prijavi problem administratoru.',
                  'If you disagree with someone, talk it through calmly or report the issue to an admin.',
                ),
              ],
            ),
          ],
        ),
        TipArticle(
          id: 'rule-app-culture',
          category: TipCategory.prevention,
          icon: Icons.forum_outlined,
          accent: communityAccent,
          title: L10n.tr(
            'Kultura na VauVau',
            'Culture on VauVau',
          ),
          summary: L10n.tr(
            'Poruke, grupe i komentari — uvek pristojno.',
            'Messages, groups, and comments — always respectful.',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Zapamti', 'Remember'),
              bullets: [
                L10n.tr(
                  'Komuniciraj pristojno.',
                  'Communicate politely.',
                ),
                L10n.tr(
                  'Ne vređaj druge korisnike.',
                  'Don’t insult other users.',
                ),
                L10n.tr(
                  'Ne uznemiravaj druge korisnike porukama.',
                  'Don’t harass others with messages.',
                ),
                L10n.tr(
                  'Ne šalji neželjen ili neprikladan sadržaj.',
                  'Don’t send unwanted or inappropriate content.',
                ),
                L10n.tr(
                  'Ne spamuj grupe, komentare ili objave.',
                  'Don’t spam groups, comments, or posts.',
                ),
                L10n.tr(
                  'Ne koristi VauVau za prevare ili obmanjivanje drugih korisnika.',
                  'Don’t use VauVau for scams or to mislead others.',
                ),
                L10n.tr(
                  'Ne objavljuj tuđe privatne podatke.',
                  'Don’t post other people’s private information.',
                ),
                L10n.tr(
                  'Prijavi sadržaj koji krši pravila.',
                  'Report content that breaks the rules.',
                ),
              ],
            ),
          ],
        ),
        TipArticle(
          id: 'rule-posts',
          category: TipCategory.prevention,
          icon: Icons.photo_camera_outlined,
          accent: communityAccent,
          title: L10n.tr(
            'Objave i sadržaj',
            'Posts and content',
          ),
          summary: L10n.tr(
            'Objavljuj ono što je vezano za pse i zajednicu.',
            'Post things related to dogs and the community.',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Zapamti', 'Remember'),
              bullets: [
                L10n.tr(
                  'Objavljuj sadržaj koji je povezan sa temom aplikacije.',
                  'Post content related to the app’s purpose.',
                ),
                L10n.tr(
                  'Ne objavljuj uvredljiv, uznemirujući ili neprikladan sadržaj.',
                  'Don’t post offensive, harassing, or inappropriate content.',
                ),
                L10n.tr(
                  'Ne objavljuj tuđe fotografije bez odgovarajuće dozvole.',
                  'Don’t post other people’s photos without proper permission.',
                ),
                L10n.tr(
                  'Ne predstavljaj tuđe fotografije ili informacije kao svoje.',
                  'Don’t present other people’s photos or info as your own.',
                ),
                L10n.tr('Ne spamuj.', 'Don’t spam.'),
                L10n.tr(
                  'Ne objavljuj sadržaj koji može ugroziti druge korisnike ili životinje.',
                  'Don’t post content that could harm other users or animals.',
                ),
              ],
            ),
          ],
        ),
        TipArticle(
          id: 'rule-not-allowed',
          category: TipCategory.prevention,
          icon: Icons.block_outlined,
          accent: communityAccent,
          title: L10n.tr(
            'Šta nije dozvoljeno',
            'What is not allowed',
          ),
          summary: L10n.tr(
            'Kratak spisak stvari koje ne tolerišemo.',
            'A short list of things we don’t tolerate.',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Nije dozvoljeno',
                'Not allowed',
              ),
              bullets: [
                L10n.tr(
                  'Uznemiravanje drugih korisnika',
                  'Harassing other users',
                ),
                L10n.tr(
                  'Pretnje i vređanje',
                  'Threats and insults',
                ),
                L10n.tr('Spam', 'Spam'),
                L10n.tr('Prevare', 'Scams'),
                L10n.tr(
                  'Lažno predstavljanje',
                  'Impersonation',
                ),
                L10n.tr(
                  'Zloupotreba tuđih podataka',
                  'Misuse of other people’s data',
                ),
                L10n.tr(
                  'Objavljivanje privatnih podataka drugih osoba',
                  'Posting other people’s private information',
                ),
                L10n.tr(
                  'Seksualno eksplicitan ili neprikladan sadržaj',
                  'Sexually explicit or inappropriate content',
                ),
                L10n.tr(
                  'Sadržaj koji promoviše nasilje ili ugrožavanje životinja',
                  'Content that promotes violence or harm to animals',
                ),
                L10n.tr(
                  'Namerno širenje lažnih informacija',
                  'Deliberately spreading false information',
                ),
                L10n.tr(
                  'Korišćenje aplikacije za aktivnosti koje nisu povezane sa njenom svrhom ili mogu ugroziti druge korisnike',
                  'Using the app for activities unrelated to its purpose or that could harm other users',
                ),
              ],
            ),
          ],
        ),
      ];

  static List<TipArticle> get important => [
        TipArticle(
          id: 'rule-lost-found',
          category: TipCategory.urgent,
          icon: Icons.campaign_outlined,
          accent: importantAccent,
          title: L10n.tr(
            'Izgubljeni i pronađeni psi',
            'Lost and found dogs',
          ),
          summary: L10n.tr(
            'Ako objavljuješ izgubljenog ili pronađenog psa, unesi što više tačnih informacija.',
            'If you post a lost or found dog, include as many accurate details as you can.',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Šta da navedeš',
                'What to include',
              ),
              bullets: [
                L10n.tr(
                  'Jasnu fotografiju psa',
                  'A clear photo of the dog',
                ),
                L10n.tr(
                  'Mesto gde je poslednji put viđen',
                  'Where they were last seen',
                ),
                L10n.tr(
                  'Datum i približno vreme',
                  'Date and approximate time',
                ),
                L10n.tr(
                  'Kontakt podatke koji su namenjeni za kontakt',
                  'Contact details meant for reaching you',
                ),
                L10n.tr(
                  'Informacije o ogrlici ili drugim prepoznatljivim detaljima',
                  'Collar details or other distinctive features',
                ),
              ],
              warning: L10n.tr(
                'Ne objavljuj tuđe privatne podatke bez dozvole.',
                'Don’t post other people’s private data without permission.',
              ),
            ),
            TipSection(
              title: L10n.tr(
                'Ako pronađeš psa',
                'If you find a dog',
              ),
              bullets: [
                L10n.tr(
                  'Ako je moguće, pokušaj bezbedno da ga zadržiš na sigurnom mestu i kontaktiraj vlasnika ili nadležne službe.',
                  'If possible, keep them safely in a secure place and contact the owner or the appropriate services.',
                ),
                L10n.tr(
                  'Ne izlaži sebe opasnosti — tvoja bezbednost je na prvom mestu.',
                  'Don’t put yourself at risk — your safety comes first.',
                ),
              ],
            ),
          ],
        ),
        TipArticle(
          id: 'rule-adoption',
          category: TipCategory.urgent,
          icon: Icons.home_outlined,
          accent: importantAccent,
          title: L10n.tr(
            'Odgovorno udomljavanje',
            'Responsible adoption',
          ),
          summary: L10n.tr(
            'Udomljavanje je dugoročna odgovornost.',
            'Adoption is a long-term responsibility.',
          ),
          sections: [
            TipSection(
              title: L10n.tr('Zapamti', 'Remember'),
              bullets: [
                L10n.tr(
                  'Ne objavljuj lažne oglase.',
                  'Don’t post fake listings.',
                ),
                L10n.tr(
                  'Navedi što tačnije informacije o psu.',
                  'Share the most accurate information about the dog.',
                ),
                L10n.tr(
                  'Nemoj skrivati poznate važne informacije o zdravlju ili ponašanju psa.',
                  'Don’t hide important known details about health or behavior.',
                ),
                L10n.tr(
                  'Dobro proveri kome poveravaš psa.',
                  'Carefully check who you entrust the dog to.',
                ),
                L10n.tr(
                  'Ne donosi odluku o udomljavanju impulsivno.',
                  'Don’t decide on adoption on impulse.',
                ),
                L10n.tr(
                  'Razmisli o prostoru, vremenu, troškovima i obavezama koje pas zahteva.',
                  'Think about space, time, costs, and the commitment a dog needs.',
                ),
              ],
            ),
          ],
          footerNote: L10n.tr(
            'VauVau je platforma za povezivanje korisnika i ne može garantovati ponašanje ili namere drugih korisnika.',
            'VauVau is a platform for connecting users and cannot guarantee other users’ behavior or intentions.',
          ),
        ),
        TipArticle(
          id: 'rule-report',
          category: TipCategory.urgent,
          icon: Icons.shield_outlined,
          accent: importantAccent,
          title: L10n.tr(
            'Vidiš nešto što krši pravila?',
            'See something that breaks the rules?',
          ),
          summary: L10n.tr(
            'Prijavi problem administratoru.',
            'Report the issue to an admin.',
          ),
          sections: [
            TipSection(
              title: L10n.tr(
                'Prijavi problem',
                'Report a problem',
              ),
              bullets: [
                L10n.tr(
                  'Ako primetiš sadržaj ili ponašanje koje nije u skladu sa VauVau pravilima, prijavi ga administratoru.',
                  'If you see content or behavior that breaks VauVau rules, report it to an admin.',
                ),
              ],
            ),
          ],
          cta: TipCtaKind.writeAdmin,
          ctaLabel: L10n.tr(
            '✉️ Piši Adminu',
            '✉️ Message Admin',
          ),
        ),
      ];
}
