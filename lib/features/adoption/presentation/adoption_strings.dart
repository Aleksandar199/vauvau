import '../../../core/l10n/l10n.dart';

abstract final class AdoptionStrings {
  static String get title => L10n.tr('Udomi ljubimca', 'Adopt a pet');
  static String get subtitle =>
      L10n.tr('Pronađi novog doma za psa ili udomi ljubimca', 'Find a new home for a dog or adopt a pet');
  static String get addCta => L10n.tr('+ Dodaj psa za udomljavanje', '+ List a dog for adoption');
  static String get addTitle => L10n.tr('Novi oglas', 'New listing');
  static String get badge => L10n.tr('Udomljava se', 'For adoption');
  static String get empty => L10n.tr('Još nema oglasa za udomljavanje.', 'No adoption listings yet.');
  static String get emptySubtitle => L10n.tr(
        'Dodajte psa ili proverite kasnije — novi oglasi stižu svakog dana.',
        'Add a dog or check back later — new listings arrive every day.',
      );
  static String get loadError =>
      L10n.tr('Došlo je do greške. Pokušajte ponovo.', 'Something went wrong. Try again.');
  static String get retry => L10n.tr('Pokušaj ponovo', 'Try again');
  static String get name => L10n.tr('Ime psa', 'Dog name');
  static String get breed => L10n.tr('Rasa', 'Breed');
  static String get age => L10n.tr('Starost', 'Age');
  static String get ageHint => L10n.tr('npr. 6 meseci ili 2 god.', 'e.g. 6 months or 2 yrs');
  static String get gender => L10n.tr('Pol', 'Gender');
  static String get male => L10n.tr('Mužjak', 'Male');
  static String get female => L10n.tr('Ženka', 'Female');
  static String get size => L10n.tr('Veličina', 'Size');
  static String get sizeSmall => L10n.tr('Mali', 'Small');
  static String get sizeMedium => L10n.tr('Srednji', 'Medium');
  static String get sizeLarge => L10n.tr('Veliki', 'Large');
  static String get story => L10n.tr('Priča o psu', 'Dog\'s story');
  static String get storyHint =>
      L10n.tr('Opišite karakter, navike i zašto traži dom.', 'Describe personality, habits, and why they need a home.');
  static String get location => L10n.tr('Lokacija', 'Location');
  static String get city => L10n.tr('Grad', 'City');
  static String get neighborhood => L10n.tr('Kvart / Naselje', 'Neighborhood');
  static String get cityRequired => L10n.tr('Izaberite grad.', 'Select a city.');
  static String get neighborhoodRequired => L10n.tr('Izaberite naselje.', 'Select a neighborhood.');
  static String get phone => L10n.tr('Kontakt telefon', 'Contact phone');
  static String get vaccinated => L10n.tr('Vakcinisan', 'Vaccinated');
  static String get sterilized => L10n.tr('Sterilisan', 'Spayed/neutered');
  static String get yes => L10n.tr('Da', 'Yes');
  static String get addPhotos => L10n.tr('Dodaj fotografije', 'Add photos');
  static String get publish => L10n.tr('Objavi oglas', 'Publish listing');
  static String get published =>
      L10n.tr('Oglas za udomljavanje je uspešno objavljen! 🐾', 'Adoption listing published successfully! 🐾');
  static String get publishing => L10n.tr('Objavljivanje...', 'Publishing...');
  static String get breedRequired => L10n.tr('Unesite rasu.', 'Enter breed.');
  static String get ageRequired => L10n.tr('Unesite starost.', 'Enter age.');
  static String get publishError =>
      L10n.tr('Oglas nije sačuvan. Pokušajte ponovo.', 'Listing was not saved. Try again.');
  static String get nameRequired => L10n.tr('Unesite ime psa.', 'Enter dog name.');
  static String get locationRequired => L10n.tr('Unesite lokaciju.', 'Enter location.');
  static String get phoneRequired => L10n.tr('Unesite kontakt telefon.', 'Enter contact phone.');
  static String get storyRequired => L10n.tr('Unesite priču o psu.', 'Enter the dog\'s story.');
  static String get owner => L10n.tr('Vlasnik / organizacija', 'Owner / organization');
  static String get sendMessage => L10n.tr('Pošalji poruku', 'Send message');
  static String get call => L10n.tr('Pozovi', 'Call');
  static String get callOwner => L10n.tr('Pozovi vlasnika', 'Call owner');
  static String get callUnavailable => L10n.tr('Broj telefona nije dostupan.', 'Phone number unavailable.');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get details => L10n.tr('Detalji', 'Details');
  static String get markAdopted => L10n.tr('Označi kao udomljen', 'Mark as adopted');
  static String get adoptedBadge => L10n.tr('Udomljen', 'Adopted');
  static String get adoptedConfirmTitle => L10n.tr('Označiti kao udomljenog?', 'Mark as adopted?');
  static String get adoptedConfirmBody => L10n.tr(
        'Oglas će nestati iz liste pasa koji traže dom.',
        'The listing will be removed from dogs looking for a home.',
      );
  static String get adoptedDone => L10n.tr('Oglas je označen kao udomljen.', 'Listing marked as adopted.');

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
      return L10n.tr('sada', 'now');
    }
    if (diff.inMinutes < 60) {
      return L10n.tr('pre ${diff.inMinutes} min', '${diff.inMinutes} min ago');
    }
    if (diff.inHours < 24) {
      return L10n.tr('pre ${diff.inHours} č', '${diff.inHours} h ago');
    }
    if (diff.inDays < 7) {
      return L10n.tr('pre ${diff.inDays} d', '${diff.inDays} d ago');
    }
    return '${value.day}.${value.month}.';
  }
}
