import '../l10n/l10n.dart';

abstract final class AppStrings {
  static const String appName = 'VauVau';
  static String get tagline => L10n.tr(
        'Upoznaj pse u okolini, pronađi društvo za šetnju i skupi lokalni čopor.',
        'Meet nearby dogs, find walking buddies, and build your local pack.',
      );
  static String get getStarted => L10n.tr('Započni', 'Get started');
  static String get illustrationPlaceholder =>
      L10n.tr('Ilustracija', 'Illustration');
  static String get homeTitle => L10n.tr('Početna', 'Home');
  static String get homeShellPlaceholder => L10n.tr(
        'Početni ekran. Otkrij, mečevi i profil biće ovde.',
        'Home screen. Discover, matches and profile will be here.',
      );
  static String get firebaseInitError => L10n.tr(
        'Firebase nije pokrenut. Pokrenite flutterfire configure i pokušajte ponovo.',
        'Firebase is not running. Run flutterfire configure and try again.',
      );
  static String get logInTitle => L10n.tr('Prijava', 'Sign in');
  static String get signUpTab => L10n.tr('Registracija', 'Sign up');
  static String get registerTitle => L10n.tr('Napravi nalog', 'Create account');
  static String get emailLabel => L10n.tr('Email', 'Email');
  static String get passwordLabel => L10n.tr('Lozinka', 'Password');
  static String get confirmPasswordLabel =>
      L10n.tr('Potvrdi lozinku', 'Confirm password');
  static String get nameLabel => L10n.tr('Ime vlasnika', 'Owner name');
  static String get nameHint => L10n.tr('npr. Ana', 'e.g. Ana');
  static String get emailHint =>
      L10n.tr('npr. ana@email.com', 'e.g. ana@email.com');
  static String get passwordHint =>
      L10n.tr('Najmanje 6 karaktera', 'At least 6 characters');
  static String get dogNameHint => L10n.tr('npr. Luna', 'e.g. Luna');
  static String get dogBreedHint =>
      L10n.tr('npr. Zlatni retriver', 'e.g. Golden Retriever');
  static String get dogAgeHint => L10n.tr('npr. 3', 'e.g. 3');
  static String get continueWithGoogle =>
      L10n.tr('Nastavi putem Google naloga', 'Continue with Google');
  static String get orDivider => L10n.tr('ili', 'or');
  static String get createAccountPrompt =>
      L10n.tr('Napravi nalog', 'Create account');
  static String get createAccount => L10n.tr('Napravi nalog', 'Create account');
  static String get alreadyHaveAccount =>
      L10n.tr('Već imaš nalog? Prijavi se', 'Already have an account? Sign in');
  static String get forgotPassword =>
      L10n.tr('Zaboravljena lozinka?', 'Forgot password?');
  static String get forgotPasswordTitle =>
      L10n.tr('Zaboravljena lozinka', 'Forgot password');
  static String get forgotPasswordBody => L10n.tr(
        'Unesite email adresu naloga. Poslaćemo vam link za resetovanje lozinke.',
        'Enter your account email. We will send you a password reset link.',
      );
  static String get sendResetLink => L10n.tr('Pošalji link', 'Send link');
  static String get resetPasswordSent => L10n.tr(
        'Link za resetovanje lozinke je poslat na vaš email.',
        'A password reset link has been sent to your email.',
      );
  static String get resetPasswordSentTitle =>
      L10n.tr('Link je poslat', 'Link sent');
  static String get resetPasswordSentBodyPrefix => L10n.tr(
        'Uputstvo za resetovanje lozinke je poslato na adresu:',
        'Password reset instructions were sent to:',
      );
  static String get resetPasswordSentBodySuffix => L10n.tr(
        'Proverite vaš Inbox i Spam/Junk sanduče.',
        'Check your Inbox and Spam/Junk folder.',
      );
  static String get resetPasswordUserNotFound => L10n.tr(
        'Korisnik sa ovom e-mail adresom nije registrovan.',
        'No account is registered with this email address.',
      );
  static String get resetPasswordTooManyRequests => L10n.tr(
        'Previše pokušaja slanja. Pokušajte ponovo malo kasnije.',
        'Too many attempts. Please try again later.',
      );
  static String get resetPasswordFailed => L10n.tr(
        'Došlo je do greške pri slanju zahteva.',
        'Something went wrong while sending the request.',
      );
  static String get resetPasswordFailedDetail =>
      L10n.tr('Neuspešno slanje: ', 'Failed to send: ');
  static String get errorTitle => L10n.tr('Greška', 'Error');
  static String get ok => L10n.tr('U redu', 'OK');
  static String get close => L10n.tr('Zatvori', 'Close');
  static String get cancel => L10n.tr('Otkaži', 'Cancel');
  static String get signOut => L10n.tr('Odjavi se', 'Sign out');
  static String get emailInvalid =>
      L10n.tr('Unesite ispravnu email adresu.', 'Enter a valid email address.');
  static String get passwordTooShort => L10n.tr(
        'Lozinka mora imati najmanje 6 karaktera.',
        'Password must be at least 6 characters.',
      );
  static String get passwordsDoNotMatch =>
      L10n.tr('Lozinke se ne poklapaju.', 'Passwords do not match.');
  static String get nameRequired => L10n.tr('Unesite ime.', 'Enter a name.');
  static String get authUnknownError => L10n.tr(
        'Došlo je do greške. Pokušajte ponovo.',
        'Something went wrong. Please try again.',
      );
  static String get authWrongPassword =>
      L10n.tr('Pogrešni podaci za prijavu', 'Incorrect sign-in details');
  static String get authUserNotFound =>
      L10n.tr('Pogrešni podaci za prijavu', 'Incorrect sign-in details');
  static String get authEmailInUse =>
      L10n.tr('Korisnik već postoji', 'Account already exists');
  static String get authWeakPassword =>
      L10n.tr('Slaba lozinka', 'Weak password');
  static String get authInvalidEmail =>
      L10n.tr('Unesite ispravnu email adresu.', 'Enter a valid email address.');
  static String get authNetwork => L10n.tr(
        'Proverite internet konekciju i pokušajte ponovo.',
        'Check your internet connection and try again.',
      );
  static String get authCancelled =>
      L10n.tr('Prijava je otkazana.', 'Sign-in was cancelled.');
  static String get authRequiresRecentLogin => L10n.tr(
        'Ponovo se prijavite, zatim obrišite nalog.',
        'Sign in again, then delete the account.',
      );
  static String get onboardingTitle => L10n.tr('Vaš pas', 'Your dog');
  static String get next => L10n.tr('Dalje', 'Next');
  static String get back => L10n.tr('Nazad', 'Back');
  static String get createDogProfile => L10n.tr('Završi', 'Finish');
  static String get stepBasicsTitle =>
      L10n.tr('Osnovni podaci', 'Basic details');
  static String get stepPersonalityTitle =>
      L10n.tr('Detalji psa', 'Dog details');
  static String get stepAreaTitle => L10n.tr('Gde šetate', 'Where you walk');
  static String get stepAreaPrivacy => L10n.tr(
        'Čuvamo samo grad i naselje — nikad kućnu adresu ni GPS.',
        'We only store city and neighborhood — never your home address or GPS.',
      );
  static String get stepPhotosTitle =>
      L10n.tr('Fotografije psa', 'Dog photos');
  static String get stepPhotosHint => L10n.tr(
        'Dodajte fotografije vašeg psa (opciono, do 5). Ovo nisu slike vlasnika.',
        'Add photos of your dog (optional, up to 5). These are not owner photos.',
      );
  static String get dogNameLabel => L10n.tr('Ime psa', 'Dog name');
  static String get dogBreedLabel => L10n.tr('Rasa', 'Breed');
  static String get customBreedLabel =>
      L10n.tr('Ostalo / Ručni unos', 'Other / Enter manually');
  static String get customBreedHint =>
      L10n.tr('Unesi rasu po želji...', 'Enter breed...');
  static String get customBreedRequired =>
      L10n.tr('Unesite rasu.', 'Enter the breed.');
  static String get dogGenderLabel => L10n.tr('Pol', 'Gender');
  static String get dogAgeLabel => L10n.tr('Starost (godine)', 'Age (years)');
  static String get dogSizeLabel => L10n.tr('Veličina', 'Size');
  static String get dogWeightLabel =>
      L10n.tr('Težina (kg, opciono)', 'Weight (kg, optional)');
  static String get dogEnergyLabel =>
      L10n.tr('Nivo energije', 'Energy level');
  static String get dogTemperamentLabel =>
      L10n.tr('Temperament', 'Temperament');
  static String get dogBioLabel =>
      L10n.tr('Opis psa (opciono)', 'Dog bio (optional)');
  static String get dogBioHint => L10n.tr(
        'Kratko opišite karakter, navike i kako pas voli da se druži...',
        'Briefly describe personality, habits, and how your dog likes to socialize...',
      );
  static String get cityLabel => L10n.tr('Grad', 'City');
  static String get neighborhoodLabel => L10n.tr('Naselje', 'Neighborhood');
  static String get neighborhoodRequired =>
      L10n.tr('Izaberite naselje.', 'Select a neighborhood.');
  static String get customNeighborhoodHint =>
      L10n.tr('Unesi naselje po želji...', 'Enter your neighborhood...');
  static String get customNeighborhoodRequired =>
      L10n.tr('Unesite naselje.', 'Enter a neighborhood.');
  static String get ownerPhotoLabel =>
      L10n.tr('Profilna slika vlasnika', 'Owner profile photo');
  static String get addOwnerPhoto =>
      L10n.tr('Dodaj profilnu sliku', 'Add profile photo');
  static String get ownerBioLabel =>
      L10n.tr('Kratak opis (opciono)', 'Short bio (optional)');
  static String get dogVaccinatedLabel => L10n.tr('Vakcinisan', 'Vaccinated');
  static String get dogChippedLabel => L10n.tr('Čipovan', 'Microchipped');
  static String get dogSterilizedLabel =>
      L10n.tr('Kastriran / Sterilisan', 'Neutered / Spayed');
  static String get addFromGallery => L10n.tr('Galerija', 'Gallery');
  static String get addFromCamera => L10n.tr('Kamera', 'Camera');
  static String get removePhoto => L10n.tr('Ukloni fotografiju', 'Remove photo');
  static String get dogNameRequired =>
      L10n.tr('Unesite ime psa.', 'Enter the dog name.');
  static String get dogBreedRequired =>
      L10n.tr('Unesite rasu.', 'Enter the breed.');
  static String get dogGenderRequired =>
      L10n.tr('Izaberite pol.', 'Select a gender.');
  static String get dogAgeRequired => L10n.tr(
        'Unesite starost u godinama (0–30).',
        'Enter age in years (0–30).',
      );
  static String get dogSizeRequired =>
      L10n.tr('Izaberite veličinu.', 'Select a size.');
  static String get dogEnergyRequired =>
      L10n.tr('Izaberite nivo energije.', 'Select an energy level.');
  static String get dogTemperamentRequired =>
      L10n.tr('Izaberite bar jednu osobinu.', 'Select at least one trait.');
  static String get dogAreaRequired =>
      L10n.tr('Izaberite grad i naselje.', 'Select a city and neighborhood.');
  static String get dogPhotosRequired => L10n.tr(
        'Dodajte između 1 i 5 fotografija.',
        'Add between 1 and 5 photos.',
      );
  static const int maxDogPhotos = 5;
  static String photoCountLabel(int count) => L10n.tr(
        '$count / $maxDogPhotos fotografija',
        '$count / $maxDogPhotos photos',
      );
  static String get photoLimitReached => L10n.tr(
        'Možete dodati najviše 5 fotografija.',
        'You can add up to 5 photos.',
      );
  static String get photoUploadFailed => L10n.tr(
        'Greška prilikom dodavanja slike. Pokušajte ponovo.',
        'Could not upload the photo. Please try again.',
      );
  static String get networkProblem => L10n.tr(
        'Problem sa mrežom. Proverite internet konekciju i pokušajte ponovo.',
        'Network problem. Check your internet connection and try again.',
      );
  static String get dogSaveFailed =>
      L10n.tr('Profil psa nije sačuvan.', 'Dog profile was not saved.');
  static String get dogSavedTitle => L10n.tr('Sačuvano', 'Saved');
  static String get dogSavedBody => L10n.tr(
        'Profil psa je uspešno sačuvan.',
        'Dog profile was saved successfully.',
      );
  static String get mustBeSignedIn =>
      L10n.tr('Morate biti prijavljeni.', 'You must be signed in.');
}
