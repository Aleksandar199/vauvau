# CLAUDE.md – projektna memorija VauVau

> **Pravila rada:**
> 1. Na početku svakog zadatka PRVO pročitaj ovaj fajl, pa otvaraj samo fajlove potrebne za zadatak.
> 2. Posle svake završene izmene ažuriraj ovaj fajl: „Dnevnik izmena“, pomeri stavke između U toku / Završeno / TODO, ispravi Strukturu/Bazu ako su se promenile.
> 3. Drži fajl kratkim. Kad dnevnik postane dugačak, starije unose sažmi u nekoliko redova.
> 4. Detalji (puna šema polja, ekrani, modeli, konfiguracija platformi) su u `docs/TEHNICKI_PREGLED.md` – otvaraj ciljanu sekciju (grep po `^##`), ne ceo fajl (9000+ linija).

---

# Projekat
- **VauVau** (paket `vauvau`, verzija `1.0.0+7`) – društvena mreža za vlasnike pasa u Srbiji (Novi Sad, Beograd, Niš, Kragujevac): discover/swipe/meč, 1:1 čet sa pozivom na šetnju, grupe i događaji, mapa mesta za pse + praćenje šetnje, priče (24h), izgubljeni psi, udomljavanje, zdravstveni karton/podsetnici, SOS/saveti, prijave/blokiranje, admin panel.
- **UI jezik:** srpski (latinica) podrazumevano, delimično engleski (sopstveni `L10n`).
- **Platforme:** Android primarna (`com.vauvau.app`, release potpisivanje, R8). iOS nije spreman (`com.example.vauvau`, nema push/entitlements). Web radi uz ograničenja (Android Firebase opcije, push isključen). Desktop = neizmenjen šablon.
- **Tehnologije:** Flutter 3.44.1 / Dart 3.12.1, flutter_riverpod 3.4.3 (bez code-gen-a), Firebase (`vauvau-3195a`): Auth, Firestore, Storage, FCM, Crashlytics, Hosting. flutter_map + OSM, geolocator, flutter_local_notifications + timezone, image_picker, cached_network_image, shared_preferences, audioplayers, http (Nominatim). Dev: flutter_lints, fake_cloud_firestore, flutter_native_splash, flutter_launcher_icons.
- Android: AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, Java 17. iOS: target 13.0, SPM (bez Podfile-a).

# Struktura
- `lib/main.dart` – init (Crashlytics handleri, lokalne notifikacije, Firebase, Firestore offline keš, FCM bg handler) → `ProviderScope(VauVauApp)`; greška → `FirebaseInitErrorApp`.
- `lib/app/` – `app.dart` (MaterialApp, tema, locale, `navigatorKey`), `routes.dart` (neiskorišćen), `firebase_init_error_app.dart`.
- `lib/core/` – zajedničko: `constants/` (stringovi, rase, `serbia_locations.dart` gradovi/kvartovi), `crash/`, `firebase/` (`firebase_status.dart` → `isFirebaseReady`, `firestore_auth_guard.dart`), `geo/`, `images/` (`image_upload_service.dart`, web prikaz slika, fallback slike), `l10n/` (`L10n`, `AppLanguage`), `services/` (`notification_service.dart`, `message_sound_player.dart`), `theme/`, `utils/` (`content_validation_service.dart`, `external_link_launcher.dart`), `widgets/`.
- `lib/services/storage_service.dart` – upload/brisanje slika u Storage (`{root}/{uid}/...`).
- `lib/features/<feature>/{domain,data,presentation}` – feature moduli:
  - `auth` – login/registracija, `AuthGate`, `AccountDeletionService`, `user_document.dart`.
  - `splash`, `welcome`, `legal` (pravne stranice/linkovi), `location` (GPS, `home_city_provider`).
  - `home` – `HomeShellScreen` (4 taba), `HomeDrawer`, `AppDrawerCatalog`.
  - `discover` – swipe, lajk/super lajk/meč, filteri, kompatibilnost.
  - `dogs` – model psa, onboarding, zdravstveni karton, podsetnici.
  - `profile` – profil vlasnika/psa, podešavanja (`AppSettingsStore`), matching filteri, odjava/brisanje.
  - `chat` – 1:1 inbox i čet (tekst, slika, lokacija, walk invite, lajkovi, unread, zvuk).
  - `groups` – grupe po rasama + grupni čet (`GroupChatScreen` koriste i događaji).
  - `events` – događaji/šetnje + čet.
  - `map` – OSM mapa, POI/places, seed mesta po gradovima, šetnja + presence, istorija šetnji, dodavanje mesta (admin).
  - `moments` – priče 24h, komentari, istaknute priče.
  - `lost_dogs` – izgubljeni/pronađeni psi, hitni popup.
  - `adoption` – oglasi za udomljavanje.
  - `moderation` – prijave sadržaja, blokiranje.
  - `notifications` – in-app notifikacije, push gateway/kontroler, rutiranje sa push-a.
  - `support` – pravila, saveti, SOS, feedback adminu.
  - `admin` – dashboard (prijave, grupe na odobrenju, feedback, korisnici, mesta).
  - `emergency` – prazni folderi.
- `test/` – ~42 test fajla + `test/fakes/`.
- `tool/` – PowerShell skripte i JSON za geokodiranje seed mesta (Photon/Nominatim/Overpass).
- `scripts/build_release.{ps1,sh}` – release build (pravi APK, ne AAB).
- `docs/` – `TEHNICKI_PREGLED.md` (pun tehnički pregled), `play-launch-checklist.md`, privacy/terms HTML, `reels/` (marketing).
- `public/` – Firebase Hosting (samo `/privacy`, `/terms`).
- `rules_test/` – testovi `firestore.rules` i `storage.rules` nad emulatorom (`@firebase/rules-unit-testing` + `node --test`). Iz `rules_test/`, posle `npm install`: `firebase emulators:exec --only firestore,storage --project demo-vauvau "node --test firestore.rules.test.mjs storage.rules.test.mjs"` (Node i firebase-tools su u `%USERPROFILE%\.cache\firebase`, vidi `firebase.cmd`).
- Root: `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `firebase.json`, `.firebaserc`, `storage-cors.json`.

### Ključni fajlovi
- `lib/features/auth/presentation/auth_gate.dart` – rutira: login / onboarding psa / `HomeShellScreen`.
- `lib/features/auth/data/auth_repository_impl.dart` – Firebase Auth + upis `users/{uid}`.
- `lib/features/home/presentation/home_shell_screen.dart` – tabovi Otkrij/Mapa/Poruke/Profil, globalni watcheri (push token, lost-dog popup, zvuk poruke, unread badge).
- `lib/features/chat/data/firestore_chat_repository.dart` – najsloženiji Firestore sloj (inbox, attach/detachRoom, optimističke poruke, unread).
- `lib/features/chat/presentation/chat_inbox.dart` – `ChatInboxController`, unread/walk-invite provideri.
- `lib/features/chat/presentation/incoming_message_sound.dart` – detektor dolazne poruke → zvuk.
- `lib/features/groups/data/firestore_groups_repository.dart` / `events/data/firestore_events_repository.dart` – grupe/događaji + seed.
- `lib/features/discover/data/firestore_discover_repository.dart` – swipe, lajkovi, mečevi, kreiranje četa.
- `lib/features/dogs/data/dogs_repository_impl.dart` – CRUD psa.
- `lib/features/map/presentation/walk_controller.dart` – šetnja, presence, spajanje mesta (`mapPlacesProvider`).
- `lib/features/map/data/places_repository.dart` – admin mesta (`places` SoT + kopija u `pois`, atomski batch).
- `lib/features/notifications/presentation/push_controller.dart` – slanje push/lokalnih notifikacija.
- `lib/features/profile/data/app_settings_store.dart` – SharedPreferences podešavanja.

# Arhitektura
- **Feature-first** + **Riverpod 3**: `Provider` (repo/servisi), `NotifierProvider` (kontroleri), `StreamProvider` (Firestore tokovi), `.family` (po ID-ju).
- **Repository pattern:** apstraktna klasa u `domain/` + `Firestore…Repository` (produkcija) i `Local…Repository` (in-memory/seed; testovi). Izbor u provideru preko `isFirebaseReady`. Nema use-case sloja.
- Neki widgeti direktno koriste `FirebaseFirestore.instance` (`swipe_dog_card.dart`, `notification_controller.dart`, `poi_report_controller.dart`).
- **Navigacija:** samo imperativni `Navigator.push(MaterialPageRoute)`; nema imenovanih ruta, go_router-a ni deep linkova. Push tap → `appNavigatorKey`.
- **Tok:** `main` → `SplashScreen` (2 s) → `AuthGate` → Login / `DogOnboardingScreen` / `HomeShellScreen`. Drawer: Grupe, Događaji, Moments, Izgubljeni psi, Udomi, Pravila & Podrška, Podešavanja, Admin (samo `role == 'admin'`).
- **Podaci:** UI → Notifier/izvedeni provideri → repozitorijum → Firestore `snapshots()` (realtime, offline keš neograničen) / Storage.
- **Nema servera ni Cloud Functions:** mečevi, brojači (`unreadByUser`, `memberCount`, `likesCount`), notifikacije i brisanje naloga rade se sa klijenta. Push sa zatvorenom aplikacijom NE stiže (klijent samo piše `notifications` / `users/{uid}/fcmInbox`).
- **Unread:** 1:1 = `chats.unreadByUser` mapa (increment na serveru); grupe/događaji = `members/{uid}.lastReadTimestamp` vs `createdAt` poruka (klijentski).
- **Lokalizacija:** `L10n` mape sr/en (bez `.arb`); jezik/tema iz `AppSettingsController` (SharedPreferences).

# Baza podataka (Firestore)
Pun spisak polja: `docs/TEHNICKI_PREGLED.md` sekcija 5 „Firestore struktura po modulima“.
- `users/{uid}` (javni, čitaju svi prijavljeni) – uid, name, photoUrl/customPhotoUrl, city/cityId/cityName, neighborhoodId/Name, bio, role (`user`/`admin`), dog (Map), primaryDogId, walkHistory[], createdAt/updatedAt. Privatna polja (`userPrivateFields` u `user_document.dart`) pravila dozvoljavaju samo da se uklone.
  - opciona javna „o meni“ polja (`OwnerDetails` u `auth/domain/owner_details.dart`, deo `AppUser.details`; izbori su stabilni ključevi iz `OwnerDetailOptions`): ageGroup, occupation (≤60), interests[], languages[], lookingFor[], favoriteActivities[], walkTimes[], walkPace, groupWalks, dogExperience, sharesAdvice, volunteerInterest (bool – čuva se samo `true`), favoriteBreed (≤60), favoriteWalkSpot (≤80), instagram (korisničko ime bez `@`). Prazna vrednost = `FieldValue.delete()` (`ownerDetailsPayload`); upisuje ih samo „Izmeni profil“ (`saveUserProfile(details:)`).
  - podkolekcije: `private/account` (samo vlasnik + admin: email, fcmToken, presence kopija, contentReports[], placeChangeRequests[]; vlasnikov klijent pri prijavi seli stara polja iz javnog dokumenta – `moveUserPrivateFields`), `fcmInbox` (niko ne čita), `blocked_users/{uid}` (blockedAt), `walks` (distanceKm, durationSeconds, startedAt/endedAt), `place_change_requests` (samo u pravilima).
- `dogs/{dogId}` – ownerId, name, breed, gender, age/ageYears/ageMonths, size, bio, isVaccinated/isMicrochipped/isSterilized, weightKg, energyLevel, temperament/likesTags/dislikesTags[], location + cityId/neighborhoodId, foto polja (photoUrl, imageUrl, photos, photoUrls, galleryUrls, primaryPhotoUrl), likesCount, superLikesCount, presence polja, storyHighlights (Map).
  - `likes/{uid}` (type, createdAt), `health_records` (category, title, administeredDate, nextDueDate, notes, notificationId), `reminders` (title, type, category, date, repeatType, reminderOffset, isCompleted, custom interval…).
- `swipes/{uid}_{dogId}` (fromUserId, fromDogId, toDogId, type), `super_likes/{uid}_{dogId}` (marker: fromUserId, targetDogId, targetOwnerId, createdAt; stari dokumenti imaju auto-id), `matches/{uidA}_{uidB}` (dogIds, userIds).
- `chats/{uidA}_{uidB}` – participantIds, dogIds, dogNames/ownerNames/breeds/photoUrls (Map po uid), lastMessage, lastMessageTimestamp, unreadByUser (Map<uid,int>), unreadCount (legacy), isNewMatch.
  - `messages` – senderId, receiverId, senderName, senderAvatarUrl, text, imageUrl, type (`text`/`walk_invite`/`location_pin`), status, walkTime, walkLocationName, replyTo*, likes[] (reakcije: goli `uid` = ❤️, `uid:emoji` za 👍😂😮😢🙏; jedna po korisniku – `core/utils/message_reactions.dart`; isto u grupama/događajima), timestamp.
- `breed_groups/{id}` – title, description, imageUrl, memberIds[], memberCount, sortOrder, isApproved, createdBy, lastMessage/lastMessageAt; `members/{uid}` (lastReadTimestamp); `messages` (senderId, text, imageUrl, type, walk invite polja, acceptedBy/declinedByUserIds, likes, createdAt).
- `events/{id}` – title, locationName, dateTime, description, imageUrl, organizerUserId/Name, participantUserIds[], cityId, lastMessage; `members`, `messages` (šema kao grupe).
- `moments/{id}` – authorUserId, dog*, momentPhotoUrl, caption, locationName, likes[], commentsCount, createdAt; `comments`.
- `lost_dogs/{id}` – dogName, breed, type (`lost`/`found`), city, neighborhood, lostDate/foundDate, imageUrl, contactPhone, uploaderUserId, status (`active`/`resolved`), comments[] (niz u dokumentu!), commentLikes, commentsCount.
- `adoption_dogs/{id}` – name, breed, age, gender, size, location, imageUrls[], contactPhone, uploaderUserId, status (`available`/`adopted`).
- `pois/{id}` (sva mesta za mapu: category, address, lat/lng, phone, openingHours, verificationStatus, sponsor polja…), `places/{id}` (admin izvor istine, kopija u `pois`), `cities/{id}` (name, lat, lng, radiusKm, isActive).
- `notifications/{id}` (toUserId/recipientId, fromUserId, type, title, body, conversationId, isRead, createdAt…; nove čet poruke – `message`/`group`/`event` – se NE upisuju ovde, samo u `fcmInbox` + lokalna notifikacija na telefonu), `reports`, `admin_notifications`, `admin_feedback` (status `new`/`resolved`), `change_requests`. Legacy: `highlights`, `support` (samo pravila).
- **Storage:** `{pets|users|moments|events|groups|adoption|lost_dogs|uploads|chats}/{uid}/{millis}.ext`, limit 8 MB.
- **Pooštreno 2026-10-15 (NIJE deployovano, testovi u `rules_test/`, 64):**
  - `users`: privatna polja samo u `private/account`; `{path=**}/private` čita samo admin (lista prijava, email-ovi).
  - `chats`: create samo par `[pozivalac, peer]` sa id-jem `sortedUid0_sortedUid1`; čitanje nepostojeće sobe dozvoljeno (create-if-absent); update samo učesnici i samo `participantIds` (isti skup ili bez sebe), `unreadByUser` (sebi 0, drugom +1), `unreadCount` 0, `isNewMatch` false, `lastMessage` (string ≤ 1000) i `lastMessageTimestamp` == `request.time`. Metapodaci sobe se pišu samo pri kreiranju (klijent više ne prepisuje postojeću sobu).
  - `events`/`breed_groups`: menja samo organizator/kreator (bez članstva drugih i `isApproved`) ili admin; ostali samo svoje članstvo (+`memberCount` ±1) i `lastMessage*` kao članovi; `isApproved: true` (i seed) samo admin.
  - `notifications`/`fcmInbox`: `fromUserId == auth.uid`, primalac nije blokirao pošiljaoca, title ≤ 500 / body/message ≤ 1000 (klijent seče na 200), `isRead == false`, `createdAt == request.time`, `recipientId == toUserId`. `swipes` create: `fromUserId == auth.uid`.
  - `matches`: pozivalac u `userIds`, id sortiran par, update samo učesnici.
  - `dogs`: `likesCount` = broj `likes/{uid}`, `superLikesCount` = broj markera `super_likes/{uid}_{dogId}`; brojač se menja samo ±1 u istom batch-u sa svojim like doc-om / markerom (super lajk se broji jednom po korisniku i psu, unlike ga ne briše). Vlasnik ne menja brojače, ali briše tuđe lajkove (brisanje naloga).
  - `lost_dogs`: komentar se samo dodaje na kraj (postojeći ostaju isti, autor = pozivalac, tekst ≤ 2000), `commentsCount` +1; lajk komentara = samo svoj uid u jednom unosu `commentLikes` (`commentLikeTarget`). Lajkovi poruka/priča/komentara: samo svoj uid; `moments.commentsCount` ±1.
  - Storage: `list` samo vlasnik foldera; `chats/` po putanji čita samo pošiljalac (sagovornik koristi `?token=` URL iz poruke, koju čitaju samo učesnici).
- **Pravila (preostali rizici):** javni profil i psi su vidljivi svim prijavljenim (ime, grad, kvart; lokacija psa za discover/mapu – svesna funkcija); član može da upiše `lastMessage` koji ne odgovara poslatoj poruci; dnevni limit super lajka je samo na klijentu (ali se broji jednom po psu); `?token=` URL slike je trajni link za svakog ko ga dobije; CORS `*` u `storage-cors.json` (ne štiti podatke – to rade pravila/token). `isAdmin()` = `get()` na `users/{uid}.role`, bez custom claims.
- **Pravila/indeksi se NE deployuju bez eksplicitnog odobrenja.**

# Servisi i eksterni API-ji
- Firebase Auth (email/lozinka aktivno; Google implementiran ali dugme sakriveno), Firestore, Storage, FCM (samo klijent), Crashlytics, Hosting (`https://vauvau-3195a.web.app/privacy|terms`).
- OSM tile-ovi (`tile.openstreetmap.org`), Nominatim geokodiranje (`address_geocoder.dart`), linkovi ka Google/Apple Maps za navigaciju.
- Lokalne notifikacije: kanali `vauvau_alerts`, `vauvau_health`; podsetnici u 09:00 lokalno.
- Geolocator foreground servis za šetnju (Android).
- Unsplash fallback slike (`fallback_image_helper.dart`).
- Ključevi su u `lib/firebase_options.dart` – ne prikazivati, ne komitovati `android/key.properties`, `*.jks`, `*.keystore`.

# Konvencije
- Fajlovi `snake_case.dart`; klase `PascalCase`; provideri `camelCaseProvider`.
- Feature-first: `domain/` (modeli, apstraktni repo), `data/` (`firestore_*`, `local_*`, seed/mock), `presentation/` (ekrani, kontroleri, `*_strings.dart`, `widgets/`).
- Svaki feature ima `*_strings.dart` za UI tekst (srpski latinica); novi stringovi idu tamo / kroz `L10n`.
- Novi repozitorijum = apstraktna klasa + Firestore + Local implementacija, izbor u provideru po `isFirebaseReady`.
- Slike: upload kroz `ImageUploadService`/`StorageService` + `ContentValidationService.validateImage`.
- Testovi u `test/<feature>_test.dart`, Firestore preko `fake_cloud_firestore` ili Local repozitorijuma; ne menjati očekivanja testova bez razloga.
- Ne menjati produkcione podatke radi testiranja; ne izmišljati podatke o mestima (adrese, telefoni, radno vreme); čuvati admin i korisničke lokacije; migracije samo uz odobrenje.
- Commit poruke na srpskom; ne pushovati na `master` bez odobrenja.

# Stanje
## Završeno
- Auth (email), onboarding psa, profil i podešavanja (tema, jezik, notifikacije, radijus).
- Discover: swipe, lajk/super lajk (dnevni limit), meč dijalog, filteri, kompatibilnost.
- 1:1 čet: tekst, slika, lokacija, poziv na šetnju (accept/decline), reply, lajkovi, unread.
- Grupe i događaji sa četom; izbor grada u događajima/šetnjama i pričama.
- Mapa: Novi Sad, Beograd (prošireni), Niš, Kragujevac; POI, admin mesta (`places`↔`pois` atomski batch), šetnja + presence + istorija.
- Priče 24h + istaknute; izgubljeni psi (hitni popup); udomljavanje; zdravstveni karton + prilagođeni podsetnici.
- Prijave/blokiranje, admin panel, pravila/saveti/SOS, feedback.
- Pravne stranice na Hosting-u, privacy policy.

- Čet: multiline unos, zvuk dolazne poruke (`assets/sounds/message.wav`, `audioplayers`), unread popravke, avatar → profil, zakazane šetnje (banner), full-screen slike (komit `a0e5c3f`).
- Prošireni profil vlasnika (opciona polja) + popup vlasnika iz Otkrij (tap na ime vlasnika).

## U toku
- Ništa.

## Poznati bagovi
1. Push ne stiže kad je app zatvorena (nema Cloud Functions).
2. Admin „Obriši“ na prijavi ne briše korisnika/poruku/psa/čet (samo moment).
3. `notifyMatch` se nigde ne poziva; prijava sadržaja pravi notifikaciju samom prijaviocu.
4. Seed grupe/događaji se upisuju sa klijenta u produkciju (lažni `memberCount`, `isApproved: true`). Po novim pravilima to sme samo admin; `ensureSeeded` kod ostalih preskače odbijen upis.
5. Čet (prijavljeno, nije menjano): pošiljalac poziva ne dobija obaveštenje kad sagovornik prihvati/odbije šetnju; pravila ne proveravaju blokadu za `chats/*/messages` (blokirani i dalje može da piše, primalac to samo ne vidi u listi; ekran otvoren iz push-a/obaveštenja blokiranog korisnika i dalje radi); poziv sa vremenom u prošlosti se tiho ignoriše (`sendWalkInvite`); stari `notifications` dokumenti tipa `message` ostaju u listi dok se razgovor ne otvori.
- Testovi (2026-10-15, posle popravki četa): 195 prolazi, 15 pada – isti skup kao pre (bez `moments_test`, koji visi). Ranije: 177 prolazi, 18 pada – isti skup kao pre popravki (admin, events, map, safety, chat walk invite, notifications, settings, widget, discover, moments – `moments_test` „owner creates a highlight“ visi 10 min). `profile_test` „opens settings and search filters“ pada (discover mock nema pse za Beograd) – ranije se nije ni kompajlirao. `flutter analyze` čist.

## TODO (po prioritetu)
1. Push na `master` (komit `a0e5c3f` je lokalan na `main`) – samo uz odobrenje.
2. Pregledati pale testove (ne menjati očekivanja bez razloga).
3. Ručno na uređaju proveriti: registraciju sa slikom, brisanje naloga (email + lozinka).
4. Zameniti 7 `print()` poziva sa `debugPrint`/Crashlytics.
5. Deploy pooštrenih `firestore.rules` i `storage.rules` samo uz odobrenje. Redosled: prvo izdati novu verziju aplikacije (radi i sa starim pravilima – privatni upisi imaju fallback, provere postojanja sobe/markera i lajk komentara takođe), pa deploy pravila kad većina korisnika ima novu verziju (stari klijent: lajk/super lajk bez batch-a, email/fcmToken/lokacija/prijave u javni profil, `commentLikes` ceo map, ponovno pisanje postojeće sobe – sve to nova pravila odbijaju). Pre toga na uređaju proveriti: registracija/prijava (nastaje `private/account`, javni profil bez email-a), meč → čet, slanje poruke + unread, grupe/događaje (join, poruka), lajk/super lajk/unlike, komentar i lajk komentara na izgubljenom psu, prijava sadržaja + admin lista prijava i korisnika, brisanje naloga.
6. Cloud Functions (push iz `fcmInbox`, serverski mečevi/notifikacije, kaskadno brisanje, admin custom claims) – traži Blaze plan.
7. Bagovi 2–4 iz liste iznad.
8. Seed grupa/događaja prebaciti u jednokratnu admin skriptu.
9. iOS (bundle id, GoogleService-Info.plist, push, DEVELOPMENT_TEAM, URL scheme); Android AAB build + ažurirati Play checklistu; web Firebase config.
10. Sopstveni tile provajder; keš/rate-limit za Nominatim.
11. Dugoročno: ujednačiti šemu lokacije/slika, ukloniti duple izvore istine i mrtav kod (`AppRoutes`, `dog_photo_persist*`, `highlights`), `.arb` lokalizacija, go_router + deep linkovi, čišćenje repoa (~7 MB splash slika, `Gist`, `docs/reels/`), CI.

# Dnevnik izmena
- [2026-09-17 – 2026-10-07] Faze 1–7: shell i brending, filteri/notifikacije/UI, Firebase Auth/Firestore/Storage, Google prijava, sinhronizacija profil/pas, priče/istaknute, saveti/SOS, safety, mapa, zdravstveni podsetnici, admin, stabilizacija testova, privacy policy.
- [2026-10-14] Gradovi Niš i Kragujevac na mapi, izbor grada u događajima/šetnjama/pričama, ručni unos kvarta, prošireni Beograd; ignorisani Firebase CLI binarni fajlovi.
- [2026-10-15] Nekomitovano: multiline čet, zvuk poruke, unread popravke, avatar → profil, zakazane šetnje, full-screen slike, novi testovi. Napravljen `docs/TEHNICKI_PREGLED.md`.
- [2026-10-15] Napravljeni `CLAUDE.md` i `.cursor/rules/project-memory.mdc` (projektna memorija).
- [2026-10-15] Popravke bagova (nekomitovano):
  - prvi lajk na grupnoj/event poruci (`_stringList` vraća promenljivu listu) – `firestore_groups_repository.dart`, `firestore_events_repository.dart`, novi `test/group_message_like_test.dart`;
  - grupni čet `scheduleFrame()` u `_jumpToEndWithRetry` – `group_chat_screen.dart`;
  - lista četova više ne zove `markRead` pre otvaranja (to radi detaljni ekran) – `chat_list_screen.dart`;
  - `totalUnreadChatCountProvider` broji iz `visibleConversationsProvider` (bez blokiranih) – `chat_inbox.dart`;
  - 1:1 lajk preko `arrayUnion`/`arrayRemove` – `firestore_chat_repository.dart`;
  - registracija: slika se bira lokalno, upload tek posle kreiranja naloga – `auth_screen.dart`;
  - brisanje naloga: reautentikacija (lozinka u dijalogu ili Google) → brisanje podataka → `user.delete()` – `firebase_auth_datasource.dart`, `auth_repository(_impl).dart`, `local_auth_repository.dart`, `auth_controller.dart`, `delete_account_action.dart`, `profile_strings.dart`, `test/fakes/fake_auth_repository.dart`;
  - `test/profile_test.dart:41` ponovo kompajlira.
- [2026-10-15] Pooštrena `firestore.rules` (nije deployovano): `chats` članstvo/create, `events`/`breed_groups` (organizator/kreator/admin; ostali samo svoje članstvo i `lastMessage*`; `isApproved` samo admin), `fromUserId` za `notifications`/`fcmInbox`/`swipes`, `matches` (pozivalac u `userIds`; update za učesnike – ranije je ponovni meč posle unlike/like pucao), `dogs` brojači ±1. Novi `rules_test/` (32 testa u emulatoru, svi prolaze). `ensureSeeded` u `firestore_groups_repository.dart`/`firestore_events_repository.dart` hvata odbijene seed upise da stream ne pukne. `flutter analyze` čist.
- [2026-10-15] Preostali rizici pravila (nije deployovano): lajk brojači vezani za `likes/{uid}` (klijent sad piše like doc + brojač u jednom batch-u – `firestore_discover_repository.dart`; super lajk se više ne „spušta“ na običan lajk), vlasnik psa sme da briše tuđe lajkove (ranije je brisanje naloga sa lajkovanim psom pucalo), `lastMessage` ograničen i vreme = server (novi `core/utils/message_preview.dart`, seče pregled na 200 znakova u čet/grupa/događaj repozitorijumima), kreator/organizator ne menja tuđe članstvo, Storage bez listanja tuđih foldera i `chats/` samo za prijavljene. `rules_test/` sad 47 testova (+`storage.rules.test.mjs`), svi prolaze; Flutter testovi chat/discover/events/groups – isti 5 pada pre i posle izmene.
- [2026-10-15] Ostali rizici pravila (nije deployovano):
  - privatna polja korisnika u `users/{uid}/private/account` (`user_document.dart`: `userPrivateFields`, `userPrivateDoc`, `moveUserPrivateFields`); pišu ih `auth_repository_impl.dart` (email + seljenje starih polja pri prijavi/obnovi sesije), `push_notification_gateway.dart` (fcmToken), `firestore_walk_presence_repository.dart` (presence), `firestore_report_repository.dart` i `poi_report_controller.dart` (prijave); admin čita prijave i email-ove preko collection group `private` (`firestore_report_repository.dart`, `firestore_admin_repository.dart`); brisanje naloga briše i `private`;
  - email se više nikad ne koristi kao javno ime (lajk/super lajk notifikacija, komentar na izgubljenom psu);
  - čet: soba se ne prepisuje ako postoji (`_createRoom`, `_tryCreateMatch`) – ranije je ponovni meč brisao `lastMessage`/unread;
  - super lajk: marker `super_likes/{uid}_{dogId}` + brojač u jednom batch-u; unlike ne skida super lajk; brisanje naloga skida marker sa -1;
  - notifikacije: blokada, dužina, `createdAt` server; push title/body se seku na 200;
  - izgubljeni psi: lajk komentara piše samo svoj unos (`commentLikes.{id}` + `commentLikeTarget`);
  - Storage `chats/` po putanji samo pošiljalac.
  - kompatibilnost sa starim pravilima dok se ne deployuju: `setUserPrivateFields` (prijave idu u javni profil ako je `private` odbijen), presence/token best-effort, `_existsSafely` za sobu/marker, lajk komentara pada nazad na ceo `commentLikes` map; admin lista prijava čita i stari javni profil.
  - `rules_test/` 64 testa, svi prolaze; Flutter: isti 15 padova pre i posle (bez `moments_test`, koji visi); `flutter analyze` čist.
- [2026-10-15] Čet „Poruke“ – popravke (pravila nisu menjana ni deployovana):
  - ime u obaveštenju: poziv u šetnju je slao ime i psa SAGOVORNIKA (`chat.ownerName`/`chat.dogName`), pa je Nina dobijala „Nina vas poziva…“; isto za poruku/sliku kad `displayName` nije postavljen. Sad je pošiljalac uvek trenutni korisnik (`_myName`/`_myDog`, `notifyWalkRequest` u `chat_inbox.dart`; i poziv sa mape u `map_screen.dart`). U `writeQueuedNotification` (`push_notification_gateway.dart`) `data.peerUserId` = pošiljalac (ranije primalac sam sebi);
  - pročitan razgovor → njegova obaveštenja (`conversationId`, i stari `message`/`walk` po pošiljaocu) dobijaju `isRead: true` upitom u Firestore (`notifications/data/conversation_notifications.dart`), ne brišu se; obaveštenja koja stignu dok je čet otvoren čitaju se odmah (`chat/presentation/open_chats.dart`); povratak u app sa otvorenim četom zove `markRead` (`chat_detail_screen.dart`); tap na push više ne dodaje novu nepročitanu kopiju (`push_controller.dart`); brišu se samo tray stavke tog četa;
  - nova poruka (1:1, grupa, događaj) više nema in-app obaveštenje: `PushPayload.showsInApp`, sender piše samo `fcmInbox`; primalac dobija lokalnu notifikaciju na telefonu (`incomingChatAlertProvider` u `incoming_message_sound.dart`, ne za otvoren čet); slanje lokacije sad šalje push;
  - lajk poruke: na mojoj (narandžastoj) poruci srce je bilo prazno i u boji teme / crveno na narandžastom – nevidljivo. `ChatLikeIndicator` (`message_bubble.dart`) crta puno srce u boji teksta balona; `CommentLikeButton` ima `likedColor`/`idleColor`;
  - obaveštenje o pozivu sa `conversationId` otvara čet umesto mape (`notification_routing.dart`);
  - novi `test/chat_notifications_test.dart` (14), `rules_test/` 65 (upit + `isRead` primaoca); Flutter: isti 15 padova pre i posle; `flutter analyze` čist.
  - poziv u šetnju ostaje i kao in-app obaveštenje (traži odgovor) – korisnik potvrdio.
- [2026-10-15] Reakcije na porukama i profil osobe (pravila nisu deployovana):
  - srce sa poruka uklonjeno (u 1:1, grupama i događajima); dugi pritisak otvara meni sa emoji redom 👍❤️😂😮😢🙏 + Odgovori/Prijavi (`showMessageActionsSheet` → `MessageActionChoice`, `ReactionPickerRow`); izabrana reakcija je bedž ispod balona (`ReactionBadge`/`BubbleWithReactions` u `chat/presentation/widgets/message_reactions.dart`) na svetloj pozadini, vidljiv i na sivom i na narandžastom balonu; ponovni izbor istog emojija uklanja reakciju;
  - reakcije se čuvaju u postojećem `likes` nizu (radi sa deployovanim pravilima koja dozvoljavaju samo `likes`); `setMessageReaction` u čet/grupa/događaj repozitorijumima (transakcija, zamena svoje reakcije), `toggleMessageLike` = ❤️ prečica; u novim pravilima `ownReaction('likes')` umesto `ownToggle` za poruke (samo svoj unos, najviše jedna reakcija, emoji iz palete);
  - avatar pored poruke otvara profil OSOBE (`profile/presentation/owner_profile_sheet.dart` + `profile/data/owner_public_profile.dart`: ime, slika, grad/kvart, bio, psi → tap otvara psa); naslov četa i dalje otvara psa;
  - testovi: novi `test/message_reactions_test.dart` (8), `chat_test`/`groups_test` avatar sad očekuje `OwnerProfileSheet`; `rules_test/` 67; Flutter 195 prolazi, isti 15 padova; `flutter analyze` čist.
- [2026-10-15] Prošireni profil vlasnika i popup vlasnika u Otkrij (pravila se ne menjaju):
  - model: `auth/domain/owner_details.dart` (`OwnerDetails`, `OwnerDetailOptions`, `normalizeInstagram`), `AppUser.details`, `UserProfile.ownerDetails`; čitanje toleriše stare dokumente, null, pogrešne tipove i nepoznate ključeve; `ownerDetailsPayload` (`user_document.dart`) briše prazna polja; `saveUserProfile(details:)` u `AuthRepository` + impl/local/fake; `ProfileController.save(writeOwnerDetails: true)` šalje ih samo iz „Izmeni profil“ (onboarding ih ne dira);
  - „Izmeni profil“: 4 proširive sekcije (O meni, Druženje i šetnje, Iskustvo sa psima, Dodatno) – `PreferenceChipGroup` (novi `labelOf`) za višestruki izbor, `ChoiceChip` za jedan izbor (ponovni tap briše), prekidači, tekst sa `maxLength` + `ContentValidationService`, Instagram validacija; stringovi u `profile_strings.dart` (`ownerOption(key)`);
  - Otkrij: ime vlasnika u `DogDetailSheet` (`_OwnerRow`, `swipe_dog_card.dart`) je dugme (narandžasto, podvučeno, strelica, Semantics) → `showOwnerProfileSheet` po `ownerId` preko `ownerProfileLoaderProvider` (`owner_public_profile.dart`); `OwnerProfileSheet` sada prikazuje samo popunjena polja po sekcijama, dugme Zatvori, indikator učitavanja, poruku o grešci sa „Pokušaj ponovo“ i „Profil nije dostupan“; slika vlasnika ili placeholder osobe (`DogImage.fallback`, nikad slika psa); email se ne prikazuje;
  - testovi: novi `test/owner_profile_details_test.dart` (17), `rules_test/` 68 (vlasnik upisuje/briše nova javna polja, drugi ne); Flutter: isti 15 padova kao na baznom komitu (bez `moments_test`); `flutter analyze` čist.
