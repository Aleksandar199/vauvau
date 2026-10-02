abstract final class GroupsStrings {
  static const String drawerItem = '👥 Grupe';
  static const String title = 'Grupe za šetnju i rase';
  static const String subtitle =
      'Pridruži se lokalnim grupama, dogovori šetnju i razmeni savete.';
  static const String join = '+ Pridruži se';
  static const String openChat = '💬 Otvori chat';
  static const String composeHint = 'Napiši poruku u grupi...';
  static const String send = 'Pošalji';
  static const String addPhoto = 'Fotografija';
  static const String gallery = 'Galerija';
  static const String camera = 'Kamera';
  static const String cancel = 'Otkaži';
  static const String photoFailed = 'Fotografija nije poslata. Pokušajte ponovo.';
  static const String emptyChat = 'Još nema poruka. Reci zdravo čoporu!';
  static const String members = 'članova';
  static const String createGroup = 'Napravi novu grupu';
  static const String createGroupTitle = 'Nova grupa';
  static const String groupName = 'Naziv grupe';
  static const String groupDescription = 'Opis (opciono)';
  static const String submitGroup = 'Pošalji na pregled';
  static const String nameRequired = 'Unesite naziv grupe.';
  static const String pendingReview =
      'Vaša grupa je poslata na pregled. Biće vidljiva nakon odobrenja administratora.';
  static const String createdApproved = 'Grupa je kreirana i odmah vidljiva.';
  static const String createFailed = 'Grupa nije kreirana. Pokušajte ponovo.';
  static const String requestSentTitle = 'Zahtev poslat';
  static const String requestSentBody =
      'Vaša grupa je uspešno poslata na pregled. Biće vidljiva svim korisnicima nakon odobrenja administratora.';
  static const String createErrorTitle = 'Greška';
  static const String ok = 'U redu';
  static const String close = 'Zatvori';

  static String createErrorBody(String details) =>
      'Neuspešno kreiranje grupe: $details';

  static String memberCount(int count) => '$count $members';
}
