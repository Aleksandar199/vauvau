abstract final class AppStrings {
  static const String appName = 'VauVau';
  static const String tagline =
      'Upoznaj pse u okolini, pronađi društvo za šetnju i skupi lokalni čopor.';
  static const String getStarted = 'Započni';
  static const String illustrationPlaceholder = 'Ilustracija';
  static const String homeTitle = 'Početna';
  static const String homeShellPlaceholder =
      'Početni ekran. Otkrij, mečevi i profil biće ovde.';
  static const String firebaseInitError =
      'Firebase nije pokrenut. Pokrenite flutterfire configure i pokušajte ponovo.';
  static const String logInTitle = 'Prijava';
  static const String signUpTab = 'Registracija';
  static const String registerTitle = 'Napravi nalog';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Lozinka';
  static const String confirmPasswordLabel = 'Potvrdi lozinku';
  static const String nameLabel = 'Ime vlasnika';
  static const String nameHint = 'npr. Ana';
  static const String emailHint = 'npr. ana@email.com';
  static const String passwordHint = 'Najmanje 6 karaktera';
  static const String dogNameHint = 'npr. Luna';
  static const String dogBreedHint = 'npr. Zlatni retriver';
  static const String dogAgeHint = 'npr. 3';
  static const String continueWithGoogle = 'Nastavi putem Google naloga';
  static const String orDivider = 'ili';
  static const String createAccountPrompt = 'Napravi nalog';
  static const String createAccount = 'Napravi nalog';
  static const String alreadyHaveAccount = 'Već imaš nalog? Prijavi se';
  static const String forgotPassword = 'Zaboravljena lozinka?';
  static const String forgotPasswordTitle = 'Zaboravljena lozinka';
  static const String forgotPasswordBody =
      'Unesite email adresu naloga. Poslaćemo vam link za resetovanje lozinke.';
  static const String sendResetLink = 'Pošalji link';
  static const String resetPasswordSent =
      'Link za resetovanje lozinke je poslat na vaš email.';
  static const String resetPasswordSentTitle = 'Link je poslat';
  static const String resetPasswordSentBodyPrefix =
      'Uputstvo za resetovanje lozinke je poslato na adresu:';
  static const String resetPasswordSentBodySuffix =
      'Proverite vaš Inbox i Spam/Junk sanduče.';
  static const String resetPasswordUserNotFound =
      'Korisnik sa ovom e-mail adresom nije registrovan.';
  static const String resetPasswordTooManyRequests =
      'Previše pokušaja slanja. Pokušajte ponovo malo kasnije.';
  static const String resetPasswordFailed =
      'Došlo je do greške pri slanju zahteva.';
  static const String resetPasswordFailedDetail = 'Neuspešno slanje: ';
  static const String errorTitle = 'Greška';
  static const String ok = 'U redu';
  static const String close = 'Zatvori';
  static const String cancel = 'Otkaži';
  static const String signOut = 'Odjavi se';
  static const String emailInvalid = 'Unesite ispravnu email adresu.';
  static const String passwordTooShort = 'Lozinka mora imati najmanje 6 karaktera.';
  static const String passwordsDoNotMatch = 'Lozinke se ne poklapaju.';
  static const String nameRequired = 'Unesite ime.';
  static const String authUnknownError = 'Došlo je do greške. Pokušajte ponovo.';
  static const String authWrongPassword = 'Pogrešni podaci za prijavu';
  static const String authUserNotFound = 'Pogrešni podaci za prijavu';
  static const String authEmailInUse = 'Korisnik već postoji';
  static const String authWeakPassword = 'Slaba lozinka';
  static const String authInvalidEmail = 'Unesite ispravnu email adresu.';
  static const String authNetwork = 'Proverite internet konekciju i pokušajte ponovo.';
  static const String authCancelled = 'Prijava je otkazana.';
  static const String authRequiresRecentLogin =
      'Ponovo se prijavite, zatim obrišite nalog.';
  static const String onboardingTitle = 'Vaš pas';
  static const String next = 'Dalje';
  static const String back = 'Nazad';
  static const String createDogProfile = 'Završi';
  static const String stepBasicsTitle = 'Osnovni podaci';
  static const String stepPersonalityTitle = 'Detalji psa';
  static const String stepAreaTitle = 'Gde šetate';
  static const String stepAreaPrivacy =
      'Čuvamo samo grad i naselje — nikad kućnu adresu ni GPS.';
  static const String stepPhotosTitle = 'Fotografije psa';
  static const String stepPhotosHint =
      'Dodajte fotografije vašeg psa (opciono, do 5). Ovo nisu slike vlasnika.';
  static const String dogNameLabel = 'Ime psa';
  static const String dogBreedLabel = 'Rasa';
  static const String dogGenderLabel = 'Pol';
  static const String dogAgeLabel = 'Starost (godine)';
  static const String dogSizeLabel = 'Veličina';
  static const String dogWeightLabel = 'Težina (kg, opciono)';
  static const String dogEnergyLabel = 'Nivo energije';
  static const String dogTemperamentLabel = 'Temperament';
  static const String cityLabel = 'Grad';
  static const String neighborhoodLabel = 'Naselje';
  static const String neighborhoodRequired = 'Izaberite naselje.';
  static const String ownerPhotoLabel = 'Profilna slika vlasnika';
  static const String addOwnerPhoto = 'Dodaj profilnu sliku';
  static const String ownerBioLabel = 'Kratak opis (opciono)';
  static const String dogVaccinatedLabel = 'Vakcinisan';
  static const String dogChippedLabel = 'Čipovan';
  static const String dogSterilizedLabel = 'Kastriran / Sterilisan';
  static const String addFromGallery = 'Galerija';
  static const String addFromCamera = 'Kamera';
  static const String removePhoto = 'Ukloni fotografiju';
  static const String dogNameRequired = 'Unesite ime psa.';
  static const String dogBreedRequired = 'Unesite rasu.';
  static const String dogGenderRequired = 'Izaberite pol.';
  static const String dogAgeRequired = 'Unesite starost u godinama (0–30).';
  static const String dogSizeRequired = 'Izaberite veličinu.';
  static const String dogEnergyRequired = 'Izaberite nivo energije.';
  static const String dogTemperamentRequired = 'Izaberite bar jednu osobinu.';
  static const String dogAreaRequired = 'Izaberite grad i naselje.';
  static const String dogPhotosRequired = 'Dodajte između 1 i 5 fotografija.';
  static const String photoUploadFailed =
      'Greška prilikom dodavanja slike. Pokušajte ponovo.';
  static const String networkProblem =
      'Problem sa mrežom. Proverite internet konekciju i pokušajte ponovo.';
  static const String dogSaveFailed = 'Profil psa nije sačuvan.';
  static const String mustBeSignedIn = 'Morate biti prijavljeni.';
}
