# Zrenjanin i Subotica – gradovi i mesta za pse

Istraživanje i implementacija: 2026-10-19. Seed fajlovi:
`lib/features/map/data/zrenjanin_dog_places_seed.dart`,
`lib/features/map/data/subotica_dog_places_seed.dart`. Ulaz i rezultat
geokodiranja: `tool/{zrenjanin,subotica}_places_raw.json` →
`tool/{zrenjanin,subotica}_places_nominatim.json`.

## Pravila statusa

- **verified** – park iz OpenStreetMap-a; park za pse potvrđen gradskim izvorom
  ili lokalnim medijem i ucrtan u OSM; firma potvrđena **sopstvenim sajtom**
  (ime, adresa, kontakt). Samo kod njih se upisuju telefon, sajt i radno vreme,
  i to tačno kako piše na sajtu.
- **unknown** (postojeći status za neprovereno) – firma nađena u javnom imeniku,
  lokalnoj vesti ili OSM-u, ali ne i na zvaničnom sajtu. Upisani su samo ime,
  adresa, kategorija, koordinate i izvor (URL). Telefon, sajt i radno vreme se
  NE upisuju dok ih admin ne potvrdi.
- Nijedno mesto nije označeno kao 24/7 ni kao hitna služba. Nijedan lokal nije
  dodat kao dog-friendly (nijedna politika nije potvrđena).
- Koordinate: Nominatim strukturirana pretraga sa tačnim kućnim brojem
  (`tool/geocode_places_nominatim.ps1`, svih 23 adresa pogođeno na nivou broja)
  ili OSM čvor/površina same firme/parka. Nema 0,0 ni centra grada kao rezerve.

## Centri mape

| Grad | Centar | Izvor |
|---|---|---|
| Zrenjanin | 45.3803, 20.3908 | Nominatim, OSM relacija 9853233 (sr.wikipedia: 45.3824, 20.3915) |
| Subotica | 46.1002, 19.6653 | Nominatim, OSM čvor `place=city` 1547830258 (sr.wikipedia: 46.1001, 19.6636) |

Radijus 15 km, zum 13 (kao Niš/Kragujevac).

## Kvartovi

- **Zrenjanin** (21, sr.wikipedia „Zrenjanin“ – gradska naselja): Centar,
  Bagljaš, Berbersko, Bolnica, Brigadira Ristića, Budžak, Budžin bulevar,
  4. jul, Čontika, Dolja, Duvanika, Gradnulica, Lesnina, Mala Amerika, Mičkej,
  Mužlja, Nova Kolonija, Putnikovo, Ruža Šulman, Šumica, Zeleno Polje, Žitni Trg.
  Okolna sela (Elemir, Ečka, Lazarevo…) nisu dodata.
- **Subotica** (21 gradska mesna zajednica, sr.wikipedia „Subotica“ – spisak
  mesnih zajednica): Centar I–III, Aleksandrovo, Bajnat, Dudova šuma, Gat, Ker,
  Kertvaroš, Makova sedmica, Mali Bajmok, Mali Radanovac, Novi Grad, Novo Selo,
  Peščara, Prozivka, Radanovac, Radijalac, Verušić, Željezničko naselje, Zorka.
  Prigradske MZ (Palić, Bajmok, Čantavir…) nisu dodate. „Ostalo / Ručni unos“
  ostaje.

## Dodata mesta – Zrenjanin (19)

| Id | Mesto | Kategorija | Status | Izvor |
|---|---|---|---|---|
| zr-park-karadjordjev | Karađorđev park | park | verified | OSM way 96241144 |
| zr-park-gradska-basta | Gradska bašta | park | verified | OSM way 463524809 |
| zr-park-titov-gaj | Titov gaj | park | verified | OSM way 1271825251 |
| zr-park-zeleznicki | Železnički park | park | verified | OSM way 418275694 |
| zr-park-secerana | Šećeranski park | park | verified | OSM way 143996737 |
| zr-park-streliste | Park Strelište | park | verified | OSM way 1273325262 |
| zr-dogpark-bagljas | Park za pse Bagljaš (kod BIG-a) | park za pse | verified | Dnevnik 8. 1. 2026 + OSM way 1491345360 |
| zr-dogpark-zeleznicki | Park za pse u Železničkom parku | park za pse | verified | Dnevnik + OSM way 1086222200 |
| zr-dogpark-secerana | Park za pse Šećerana | park za pse | verified | Dnevnik + OSM way 1118597340 |
| zr-dogpark-motel | Park za pse Motel | park za pse | unknown | Dnevnik navodi „Motel“; OSM way 1208252981 – podudaranje nije sigurno |
| zr-vet-dimic | Veterina Dimić, Žarka Zrenjanina 78 | veterinar | verified | vetdimic.com (tel. 023 567 021; pon–pet 08–19, sub 09–14, ned 10–13; dežurstvo 19–24 – NIJE 24/7) |
| zr-vet-laki-vet | Laki Vet, Topličina 13a | veterinar | unknown | volimzrenjanin.com (2023) |
| zr-vet-mila-vet | Mila Vet, Miletićeva 20 | veterinar | unknown | Facebook stranica |
| zr-vet-ultimate-vet | Ultimate Vet, Cara Dušana 14a | veterinar | unknown | dezurniveterinar.com; zvanični sajt ultimatevet.rs ne radi |
| zr-vet-stanica-zrenjanin | Veterinarska stanica Zrenjanin, Koče Kolarova 38 | veterinar | unknown | planplus.rs |
| zr-vet-canis | Veterinarska ambulanta Canis, Knićaninova 12 | veterinar | unknown | imenik.rs |
| zr-vet-taurus | Veterinarska stanica Taurus, Elemirski drum 56 | veterinar | unknown | OSM čvor 5310930623 (broj iz Waze-a) |
| zr-shop-gama-pet | Gama Pet, Koče Kolarova 39 | pet shop | unknown | kandidat + OSM čvor 4734330123 na istoj adresi |
| zr-shop-aristo-pets | Aristo Pets, Bagljaš zapad 5 | pet shop | unknown | planplus.rs + OSM |

## Dodata mesta – Subotica (31)

| Id | Mesto | Kategorija | Status | Izvor |
|---|---|---|---|---|
| su-park-dudova-suma | Dudova šuma | park | verified | OSM way 359835105 (u opisu: gradski ograđeni prostor za pse iz 2020) |
| su-park-prozivka | Park Prozivka | park | verified | OSM way 400328561 |
| su-park-ferenca-rajhla | Park Ferenca Rajhla | park | verified | OSM way 75683509 |
| su-park-slobode | Park slobode | park | verified | OSM way 78067069 |
| su-park-mali-bajmok | Park Mali Bajmok | park | verified | OSM way 1088618682 |
| su-dogpark-prozivka | Park za pse Prozivka | park za pse | verified | gradsubotica.co.rs 9. 1. 2020 + OSM way 1177949865 |
| su-vet-veterinar | Veterinarska stanica Veterinar, Trg Paje Kujundžića 2/a | veterinar | verified | veterinarsubotica.rs (024 671 060; pon–pet 07–19, sub 07–14, ned 08–11) |
| su-vet-panvet | Panvet, Koste Racina 5 | veterinar | verified | panvet.info (024 571 920; radno vreme na sajtu je slika – nije upisano) |
| su-vet-viva | Veterinarska ambulanta Viva, Pačirski put 21 | veterinar | verified | vivaveterinar.rs (060 1304878; radno vreme nije na sajtu) |
| su-vet-animed | Animed, Blaška Rajića 30 | veterinar | unknown | OSM; sajt veterinarsubotica.com nije odgovarao |
| su-vet-happy-vet | Happy Vet, Partizanskih baza 35 | veterinar | unknown | OSM čvor 9555822307 |
| su-vet-ekosvet | Ekosvet, Braće Majera 40 | veterinar | unknown | OSM čvor 13206349370 |
| su-vet-sudarevic | Sudarević-vet, Vlasenička 41 | veterinar | unknown | OSM čvor 13206349371 |
| su-vet-libero | Libero veterina, Bore Stankovića 6 | veterinar | unknown | OSM čvor 13206349372 |
| su-vet-radakovic | Radaković vet, Lazara Bačića 6 | veterinar | unknown | OSM čvor 13206349367 |
| su-vet-stanica-subotica | Veterinarska stanica Subotica (javna), Segedinski put 88 | veterinar | unknown | OSM čvor 13206349366 |
| su-shop-pet-centar | Pet Centar Subotica, Bajnatska 25 | pet shop / vet. apoteka | verified | pet-centar.rs (024 52 25 82; pon–ned 09–21) – jedina filijala; „Bajnatska bb“ iz imenika je ista radnja |
| su-shop-pet-zone | Pet Zone, Segedinski put 88a | pet shop | unknown | planplus.rs + OSM |
| su-shop-petbox | Petbox, Somborski put 35 | pet shop | unknown | planplus.rs |
| su-shop-svet-kucnih-ljubimaca | Svet kućnih ljubimaca, Ivana Milankovića 40 | pet shop | unknown | planplus.rs (OSM: „Svet ljubimaca“, br. 42) |
| su-shop-pet-svet-024-lajosa-joa | Pet Svet 024, Lajoša Joa 5 | pet shop | unknown | OSM čvor 7551931549 |
| su-shop-pet-svet-024-osmog-marta | Pet Svet 024, Osmog marta 9v | pet shop | unknown | OSM čvor 13174220467 |
| su-shop-maxpet | MaxPet, Braće Radić 118 | pet shop | unknown | OSM čvor 9366300419 |
| su-shop-little-pet-shop | Little Pet Shop 024, Gundulićeva 53 | pet shop | unknown | OSM čvor 13165470301 |
| su-shop-mondo-animale | Mondo Animale, Trg Jakaba i Komora 8 | vet. apoteka (kategorija pet shop) | unknown | OSM čvor 13206349365 |
| su-groom-anastazija | Anastazija Grooming, Petra Čajkovskog 12 | grooming | unknown | planplus.rs, subotica.biz |
| su-groom-bokine-sape | Bokine šape, Šumska 9 | grooming | unknown | subotica.biz |
| su-groom-diego | Grooming salon Diego, Braće Radić 87 | grooming | unknown | OSM čvor 9368486334 (geokod adrese 15 m od čvora) |
| su-groom-godzi | Godži Groom, Nade Dimić 17 | grooming | unknown | OSM čvor 13119600510 |
| su-wash-samousluzno-kupanje | Samouslužno kupanje pasa, Trg sinagoge 1a | samouslužno kupanje | unknown | kupanjepasa.com (0–24); adresa samo iz pretrage |
| su-shelter-prihvataliste | Prihvatilište za napuštene pse i mačke, Deveta nova 249 (Zorka) | prihvatilište | unknown | gradsubotica.co.rs 2019 (JKP „Čistoća i zelenilo“) |

## Kandidati za ručnu proveru (NISU na mapi)

| Kandidat | Razlog |
|---|---|
| Ultimate Vet, Pančevačka 38 (Zrenjanin) | Nijedan izvor ne potvrđuje ovu adresu; svi navode Cara Dušana 14a. Dežurstvo 0–24 samo na eksperimentalnom imeniku. |
| Premium Pet, Bagljaš zapad bb (Zrenjanin) | Samo planplus; „bb“ nema kućni broj → nema pouzdanih koordinata. |
| PetShop Sumo, Pedigree, Luna M (Zrenjanin) | Samo OSM ime, bez adrese. |
| Prihvatilište Zrenjanin | Nije nađena adresa ni operater. |
| Park za pse u Dudovoj šumi (Subotica) | Grad ga je otvorio 2020, ali tačno mesto nije ucrtano → bez izmišljenog pina; pomenut u opisu parka. |
| Prihvatilište – „Zapadni vinogradi bb“ (Subotica) | Planplus; gradski članak navodi Deveta nova 249 – proveriti koja je tačna. |
| Veterinarski specijalistički institut Subotica, Segedinski put 88 | Institut (laboratorija, farme), nije ambulanta za ljubimce; na istoj adresi je javna veterinarska stanica (dodata kao unknown). |
| Panvet – broj za hitne | Sajt i OSM se razlikuju (065/9751 920 vs 065 9571920) → nije upisan. |
| Nera & Ciara Pet (Arsenija Čarnojevića 70), Paw Styler (Dože Đerđa 15), Pet salon Tiffany (Antona Askerca 42), GroomRoom Nevena (Mihajla Radnića 16), Maša Grooming (Porečka 20) – Subotica | Nijedan javni izvor nije nađen. |
| Doggy Day Spa (Subotica) | Pomenut u pretrazi, bez adrese. |
| Pansion za pse Kia, Josipa Kolumba 60 (Subotica); Pansion za pse Tina, Dr Emila Gavrila 22 (Zrenjanin) | Samo imenik; nije provereno da li rade. |
| Dog-friendly lokali (oba grada) | Nijedna politika lokala nije potvrđena. |
| Šetači, pet taxi, treneri, dežurne službe 24/7 | Nisu nađeni pouzdani izvori. |

## Seed, `places` → `pois` i duplikati

- Mesta su ugrađeni katalog u aplikaciji (`PoiSeedData.allVerified` →
  `mockMapPlaces` → `mapPlacesProvider`), isto kao Niš i Kragujevac. Spajanje po
  id-ju: seed < korisnički `pois` < admin `places`, pa admin izmena istog id-ja
  zamenjuje seed bez duplog markera. **Ništa nije upisano u produkcionu bazu.**
- Kad admin potvrdi/izmeni seed mesto (Admin → mesta / izmena POI),
  `FirestorePlacesRepository.updatePlace` u jednom batch-u piše `places/{id}` i
  `pois/{id}` sa istim stabilnim id-jem (`zr-…`, `su-…`). Ručni upis u obe
  kolekcije nije potreban.
- `PlaceDuplicates` (`lib/features/map/domain/place_duplicates.dart`): duplikat =
  isti grad + isto normalizovano ime (bez dijakritike/ćirilice/interpunkcije) +
  ista normalizovana adresa ili pin na ≤ 75 m. Različite firme na istoj adresi
  i isto ime na drugoj adresi se NE spajaju. Primena: seed novih gradova
  (`PoiSeedData._cleanCitySeed`, uz odbacivanje loših koordinata) i upozorenje
  u admin „Dodaj mesto“ pre upisa.

## Pravila i indeksi

Nisu potrebna nova pravila ni indeksi: `cities`, `places`, `pois` već
prihvataju proizvoljan `cityId`; mapa čita cele kolekcije. Stare verzije
aplikacije ne poznaju `MapCity.zrenjanin/subotica` i takav `pois.city` čitaju
kao Novi Sad (prikazali bi ga u Novom Sadu) – zato admin mesta u novim gradovima
upisivati tek posle izdavanja nove verzije.
