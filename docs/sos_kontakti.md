# SOS kontakti – izvori i ručna provera

Provereno: **20. 10. 2026.** Podaci u aplikaciji: `lib/features/support/domain/sos_contacts.dart`
(`SosContacts.byCity`, jedan unos = jedan kontakt sa `sourceUrl`). U aplikaciju je ušlo samo ono
što piše na zvaničnom sajtu grada, JKP-a ili same ambulante. „0–24“ (grupa „Dežurni veterinar 0–24“)
samo kad izvor to izričito kaže. Imenici (dezurniveterinar.rs/.com, PlanPlus, Feruvi, Google
kartice, Facebook) korišćeni su samo kao trag.

## U aplikaciji

| Grad | Grupa | Kontakt | Telefoni | Napomena (iz izvora) | Izvor |
|---|---|---|---|---|---|
| Novi Sad | 0–24 | Milenium Vet, Subotička 55 | 065 474 9212 | Dežurni veterinar 00–24; pon–pet 9–20, sub 10–13 | https://www.mileniumvet.rs/ |
| Novi Sad | Ambulante | NS VET, Branislava Borote 2 | 021 493 007, 063 590 192, 064 232 0136 | Pon–sub 8–20, ned 9–12; hitne/dežurstvo **20–24** | https://www.nsvet.rs/ |
| Novi Sad | Ambulante | Ambulanta za male životinje (JKP Zoohigijena i veterina), Futoški put 13 | 021 403 402 | – | https://zoohigijenans.co.rs/kontakt/ |
| Novi Sad | Zoohigijena | JKP Zoohigijena i veterina – prihvatilište, Put šajkaškog odreda bb | 021 640 3220 | Prijava povređene životinje u radno vreme; rad. dani 7:30–19, vikend 7:30–18 | https://zoohigijenans.co.rs/kontakt/ |
| Beograd | 0–24 | Vet Planet, Tošin bunar 128 | 011 7707 227, 065 3565 664 | Pon–ned 00–24 | https://vetplanet.rs/ |
| Beograd | 0–24 | Vet Urgent – VET klinika Sveti Vrači, Admirala Vukovića 75 | 063 342 235, 011 2461 383 | Dežurstva 00–24, klinika 9–20 | https://veturgent.rs/ |
| Beograd | Ambulante | Hitna pomoć za životinje (JKP Veterina Beograd), Bul. kralja Aleksandra 602 | 062 80 90 333 | Rad. dani 8–20, vikend 8–16 | https://www.veterinabeograd.rs/kontakt |
| Beograd | Ambulante | Veterinarska klinika za male životinje (JKP), Bul. despota Stefana 119 | 011 276 40 88 | Rad. dani 8–20, sub 10–14, ned 10–12 | https://www.veterinabeograd.rs/kontakt |
| Beograd | Zoohigijena | JKP Veterina Beograd – komunalna zoohigijena | 011 329 3099, 063 549 161 (noću) | 011…: rad. dani 7–20, sub 7–14, ned 7–12; 063…: rad. dani 20–7, sub od 14, ned od 12 | https://www.veterinabeograd.rs/komunalna-zoohigijena |
| Beograd | Zoohigijena | Prihvatilište Rakovica, Slavka Miljkovića bb | 011 715 8100, 062 412 436 | Info o životinjama 10–12 | https://www.veterinabeograd.rs/kontakt |
| Beograd | Ostalo | Izgubljene vlasničke životinje (JKP) | 011 276 43 66 lok. 115 | Rad. dani 7:30–15:30 | https://www.veterinabeograd.rs/kontakt |
| Niš | 0–24 | Vet Medica, Bulevar Mediana 5 | 064 170 64 70 | „Dežurni telefon 24/7“, vikend i praznici | https://vetmedica.rs/ |
| Niš | Ambulante | Veterinarska stanica Niš, Ivana Milutinovića 64 | 018 42 41 499, 063 41 85 42 (dežurni van radnog vremena) | Pon–pet 8–20, sub 8–14, ned 9–13 | https://veterinarskastanicanis.rs/kontakt/ |
| Niš | Zoohigijena | JKP Mediana – ZOO higijena | 064 850 99 81 | – | https://jkpmediana.rs/kontakt/ |
| Niš | Ostalo | JKP Mediana – kontakt centar | 0800 018 002, 018 25 01 25 | Besplatan poziv | https://jkpmediana.rs/kontakt/ |
| Kragujevac | 0–24 | Kragujvet Pet, Kneza Miloša 1A | 063 303 476, 034 258 080 | „Za hitne intervencije zvati od 0 do 24h na 063 303 476“; rad. dani 8–20, sub 9–15 | https://veterinarkragujevac.rs/kontakt/ |
| Kragujevac | 0–24 | Medikavet, Hadži Milentijeva 3 | 064 12 68 424 (00–24), 034 355 325 (08–20) | – | https://medikavet.rs/ |
| Kragujevac | Zoohigijena | JKP Šumadija – služba zoohigijene | 034 350 054 | Hvatanje i zbrinjavanje pasa lutalica | https://jkpsumadija.rs/sr/kontakti.html |
| Kragujevac | Ostalo | JKP Šumadija – besplatan poziv | 0800 350 034 | – | https://jkpsumadija.rs/sr/kontakti.html |
| Zrenjanin | Ambulante | Veterina Dimić, Žarka Zrenjanina 78 | 023 567 021, 064 66 28 977, 064 64 65 423 | Rad. dani 8–19, sub 9–14, ned 10–13; dežurna služba **19–24** | https://vetdimic.com/?page_id=7 |
| Zrenjanin | Zoohigijena | Zoohigijenska služba JKP „Čistoća i zelenilo“, prihvatilište dr Tihomira Ostojića bb | 064 811 68 78 | Dežurni telefon; rad. dani 7–22, sub/ned 8–15 | https://www.jkpciz.co.rs/index.php/usluge-zoohigijene |
| Subotica | Ambulante | Panvet, Koste Racina 5 | 024 571 920, 069 571 9200 (hitne intervencije) | – | http://www.panvet.info/kontakt |
| Subotica | Ambulante | Veterinarska stanica Veterinar, Trg Paje Kujundžića 2/a | 024 671 060, 024 539 229, 060 671 0600 | Pon–pet 7–19 | https://www.veterinarsubotica.rs/kontakt |
| Subotica | Zoohigijena | Prihvatilište za napuštene pse i mačke (JKP „Čistoća i zelenilo“), 9. Nova 249 (Ganjo šor 137) | 024 670 595, 062 248 915 | – | https://www.cistoca-su.co.rs/kontakt/ |
| Subotica | Ostalo | JKP „Čistoća i zelenilo“ – besplatna info linija | 0800 151 152 | – | https://www.cistoca-su.co.rs/kontakt/ |

Zrenjanin i Subotica nemaju zvanično potvrđenog veterinara 0–24 → ekran prikazuje napomenu
umesto grupe „Dežurni veterinar 0–24“.

## Zastareli / ispravljeni postojeći kontakti

- **NS VET (Novi Sad)** – aplikacija je pisala „NS VET (00–24h)“. Zvanični sajt kaže: pon–sub 8–20,
  ned 9–12, hitne intervencije/dežurstvo u ambulanti **20–24**. Prebačen u „Veterinarske ambulante“
  sa tačnim vremenom; dodat treći broj sa sajta (064 232 0136). Brojevi 021 493 007 i 063 590 192
  i dalje važe.
- „Ambulanta Futoški put“ (021 403 402) – broj važi; to je Ambulanta za male životinje JKP
  Zoohigijena i veterina (Futoški put 13), sada pod tim imenom.
- Ostali postojeći (Milenium Vet, Vet Planet, Vet Urgent, JKP Veterina Beograd, JKP Zoohigijena
  Novi Sad) – brojevi potvrđeni na zvaničnim sajtovima; dodate adrese.

## Za ručnu proveru (nije u aplikaciji)

| Grad | Kandidat | Šta je nađeno | Zašto nije upisano |
|---|---|---|---|
| Zrenjanin | Ultimate Vet, 064 20 22 811 (i 023 603 736) | dezurniveterinar.rs: „non-stop 00–24“, Cara Dušana 14a; Facebook i oglas iz 2020 (ILoveZrenjanin): Pančevačka 38, „nakon radnog vremena telefoni su dostupni samo za hitne intervencije“ | Zvanični sajt ultimatevet.rs nije dostupan; adrese se razlikuju; 0–24 samo u imeniku. Najbolji kandidat za 0–24 u Zrenjaninu – pozvati i proveriti adresu. |
| Zrenjanin | Veterinarska ambulanta Canis | Imenik.rs: „za hitne slučajeve dežurni veterinar“ | Samo imenik, bez telefona/vremena. |
| Subotica | Panvet – drugi hitni broj 065/9751 920 | Na zvaničnom sajtu uz 069/571 9200; OSM navodi 065 9571920 | Verovatno greška u kucanju na jednom od izvora. Google isečak sa panvet.info pominje „hitni slučajevi 19–24, 365 dana“, ali toga nema na trenutnoj strani. |
| Subotica | Veterinarska stanica Subotica DOO, Segedinski put 88 (024 547 858) | Google kartica: kategorija „Hitna veterinarska služba“ | Nema zvaničnog izvora za hitni rad. |
| Subotica | Ambulanta u Lazara Bačića 6 | subotica.biz: „vikendom hitne intervencije, dežurstvo 00–24h“ | Samo poslovni adresar; naziv/telefon nisu provereni. |
| Subotica | Veterinarska ambulanta Viva, Pačirski put 21 (060 1304878) | Seed mapa (zvanični sajt) | Nema podataka o hitnom radu – može se dodati u „Ambulante“ ako želite. |
| Niš | Vet Impuls, Josifa Pančića 4 (018 523 230, dežurni 062 517 528) | zooplanet.org.rs „Korisni telefoni“ + PlanPlus | Nije potvrđeno na sajtu ambulante. |
| Niš | „Veterinarska stanica Niš (24h)“ | zooplanet.org.rs | Zvanični sajt NE kaže 24h (radno vreme + dežurni broj van radnog vremena) → u aplikaciji bez oznake 0–24. |
| Niš | Adresa prihvatilišta JKP Mediana | Imenici: „Gradska deponija“ | Zvanični sajt daje samo telefon. |
| Kragujevac | Medicus Vet, Bregalnička 8 (064 2789 671) | dezurniveterinar.rs: „non-stop 00–24“ | Samo imenik. |
| Kragujevac | Dog-Ma Vet (nedeljom hitni slučajevi 065 310 79 78) | Instagram profil ambulante | Nije zvanični sajt; proveriti. |
| Kragujevac | Adresa prihvatilišta JKP Šumadija; privatni azil „Vučjak“ | Mediji / strani sajtovi | Nema zvaničnog izvora sa adresom/telefonom. |
| Svi | Nacionalni brojevi (192 policija – zlostavljanje životinja, veterinarska inspekcija) | – | Nisu postojali u SOS-u; nisu dodati bez odluke i zvaničnog izvora. |

## Kako dodati/izmeniti kontakt

1. Proveriti na zvaničnom sajtu, upisati u `SosContacts.byCity` (grad iz `SerbiaLocations`) sa
   `sourceUrl`, a `SosContacts.checkedOn` pomeriti na datum provere.
2. `SosContactKind.emergencyVet` samo kad izvor kaže 0–24 (test `sos_contacts_test.dart` traži
   „0–24“/„00–24“/„24/7“ u napomeni).
3. Telefon pisati kao na izvoru (cifre, razmaci, `/`, `-`); test proverava da je ispravan `tel:` URI.
