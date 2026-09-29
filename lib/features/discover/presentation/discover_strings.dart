abstract final class DiscoverStrings {
  static const String title = 'Otkrij';
  static const String signOut = 'Odjavi se';
  static const String pass = 'Preskoči';
  static const String like = 'Lajkuj';
  static const String liked = 'Lajkovano';
  static const String superLike = 'Super lajk';
  static const String newMatch = 'Novi meč!';
  static const String sendMessage = 'Pošalji poruku';
  static const String keepSearching = 'Nastavi sa pretragom';
  static const String emptyTitle = 'Nema više pasa u vašoj okolini.';
  static const String emptySubtitle =
      'Pokušajte sa širenjem filtera.';
  static const String resetFilters = 'Resetuj filtere';
  static const String genderAll = 'Svi';
  static const String sizeSmall = 'Mali';
  static const String sizeMid = 'Srednji';
  static const String sizeBig = 'Veliki';
  static const String energyTitle = 'Energetski nivo';
  static const String energyLow = 'Nizak';
  static const String energyMid = 'Srednji';
  static const String energyHigh = 'Visok';
  static const String distanceTitle = 'Maksimalna udaljenost';
  static const String ageTitle = 'Dobne granice';
  static const String vaccinatedOnly = 'Samo vakcinisani';
  static const String sterilizedOnly = 'Samo sterilisani';
  static const String reset = 'Poništi';
  static const String applyFilters = 'Primeni filtere';
  static const String genderTitle = 'Pol';
  static const String genderMale = 'Mužjak';
  static const String genderFemale = 'Ženka';
  static const String sizeTitle = 'Veličina psa';
  static const String search = 'Pretraga';
  static const String nearbyTitle = 'Psi u tvojoj blizini';
  static const String yourPet = 'Tvoj ljubimac';
  static const String walkingBadge = '🟢 U šetnji';
  static const String restingBadge = 'Odmaram';
  static const String lookingForPlayBadge = 'Tražim društvo za igru';
  static const String searchHint = 'Pretraži po rasi, imenu ili lokaciji...';
  static const String chipAll = 'Svi';
  static const String chipWalking = 'U šetnji';
  static const String chipSmall = 'Mali';
  static const String chipMedium = 'Srednji';
  static const String chipLarge = 'Veliki';
  static const String filters = 'Napredni filteri';
  static const String message = 'Poruka';
  static const String location = 'Lokacija';
  static const String chatPlaceholder = 'Poruke uskoro stižu.';
  static const String chatTitle = 'Poruke';
  static const String chatBack = 'Nazad';
  static const String likedToast = 'Lajk poslat';
  static const String likeFailed =
      'Lajk nije sačuvan. Proverite konekciju i pokušajte ponovo.';
  static const String passedToast = 'Preskočeno';
  static const String superLikedToast = 'Super lajk poslat!';
  static const String gender = 'Pol';
  static const String about = 'O psu';
  static const String getsAlong = 'Slaganje sa';
  static const String sterilized = 'Sterilisan / Kastriran';
  static const String reportProfile = 'Prijavi profil';
  static const String reportConfirmTitle = 'Prijavi profil?';
  static const String reportConfirmBody =
      'Prijava će biti poslata moderatorima na pregled.';
  static const String reportConfirmAction = 'Prijavi';
  static const String cancel = 'Otkaži';
  static const String details = 'Detaljan profil';
  static const String breed = 'Rasa';
  static const String age = 'Starost';
  static const String size = 'Veličina';
  static const String energy = 'Nivo energije';
  static const String traits = 'Osobine';
  static const String vaccinated = 'Vakcinisan';
  static const String chipped = 'Čipovan';
  static const String owner = 'Vlasnik';
  static const String close = 'Zatvori';
  static const String yes = 'Da';
  static const String no = 'Ne';
  static const String weight = 'Težina';

  static String years(int value) {
    final n = value.abs();
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (n == 1) {
      return '$n godina';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$n godine';
    }
    return '$n godina';
  }

  static String kg(double value) => '${value.toStringAsFixed(0)} kg';

  static String locationBadge(String city, double km) {
    final value = km == km.roundToDouble()
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
    return '$city · $value km';
  }
}
