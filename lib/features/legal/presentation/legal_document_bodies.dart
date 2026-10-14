import '../../../core/l10n/l10n.dart';

class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

abstract final class PrivacyPolicyBody {
  static List<LegalSection> sections() => [
        LegalSection(
          title: L10n.tr('1. Ko smo mi', '1. Who we are'),
          body: L10n.tr(
            'VauVau („aplikacija“) je društvena platforma za vlasnike pasa. '
            'Kontrolor podataka je tim VauVau. Kontakt: vauvau.app@gmail.com.',
            'VauVau (“the app”) is a social platform for dog owners. '
            'The data controller is the VauVau team. Contact: vauvau.app@gmail.com.',
          ),
        ),
        LegalSection(
          title: L10n.tr('2. Koje podatke prikupljamo', '2. Data we collect'),
          body: L10n.tr(
            '• Nalog: email, ime/prikazno ime, fotografija profila.\n'
            '• Psi: ime, rasa, starost, pol, veličina, opis, fotografije.\n'
            '• Lokacija: GPS tokom aktivne šetnje (sa obaveštenjem) i dok je '
            'aplikacija otvorena radi mape i „u blizini“ funkcija.\n'
            '• Poruke i sadržaj: chat, momente, događaje, grupe, oglase za '
            'udomljavanje i izgubljene pse koje sami objavite.\n'
            '• Obaveštenja: FCM token uređaja radi push poruka.\n'
            '• Tehnički podaci: osnovni podaci o uređaju/aplikaciji potrebni '
            'za rad Firebase usluga.',
            '• Account: email, display name, profile photo.\n'
            '• Dogs: name, breed, age, gender, size, bio, photos.\n'
            '• Location: GPS during an active walk (with a notification) and '
            'while the app is open for map / nearby features.\n'
            '• Messages & content: chat, moments, events, groups, adoption and '
            'lost-dog listings you post.\n'
            '• Notifications: device FCM token for push alerts.\n'
            '• Technical data: basic device/app data needed for Firebase.',
          ),
        ),
        LegalSection(
          title: L10n.tr('3. Zašto obrađujemo podatke', '3. Why we process data'),
          body: L10n.tr(
            'Podatke koristimo da omogućimo nalog, matching i chat, praćenje '
            'šetnji, mape, obaveštenja, moderaciju i bezbednost zajednice, '
            'kao i da odgovorimo na zahteve za podršku.',
            'We use data to provide accounts, matching and chat, walk tracking, '
            'maps, notifications, community moderation and safety, and to '
            'respond to support requests.',
          ),
        ),
        LegalSection(
          title: L10n.tr('4. Deljenje podataka', '4. Sharing'),
          body: L10n.tr(
            'Profil i sadržaj koji objavite vide drugi korisnici VauVau-a. '
            'Tehnički obrađivači (npr. Google Firebase: Auth, Firestore, Storage, '
            'Cloud Messaging) obrađuju podatke u naše ime. Ne prodajemo lične '
            'podatke trećim stranama za oglašavanje.',
            'Your profile and content you post are visible to other VauVau users. '
            'Processors such as Google Firebase (Auth, Firestore, Storage, Cloud '
            'Messaging) handle data on our behalf. We do not sell personal data '
            'to third parties for advertising.',
          ),
        ),
        LegalSection(
          title: L10n.tr('5. Lokacija', '5. Location'),
          body: L10n.tr(
            'Lokaciju ne tražimo kao „uvek dozvoli“ u pozadini na Androidu. '
            'Tokom šetnje koristimo GPS uz trajno obaveštenje (foreground service). '
            'Možete odbijati dozvole u podešavanjima uređaja; neke funkcije mape '
            'tada neće raditi.',
            'On Android we do not request “Allow all the time” background access. '
            'During walks we use GPS with a persistent notification (foreground '
            'service). You can revoke permissions in system settings; some map '
            'features will then be unavailable.',
          ),
        ),
        LegalSection(
          title: L10n.tr('6. Čuvanje i bezbednost', '6. Retention & security'),
          body: L10n.tr(
            'Podatke čuvamo dok imate nalog ili dok su potrebni za uslugu i '
            'zakonske obaveze. Koristimo Firebase bezbednosne kontrole; ipak, '
            'nijedan sistem nije 100% bez rizika.',
            'We keep data while you have an account or as needed for the service '
            'and legal obligations. We use Firebase security controls; no system '
            'is 100% risk-free.',
          ),
        ),
        LegalSection(
          title: L10n.tr('7. Vaša prava', '7. Your rights'),
          body: L10n.tr(
            'Možete da zatražite uvid, ispravku ili brisanje podataka. U '
            'aplikaciji: Profil → Obriši nalog — briše profil, pse, fotografije, '
            'momente, vaše chat poruke, mečeve, oglase i događaje koje ste '
            'organizovali. Takođe pišite na vauvau.app@gmail.com. Zavisno od '
            'lokalnog prava (npr. GDPR), možete imati dodatna prava.',
            'You may request access, correction, or deletion. In the app: '
            'Profile → Delete account — removes your profile, dogs, photos, '
            'moments, your chat messages, matches, listings, and events you '
            'organized. Or email vauvau.app@gmail.com. Depending on local law '
            '(e.g. GDPR), you may have additional rights.',
          ),
        ),
        LegalSection(
          title: L10n.tr('8. Deca', '8. Children'),
          body: L10n.tr(
            'VauVau nije namenjen deci mlađoj od 13 godina (ili više ako to '
            'zahteva lokalni zakon). Ne prikupljamo svesno podatke od dece.',
            'VauVau is not directed at children under 13 (or older if required '
            'by local law). We do not knowingly collect data from children.',
          ),
        ),
        LegalSection(
          title: L10n.tr('9. Izmene', '9. Changes'),
          body: L10n.tr(
            'Politiku možemo ažurirati. Nova verzija će biti dostupna u '
            'aplikaciji i na vauvau.app/privacy. Nastavak korišćenja nakon '
            'izmene znači prihvatanje ažurirane politike.',
            'We may update this policy. The latest version will be available in '
            'the app and at vauvau.app/privacy. Continued use after a change '
            'means you accept the updated policy.',
          ),
        ),
      ];
}

abstract final class TermsOfServiceBody {
  static List<LegalSection> sections() => [
        LegalSection(
          title: L10n.tr('1. Prihvatanje', '1. Acceptance'),
          body: L10n.tr(
            'Korišćenjem VauVau prihvatate ove uslove i Politiku privatnosti. '
            'Ako se ne slažete, nemojte koristiti aplikaciju.',
            'By using VauVau you accept these terms and the Privacy Policy. '
            'If you disagree, do not use the app.',
          ),
        ),
        LegalSection(
          title: L10n.tr('2. Nalog', '2. Account'),
          body: L10n.tr(
            'Odgovorni ste za tačnost podataka i bezbednost prijave. Jedan '
            'korisnik — jedan nalog. Zabranjeno je lažno predstavljanje.',
            'You are responsible for accurate information and account security. '
            'One person — one account. Impersonation is prohibited.',
          ),
        ),
        LegalSection(
          title: L10n.tr('3. Ponašanje', '3. Conduct'),
          body: L10n.tr(
            'Poštujte druge vlasnike i pse. Zabranjeni su govor mržnje, '
            'uznemiravanje, spam, prevara, ilegalan sadržaj i zloupotreba '
            'lokacije ili fotografija. Moderatori mogu ukloniti sadržaj i '
            'naloge koji krše pravila.',
            'Respect other owners and dogs. Hate speech, harassment, spam, '
            'fraud, illegal content, and abuse of location or photos are banned. '
            'Moderators may remove content and accounts that break the rules.',
          ),
        ),
        LegalSection(
          title: L10n.tr('4. Sadržaj korisnika', '4. User content'),
          body: L10n.tr(
            'Zadržavate prava na svoj sadržaj, ali dajete VauVau-u dozvolu da '
            'ga prikaže u aplikaciji. Ne objavljujte sadržaj na koji nemate '
            'prava.',
            'You keep rights to your content but grant VauVau permission to '
            'display it in the app. Do not post content you lack rights to.',
          ),
        ),
        LegalSection(
          title: L10n.tr('5. Bezbednost u stvarnom svetu', '5. Real-world safety'),
          body: L10n.tr(
            'Šetnje i susreti su na vašu odgovornost. Proverite pse, okruženje '
            'i lokalne propise. VauVau nije veterinarska ni hitna služba.',
            'Walks and meetups are at your own risk. Check dogs, surroundings, '
            'and local rules. VauVau is not a veterinary or emergency service.',
          ),
        ),
        LegalSection(
          title: L10n.tr('6. Dostupnost usluge', '6. Service availability'),
          body: L10n.tr(
            'Trudimo se da usluga radi pouzdano, ali ne garantujemo '
            'neprekidan rad. Možemo menjati ili ukinuti funkcije uz razuman '
            'napor da vas obavestimo.',
            'We aim for reliable service but do not guarantee uninterrupted '
            'uptime. We may change or discontinue features with reasonable '
            'notice when practical.',
          ),
        ),
        LegalSection(
          title: L10n.tr('7. Odricanje odgovornosti', '7. Disclaimer'),
          body: L10n.tr(
            'Aplikacija se pruža „kakva jeste“. U meri dozvoljenoj zakonom '
            'ne odgovaramo za indirektne štete nastale korišćenjem ili '
            'nemogućnošću korišćenja VauVau-a.',
            'The app is provided “as is”. To the extent allowed by law we are '
            'not liable for indirect damages from using or being unable to '
            'use VauVau.',
          ),
        ),
        LegalSection(
          title: L10n.tr('8. Kontakt', '8. Contact'),
          body: L10n.tr(
            'Pitanja: vauvau.app@gmail.com',
            'Questions: vauvau.app@gmail.com',
          ),
        ),
      ];
}
