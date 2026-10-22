# Video u pričama i objavama – čuvanje i kvote

Proveravano: 20.10.2026 (kvote), 22.10.2026 (deployovana pravila, kompresija). Izvori:
- https://firebase.google.com/pricing (tabela „Cloud Storage“)
- https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024
- https://pub.dev/packages/video_compressor_plus (kompresija na telefonu)

## Kako se video priprema i čuva

1. Korisnik bira ili snima video u kvalitetu koji telefon ima (`image_picker`).
   Kamera staje na 15 s; video iz galerije može biti duži.
2. **Priprema na telefonu** (Android i iOS, `core/media/picked_video.dart` →
   `prepareVideoForUpload`, paket `video_compressor_plus`: Android MediaCodec,
   iOS AVFoundation, bez FFmpeg-a):
   - duži video se skraćuje na **prvih 15 s** (korisnik vidi napomenu);
   - rezolucija se smanjuje na **najviše 720p** (uspravno 720×1280), 30 fps;
     orijentacija i odnos stranica ostaju;
   - ako je i tada ≥ 20 MB, radi se drugi prolaz na 540p; ako ni to ne pomogne,
     video se odbija uz poruku;
   - rezultat se UVEK ponovo meri (trajanje i veličina) pre otpremanja.
   Na webu nema kodera: video mora već biti ≤ 15 s i < 20 MB.
3. **Sam fajl ide u Firebase Storage**, u bucket projekta
   `vauvau-3195a.firebasestorage.app`:
   - priča: `stories/{uid}/{storyId}/media` – privatno, svako čitanje prolazi
     `storage.rules` (publika, blokada, istek 24 h);
   - objava: `moments/{uid}/{draftId}.mp4` – javni link sa tokenom (kao slike).
4. **U Firestore ide samo mali dokument** (nekoliko stotina bajtova): putanja ili
   link do fajla + `mediaType: 'video'` + opis, grad, autor… Video nikad nije u
   bazi, pa ne troši Firestore kvotu.
5. Gledanje:
   - priča: na telefonu se video jednom preuzme u privremeni folder aplikacije i
     pušta odatle; na webu se pušta preko privremenog linka;
   - objava: ništa se ne preuzima dok korisnik ne tapne na video (bez autoplay-a,
     bez zvuka, samo jedan video svira u isto vreme).
6. Brisanje priče/objave briše i fajl. Priče koje samo isteknu (24 h) ostaju u
   Storage-u dok se ne podesi lifecycle pravilo (vidi Preporuke).

## Pravila (stanje 22.10.2026)

Provereno čitanjem aktivnih pravila sa Firebase-a (Rules API): `cloud.firestore`
(deploy 22.10. 08:32 UTC) i `firebase.storage/vauvau-3195a.firebasestorage.app`
(deploy 22.10. 08:34 UTC) su **identični** `firestore.rules` i `storage.rules` u
repou: `mediaType` `image`/`video` za objave i priče, video < 20 MB
(mp4/quicktime/webm/3gpp) samo u `moments/` i `stories/`.

## Koje kvote važe

Bucket je novog tipa (`*.firebasestorage.app`). Po zvaničnim FAQ-u, Cloud Storage
od septembra 2024 traži **Blaze plan** (pay-as-you-go), a Spark projekti od
3.2.2026 nemaju pristup nijednom bucketu. Cloud Functions su deployovane
22.10.2026, a i one traže Blaze, pa je projekat na Blaze planu – iznos i budžet
proveri u **Firebase Console → Usage and billing**.

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
plaća se od prvog bajta po ceni Google Cloud Storage-a.

## Okvirna procena (nije merenje na uređaju)

Posle pripreme: 720p, ~4 Mbit/s video + zvuk ≈ **0,5 MB po sekundi**, pa je video
od 15 s oko **7–8 MB** (bez obzira da li je snimljen u 1080p ili 4K).

- Skladište: 5 GB / ~8 MB ≈ **600 videa** istovremeno (bez slika). Priče se
  same ne brišu dok se ne uključi lifecycle pravilo.
- Preuzimanje: 100 GB / ~8 MB ≈ **12.500 gledanja mesečno** (~400 dnevno).
  Jedna priča od 8 MB koju pogleda 100 pratilaca = 0,8 GB.
- Upload: 5.000 mesečno za SVE fajlove (slike profila, psa, četa, objave, priče).

## Preporuke

1. **Lifecycle pravilo** za prefiks `stories/` (briši starije od 2 dana) –
   Google Cloud Console → Cloud Storage → bucket → Lifecycle. Već je u TODO 6b.
2. Postaviti budžet i upozorenje u Google Cloud Billing (npr. 5 €), da trošak
   ne iznenadi.
3. Na uređaju proveriti stvarne veličine (snimak 1080p/4K, dug video iz
   galerije) i vreme pripreme na slabijem telefonu.

## Poznata ograničenja

- iOS (još nije objavljen): paket na iOS-u ne primenjuje skraćivanje kad video
  ima zvuk. Aplikacija to hvata – duži video posle obrade i dalje ima više od
  15 s, pa se odbija uz poruku da se skrati u Fotografijama. Proveriti kad
  stigne prvi iOS build.
- Web: nema smanjenja ni skraćivanja.
