# Firebase App Check (Play Integrity / App Attest)

Cilj: Firestore, Storage i ostali servisi primaju zahteve samo od **originalne
VauVau aplikacije** instalirane iz prodavnice na uređaju koji prolazi proveru
integriteta. Blokira skripte sa ukradenim tokenom, prepakovane APK-ove i
emulatore (koji su zaobilazili proveru lažnog GPS-a).

Ne hvata: lažnu lokaciju na pravom telefonu (to radi `isMocked` + server).

## Šta je urađeno u kodu
- paket `firebase_app_check` (`pubspec.yaml`), `lib/core/firebase/app_check_setup.dart`,
  poziv `activateAppCheck()` u `lib/main.dart` odmah posle `Firebase.initializeApp`.
- release Android = Play Integrity, release iOS = App Attest (uz DeviceCheck rezervu),
  debug (`flutter run`) = debug provajder, release web / desktop = isključeno.
- Aktivacija nikad ne ruši pokretanje aplikacije.
- **Dok se u konzoli ne uključi „Enforce“, ništa se ne blokira** – samo se mere
  zahtevi (Firebase Console → App Check → APIs → „Verified / Unverified“).

## Podešavanje u konzoli (radi vlasnik projekta)
1. **Google Cloud** (projekat `vauvau-3195a`): uključiti *Play Integrity API*.
2. **Play Console** → aplikacija → App integrity: povezati Google Cloud projekat
   `vauvau-3195a`.
3. **Firebase Console → App Check → Apps → Android (com.vauvau.app)**: provajder
   *Play Integrity*; dodati SHA-256 otiske ključeva (Play app signing ključ iz Play
   Console → App integrity, i upload ključ). TTL tokena: podrazumevano.
4. **iOS** (kad bude izdat): provajder *App Attest*; u Xcode/Codemagic uključiti
   capability *App Attest* (entitlement `com.apple.developer.devicecheck.appattest-environment`);
   za DeviceCheck rezervu otpremiti DeviceCheck ključ (.p8) u App Check.
5. **Debug tokeni** (za testiranje sa računara): prvi put kad pokreneš
   `flutter run` (telefon ili `-d chrome`), u konzoli/logu piše
   „Debug App Check token: …“ – dodati ga u App Check → Apps → ⋮ → *Manage debug tokens*.

## Redosled uključivanja (bitno)
1. Izdati verziju aplikacije sa App Check-om (ova izmena) i sačekati da je većina
   korisnika ažurira (Admin → Početna → „Verzija aplikacije“, `minBuild` može da
   natera ažuriranje).
2. U App Check → APIs pratiti *Verified* zahteve; kad je ~sve verifikovano:
3. **Enforce** za *Cloud Firestore*, pa za *Cloud Storage*. Stari klijenti bez
   App Check-a tada prestaju da rade – zato tek posle koraka 1.
4. Cloud Functions koje se okidaju iz Firestore-a (rewardWalk, push) nisu pogođene.

## Kvota
Play Integrity: podrazumevano 10 000 provera dnevno po projektu (token se obnavlja
retko, nije jedna provera po zahtevu); ako treba više, traži se povećanje u Google Cloud-u.

## Preostali koraci za vlasnika (3, 5, 6)
- **SHA-256 Play app signing ključa:** Play Console → Test and release → App integrity
  (ili Setup → App signing) → *App signing key certificate* → kopiraj SHA-256 i pošalji
  ga; dodaje se komandom `firebase apps:android:sha:create <appId> <sha256>`
  (appId aplikacije `com.vauvau.app` je `1:461477755452:android:13d12fdcbb5f9d68912139`).
  Bez njega Play Integrity tokeni sa korisničkih telefona ne prolaze proveru.
- **Debug token:** `flutter run` na telefonu → u logu traži „Debug App Check token“ →
  Firebase Console → App Check → Apps → VauVau → ⋮ → *Manage debug tokens* → Add.
- **Enforce:** tek kad App Check → APIs pokazuje *Verified* za zahteve iz release
  build-a sa Internal testinga. Prvo Firestore, pa Storage. Ako nešto ne radi,
  isključi Enforce (odmah važi).
