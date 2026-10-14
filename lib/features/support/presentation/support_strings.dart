import '../../../core/l10n/l10n.dart';

abstract final class SupportStrings {
  static String get title => L10n.tr('Pravila & Podrška', 'Rules & Support');
  static String get rulesTab => L10n.tr('📜 Pravila', '📜 Rules');
  static String get tipsTab => L10n.tr('💡 Saveti', '💡 Tips');
  static String get contactTab => L10n.tr('✉️ Piši Adminu', '✉️ Contact admin');
  static String get sosIntro =>
      L10n.tr('Dežurne službe 00–24h. Novi Sad i Beograd.', 'On-call services 24/7. Novi Sad and Belgrade.');
  static String get sosBadge => L10n.tr('HITNA POMOĆ', 'EMERGENCY');
  static String get sosSubtitle => L10n.tr('Brze linije i dežurne službe', 'Hotlines and on-call services');
  static String get sosVet => L10n.tr('VETERINAR', 'VET');
  static String get sosShelter => L10n.tr('AZIL / ZOOHIGIJENA', 'SHELTER / ANIMAL CONTROL');
  static String get sosLocal => L10n.tr('LOKALNA SLUŽBA', 'LOCAL SERVICE');
  static String get sosHelpTitle => L10n.tr('Brza pomoć', 'Quick help');
  static String get callNow => L10n.tr('Pozovi', 'Call');
  static String get callUnavailable =>
      L10n.tr('Poziv nije moguć na ovom uređaju.', 'Calling is not available on this device.');

  static String get rulesTitle => L10n.tr('Pravila VauVau zajednice', 'VauVau community rules');
  static String get rulesIntro => L10n.tr(
        'VauVau je mesto za druženje, šetnje, upoznavanje i pomoć psima i njihovim vlasnicima. Poštuj druge korisnike, njihove pse i zajednički prostor.',
        'VauVau is for meetups, walks, discovery, and helping dogs and their owners. Respect other users, their dogs, and shared spaces.',
      );
  static String get rulesLocalNote => L10n.tr(
        'Poštuj i lokalna pravila koja važe na mestu na kojem se nalaziš.',
        'Also follow local rules that apply where you are.',
      );
  static String get rulesCategoryDaily => L10n.tr('🐕 SVAKODNEVNA PRAVILA', '🐕 EVERYDAY RULES');
  static String get rulesCategoryCommunity =>
      L10n.tr('🛡️ PONAŠANJE ZAJEDNICE', '🛡️ COMMUNITY CONDUCT');
  static String get rulesCategoryImportant => L10n.tr('🚨 VAŽNE SITUACIJE', '🚨 IMPORTANT SITUATIONS');
  static String get rulesOutroTitle => L10n.tr('VauVau je zajednica.', 'VauVau is a community.');
  static String get rulesOutroBody => L10n.tr(
        'Imaj razumevanja prema drugim vlasnicima, poštuj njihove pse i učini da VauVau bude prijatno mesto za sve.',
        'Be understanding toward other owners, respect their dogs, and help keep VauVau welcoming for everyone.',
      );
  static String get rulesUpdateNote => L10n.tr(
        'Pravila mogu biti ažurirana kako se VauVau zajednica bude razvijala.',
        'Rules may be updated as the VauVau community grows.',
      );
  static String get tipsIntro => L10n.tr(
        'Korisne informacije za svakodnevnu brigu, bezbednost i zdravlje vašeg psa.',
        'Useful info for daily care, safety, and your dog\'s health.',
      );
  static String get tipsTitle => L10n.tr('Saveti za vlasnike pasa', 'Tips for dog owners');
  static String get tipsDisclaimer => L10n.tr(
        'Informacije su edukativnog karaktera i ne zamenjuju pregled i savet veterinara.',
        'Information is educational and does not replace a vet exam or advice.',
      );
  static String get tipsCategoryUrgent => L10n.tr('🚨 HITNO', '🚨 URGENT');
  static String get tipsCategoryPrevention => L10n.tr('🛡️ PREVENCIJA', '🛡️ PREVENTION');
  static String get tipsCategoryDaily => L10n.tr('🐕 SVAKODNEVNA BRIGA', '🐕 DAILY CARE');
  static String get tipsQuickCheckTitle => L10n.tr('🚨 Nisi siguran šta da uradiš?', '🚨 Not sure what to do?');
  static String get tipsQuickCheckBody => L10n.tr(
        'Ako pas teško diše, gubi svest, ima napad, jako krvari, sumnja se na trovanje, doživi ozbiljnu povredu ili pokazuje znake toplotnog udara — ne čekaj da se stanje samo popravi. Kontaktiraj veterinara.',
        'If your dog has trouble breathing, loses consciousness, has a seizure, bleeds heavily, may be poisoned, has a serious injury, or shows heatstroke signs — don\'t wait for it to pass. Contact a vet.',
      );
  static String get tipsFindVetCta => L10n.tr('📍 PRONAĐI DEŽURNOG VETERINARA', '📍 FIND ON-CALL VET');
  static String get tipsSourcesNote => L10n.tr(
        'Informacije u ovoj sekciji zasnovane su na preporukama relevantnih veterinarskih organizacija i služe samo za edukativne svrhe.',
        'Information in this section is based on recommendations from relevant veterinary organizations and is for educational purposes only.',
      );
  static String get contactIntro => L10n.tr(
        'Imate predlog, problem, pohvalu ili pitanje? Poruka stiže direktno '
        'VauVau timu.',
        'Have a suggestion, issue, praise, or question? Your message goes directly to the VauVau team.',
      );

  static String get category => L10n.tr('Kategorija', 'Category');
  static String get subject => L10n.tr('Naslov', 'Subject');
  static String get message => L10n.tr('Poruka', 'Message');
  static String get send => L10n.tr('Pošalji', 'Send');
  static String get subjectRequired => L10n.tr('Unesite naslov.', 'Enter a subject.');
  static String get messageRequired => L10n.tr('Unesite poruku.', 'Enter a message.');
  static String get messageTooShort =>
      L10n.tr('Poruka mora imati bar 10 karaktera.', 'Message must be at least 10 characters.');
  static String get sentTitle => L10n.tr('Hvala! 🐾', 'Thank you! 🐾');
  static String get sentBody => L10n.tr(
        'Poruka je poslata adminu. Javićemo vam se ako bude potrebno.',
        'Your message was sent to the admin. We\'ll reach out if needed.',
      );
  static String get ok => L10n.tr('U redu', 'OK');
  static String get sendError =>
      L10n.tr('Poruka nije poslata. Pokušajte ponovo.', 'Message was not sent. Try again.');
  static String get followUs => L10n.tr('Pratite nas & Kontakt', 'Follow us & contact');
  static String get linkError => L10n.tr('Nije moguće otvoriti link.', 'Could not open link.');
  static String get aboutTitle => L10n.tr('O aplikaciji', 'About the app');
  static String get aboutBody => L10n.tr(
        'VauVau povezuje vlasnike pasa za šetnje, druženje i pomoć u komšiluku.',
        'VauVau connects dog owners for walks, meetups, and neighborhood help.',
      );
  static String get appVersion => L10n.tr('Verzija 1.0.0', 'Version 1.0.0');
}
