import '../../../core/l10n/l10n.dart';

abstract final class DiscoverStrings {
  static String get title => L10n.tr('Otkrij', 'Discover');
  static String get signOut => L10n.tr('Odjavi se', 'Sign out');
  static String get pass => L10n.tr('Preskoči', 'Pass');
  static String get like => L10n.tr('Lajkuj', 'Like');
  static String get liked => L10n.tr('Lajkovano', 'Liked');
  static String get superLike => L10n.tr('Super lajk', 'Super Like');
  static String get newMatch => L10n.tr('Novi meč!', 'New match!');
  static String get sendMessage => L10n.tr('Pošalji poruku', 'Send message');
  static String get keepSearching =>
      L10n.tr('Nastavi sa pretragom', 'Keep searching');
  static String get emptyTitle => L10n.tr(
        'Nema više pasa u vašoj okolini.',
        'No more dogs in your area.',
      );
  static String get emptySubtitle => L10n.tr(
        'Pokušajte sa širenjem filtera.',
        'Try widening your filters.',
      );
  static String get resetFilters =>
      L10n.tr('Resetuj filtere', 'Reset filters');
  static String get loadingDogs =>
      L10n.tr('Učitavanje pasa u blizini…', 'Loading nearby dogs…');
  static String get genderAll => L10n.tr('Svi', 'All');
  static String get sizeSmall => L10n.tr('Mali', 'Small');
  static String get sizeMid => L10n.tr('Srednji', 'Medium');
  static String get sizeBig => L10n.tr('Veliki', 'Large');
  static String get energyTitle =>
      L10n.tr('Energetski nivo', 'Energy level');
  static String get energyLow => L10n.tr('Nizak', 'Low');
  static String get energyMid => L10n.tr('Srednji', 'Medium');
  static String get energyHigh => L10n.tr('Visok', 'High');
  static String get distanceTitle =>
      L10n.tr('Maksimalna udaljenost', 'Maximum distance');
  static String get ageTitle => L10n.tr('Dobne granice', 'Age range');
  static String get vaccinatedOnly =>
      L10n.tr('Samo vakcinisani', 'Vaccinated only');
  static String get sterilizedOnly =>
      L10n.tr('Samo sterilisani', 'Sterilized only');
  static String get reset => L10n.tr('Poništi', 'Reset');
  static String get applyFilters =>
      L10n.tr('Primeni filtere', 'Apply filters');
  static String get genderTitle => L10n.tr('Pol', 'Gender');
  static String get genderMale => L10n.tr('Mužjak', 'Male');
  static String get genderFemale => L10n.tr('Ženka', 'Female');
  static String get sizeTitle => L10n.tr('Veličina psa', 'Dog size');
  static String get search => L10n.tr('Pretraga', 'Search');
  static String get nearbyTitle =>
      L10n.tr('Psi u tvojoj blizini', 'Dogs near you');
  static String get yourPet => L10n.tr('Tvoj ljubimac', 'Your pet');
  static String get walkingBadge =>
      L10n.tr('🟢 U šetnji', '🟢 On a walk');
  static String get restingBadge => L10n.tr('Odmaram', 'Resting');
  static String get lookingForPlayBadge => L10n.tr(
        'Tražim društvo za igru',
        'Looking for playmates',
      );
  static String get searchHint => L10n.tr(
        'Pretraži po rasi, imenu ili lokaciji...',
        'Search by breed, name, or location...',
      );
  static String get chipAll => L10n.tr('Svi', 'All');
  static String get chipWalking => L10n.tr('U šetnji', 'On a walk');
  static String get chipSmall => L10n.tr('Mali', 'Small');
  static String get chipMedium => L10n.tr('Srednji', 'Medium');
  static String get chipLarge => L10n.tr('Veliki', 'Large');
  static String get filters => L10n.tr('Napredni filteri', 'Advanced filters');
  static String get message => L10n.tr('Poruka', 'Message');
  static String get location => L10n.tr('Lokacija', 'Location');
  static String get chatPlaceholder =>
      L10n.tr('Poruke uskoro stižu.', 'Messages coming soon.');
  static String get chatTitle => L10n.tr('Poruke', 'Messages');
  static String get chatBack => L10n.tr('Nazad', 'Back');
  static String get likedToast => L10n.tr('Lajk poslat', 'Like sent');
  static String get likeFailed => L10n.tr(
        'Lajk nije sačuvan. Proverite konekciju i pokušajte ponovo.',
        'Like was not saved. Check your connection and try again.',
      );
  static String get passedToast => L10n.tr('Preskočeno', 'Passed');
  static String get superLikedToast =>
      L10n.tr('Super lajk poslat!', 'Super Like sent!');
  static String get superLikeDailyLimitTitle =>
      L10n.tr('Dnevni Super Like', 'Daily Super Like');
  static String get superLikeDailyLimitBody => L10n.tr(
        'Iskoristili ste vaš dnevni Super Like! ⭐ Možete poslati sledeći sutra.',
        'You used your daily Super Like! ⭐ You can send the next one tomorrow.',
      );
  static String get superLikeSuccessTitle =>
      L10n.tr('⭐ Super Like poslat!', '⭐ Super Like sent!');
  static String get superLikeSuccessHint => L10n.tr(
        'Imate 1 Super Like na 24h. Sledeći možete poslati sutra.',
        'You get 1 Super Like every 24h. You can send the next one tomorrow.',
      );
  static String get superLikeFailed => L10n.tr(
        'Super Like nije sačuvan. Proverite konekciju i pokušajte ponovo.',
        'Super Like was not saved. Check your connection and try again.',
      );
  static String get messageUnavailable => L10n.tr(
        'Poruka nije dostupna — vlasnik profila nije poznat.',
        'Message unavailable — profile owner is unknown.',
      );
  static String get ownProfileMessage => L10n.tr(
        'Ne možete slati poruku sopstvenom profilu.',
        'You cannot message your own profile.',
      );
  static String get unlikedToast => L10n.tr('Lajk uklonjen', 'Like removed');
  static String get gender => L10n.tr('Pol', 'Gender');
  static String get about => L10n.tr('O psu', 'About');
  static String get getsAlong => L10n.tr('Slaganje sa', 'Gets along with');
  static String get sterilized =>
      L10n.tr('Sterilisan / Kastriran', 'Sterilized / Neutered');
  static String get reportProfile =>
      L10n.tr('Prijavi profil', 'Report profile');
  static String get reportConfirmTitle =>
      L10n.tr('Prijavi profil?', 'Report profile?');
  static String get reportConfirmBody => L10n.tr(
        'Prijava će biti poslata moderatorima na pregled.',
        'The report will be sent to moderators for review.',
      );
  static String get reportConfirmAction => L10n.tr('Prijavi', 'Report');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get details => L10n.tr('Detaljan profil', 'Full profile');
  static String get breed => L10n.tr('Rasa', 'Breed');
  static String get age => L10n.tr('Starost', 'Age');
  static String get size => L10n.tr('Veličina', 'Size');
  static String get energy => L10n.tr('Nivo energije', 'Energy level');
  static String get traits => L10n.tr('Osobine', 'Traits');
  static String get vaccinated => L10n.tr('Vakcinisan', 'Vaccinated');
  static String get chipped => L10n.tr('Čipovan', 'Microchipped');
  static String get owner => L10n.tr('Vlasnik', 'Owner');
  static String get close => L10n.tr('Zatvori', 'Close');
  static String get yes => L10n.tr('Da', 'Yes');
  static String get no => L10n.tr('Ne', 'No');
  static String get weight => L10n.tr('Težina', 'Weight');
  static String get health => L10n.tr('Zdravlje', 'Health');
  static String get energyShort => L10n.tr('Energija', 'Energy');
  static String get stories => L10n.tr('Priče', 'Stories');
  static String weightValue(double kg) =>
      '${kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1)} kg';
  static String get likes => L10n.tr('Voli', 'Likes');
  static String get dislikes => L10n.tr('Ne voli', 'Dislikes');

  static String superLikedDog(String dogName) => L10n.tr(
        '⭐ Dali ste Super Like za $dogName!',
        '⭐ You sent a Super Like to $dogName!',
      );

  static String years(int value) {
    if (L10n.isEnglish) {
      final n = value.abs();
      return n == 1 ? '$n year' : '$n years';
    }
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
