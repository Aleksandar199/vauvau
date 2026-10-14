# VauVau — Play launch checklist

Use this before Production. Check boxes as you complete them.

## Already in the app (verify once on release AAB)

- [x] Signed release AAB builds (`android/key.properties` + upload keystore)
- [x] Privacy policy live: https://vauvau-3195a.web.app/privacy
- [x] Terms of service live: https://vauvau-3195a.web.app/terms
- [x] In-app account deletion (Profile → delete account) + email fallback
- [x] Crashlytics enabled (release build reports non-fatals / crashes)
- [x] Firestore/Storage ownership rules deployed
- [x] Chat message page size capped; room listeners detached when leaving chat
- [x] Discover feed: `orderBy(createdAt)` + `limit(15)` + infinite scroll
- [x] Map live walkers: `limit(50)` + subscribe only on Map tab
- [x] R8 minify + shrink resources enabled for release

## Firebase / backend

- [x] Release SHA-1 and SHA-256 added in Firebase (app `com.vauvau.app` / VauVau Release)
- [x] Debug SHA-1/SHA-256 also registered on `com.vauvau.app` (local Google Sign-In)
- [x] `google-services.json` refreshed (Android OAuth clients for upload + debug certs)
- [x] Firestore rules deployed: `.\firebase.cmd deploy --only firestore:rules`
- [x] Storage rules deployed: `.\firebase.cmd deploy --only storage`
- [x] Firestore indexes deployed: `.\firebase.cmd deploy --only firestore:indexes`
- [ ] Confirm indexes are **Enabled** in Firebase Console → Firestore → Indexes (may take a few minutes after deploy)
- [x] Hosting still serves `/privacy` and `/terms` after any hosting change
- [ ] (Optional later) Cloud Functions for FCM send
- [ ] (Optional later) App Check

### Release fingerprints (upload keystore)

| Type   | Hash |
|--------|------|
| SHA-1  | `AC:C3:C6:71:9A:29:8B:8D:B8:78:2F:86:F6:0F:67:95:B5:24:4F:85` |
| SHA-256| `7F:67:88:DF:AB:A9:AC:CC:A0:C1:F9:E2:6D:BD:66:EB:A1:84:8C:2C:37:CB:C7:62:FE:0B:1B:BB:30:04:97:70` |

## Play Console — store & policy

- [ ] App name, short description, full description (SR / EN as needed)
- [ ] Icon 512×512, feature graphic, phone screenshots
- [ ] Privacy policy URL + Terms URL linked in Console
- [ ] Data safety form completed (auth, photos, location, chat, Crashlytics, FCM token, …)
- [ ] Account deletion path declared (in-app + email)
- [ ] Content rating questionnaire
- [ ] Target audience / news apps / COVID declarations as prompted
- [ ] Sensitive permissions justification (location + foreground service for walks)
- [ ] Contact email for store listing

## Build & upload

- [x] `pubspec.yaml` version `1.0.0+4`
- [x] `flutter build appbundle --release` succeeds with R8
- [x] AAB artifact: `release/vauvau-1.0.0+4-release.aab` (also `build/app/outputs/bundle/release/app-release.aab`)
- [ ] Upload AAB to **Internal testing** in Play Console (manual — no Play API credentials in repo)
- [ ] Target SDK meets current Play requirement (API 36 for new apps as of 2026)
- [ ] Upload keystore backed up offline (password + `.jks` / `.keystore`)

### Internal testing upload (manual)

1. Open [Play Console](https://play.google.com/console) → VauVau → **Testing → Internal testing**.
2. Create a new release → upload `release/vauvau-1.0.0+4-release.aab`.
3. Add yourself (and testers) by email → save → roll out.
4. Install from the testers link and run the smoke list below.

## Smoke test on Internal / Closed track (release build)

- [ ] Email/password sign-up + login
- [ ] Google Sign-In
- [ ] Dog onboarding + photo upload
- [ ] Discover swipe / match
- [ ] Chat send + receive
- [ ] Map: start/pause/end walk, see other walkers (if any)
- [ ] Moments create + like/comment
- [ ] Health reminder local notification (optional)
- [ ] Delete account end-to-end
- [ ] Force a test crash → appears in Crashlytics

## Go live

- [ ] Closed testing with 3–5 real users (no blocker bugs)
- [ ] Promote to Production (or open testing → production)
- [ ] Monitor Crashlytics + Play ANRs for 48h after launch

## Deferred (not required for first publish)

- Cloud Functions → real push for chat/match while app backgrounded
- Firebase App Check
- Custom domain for legal pages
- iOS App Store track
