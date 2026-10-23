# VauVau za iOS – vodič korak po korak (bez Mac-a)

> Napravljeno 2026-10-21. Cene i rokovi su sa zvaničnih sajtova u tom trenutku –
> pre plaćanja proveri na linku.
>
> **Ko radi:** 🧑 = ti ručno (web, nalog, plaćanje) · 🤖 = već urađeno u repou / radi CI · 💬 = javi Claude-u (pošalji fajl ili log)
>
> **Status:** ✅ urađeno · ⬜ nije urađeno

## Pregled

| # | Korak | Ko | Status |
|---|---|---|---|
| 0 | iOS projekat u repou (bundle id, dozvole, push, target, ikonice, Codemagic) | 🤖 | ✅ |
| 1 | Apple Developer Program (99 USD/god.) | 🧑 | ✅ |
| 2 | App ID `com.vauvau.app` + Push + APNs ključ | 🧑 | ✅ |
| 3 | Aplikacija u App Store Connect-u + API ključ | 🧑 | ✅ |
| 4 | Firebase: iOS aplikacija `com.vauvau.app`, novi `GoogleService-Info.plist`, APNs ključ | 🧑 + 💬 | ✅ |
| 5 | Codemagic: nalog, API ključ, sertifikat, profil | 🧑 | ✅ |
| 6 | Prvi build → TestFlight (interni testeri) | 🧑 pokreće, 🤖 builduje | ✅ |
| 7 | Testiranje na pozajmljenom iPhone-u | 🧑 | ⬜ |
| 8 | Eksterni testeri (Beta App Review) | 🧑 | ⬜ |
| 9 | App Store: opis, slike, privatnost, demo nalog, slanje na pregled | 🧑 | ⬜ |
| 10 | App Store ID u kodu (✅ 2026-10-23); posle objave ručno `app_config/ios` | 🧑 | ⬜ |

> **Stanje 2026-10-23:** koraci 1–6 urađeni (build 13 na TestFlight-u, App Store Connect ID `6826107299`). Build 13 je pravljen PRE usklađivanja `lib/firebase_options.dart` sa novom Firebase iOS aplikacijom – radi sa starom (`com.example.vauvau`), pa push i Crashlytics na njemu ne idu u novu aplikaciju. Za testiranje push-a koristiti build 14 ili noviji. Codemagic build se pokreće RUČNO (Start new build, grana `main`) – push na GitHub ga ne pokreće sam.

**Mac nije potreban ni u jednom koraku.** Build radi Codemagic na svom Mac-u u oblaku,
sve ostalo je u web pregledaču. iPhone je potreban samo za probu (korak 7) i za
snimke ekrana (korak 9) – može pozajmljen.

---

## Zašto Codemagic (poređenje)

| | Codemagic (preporuka) | GitHub Actions (macOS) | MacinCloud (iznajmljen Mac) |
|---|---|---|---|
| Cena | 500 besplatnih macOS minuta mesečno (lični nalog); jedan build ≈ 15–25 min → ~20 buildova besplatno; posle toga plaćanje po minutu | Privatni repo: besplatnih 2.000 min, ali macOS minut se broji ×10 → ~200 min ≈ 8–10 buildova; preko toga po minutu | Plaća se po satu ili mesečno (oko 1 USD/h ili ~25–50 USD/mes, zavisno od paketa) |
| Potpisivanje bez Mac-a | Da – sertifikat i profil pravi iz web interfejsa preko App Store Connect API ključa | Teže – treba `.p12` sertifikat (pravi se `openssl`-om) + profil kao tajne, ili fastlane match | Da, ali ručno u Xcode-u preko udaljene radne površine |
| Upload na TestFlight | Ugrađeno (`publishing: app_store_connect`) | Treba dodatni korak (fastlane/altool) | Ručno iz Xcode-a / Transporter-a |
| Složenost za tebe | Najmanja: klikovi u web-u + `codemagic.yaml` koji je već u repou | Srednja/velika | Velika (Xcode, remote desktop) |

**Izbor: Codemagic.** Konfiguracija je u [`codemagic.yaml`](../codemagic.yaml).
MacinCloud vredi samo ako jednom zatreba pravi Xcode/simulator (npr. snimci ekrana bez iPhone-a).

Linkovi: [Codemagic cene](https://codemagic.io/pricing/) ·
[GitHub Actions cene](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions) ·
[MacinCloud](https://www.macincloud.com/pricing.htm)

---

## Korak 0 – šta je već urađeno u repou 🤖 ✅

- Bundle id `com.vauvau.app` (isti kao Android) za Debug/Release/Profile; testovi `com.vauvau.app.RunnerTests` – `ios/Runner.xcodeproj/project.pbxproj`.
- Minimalni iOS **15.0** (Firebase paketi traže 15; ostali pluginovi 11–13). Aplikacija je **samo za iPhone** (`TARGETED_DEVICE_FAMILY = 1`) – App Store tada ne traži iPad snimke ekrana; na iPad-u i dalje radi u iPhone prikazu.
- `ios/Runner/Info.plist`: ime „VauVau“, objašnjenja dozvola na srpskom (kamera, galerija, mikrofon za video, lokacija dok se koristi i za šetnju sa zaključanim ekranom), `UIBackgroundModes` (location, remote-notification, fetch), šeme za `url_launcher` (tel, sms, mailto, whatsapp, viber, maps, comgooglemaps, itms-apps), Google URL šema (iz trenutnog plist-a – menja se u koraku 4), `ITSAppUsesNonExemptEncryption = false` (TestFlight ne pita za izvoz šifrovanja).
- `ios/Runner/Runner.entitlements` (push `aps-environment`) povezan u projekat; `GoogleService-Info.plist` dodat u Xcode projekat (ranije je bio samo u folderu, pa ga build nije pakovao).
- `AppDelegate.swift`: lokalne notifikacije se prikazuju i dok je aplikacija otvorena.
- Ikonice (VauVau logo, bez alfa kanala – App Store to traži) i splash već postoje (`flutter_launcher_icons`, `flutter_native_splash`, `ios: true` u `pubspec.yaml`).
- Poruka „Ažuriraj“: na iOS-u **nikad ne otvara Google Play**. Čita `app_config/ios` (ne `android`) i prikazuje se tek kad se u kod upiše App Store ID (korak 10).
- `codemagic.yaml`: build IPA, potpisivanje, upload na TestFlight; proverava da je Firebase plist za `com.vauvau.app`.

**Ne može da se proveri sa Windows-a:** da li se iOS build zaista kompajlira. Prvi
Codemagic build (korak 6) je prva prava provera – ako padne, pošalji log Claude-u 💬.

---

## Korak 1 – Apple Developer Program 🧑

1. Napravi ili koristi postojeći **Apple Account** (Apple ID) i uključi **dvofaktorsku zaštitu** (obavezna). Na Windows-u: [account.apple.com](https://account.apple.com).
2. Idi na [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/) → **Start your enrollment**.
3. Izaberi tip:
   - **Fizičko lice (Individual)** – najbrže. U App Store-u kao prodavac piše tvoje ime i prezime. Treba lična karta/pasoš za proveru identiteta.
   - **Firma (Organization)** – u prodavnici piše ime firme. Treba **D-U-N-S broj** (besplatan, [provera/zahtev](https://developer.apple.com/enroll/duns-lookup/)); dobijanje može trajati od nekoliko dana do par nedelja, a zatim Apple proverava firmu (telefonski poziv ovlašćenom licu).
4. Plati **99 USD godišnje** (kartica). Bez plaćanja nema TestFlight-a ni App Store-a.
5. Odobrenje: za fizičko lice obično do 48 h, za firmu duže. Stiže email „Welcome to the Apple Developer Program“.

Dokumentacija: [Enrollment](https://developer.apple.com/help/account/membership/program-enrollment/) ·
[Šta treba za firmu](https://developer.apple.com/support/enrollment/)

> Kad dobiješ pristup, zapiši **Team ID** (developer.apple.com → Account → Membership details; 10 znakova). Nije tajna, treba u koraku 4.

---

## Korak 2 – App ID, Push i APNs ključ 🧑

Sve na [developer.apple.com/account](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles**.

1. **Identifiers → +** → *App IDs* → *App* → Continue.
   - Description: `VauVau`
   - Bundle ID: **Explicit** → `com.vauvau.app` (mora tačno ovako – tako je u projektu).
   - Capabilities: uključi **Push Notifications**. (Sign in with Apple NE treba dok je Google prijava sakrivena – vidi „App Review“.)
   - Continue → Register.
2. **Keys → +** → ime `VauVau APNs` → uključi **Apple Push Notifications service (APNs)** → Continue → Register → **Download**.
   - Fajl `AuthKey_XXXXXXXXXX.p8` može da se preuzme **samo jednom**. Sačuvaj ga van repoa (npr. u menadžer lozinki). Zapiši **Key ID**.
   - Nikad ga ne stavljaj u `vauvau` folder i ne šalji u čet.

Dokumentacija: [Registrovanje App ID-a](https://developer.apple.com/help/account/identifiers/register-an-app-id/) ·
[APNs ključ](https://developer.apple.com/help/account/keys/create-a-private-key/)

---

## Korak 3 – App Store Connect: aplikacija i API ključ 🧑

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps → + → New App**:
   - Platform: iOS · Name: `VauVau` (ako je zauzeto, npr. `VauVau – psi i šetnje`) · Primary language: **Serbian** (ili English) · Bundle ID: `com.vauvau.app` · SKU: `vauvau-ios` · User Access: Full Access.
2. Otvori aplikaciju → **App Information** → zapiši **Apple ID** (samo cifre, npr. `6712345678`). Nije tajna – upiši ga u `codemagic.yaml` (`APP_STORE_APPLE_ID`) ili ga pošalji Claude-u 💬 da upiše.
3. **API ključ za Codemagic:** Users and Access → **Integrations** → App Store Connect API → **Team Keys** → **+**:
   - Name: `Codemagic` · Access: **App Manager** (ako Codemagic kasnije javi da ne može da napravi sertifikat, napravi novi ključ sa **Admin**).
   - **Download API Key** (`AuthKey_YYYYYYYYYY.p8`) – opet **samo jednom**. Zapiši **Key ID** i **Issuer ID** (piše iznad tabele ključeva).
   - Ovo je TAJNA: ide samo u Codemagic (korak 5), nikad u repo.

Dokumentacija: [Nova aplikacija](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app) ·
[API ključevi](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)

---

## Korak 4 – Firebase za iOS 🧑 + 💬

U Firebase-u već postoji iOS aplikacija, ali sa šablonskim bundle id-jem `com.example.vauvau` (on se ne može promeniti). Treba nova za `com.vauvau.app`. **Ovo ne dira produkcione podatke ni pravila** – samo dodaje aplikaciju u projekat.

1. [console.firebase.google.com](https://console.firebase.google.com) → projekat **vauvau-3195a** → ⚙️ **Project settings** → *Your apps* → **Add app** → **iOS**.
   - Apple bundle ID: `com.vauvau.app` · App nickname: `VauVau iOS` · App Store ID: prazno (može kasnije).
   - **Download GoogleService-Info.plist**. Ostale korake čarobnjaka (SDK, kod) preskoči – to je već u projektu.
2. Sačuvaj preuzeti fajl preko postojećeg: `vauvau\ios\Runner\GoogleService-Info.plist` (zameni). 💬 Javi Claude-u „zamenio sam plist“ – on ažurira `lib/firebase_options.dart` (iOS `appId`, `iosBundleId`) i Google URL šemu u `Info.plist`, pa komituje. (Ovaj plist nije tajna u smislu ključa za potpisivanje – Firebase ga tretira kao javnu konfiguraciju, isto kao Android `google-services.json`; zaštitu rade Firestore/Storage pravila.)
3. **APNs ključ u Firebase:** Project settings → **Cloud Messaging** → *Apple app configuration* → izaberi `VauVau iOS` → **APNs Authentication Key → Upload** → `.p8` iz koraka 2, Key ID i **Team ID** (korak 1).
4. Staru iOS aplikaciju `com.example.vauvau` možeš ostaviti (ne smeta) ili obrisati kasnije.

> Napomena: push dok je aplikacija zatvorena i dalje ne stiže ni na Androidu (nema Cloud Functions – poznati bag 1 u CLAUDE.md). APNs se podešava sada da bi radio kad se to doda; lokalne notifikacije (podsetnici, poruke dok je app u pozadini) ne zavise od APNs-a.

Dokumentacija: [Firebase iOS setup](https://firebase.google.com/docs/ios/setup) ·
[FCM na Apple platformama](https://firebase.google.com/docs/cloud-messaging/ios/certs)

---

## Korak 5 – Codemagic 🧑

1. [codemagic.io/signup](https://codemagic.io/signup) → **Sign up with GitHub** → dozvoli pristup repou `Aleksandar199/vauvau`.
2. **Add application** → GitHub → `vauvau` → tip **Flutter App** → izaberi da se koristi **codemagic.yaml** (fajl je već u repou na `master`).
3. **API ključ (tajna):** Team settings (za lični nalog: *Personal Account* → Settings) → **Integrations → Developer Portal → Connect**:
   - **App Store Connect API key name: `VauVau ASC`** (mora tačno ovako – tako piše u `codemagic.yaml`)
   - Issuer ID, Key ID, i upload `.p8` iz koraka 3.
4. **Sertifikat:** Team settings → **codemagic.yaml settings → Code signing identities → iOS certificates → Generate certificate** → tip *Apple Distribution* → integracija `VauVau ASC` → ime npr. `vauvau_dist`. Codemagic napravi sertifikat kod Apple-a – Mac nije potreban. Ako ponudi preuzimanje `.p12` + lozinke, sačuvaj ih van repoa.
5. **Profil:** na [developer.apple.com → Profiles → +](https://developer.apple.com/account/resources/profiles/add) → **App Store Connect** (Distribution) → App ID `com.vauvau.app` → izaberi sertifikat iz tačke 4 → ime `VauVau App Store` → Generate. Zatim u Codemagic-u: **iOS provisioning profiles → Fetch profiles** → označi `VauVau App Store` → Save.
   - Ako kasnije menjaš capability na App ID-u (npr. dodaš Sign in with Apple), profil postaje nevažeći – napravi ga ponovo i ponovo *Fetch*.
6. (Opciono) u `codemagic.yaml` upiši `APP_STORE_APPLE_ID` iz koraka 3 – tada Codemagic sam podiže broj builda ako je isti broj već poslat na TestFlight.

Dokumentacija: [Codemagic Flutter iOS](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/) ·
[Potpisivanje iOS](https://docs.codemagic.io/yaml-code-signing/signing-ios/) ·
[Objava na App Store Connect](https://docs.codemagic.io/yaml-publishing/app-store-connect/)

---

## Korak 6 – prvi build i TestFlight 🧑 + 🤖

1. Codemagic → aplikacija `vauvau` → **Start new build** → branch `master` → workflow **iOS → TestFlight** → Start.
2. Build traje ~15–25 min. Koraci: provera Firebase plist-a → `flutter pub get` → `flutter analyze` → potpisivanje → `flutter build ipa` → upload na App Store Connect.
   - Ako padne na „GoogleService-Info.plist nije za com.vauvau.app“ → nije urađen korak 4.2.
   - Ako padne bilo gde drugde → 💬 pošalji Claude-u ceo log tog koraka (dugme *Download log*).
3. Posle uploada Apple obrađuje build 10–60 min; stiže email. U App Store Connect → aplikacija → **TestFlight** pojavljuje se build (npr. `1.0.0 (13)`).
4. **Interni testeri** (bez pregleda kod Apple-a, do 100 osoba koje su članovi tvog App Store Connect tima): TestFlight → *Internal Testing* → **+** grupa `Tim` → dodaj sebe/osobe (Users and Access → pozovi ih prvo kao korisnike sa ulogom npr. *Developer* ili *Marketing*). Uključi *Automatic distribution*.

Broj builda: isti `+N` iz `pubspec.yaml` kao za Android (poruka „Ažuriraj“ ga čita). Za svaki novi TestFlight build mora biti veći broj – podigni `version:` u `pubspec.yaml` (ili postavi `APP_STORE_APPLE_ID` pa Codemagic podiže sam).

Dokumentacija: [TestFlight pregled](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview) ·
[Interni testeri](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers)

---

## Korak 7 – testiranje bez svog iPhone-a 🧑

- **Pozajmljen iPhone (preporuka):** vlasnik instalira aplikaciju **TestFlight** iz App Store-a. Ti ga dodaš kao internog testera (njegov Apple ID email) ili eksternog (korak 8, može i javni link). Instalacija ne briše ništa sa njegovog telefona; build važi 90 dana.
- **Simulator** postoji samo na Mac-u – jedina opcija bez Mac-a je iznajmljen Mac (MacinCloud) na sat-dva. Za normalno testiranje nije potreban.
- Šta proveriti na iPhone-u (istim redom kao na Androidu):
  1. registracija sa slikom (kamera + galerija – pojavljuju se srpska objašnjenja dozvola), prijava, odjava;
  2. Otkrij → lajk → meč → čet (tekst, slika, lokacija, poziv u šetnju), zvuk poruke;
  3. priče i objave sa videom (kamera traži i mikrofon), plejer;
  4. mapa i **šetnja**: pokreni, zaključaj ekran 2–3 min, otključaj – ruta mora da raste; gore levo se vidi plava oznaka lokacije;
  5. notifikacije: dozvola, podsetnik iz zdravstvenog kartona, obaveštenje o poruci dok je app u pozadini;
  6. linkovi: poziv (SOS), SMS, email, WhatsApp/Viber deljenje profila, navigacija (Google/Apple Maps);
  7. **Obriši nalog** (Profil → podešavanja) – Apple ovo obavezno proverava.
- Greške vidiš i u Firebase Crashlytics (Android i iOS zajedno).

---

## Korak 8 – eksterni testeri i Beta App Review 🧑

1. TestFlight → **External Testing → +** grupa (npr. `Prijatelji VauVau`) → dodaj build.
2. Popuni **Test Information**: opis šta testirati, email za povratne informacije, **demo nalog** (vidi korak 9.4), napomene.
3. Prvi build ide na **Beta App Review** (obično do 24–48 h). Sledeći buildovi iste verzije uglavnom prolaze odmah.
4. Pozovi testere emailom ili uključi **Public Link** (do 10.000 testera).

Dokumentacija: [Eksterni testeri](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers)

---

## Korak 9 – App Store i App Review 🧑

### 9.1 Stranica aplikacije
App Store Connect → aplikacija → verzija **1.0**:
- Opis, ključne reči, kategorija (*Social Networking* ili *Lifestyle*), URL podrške, **Privacy Policy URL: `https://vauvau-3195a.web.app/privacy`** (već postoji), Terms: `https://vauvau-3195a.web.app/terms`.
- **Snimci ekrana:** potrebni samo za iPhone 6,9" (1320×2868 ili 1290×2796 px). Napravi ih na pozajmljenom iPhone 15/16 Pro Max ili Plus; sa manjeg iPhone-a se mogu uvećati, ali slika mora da prikazuje stvarnu aplikaciju. [Specifikacija](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)
- **Age Rating** upitnik: aplikacija ima korisnički sadržaj i čet → odgovori iskreno (verovatno 12+ ili 13+ po novim kategorijama).

### 9.2 App Privacy upitnik (obavezan)
App Store Connect → **App Privacy**. Predlog odgovora (proveri pre slanja):

| Podatak | Prikuplja se | Vezan za korisnika | Svrha | Praćenje (tracking) |
|---|---|---|---|---|
| Ime, email | da | da | App Functionality | ne |
| Fotografije i video | da | da | App Functionality | ne |
| Precizna lokacija (ruta šetnje, samo vlasnik vidi) | da | da | App Functionality | ne |
| Približna lokacija (grad, ~200 m za druge) | da | da | App Functionality | ne |
| Poruke i drugi korisnički sadržaj | da | da | App Functionality | ne |
| User ID | da | da | App Functionality | ne |
| Podaci o padu aplikacije (Crashlytics) | da | ne | App Functionality / Analytics | ne |

Aplikacija nema reklame i ne prati korisnike van aplikacije → **App Tracking Transparency nije potreban**.
[Dokumentacija](https://developer.apple.com/app-store/app-privacy-details/)

### 9.3 Šta App Review proverava kod VauVau
| Zahtev | Smernica | Stanje |
|---|---|---|
| Politika privatnosti (link u App Store Connect-u i u aplikaciji) | 5.1.1 | ✅ postoji na Hosting-u |
| Brisanje naloga u samoj aplikaciji | 5.1.1(v) | ✅ postoji (Profil → podešavanja → Obriši nalog) |
| **Sign in with Apple** | 4.8 | ✅ nije potreban dok je prijava samo email + lozinka. Ako se uključi Google prijava, MORA se dodati i Apple prijava (💬 posao za Claude-a + capability u koraku 2 + novi profil) |
| Korisnički sadržaj: prijava, blokiranje, moderacija, kontakt | 1.2 | ✅ postoje prijave, blokiranje i admin moderacija. ⬜ Proveri da korisnik pri registraciji prihvata uslove korišćenja (nulta tolerancija za uvredljiv sadržaj) – ako ne, 💬 dodati potvrdu |
| Lokacija u pozadini mora imati jasnu svrhu | 2.5.4, 5.1.1 | ✅ traži se samo „dok se koristi“; ruta se meri u pozadini samo dok je šetnja pokrenuta (plava oznaka). Objasni u *Review Notes* (tekst ispod) |
| Demo nalog | 2.1 | ⬜ napravi ga (9.4) |
| Šifrovanje / izvoz | – | ✅ `ITSAppUsesNonExemptEncryption = false` (samo HTTPS) |
| Aplikacija ne sme da upućuje na Google Play | 2.3.10 | ✅ poruka „Ažuriraj“ na iOS-u ne otvara Play. ⬜ Tekst „Pozovi prijatelje“/„Podeli profil“ za sada sadrži Play link – posle objave na App Store-u 💬 dodati i App Store link |

[App Review smernice](https://developer.apple.com/app-store/review/guidelines/)

### 9.4 Demo nalog za recenzente
- Napravi u aplikaciji (na Androidu ili iPhone-u) nalog npr. `review.vauvau@…` sa jednim psom, slikom i par poruka sa drugim test nalogom. To je novi nalog u produkciji – pravi ga ti, ručno.
- Upiši email i lozinku u **App Review Information → Sign-in required**. Ne koristi svoj lični ni admin nalog.

### 9.5 Predlog teksta za *Review Notes* (engleski)
```
VauVau is a social app for dog owners in Serbia (Novi Sad, Belgrade, Niš,
Kragujevac, Zrenjanin, Subotica). Content is in Serbian; the map works anywhere.

Demo account: <email> / <password> (has a dog profile and a chat).

Location: the app asks only for "While Using" permission. Background location is
used ONLY while the user has started a dog walk (Map → Start walk), to measure
the walk route with the screen locked; the blue location indicator is shown and
tracking stops when the walk ends. The route is visible only to the user; others
see an approximate area (~200 m).

Account deletion: Profile → Settings → Delete account.
User-generated content can be reported and users can be blocked from any
profile, post or message; reports are reviewed by our moderators.
```

### 9.6 Slanje
Verzija 1.0 → **Build** → izaberi TestFlight build → **Add for Review** → **Submit**. Pregled obično traje 1–3 dana. Ako odbiju, poruka stiže u App Store Connect → *Resolution Center* → 💬 pošalji tekst Claude-u.

---

## Korak 10 – posle objave 💬

1. Pošalji Claude-u Apple ID aplikacije (korak 3.2) → upisuje ga u `kAppStoreId` (`lib/features/app_update/domain/app_update.dart`). Od sledećeg izdanja poruka „Ažuriraj“ na iOS-u otvara App Store.
2. U Firestore Console ručno napravi dokument `app_config/ios` sa poljima `minBuild` (broj, npr. 0) i `latestBuild` (broj poslednjeg iOS builda). Pravila to već dozvoljavaju (admin piše). Admin kartica „Verzija aplikacije“ u aplikaciji za sada menja samo `app_config/android`.
3. Podesi godišnju obnovu Apple Developer članarine (bez nje aplikacija nestaje iz prodavnice).

---

## Kontrolna lista pre slanja na App Review

- [ ] Apple Developer Program aktivan (korak 1)
- [ ] App ID `com.vauvau.app` sa Push Notifications (korak 2)
- [ ] Firebase iOS app `com.vauvau.app`, novi plist u repou, APNs ključ u Firebase-u (korak 4)
- [ ] Codemagic build zelen, build vidljiv u TestFlight-u (korak 6)
- [ ] Proba na iPhone-u prošla (korak 7), posebno šetnja sa zaključanim ekranom i brisanje naloga
- [ ] Snimci ekrana 6,9", opis, kategorija, URL podrške, Privacy Policy URL (9.1)
- [ ] App Privacy upitnik (9.2) i Age Rating
- [ ] Prihvatanje uslova korišćenja pri registraciji provereno (9.3)
- [ ] Demo nalog + Review Notes (9.4, 9.5)
- [ ] Nijedna tajna u repou: `.p8` ključevi, `.p12`, lozinke su samo u Codemagic-u / tvom menadžeru lozinki

## Poznata ograničenja na iOS-u (stanje 2026-10-21)

- iOS build nije proveren lokalno (nema Mac-a) – prva provera je Codemagic.
- Push sa zatvorenom aplikacijom ne stiže (isto kao Android – nema Cloud Functions).
- Crashlytics na iOS-u beleži padove, ali bez automatskog slanja dSYM fajlova stack trace može biti nečitljiv; kasnije dodati upload dSYM-a u Codemagic.
- SMS iz „Izgubljeni psi“/„Podeli“ koristi `sms:?body=` – na iPhone-u proveriti da li se tekst popunjava.
- Admin kartica „Verzija aplikacije“ menja samo `app_config/android`.
