# Nagrade preko servera (Cloud Functions)

Od 2026-10-22 poene za šetnje i izazove dodeljuje server, ne aplikacija.

## Kako radi
1. Aplikacija na „Završi šetnju“ samo snimi zapis šetnje: `users/{uid}/walks/{walkId}`
   (ruta sa vremenom i preciznošću, trajanje, oznake).
2. Funkcija `rewardWalk` (`functions/rewards.js`) se okida na novi zapis i:
   - ponovo računa pređeni put iz rute (klijentska kilometraža može biti najviše
     10 % veća od rute), proverava vreme (kraj ≤ 48 h ranije, ≤ 4 h trajanje),
     prosečnu brzinu (≤ 7 km/h) i korake (≤ 9 km/h);
   - odbija lažne oznake (`mock`, `suspicious`), preskromnu rutu, rutu sa gotovo
     konstantnom brzinom (sintetički signal) i **ponovljenu rutu** (otisak rute u
     `route_fingerprints`, i između naloga);
   - u jednoj transakciji piše evidenciju `reward_ledger/walk_{id}`, saldo
     `rewards/summary`, napredak dana/nedelje, i otisak rute; zatim naplaćuje
     aktivne izazove koje je napredak ispunio (`ch_{izazov}_{period}`);
   - upisuje ishod u `users/{uid}/reward_results/{walkId}` (status, razlog, poeni).
3. Aplikacija čeka taj ishod (do 25 s) i prikazuje ga; ako server kasni ili nema
   interneta, kaže da će nagrada stići.
4. Pravila (`firestore.rules`) više ne dozvoljavaju klijentu da piše poene,
   napredak ni evidenciju (osim kupovine kupona).

Funkcija je idempotentna: ista šetnja se nikad ne plaća dvaput (ni pri ponovnom
okidanju, ni ako je stariji klijent već platio).

## Redosled puštanja (deploy traži odobrenje)
1. `firebase deploy --only functions` – dodaje `rewardWalk` (ništa ne menja dok
   se ne promene pravila).
2. `firebase deploy --only firestore:rules` – klijent više ne piše poene.
   Stari klijenti: njihov upis poena je odbijen, ali zapis šetnje prolazi, pa
   server ipak plati (stara aplikacija javi „server ne prihvata nagrade“ iako je
   poen dodat).
3. Nova verzija aplikacije (čeka ishod servera).

## Testovi
- `cd functions && npm test` – logika (15 testova, bez emulatora).
- `firebase emulators:exec --only firestore --project demo-vauvau-fn "cd functions && node --test test/rewards_award.test.js"` – upisi u bazu (9 testova).
- `rules_test/rewards.rules.test.mjs` – klijent ne sme da piše poene.

## Troškovi (Blaze)
Projekat je na Blaze planu. Jedna šetnja = jedan poziv funkcije + oko 10 čitanja/
upisa dokumenata; mesečna besplatna kvota (2 mil. poziva funkcija, 50 000
čitanja i 20 000 upisa dnevno za Firestore) je daleko iznad toga za početni broj
korisnika. Upozorenje na potrošnju: vidi `docs/video_cuvanje.md` (Billing →
Budgets & alerts). Upozorenje samo šalje mejl, ne zaustavlja potrošnju.

## Šta server NE može
Ne dokazuje da je neko stvarno hodao: rutu koja izgleda prirodno i dolazi iz
originalne aplikacije može da napiše i skripta. Sledeći sloj je Firebase App
Check (Play Integrity / App Attest) – traži paket `firebase_app_check`.
