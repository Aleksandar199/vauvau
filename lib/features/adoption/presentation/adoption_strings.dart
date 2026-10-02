abstract final class AdoptionStrings {
  static const String title = 'Udomi ljubimca';
  static const String subtitle =
      'Pronađi novog doma za psa ili udomi ljubimca';
  static const String addCta = '+ Dodaj psa za udomljavanje';
  static const String addTitle = 'Novi oglas';
  static const String badge = 'Udomljava se';
  static const String empty = 'Još nema oglasa za udomljavanje.';
  static const String emptySubtitle =
      'Dodajte psa ili proverite kasnije — novi oglasi stižu svakog dana.';
  static const String loadError =
      'Došlo je do greške. Pokušajte ponovo.';
  static const String retry = 'Pokušaj ponovo';
  static const String name = 'Ime psa';
  static const String breed = 'Rasa';
  static const String age = 'Starost';
  static const String ageHint = 'npr. 6 meseci ili 2 god.';
  static const String gender = 'Pol';
  static const String male = 'Mužjak';
  static const String female = 'Ženka';
  static const String size = 'Veličina';
  static const String sizeSmall = 'Mali';
  static const String sizeMedium = 'Srednji';
  static const String sizeLarge = 'Veliki';
  static const String story = 'Priča o psu';
  static const String storyHint = 'Opišite karakter, navike i zašto traži dom.';
  static const String location = 'Lokacija';
  static const String city = 'Grad';
  static const String neighborhood = 'Kvart / Naselje';
  static const String cityRequired = 'Izaberite grad.';
  static const String neighborhoodRequired = 'Izaberite naselje.';
  static const String phone = 'Kontakt telefon';
  static const String vaccinated = 'Vakcinisan';
  static const String sterilized = 'Sterilisan';
  static const String yes = 'Da';
  static const String addPhotos = 'Dodaj fotografije';
  static const String publish = 'Objavi oglas';
  static const String published =
      'Oglas za udomljavanje je uspešno objavljen! 🐾';
  static const String publishing = 'Objavljivanje...';
  static const String breedRequired = 'Unesite rasu.';
  static const String ageRequired = 'Unesite starost.';
  static const String publishError = 'Oglas nije sačuvan. Pokušajte ponovo.';
  static const String nameRequired = 'Unesite ime psa.';
  static const String locationRequired = 'Unesite lokaciju.';
  static const String phoneRequired = 'Unesite kontakt telefon.';
  static const String storyRequired = 'Unesite priču o psu.';
  static const String owner = 'Vlasnik / organizacija';
  static const String sendMessage = 'Pošalji poruku';
  static const String call = 'Pozovi';
  static const String callOwner = 'Pozovi vlasnika';
  static const String callUnavailable = 'Broj telefona nije dostupan.';
  static const String cancel = 'Otkaži';
  static const String details = 'Detalji';
  static const String markAdopted = 'Označi kao udomljen';
  static const String adoptedBadge = 'Udomljen';
  static const String adoptedConfirmTitle = 'Označiti kao udomljenog?';
  static const String adoptedConfirmBody =
      'Oglas će nestati iz liste pasa koji traže dom.';
  static const String adoptedDone = 'Oglas je označen kao udomljen.';

  static String sizeLabel(String size) {
    return switch (size) {
      'mali' => sizeSmall,
      'veliki' => sizeLarge,
      _ => sizeMedium,
    };
  }

  static String genderLabel(String gender) {
    return gender == 'ženka' ? female : male;
  }

  static String callLabel(String phone) {
    final compact = phone.replaceAll(' ', '');
    if (compact.length < 6) {
      return '$callOwner: $phone';
    }
    return '$callOwner: ${phone.trim()}';
  }

  static String timeAgo(DateTime value, [DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(value);
    if (diff.inMinutes < 1) {
      return 'sada';
    }
    if (diff.inMinutes < 60) {
      return 'pre ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'pre ${diff.inHours} č';
    }
    if (diff.inDays < 7) {
      return 'pre ${diff.inDays} d';
    }
    return '${value.day}.${value.month}.';
  }
}
