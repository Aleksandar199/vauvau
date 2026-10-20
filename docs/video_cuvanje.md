# Video u pričama i objavama – čuvanje i kvote

Proveravano: 20.10.2026. Izvori:
- https://firebase.google.com/pricing (tabela „Cloud Storage“)
- https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024

## Kako se video čuva

1. Telefon bira ili snima video (`image_picker`). Kamera staje na limitu
   (priča 15 s, objava 30 s). Video iz galerije aplikacija proverava posle izbora:
   trajanje (preko `video_player`) i veličinu (< 20 MB). Predug ili prevelik
   video se odbija uz poruku šta treba uraditi (`core/media/video_limits.dart`,
   `checkVideo`).
2. **Sam fajl ide u Firebase Storage**, u bucket projekta
   `vauvau-3195a.firebasestorage.app`:
   - priča: `stories/{uid}/{storyId}/media` – privatno, svako čitanje prolazi
     `storage.rules` (publika, blokada, istek 24 h);
   - objava: `moments/{uid}/{draftId}.mp4` – javni link sa tokenom (kao slike).
3. **U Firestore ide samo mali dokument** (nekoliko stotina bajtova): putanja ili
   link do fajla + `mediaType: 'video'` + opis, grad, autor… Video nikad nije u
   bazi, pa ne troši Firestore kvotu.
4. Gledanje:
   - priča: na telefonu se video jednom preuzme u privremeni folder aplikacije i
     pušta odatle (ponovno gledanje iste priče na istom telefonu ne preuzima
     ponovo dok OS ne očisti keš); na webu se pušta preko privremenog linka;
   - objava: ništa se ne preuzima dok korisnik ne tapne na video (bez autoplay-a,
     bez zvuka, samo jedan video svira u isto vreme).
5. Brisanje priče/objave briše i fajl. Priče koje samo isteknu (24 h) ostaju u
   Storage-u dok se ne podesi lifecycle pravilo (vidi Preporuke).

## Koje kvote važe

Bucket je novog tipa (`*.firebasestorage.app`). Po zvaničnim FAQ-u, Cloud Storage
od septembra 2024 traži **Blaze plan** (pay-as-you-go), a Spark projekti od
3.2.2026 nemaju pristup nijednom bucketu. Pošto otpremanje slika radi, projekat je
verovatno već na Blaze planu – **proveri u Firebase Console → Usage and billing**
(iz fajlova u repou plan ne može da se utvrdi).

Besplatni nivo za `*.firebasestorage.app` (Firebase pricing stranica, isti brojevi
kao Google Cloud „Always Free“):

| Šta | Besplatno | Napomena |
|---|---|---|
| Skladište | 5 GB-meseci | prosečno zauzeće tokom meseca |
| Preuzimanje (egress) | 100 GB mesečno | svako gledanje videa = preuzimanje celog fajla |
| Upload operacije | 5.000 mesečno | svaka slika ili video koji se otpremi |
| Download operacije | 50.000 mesečno | |

Važi **samo ako je bucket u regionu `us-central1`, `us-east1` ili `us-west1`**
(Console → Storage → podešavanja bucketa). U drugom regionu (npr. `europe-west`)
plaća se od prvog bajta po ceni Google Cloud Storage-a. Iznad besplatnog nivoa
naplaćuje se po Google Cloud Storage cenovniku (linkovan sa pricing stranice).

## Okvirna procena (nije merenje)

Telefon snima otprilike 1 MB/s na 720p i 2–2,5 MB/s na 1080p.

- Priča 15 s na 720p ≈ 15 MB; objava 30 s na 720p ≈ 30 MB → **prelazi limit od
  20 MB** i biva odbijena. Na 1080p i priča od 15 s (≈ 30 MB) prelazi limit.
  Prolaze: kraći snimci, 720p, ili video koji je već kompresovan (npr. poslat
  preko WhatsApp-a/Vibera).
- Skladište: 5 GB / ~15 MB ≈ **330 videa** istovremeno (bez slika). Priče se
  same ne brišu dok se ne uključi lifecycle pravilo.
- Preuzimanje: 100 GB / ~15 MB ≈ **6.600 gledanja mesečno** (~220 dnevno).
  Jedna priča od 15 MB koju pogleda 100 pratilaca = 1,5 GB.
- Upload: 5.000 mesečno za SVE fajlove (slike profila, psa, četa, objave, priče).

## Preporuke

1. Ostaviti limite (priča 15 s, objava 30 s, < 20 MB) – trajanje i veličina su
   jedina kočnica troška; `storage.rules` proverava veličinu i tip i kad je
   klijent izmenjen (trajanje ne može da se proveri u pravilima).
2. **Lifecycle pravilo** za prefiks `stories/` (briši starije od 2 dana) –
   Google Cloud Console → Cloud Storage → bucket → Lifecycle. Već je u TODO 6b.
3. Kompresija na telefonu (npr. paket `video_compress`) pre otpremanja – tek
   tada objava od 30 s realno staje u 20 MB. Traži nativni paket i proveru na
   uređaju, zato nije urađeno u ovoj izmeni.
4. Postaviti budžet i upozorenje u Google Cloud Billing (npr. 5 €), da trošak
   ne iznenadi.
