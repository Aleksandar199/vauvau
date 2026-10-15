# VauVau – kompletan tehnički pregled

> Stanje koda: lokalna radna kopija `C:\Users\ljz2mv\Desktop\vauvau`, grana `main` (prati `origin/master`), poslednji commit `56f3fa3`. Datum pregleda: 15. oktobar 2026.
> Pregledani su svi fajlovi projekta osim generisanih i binarnih (`build/`, `.dart_tool/`, `docs/reels/ffmpeg/`, slike/ikone). Sekcije 2, 4, 6, 7 i delovi 5 i 11 su organizovani po modulima. Izraz „van obuhvata/slice-a“ u tim delovima znači da je stvar opisana u drugom modulu istog dokumenta.
> Sve što nije moglo da se utvrdi iz koda označeno je kao **nejasno / nije provereno**. Tajni ključevi nisu prikazani.
> Postoje nekomitovane izmene (25 fajlova, `git status`): multiline unos u čet, zvuk dolazne poruke, popravke brojača nepročitanih, avatar → profil, zakazane šetnje, full-screen slike u četu i prateći testovi.

---

## 1. OPŠTE INFORMACIJE

### Naziv i svrha
- **Naziv:** VauVau (paket `vauvau`, `pubspec.yaml`: „A mobile app for dog owners to discover nearby dogs and find walking buddies.“). Verzija `1.0.0+7`.
- **Svrha:** društvena mreža za vlasnike pasa u Srbiji (početno Novi Sad, zatim Beograd, Niš, Kragujevac):
  - otkrivanje pasa u blizini, lajk / super lajk i meč;
  - 1:1 čet sa pozivom na šetnju, lokacijom i slikama;
  - grupe i događaji sa grupnim četom;
  - mapa mesta za pse (parkovi, veterinari, pet shopovi, hoteli) sa praćenjem šetnje i prikazom „ko je u šetnji“;
  - priče (Moments, 24h) i istaknute priče;
  - izgubljeni i pronađeni psi, udomljavanje;
  - zdravstveni karton i podsetnici, SOS kontakti, saveti i pravila;
  - prijave sadržaja i blokiranje, admin panel.
- **UI jezik:** srpski (latinica) podrazumevano, uz delimičan engleski (`AppLanguage`: sr/en preko sopstvenog `L10n`; mnogi stringovi nisu prevedeni – vidi sekciju 11).

### Ciljne platforme
| Platforma | Stanje |
|---|---|
| **Android** | Primarna. `applicationId com.vauvau.app`, release potpisivanje, R8. Postoji AAB `1.0.0+4` u lokalnom `release/` (gitignored). |
| **iOS** | Konfigurisan delimično: bundle id je šablonski `com.example.vauvau`, nema URL scheme za Google Sign-In, nema push entitlements → **nije spremno za App Store**. |
| **Web** | Radi uz ograničenja: koristi **Android** Firebase opcije, push je isključen (`NoopPushNotificationGateway`). Firebase Hosting služi samo pravne stranice, ne web build. |
| Windows / macOS / Linux | Neizmenjen `flutter create` šablon (`com.example`). Linux nema Firebase pluginove; macOS nema `network.client` entitlement. **Nije ciljna platforma u praksi.** |

### Tehnologije i verzije (lokalno okruženje)
- Flutter **3.44.1** (stable, rev. `924134a44c`), Dart **3.12.1** (`environment.sdk: ^3.12.1`).
- State management: **flutter_riverpod 3.4.3** (Notifier / NotifierProvider / StreamProvider / Provider.family; bez code-gen-a).
- Backend: **Firebase**, projekat `vauvau-3195a`: Auth, Cloud Firestore, Storage, Messaging, Crashlytics, Hosting. **Nema Cloud Functions.**
- Mape: `flutter_map` + OpenStreetMap tile-ovi (nema Google Maps ključa).
- Android: AGP 9.0.1, Gradle 9.1.0, Kotlin plugin 2.3.20, Java 17 + desugaring; `compileSdk`/`targetSdk`/`minSdk` dolaze iz Flutter SDK-a (lokalno 36/36/24).
- iOS: deployment target 13.0, Swift 5, pluginovi preko Swift Package Manager-a (nema Podfile-a).

### Zavisnosti (`pubspec.yaml` → razrešena verzija iz `pubspec.lock`)
| Paket | Ograničenje | Razrešeno | Čemu služi u projektu |
|---|---|---|---|
| flutter, flutter_localizations | sdk | – | Framework; Material/Cupertino lokalizacije (sr/en) |
| intl | any | 0.20.2 | Formatiranje datuma/vremena |
| cupertino_icons | ^1.0.8 | 1.0.9 | iOS ikone (šablon) |
| web | ^1.1.0 | 1.1.1 | JS interop za web prikaz Firebase slika (`firebase_web_image_web.dart`) |
| firebase_core | ^4.15.0 | 4.15.0 | Inicijalizacija Firebase-a |
| firebase_auth | ^6.7.0 | 6.7.0 | Prijava email/lozinka i Google |
| google_sign_in | ^6.2.1 | 6.3.0 | Google nalog (implementirano, ali UI dugme je sakriveno) |
| flutter_riverpod | ^3.4.3 | 3.4.3 | State management / DI |
| cloud_firestore | ^6.10.0 | 6.10.0 | Glavna baza (offline persistencija uključena, keš neograničen) |
| http | ^1.5.0 | 1.6.0 | HTTP pozivi (geokodiranje adresa – `address_geocoder.dart`, Nominatim) |
| image_picker | ^1.2.4 | 1.2.4 | Galerija/kamera za slike pasa, četa, priča, oglasa |
| path_provider | ^2.1.5 | 2.1.6 | Lokalni fajlovi (koristi ga neiskorišćen `dog_photo_persist_io.dart`) |
| flutter_map | ^8.2.2 | 8.3.2 | Mapa (OSM) |
| flutter_map_marker_cluster | ^8.2.2 | 8.2.2 | Klasterovanje markera na mapi |
| latlong2 | ^0.9.1 | 0.9.1 | Koordinate i udaljenosti |
| geolocator | ^14.0.2 | 14.0.3 | GPS lokacija, praćenje šetnje (Android foreground servis) |
| firebase_messaging | ^16.0.4 | 16.7.0 | FCM token, foreground/opened handleri |
| url_launcher | ^6.3.2 | 6.3.2 | Telefon, SMS, email, mape, pravne stranice, društvene mreže |
| shared_preferences | ^2.5.3 | 2.5.5 | Podešavanja aplikacije, flag hitnog popupa |
| flutter_local_notifications | ^22.3.1 | 22.3.1 | Lokalne notifikacije (kanali `vauvau_alerts`, `vauvau_health`), zakazani podsetnici |
| timezone | ^0.11.1 | 0.11.1 | Zakazivanje podsetnika u lokalnoj zoni |
| flutter_timezone | ^5.1.0 | 5.1.0 | Čitanje vremenske zone uređaja |
| cached_network_image | ^3.4.1 | 3.4.1 | Keširanje slika sa mreže |
| firebase_storage | ^13.6.0 | 13.6.0 | Upload/brisanje slika |
| firebase_crashlytics | ^5.4.0 | 5.4.0 | Prijava padova i grešaka |
| audioplayers | ^6.8.1 | 6.8.1 | Zvuk dolazne poruke (`assets/sounds/message.wav`) – **nekomitovano** |
| **dev:** flutter_test | sdk | – | Testovi |
| **dev:** flutter_lints | ^6.0.0 | 6.0.0 | Lint pravila (`analysis_options.yaml` = podrazumevani skup) |
| **dev:** flutter_native_splash | ^2.4.6 | 2.4.8 | Generisanje native splash-a (boja `#0F172A`) |
| **dev:** flutter_launcher_icons | ^0.14.4 | 0.14.4 | Generisanje ikona iz `assets/images/vauvau_logo.png` |
| **dev:** fake_cloud_firestore | ^4.3.0 | 4.3.0 | Lažni Firestore za unit testove – **nekomitovano** |

Asseti: `assets/images/` (ceo folder – uključuje i ~7 MB nekorišćenih starih splash slika) i `assets/sounds/`. Nema custom fontova.

---
## 2. STRUKTURA PROJEKTA
Stablo ispod je generisano iz `git ls-files` + nepraćenih (ne-ignorisanih) fajlova. Izostavljeni su `build/`, `.dart_tool/`, `docs/reels/ffmpeg/` i ovaj dokument. Gitignored lokalni fajlovi (npr. `android/key.properties`, `release/`, `firebase.exe`) nisu u stablu, ali su opisani u sekciji 10 / 11.
Ukupno fajlova u stablu: 592.
```text
.firebaserc
.gitignore
.metadata
analysis_options.yaml
android/
  .gitignore
  app/
    build.gradle.kts
    google-services.json
    proguard-rules.pro
    src/
      debug/
        AndroidManifest.xml
      main/
        AndroidManifest.xml
        kotlin/
          com/
            vauvau/
              app/
                MainActivity.kt
        res/
          drawable/
            background.png
            launch_background.xml
            splash_icon_empty.xml
          drawable-hdpi/
            ic_launcher_foreground.png
          drawable-mdpi/
            ic_launcher_foreground.png
          drawable-v21/
            background.png
            launch_background.xml
          drawable-xhdpi/
            ic_launcher_foreground.png
          drawable-xxhdpi/
            ic_launcher_foreground.png
          drawable-xxxhdpi/
            ic_launcher_foreground.png
          mipmap-anydpi-v26/
            ic_launcher.xml
          mipmap-hdpi/
            ic_launcher.png
          mipmap-mdpi/
            ic_launcher.png
          mipmap-xhdpi/
            ic_launcher.png
          mipmap-xxhdpi/
            ic_launcher.png
          mipmap-xxxhdpi/
            ic_launcher.png
          values/
            colors.xml
            styles.xml
          values-night/
            styles.xml
          values-night-v31/
            styles.xml
          values-v31/
            styles.xml
      profile/
        AndroidManifest.xml
  build.gradle.kts
  gradle.properties
  gradle/
    wrapper/
      gradle-wrapper.properties
  key.properties.example
  settings.gradle.kts
assets/
  images/
    .gitkeep
    vauvau_logo.png
    vauvau_splash.png
    vauvau_splash_old.png
    vauvau_splash_old1.png
    vauvau_splash_old2.jpg
    vauvau_splash11.png
    vauvau_splash3.png
  sounds/
    message.wav
docs/
  play-launch-checklist.md
  privacy-policy.html
  reels/
    01_hook.jpg
    02_value.jpg
    03_features.jpg
    04_cta.jpg
    CAPTION.txt
    vauvau-reels-najava.mp4
    vauvau-reels-preview.html
  terms-of-service.html
firebase.cmd
firebase.json
firestore.indexes.json
firestore.rules
Gist
ios/
  .gitignore
  Flutter/
    AppFrameworkInfo.plist
    Debug.xcconfig
    Release.xcconfig
  Runner.xcodeproj/
    project.pbxproj
    project.xcworkspace/
      contents.xcworkspacedata
      xcshareddata/
        IDEWorkspaceChecks.plist
        WorkspaceSettings.xcsettings
    xcshareddata/
      xcschemes/
        Runner.xcscheme
  Runner.xcworkspace/
    contents.xcworkspacedata
    xcshareddata/
      IDEWorkspaceChecks.plist
      WorkspaceSettings.xcsettings
  Runner/
    AppDelegate.swift
    Assets.xcassets/
      AppIcon.appiconset/
        Contents.json
        Icon-App-1024x1024@1x.png
        Icon-App-20x20@1x.png
        Icon-App-20x20@2x.png
        Icon-App-20x20@3x.png
        Icon-App-29x29@1x.png
        Icon-App-29x29@2x.png
        Icon-App-29x29@3x.png
        Icon-App-40x40@1x.png
        Icon-App-40x40@2x.png
        Icon-App-40x40@3x.png
        Icon-App-50x50@1x.png
        Icon-App-50x50@2x.png
        Icon-App-57x57@1x.png
        Icon-App-57x57@2x.png
        Icon-App-60x60@2x.png
        Icon-App-60x60@3x.png
        Icon-App-72x72@1x.png
        Icon-App-72x72@2x.png
        Icon-App-76x76@1x.png
        Icon-App-76x76@2x.png
        Icon-App-83.5x83.5@2x.png
      LaunchBackground.imageset/
        background.png
        Contents.json
      LaunchImage.imageset/
        Contents.json
        LaunchImage.png
        LaunchImage@2x.png
        LaunchImage@3x.png
        README.md
    Base.lproj/
      LaunchScreen.storyboard
      Main.storyboard
    GoogleService-Info.plist
    Info.plist
    Runner-Bridging-Header.h
    SceneDelegate.swift
  RunnerTests/
    RunnerTests.swift
lib/
  app/
    app.dart
    firebase_init_error_app.dart
    routes.dart
  core/
    constants/
      app_strings.dart
      dog_breeds.dart
      serbia_locations.dart
    crash/
      crash_reporting.dart
    firebase/
      firebase_status.dart
      firestore_auth_guard.dart
    geo/
      firestore_geo.dart
      geo.dart
    images/
      app_image_provider.dart
      app_image_provider_io.dart
      app_image_provider_web.dart
      dog_image.dart
      dog_photo_urls.dart
      fallback_image_helper.dart
      firebase_web_image.dart
      firebase_web_image_stub.dart
      firebase_web_image_web.dart
      image_upload_service.dart
    l10n/
      app_language.dart
      l10n.dart
    network/
      network_failure.dart
    services/
      message_sound_player.dart
      notification_service.dart
    theme/
      app_cards.dart
      app_colors.dart
      app_theme.dart
      app_theme_preference.dart
    utils/
      content_validation_service.dart
      external_link_launcher.dart
    widgets/
      brand_mark.dart
      breed_field.dart
      city_neighborhood_fields.dart
      comment_like_button.dart
      feed_state.dart
      illustration_placeholder.dart
      primary_button.dart
      ui_bits.dart
  features/
    admin/
      data/
        firestore_admin_repository.dart
        local_admin_repository.dart
      domain/
        admin_models.dart
        admin_repository.dart
      presentation/
        admin_controller.dart
        admin_dashboard_screen.dart
        admin_strings.dart
        tabs/
          admin_feedback_tab.dart
          admin_groups_tab.dart
          admin_moments_tab.dart
          admin_reports_tab.dart
          admin_users_tab.dart
        widgets/
          admin_confirm_dialog.dart
          admin_edit_poi_dialog.dart
    adoption/
      data/
        firestore_adoption_repository.dart
        local_adoption_repository.dart
        mock_adoption_dogs.dart
      domain/
        adoption_dog.dart
        adoption_repository.dart
      presentation/
        adoption_controller.dart
        adoption_strings.dart
        phone_launcher.dart
        screens/
          adoption_detail_screen.dart
          adoption_screen.dart
        widgets/
          add_adoption_dog_sheet.dart
          adoption_card.dart
    auth/
      data/
        account_deletion_service.dart
        auth_repository_impl.dart
        firebase_auth_datasource.dart
        local_auth_repository.dart
        user_document.dart
      domain/
        app_user.dart
        auth_exception.dart
        auth_repository.dart
        user_dog_profile.dart
      presentation/
        auth_controller.dart
        auth_gate.dart
        auth_providers.dart
        auth_screen.dart
        forgot_password_dialog.dart
        login_screen.dart
        register_screen.dart
        widgets/
          auth_text_field.dart
          google_sign_in_button.dart
    chat/
      data/
        firestore_chat_repository.dart
        local_chat_repository.dart
        mock_conversations.dart
        walk_locations.dart
      domain/
        chat_conversation.dart
        chat_message.dart
        chat_repository.dart
        chat_room.dart
        chat_time.dart
        scheduled_walk.dart
      presentation/
        chat_detail_screen.dart
        chat_inbox.dart
        chat_list_screen.dart
        chat_screen.dart
        chat_strings.dart
        incoming_likes.dart
        incoming_message_sound.dart
        matches_screen.dart
        schedule_walk_sheet.dart
        screens/
          chats_screen.dart
        widgets/
          chat_ui.dart
          dog_avatar.dart
          location_choice_chip.dart
          location_picker_sheet.dart
          location_pin_bubble.dart
          message_bubble.dart
          message_reply.dart
          scheduled_walks_banner.dart
          walk_invite_card.dart
    discover/
      data/
        dog_profile_mapper.dart
        firestore_discover_repository.dart
        load_discover_profile.dart
        local_discover_repository.dart
        mock_discover_profiles.dart
      domain/
        compatibility.dart
        discover_profile.dart
        discover_repository.dart
        geo_query.dart
      presentation/
        discover_controller.dart
        discover_image.dart
        discover_screen.dart
        discover_strings.dart
        widgets/
          compatibility_card.dart
          directory_cards.dart
          discover_app_bar.dart
          discover_dog_photo.dart
          discover_empty_state.dart
          discover_filter_chip.dart
          discover_filters_bottom_sheet.dart
          discover_search_sheet.dart
          dog_photo_gallery.dart
          match_dialog.dart
          swipe_dog_card.dart
    dogs/
      data/
        dog_photo_persist.dart
        dog_photo_persist_io.dart
        dog_photo_persist_web.dart
        dog_photo_storage.dart
        dogs_repository_impl.dart
        firestore_health_repository.dart
        firestore_reminder_repository.dart
        local_dogs_repository.dart
        local_health_repository.dart
        local_reminder_repository.dart
      domain/
        dog.dart
        dog_area.dart
        dog_draft.dart
        dog_enums.dart
        dog_preference_tags.dart
        dog_reminder.dart
        dogs_exception.dart
        dogs_repository.dart
        health_record.dart
        health_repository.dart
        reminder_repository.dart
        reminder_schedule.dart
      presentation/
        dog_providers.dart
        health/
          add_reminder_sheet.dart
          dog_health_tab.dart
          health_card_screen.dart
          health_controller.dart
          health_record_sheet.dart
          health_strings.dart
          reminder_controller.dart
          reminder_form_sheet.dart
          reminder_strings.dart
          reminders_screen.dart
        onboarding/
          dog_onboarding_controller.dart
          dog_onboarding_screen.dart
          option_chips.dart
          steps/
            area_step.dart
            basics_step.dart
            personality_step.dart
            photos_step.dart
        widgets/
          preference_chip_group.dart
    events/
      data/
        firestore_events_repository.dart
        local_events_repository.dart
        seed_events.dart
      domain/
        event_model.dart
        events_repository.dart
      presentation/
        create_event_screen.dart
        events_controller.dart
        events_screen.dart
        events_strings.dart
        widgets/
          event_card.dart
          events_promo_banner.dart
    groups/
      data/
        firestore_groups_repository.dart
        local_groups_repository.dart
        seed_breed_groups.dart
      domain/
        groups_models.dart
      presentation/
        group_chat_screen.dart
        group_unread_alerts.dart
        groups_controller.dart
        groups_list_screen.dart
        groups_strings.dart
        widgets/
          group_card.dart
    home/
      domain/
        app_drawer_catalog.dart
      presentation/
        home_drawer.dart
        home_shell_screen.dart
        home_tab.dart
    legal/
      domain/
        legal_urls.dart
      presentation/
        legal_consent_text.dart
        legal_document_bodies.dart
        legal_document_screen.dart
        legal_strings.dart
    location/
      data/
        geolocator_location_client.dart
      domain/
        location_access.dart
        location_client.dart
        user_location.dart
      presentation/
        home_city_provider.dart
        location_controller.dart
        location_disclosure.dart
        location_strings.dart
    lost_dogs/
      data/
        firestore_lost_dog_repository.dart
        local_lost_dog_repository.dart
        lost_dog_popup_store.dart
      domain/
        lost_dog.dart
        lost_dog_matcher.dart
        lost_dog_repository.dart
      presentation/
        lost_dog_actions.dart
        lost_dog_emergency_host.dart
        lost_dog_strings.dart
        lost_dogs_controller.dart
        lost_dogs_screen.dart
        report_lost_dog_sheet.dart
    map/
      data/
        address_geocoder.dart
        belgrade_dog_places_seed.dart
        cities_repository.dart
        firestore_poi_repository.dart
        firestore_walk_presence_repository.dart
        kragujevac_dog_places_seed.dart
        local_walk_presence_repository.dart
        mock_map_data.dart
        nis_dog_places_seed.dart
        places_repository.dart
        poi_seed_data.dart
        walk_history_repository.dart
      domain/
        city_model.dart
        map_city.dart
        map_place.dart
        map_place_type.dart
        models/
          poi_model.dart
        poi_repository.dart
        walk_presence_repository.dart
        walk_record.dart
        walk_session.dart
        walking_dog_pin.dart
      presentation/
        add_place_screen.dart
        cities_controller.dart
        map_screen.dart
        map_strings.dart
        maps_launcher.dart
        poi_report_controller.dart
        user_poi_controller.dart
        walk_controller.dart
        walk_history_controller.dart
        widgets/
          add_poi_sheet.dart
          city_picker_sheet.dart
          mock_map_canvas.dart
          osm_tile_layer.dart
          place_sheet.dart
          walk_history_sheet.dart
          walk_stats_panel.dart
          walker_sheet.dart
    moderation/
      data/
        firestore_blocked_users_repository.dart
        firestore_report_repository.dart
        local_blocked_users_repository.dart
        local_report_repository.dart
      domain/
        blocked_users_repository.dart
        content_report.dart
      presentation/
        block_controller.dart
        moderation_strings.dart
        report_controller.dart
        report_sheet.dart
        safety_menu.dart
    moments/
      data/
        firestore_highlights_repository.dart
        firestore_moments_repository.dart
        local_highlights_repository.dart
        local_moments_repository.dart
        seed_moments.dart
      domain/
        highlights_repository.dart
        moment_model.dart
        moments_repository.dart
        story_highlight.dart
      presentation/
        create_moment_sheet.dart
        highlight_sheets.dart
        moments_controller.dart
        moments_screen.dart
        moments_strings.dart
        pointer_safe.dart
        stories_controller.dart
        story_viewer.dart
        widgets/
          moment_comments_sheet.dart
          story_widgets.dart
    notifications/
      data/
        mock_notifications.dart
        push_notification_gateway.dart
        push_platform.dart
      domain/
        app_notification.dart
        push_payload.dart
      presentation/
        notification_controller.dart
        notification_routing.dart
        notification_screen.dart
        notification_strings.dart
        push_bootstrap.dart
        push_controller.dart
        push_navigation.dart
    profile/
      data/
        app_settings_store.dart
      domain/
        app_settings.dart
        matching_filters.dart
        user_profile.dart
      presentation/
        delete_account_action.dart
        edit_owner_profile_screen.dart
        edit_profile_screen.dart
        matching_filters_sheet.dart
        profile_controller.dart
        profile_screen.dart
        profile_strings.dart
        profile_system_sheet.dart
        settings_screen.dart
        sign_out_action.dart
        widgets/
          profile_ui.dart
    splash/
      presentation/
        screens/
          splash_screen.dart
        widgets/
          splash_clouds.dart
          splash_mascot.dart
    support/
      data/
        firestore_support_repository.dart
        local_support_repository.dart
      domain/
        admin_feedback.dart
        official_contacts.dart
        support_repository.dart
      presentation/
        about_app_dialog.dart
        rules_and_support_screen.dart
        rules_content.dart
        rules_tab.dart
        sos_tab.dart
        support_content.dart
        support_controller.dart
        support_strings.dart
        tips_content.dart
        tips_tab.dart
        widgets/
          admin_feedback_form.dart
          official_contact_links.dart
          support_guide_card.dart
          tip_article_card.dart
  firebase_options.dart
  main.dart
  services/
    storage_service.dart
linux/
  .gitignore
  CMakeLists.txt
  flutter/
    CMakeLists.txt
    generated_plugin_registrant.cc
    generated_plugin_registrant.h
    generated_plugins.cmake
  runner/
    CMakeLists.txt
    main.cc
    my_application.cc
    my_application.h
macos/
  .gitignore
  Flutter/
    Flutter-Debug.xcconfig
    Flutter-Release.xcconfig
    GeneratedPluginRegistrant.swift
  Runner.xcodeproj/
    project.pbxproj
    project.xcworkspace/
      xcshareddata/
        IDEWorkspaceChecks.plist
    xcshareddata/
      xcschemes/
        Runner.xcscheme
  Runner.xcworkspace/
    contents.xcworkspacedata
    xcshareddata/
      IDEWorkspaceChecks.plist
  Runner/
    AppDelegate.swift
    Assets.xcassets/
      AppIcon.appiconset/
        app_icon_1024.png
        app_icon_128.png
        app_icon_16.png
        app_icon_256.png
        app_icon_32.png
        app_icon_512.png
        app_icon_64.png
        Contents.json
    Base.lproj/
      MainMenu.xib
    Configs/
      AppInfo.xcconfig
      Debug.xcconfig
      Release.xcconfig
      Warnings.xcconfig
    DebugProfile.entitlements
    Info.plist
    MainFlutterWindow.swift
    Release.entitlements
  RunnerTests/
    RunnerTests.swift
public/
  index.html
  privacy/
    index.html
  terms/
    index.html
pubspec.lock
pubspec.yaml
README.md
scripts/
  build_release.ps1
  build_release.sh
storage.rules
storage-cors.json
test/
  admin_test.dart
  adoption_test.dart
  chat_test.dart
  chat_unread_test.dart
  compatibility_test.dart
  content_validation_test.dart
  discover_feed_order_test.dart
  discover_test.dart
  dog_health_test.dart
  dog_photo_gallery_test.dart
  dog_reminder_test.dart
  events_city_test.dart
  events_test.dart
  fakes/
    fake_auth_repository.dart
    fake_dogs_repository.dart
  fallback_image_helper_test.dart
  group_inbox_test.dart
  groups_test.dart
  home_city_test.dart
  incoming_message_sound_test.dart
  kragujevac_city_test.dart
  location_label_test.dart
  lost_dog_neighborhood_test.dart
  lost_dogs_test.dart
  map_test.dart
  message_bubble_avatar_test.dart
  moments_test.dart
  nis_city_test.dart
  nis_places_test.dart
  notifications_test.dart
  profile_test.dart
  reminder_schedule_test.dart
  safety_test.dart
  schedule_walk_sheet_test.dart
  scheduled_walks_test.dart
  settings_test.dart
  splash_test.dart
  storage_owner_folder_test.dart
  support_test.dart
  widget_test.dart
tool/
  belgrade_places_geocoded.json
  belgrade_places_raw.json
  generate_belgrade_seed.ps1
  geocode_belgrade_places.ps1
  geocode_places.ps1
  geocode_places_nominatim.ps1
  kragujevac_places_geocoded.json
  kragujevac_places_nominatim.json
  kragujevac_places_raw.json
  nis_geocode_log.txt
  nis_geocode_log_extra.txt
  nis_nominatim_parks.txt
  nis_nominatim_retry.txt
  nis_osm_parks.json
  nis_osm_parks.txt
  nis_places_nominatim.json
  nis_places_nominatim_extra.json
  nis_places_raw.json
  nis_places_raw_extra.json
web/
  favicon.png
  icons/
    Icon-192.png
    Icon-512.png
    Icon-maskable-192.png
    Icon-maskable-512.png
  index.html
  manifest.json
windows/
  .gitignore
  CMakeLists.txt
  flutter/
    CMakeLists.txt
    generated_plugin_registrant.cc
    generated_plugin_registrant.h
    generated_plugins.cmake
  runner/
    CMakeLists.txt
    flutter_window.cpp
    flutter_window.h
    main.cpp
    resource.h
    resources/
      app_icon.ico
    runner.exe.manifest
    Runner.rc
    utils.cpp
    utils.h
    win32_window.cpp
    win32_window.h
```

### Opis fajlova po modulima
Svaki `.dart` fajl u `lib/` je opisan ispod (broj u zagradi = broj linija). Platformski, konfiguracioni i test fajlovi su u poslednjoj podsekciji.
### 2.1 Core, app, servisi, auth, splash, legal, lokacija, home
#### Koren / app
- `lib/main.dart` (56) – Ulazna tačka: `installGlobalErrorHandlers()`, inicijalizacija `NotificationService`, `Firebase.initializeApp`, Firestore offline perzistencija (neograničen keš), registracija FCM background handlera, Crashlytics init, zatim `runApp(ProviderScope(VauVauApp))`; u slučaju greške pokreće `FirebaseInitErrorApp`.
- `lib/firebase_options.dart` (37) – Ručno održavan `DefaultFirebaseOptions` sa Android i iOS konfiguracijom; web i ostale platforme padaju na Android opcije.
- `lib/app/app.dart` (79) – `VauVauApp` (`MaterialApp`): tema (light/dark iz podešavanja), jezik (`L10n.setLanguage`), `navigatorKey: appNavigatorKey`, `home: SplashScreen`; sluša `authStateProvider` i šalje uid u Crashlytics.
- `lib/app/firebase_init_error_app.dart` (34) – Minimalni `MaterialApp` koji prikazuje tekst greške inicijalizacije Firebase-a (tamna tema).
- `lib/app/routes.dart` (14) – `AppRoutes` sa imenovanim rutama `/login` i `/register`; mapa se **nigde ne koristi** (MaterialApp nema `routes:`).

#### core/constants
- `lib/core/constants/app_strings.dart` (232) – `AppStrings`: dvojezični (sr/en) stringovi za auth, onboarding psa, greške, mreža; konstanta `maxDogPhotos = 5`.
- `lib/core/constants/dog_breeds.dart` (84) – `DogBreeds`: lista 56 predloženih rasa, `customId = '__custom__'`, pomoćne metode za dropdown.
- `lib/core/constants/serbia_locations.dart` (430) – Modeli `Neighborhood`, `CityLocation` i `SerbiaLocations` (Novi Sad, Beograd, Niš, Kragujevac sa naseljima), liste za udomljavanje i funkcije za normalizaciju/sanitizaciju labela lokacije.

#### core/crash, core/firebase
- `lib/core/crash/crash_reporting.dart` (61) – `CrashReporting`: tanak omotač oko Crashlytics-a; no-op na webu, Windows/Linux i kad Firebase nije spreman.
- `lib/core/firebase/firebase_status.dart` (3) – Getter `isFirebaseReady` (`Firebase.apps.isNotEmpty`).
- `lib/core/firebase/firestore_auth_guard.dart` (201) – `FirestoreAuthGuard` (soft-fail za `permission-denied`/mrežne greške, `run`, `guardedStream`) i `firestoreAuthReadyProvider`.

#### core/geo
- `lib/core/geo/firestore_geo.dart` (29) – `firestoreLocationFields` (mapa za upis lokacije u Firestore) i `geoCoordFromMap` (čitanje).
- `lib/core/geo/geo.dart` (174) – `GeoCoord` (sa hardkodovanim koordinatama 4 grada), `haversineKm`, `GeoHash` (encode, susedi, coverage prefiksi).

#### core/images
- `lib/core/images/app_image_provider.dart` (6) – Uslovni export `appImageProvider(url)` (io vs web). Nema poziva u `lib/`.
- `lib/core/images/app_image_provider_io.dart` (36) – Native implementacija: prazno/`placeholder:` → providni 1×1 PNG, http(s) → `NetworkImage`, `assets/` → `AssetImage`, inače `FileImage`.
- `lib/core/images/app_image_provider_web.dart` (12) – Web implementacija: http(s)/ostalo → `NetworkImage`, `assets/` → `AssetImage`.
- `lib/core/images/dog_image.dart` (415) – `buildDogImage`/`DogImage` widget: data-URI, http(s), `gs://`, Firebase Storage (sa HTTPS rezolucijom, fallback na bajtove, HTML `<img>` na webu), ilustracija kao fallback.
- `lib/core/images/dog_photo_urls.dart` (114) – Pomoćne funkcije za URL-ove fotografija: skupljanje iz više polja, deduplikacija, filtriranje stock CDN-ova, `firestorePhotoFields`.
- `lib/core/images/fallback_image_helper.dart` (145) – `FallbackImageHelper` (10 Unsplash URL-ova samo za prikaz, boje), `DogIllustrationFallback`, `FallbackIllustrationCaption` (bedž „Ilustrovana slika“).
- `lib/core/images/firebase_web_image.dart` (2) – Uslovni export stub/web.
- `lib/core/images/firebase_web_image_stub.dart` (11) – Non-web stub koji baca `UnsupportedError`.
- `lib/core/images/firebase_web_image_web.dart` (57) – Renderuje Storage sliku kao HTML `<img>` preko `platformViewRegistry` (zaobilazi CORS u CanvasKit-u).
- `lib/core/images/image_upload_service.dart` (81) – `ImageUploadService`: legacy omotač oko `StorageService` (upload bajtova/XFile, `uploadAll`).

#### core/l10n, network, services
- `lib/core/l10n/app_language.dart` (28) – Enum `AppLanguage` (sr, en) sa `locale`, `label`, `fromCode`.
- `lib/core/l10n/l10n.dart` (16) – `L10n`: globalno statičko stanje jezika i `tr(sr, en)`.
- `lib/core/network/network_failure.dart` (83) – `NetworkFailure`, `isNetworkFailure`, `networkOrFallbackMessage`, `showNetworkErrorSnackBar`.
- `lib/core/services/message_sound_player.dart` (52) – `MessageSoundPlayer` (apstraktno), `AudioMessageSoundPlayer` (audioplayers, `sounds/message.wav`) i `messageSoundPlayerProvider`.
- `lib/core/services/notification_service.dart` (341) – `NotificationService`: lokalne notifikacije (podsetnici za zdravlje u 09:00, prikaz FCM alerta u foreground-u, brisanje iz trake) i `notificationServiceProvider`.

#### core/theme
- `lib/core/theme/app_cards.dart` (283) – `AppCardTokens`, enum `StatusBadgeTone`, widgeti `StatusBadge`, `ImageOverlayBadge`, `CardLocationRow`, `CardTimeLabel`, `CardTitleText`, `DetailPrimaryButton`, `AppCard`.
- `lib/core/theme/app_colors.dart` (35) – Paleta boja (`primary = 0xFFEA580C` itd.) i `cardShadow`.
- `lib/core/theme/app_theme.dart` (219) – `AppTheme.light()/dark()` (Material 3); na webu isključene page tranzicije (`_NoPageTransitionsBuilder`).
- `lib/core/theme/app_theme_preference.dart` (24) – Enum `AppThemePreference` (dark – podrazumevano, light).

#### core/utils
- `lib/core/utils/content_validation_service.dart` (127) – `ContentValidationService`: filter psovki (hardkodovana lista), spam/URL heuristike, validacija slika po ekstenziji/MIME i magic bajtovima.
- `lib/core/utils/external_link_launcher.dart` (14) – `ExternalLinkLauncher` (url_launcher, eksterna aplikacija) i `externalLinkLauncherProvider`.

#### core/widgets
- `lib/core/widgets/brand_mark.dart` (44) – Logo (narandžasti krug sa šapom) + tekst „VauVau“.
- `lib/core/widgets/breed_field.dart` (125) – Dropdown rasa + slobodan unos za „Ostalo“.
- `lib/core/widgets/city_neighborhood_fields.dart` (121) – Dropdown grad + naselje + slobodan unos naselja.
- `lib/core/widgets/comment_like_button.dart` (54) – Mali „srce + broj“ like dugme (tooltip podrazumevano „Lajk“).
- `lib/core/widgets/feed_state.dart` (328) – `SoftPlaceholder` (shimmer), `FeedShimmerGrid`, `FeedStateView`, `AppErrorContainer`, `installGlobalErrorHandlers()`.
- `lib/core/widgets/illustration_placeholder.dart` (40) – Gradijent sa ikonom šape i tekstom „Ilustracija“; **nema poziva u `lib/`**.
- `lib/core/widgets/primary_button.dart` (23) – Full-width `FilledButton`.
- `lib/core/widgets/ui_bits.dart` (228) – `PulseBadge`, `PersonalityBadge`, `DetailPillChip`, `MetricStatChip`, `DistancePill`, `GenderIcon`.

#### services
- `lib/services/storage_service.dart` (470) – `StorageService`: upload (galerija/kamera/XFile/bajtovi) na Firebase Storage pod owner-scoped putanjom, rezolucija `gs://`→HTTPS, download bajtova sa in-memory kešom, brisanje.

#### features/auth
- `lib/features/auth/data/account_deletion_service.dart` (317) – `AccountDeletionService`: klijentsko kaskadno brisanje Firestore podataka i Storage slika korisnika pre brisanja Auth naloga.
- `lib/features/auth/data/auth_repository_impl.dart` (444) – `AuthRepositoryImpl`: Firebase implementacija `AuthRepository` (stream korisnika obogaćen Firestore dokumentom, prijava, registracija, Google, odjava, reset, brisanje, čuvanje profila/psa/fotke).
- `lib/features/auth/data/firebase_auth_datasource.dart` (114) – `FirebaseAuthDatasource`: direktni pozivi `FirebaseAuth` i `GoogleSignIn`.
- `lib/features/auth/data/local_auth_repository.dart` (133) – `LocalAuthRepository` (in-memory demo) i konstanta `localDemoUser`.
- `lib/features/auth/data/user_document.dart` (49) – `userCollection = 'users'`, `emptyDogMap()`, `userDocumentPayload(...)`.
- `lib/features/auth/domain/app_user.dart` (149) – Enum `UserRole`, ekstenzija `UserRoleX`, model `AppUser`.
- `lib/features/auth/domain/auth_exception.dart` (21) – Enum `AuthErrorCode` i `AuthException`.
- `lib/features/auth/domain/auth_repository.dart` (48) – Apstraktni `AuthRepository`.
- `lib/features/auth/domain/user_dog_profile.dart` (74) – Model `UserDogProfile` (pas ugnježden u user dokumentu).
- `lib/features/auth/presentation/auth_controller.dart` (154) – `AuthController` (Notifier<AsyncValue<void>>), enum `AuthBusy`, `authControllerProvider`.
- `lib/features/auth/presentation/auth_gate.dart` (53) – `AuthGate`: loading → login → onboarding psa → home shell.
- `lib/features/auth/presentation/auth_providers.dart` (47) – `authRepositoryProvider`, `SessionSignedOut`/`sessionSignedOutProvider`, `authStateProvider`, `isAdminProvider`.
- `lib/features/auth/presentation/auth_screen.dart` (628) – `AuthScreen` sa tabovima Prijava/Registracija (forme, upload profilne slike vlasnika, izbor grada/naselja, pravna saglasnost).
- `lib/features/auth/presentation/forgot_password_dialog.dart` (235) – Dijalog za reset lozinke; poziva `FirebaseAuth.instance.sendPasswordResetEmail` direktno.
- `lib/features/auth/presentation/login_screen.dart` (10) – `LoginScreen` = `AuthScreen()` (tab Prijava).
- `lib/features/auth/presentation/register_screen.dart` (12) – `RegisterScreen` = `AuthScreen(initialMode: signUp)`.
- `lib/features/auth/presentation/widgets/auth_text_field.dart` (54) – `TextFormField` sa opcionim prikaz/sakrij lozinke.
- `lib/features/auth/presentation/widgets/google_sign_in_button.dart` (129) – Google dugme sa custom-painted logom; **trenutno se ne koristi** (zakomentarisano u `auth_screen.dart`).

#### features/splash
- `lib/features/splash/presentation/screens/splash_screen.dart` (86) – `SplashScreen`: full-screen slika `assets/images/vauvau_splash.png`, posle 2 s `pushReplacement` na `AuthGate` sa fade tranzicijom.
- `lib/features/splash/presentation/widgets/splash_clouds.dart` (49) – `SplashClouds` (CustomPaint oblaci); **nema poziva u `lib/`**.
- `lib/features/splash/presentation/widgets/splash_mascot.dart` (159) – `SplashMascot` (CustomPaint maskota psa sa srcem); **nema poziva u `lib/`**.

#### features/legal
- `lib/features/legal/domain/legal_urls.dart` (17) – `LegalUrls`: URL-ovi politike privatnosti i uslova (Firebase Hosting) i kontakt email URI (iz `OfficialContacts`, van slice-a).
- `lib/features/legal/presentation/legal_consent_text.dart` (88) – `LegalConsentText`: rečenica „Kreiranjem naloga prihvatate …“ sa tapabilnim linkovima.
- `lib/features/legal/presentation/legal_document_bodies.dart` (210) – `LegalSection`, `PrivacyPolicyBody` (9 sekcija), `TermsOfServiceBody` (8 sekcija), dvojezično.
- `lib/features/legal/presentation/legal_document_screen.dart` (113) – Enum `LegalDocumentKind`, `openLegalDocument()`, `LegalDocumentScreen`.
- `lib/features/legal/presentation/legal_strings.dart` (45) – `LegalStrings` (naslovi, „Poslednje ažuriranje: 12. oktobar 2026.“, kontakt).

#### features/location
- `lib/features/location/data/geolocator_location_client.dart` (200) – `GeolocatorLocationClient` (geolocator; foreground servis za šetnju na Androidu) i `FallbackLocationClient` (no-op).
- `lib/features/location/domain/location_access.dart` (11) – Enum `LocationAccess` i `canTrack`.
- `lib/features/location/domain/location_client.dart` (21) – Apstraktni `LocationClient`.
- `lib/features/location/domain/user_location.dart` (35) – Model `UserLocation` sa `noviSadFallback`.
- `lib/features/location/presentation/home_city_provider.dart` (42) – Model `HomeCity` i `homeCityProvider` (grad iz profila korisnika).
- `lib/features/location/presentation/location_controller.dart` (73) – `LocationController`, `locationClientProvider`, `userLocationProvider`.
- `lib/features/location/presentation/location_disclosure.dart` (131) – „Prominent disclosure“ dijalog pre sistemskog zahteva za lokaciju i `requestLocationPermissionWithDisclosure`.
- `lib/features/location/presentation/location_strings.dart` (24) – Tekstovi disclosure dijaloga.

#### features/home
- `lib/features/home/domain/app_drawer_catalog.dart` (146) – `AppDrawerDestination`, enum `DrawerItemKind`, `AppDrawerCatalog` (labele i liste stavki drawera).
- `lib/features/home/presentation/home_drawer.dart` (385) – `HomeDrawer` (zaglavlje sa avatarom, sekcije, admin stavka sa badge-om) i `DrawerSectionScreen` (generički ekran, praktično nedostupan).
- `lib/features/home/presentation/home_shell_screen.dart` (143) – `HomeShellScreen`: Scaffold sa drawerom, AppBar-om, `IndexedStack` od 4 taba i `NavigationBar`; omotan u `PushBootstrap` i `LostDogEmergencyHost`.
- `lib/features/home/presentation/home_tab.dart` (19) – `HomeTabIndex` Notifier i `homeTabIndexProvider`.

### 2.2 Chat, grupe, događaji
#### lib/features/chat/domain
- `lib/features/chat/domain/chat_repository.dart` (76) – Apstraktni interfejs `ChatRepository` za 1:1 chat: inbox, sobe, poruke, pozivi na šetnju, lajkovi, attach/detach listenera po sobi.
- `lib/features/chat/domain/chat_message.dart` (156) – Model `ChatMessage` + enumi `ChatMessageType` i `WalkInviteStatus`; mapiranje tip/status ↔ string ključevi, isecanje reply teksta, parsiranje lajkova.
- `lib/features/chat/domain/chat_conversation.dart` (93) – Model `ChatConversation` (red u inbox-u sa peer psom/vlasnikom, porukama, unread brojačem) + getter `room` koji pravi `ChatRoom`.
- `lib/features/chat/domain/chat_room.dart` (34) – Lagani model `ChatRoom` (id, učesnici, psi, poslednja poruka, unread).
- `lib/features/chat/domain/chat_time.dart` (22) – Top-level funkcije `formatChatTimestamp` (HH:mm / „Juče“ / d.M.) i `formatWalkStamp` (d.M. HH:mm).
- `lib/features/chat/domain/scheduled_walk.dart` (17) – Model `ScheduledWalk` za baner „Zakazane šetnje“.

#### lib/features/chat/data
- `lib/features/chat/data/firestore_chat_repository.dart` (1066) – Firestore implementacija `ChatRepository`: listener na `chats` (po `participantIds`), ograničeni listeneri poruka po otvorenoj sobi (ref-count), zasebni listeneri za walk invite poruke svih soba, optimistički upisi sa rollback-om, `unreadByUser` brojači.
- `lib/features/chat/data/local_chat_repository.dart` (355) – In-memory implementacija `ChatRepository` (seed lista, sve operacije lokalno, `hasLoadedInbox` uvek `true`).
- `lib/features/chat/data/mock_conversations.dart` (151) – `seedChatConversations(now)` – 6 mock razgovora napravljenih iz `mockDiscoverProfiles` (kiki, maza, lola, rex, djole, bobi).
- `lib/features/chat/data/walk_locations.dart` (5) – Konstantna lista `scheduledWalkLocations` (3 hardkodovane lokacije u Novom Sadu).

#### lib/features/chat/presentation
- `lib/features/chat/presentation/chat_inbox.dart` (370) – `ChatInboxController` (Notifier) i svi chat provideri: izbor repozitorijuma, inbox, loaded flag, vidljivi razgovori (bez blokiranih), walk invites, zakazane šetnje, ukupni unread broj (chat+grupe+događaji).
- `lib/features/chat/presentation/chat_detail_screen.dart` (731) – Ekran 1:1 razgovora: lista poruka, reply, lajk, prijava poruke, slanje teksta/fotografije/lokacije/poziva na šetnju, scroll na prvu nepročitanu, markRead.
- `lib/features/chat/presentation/chat_list_screen.dart` (647) – Inbox („Poruke“ tab): novi lajkovi, pretraga, novi mečevi (horizontalno), spojena lista 1:1 + grupe + događaji sortirana po aktivnosti, skeleton i prazno stanje.
- `lib/features/chat/presentation/chat_screen.dart` (14) – Tanak omotač `ChatScreen` koji samo renderuje `ChatDetailScreen`.
- `lib/features/chat/presentation/matches_screen.dart` (12) – `MatchesScreen` koji samo vraća `ChatsScreen` (koristi se kao tab u `HomeShellScreen`).
- `lib/features/chat/presentation/screens/chats_screen.dart` (5) – `ChatsScreen extends ChatListScreen` bez ikakve dodatne logike (alias).
- `lib/features/chat/presentation/chat_strings.dart` (133) – `ChatStrings` – lokalizovani (sr/en preko `L10n.tr`) stringovi za chat.
- `lib/features/chat/presentation/incoming_message_sound.dart` (136) – `IncomingMessageDetector`, `ThreadActivity`, `systemMessageAlertsAudibleProvider` i `incomingMessageSoundProvider` – pušta zvuk kada stigne nova poruka (chat/grupa/događaj).
- `lib/features/chat/presentation/incoming_likes.dart` (119) – `IncomingLike` model i provideri koji iz `swipes` kolekcije čitaju ko je lajkovao mog psa (bez onih sa kojima već postoji chat).
- `lib/features/chat/presentation/schedule_walk_sheet.dart` (266) – Bottom sheet za zakazivanje šetnje (datum, vreme, lokacija chip ili ručni unos; validacija da je u budućnosti). Koristi se i u 1:1 i u grupnom/event chatu.

#### lib/features/chat/presentation/widgets
- `widgets/chat_ui.dart` (226) – `ChatUiTokens` (dimenzije/radijusi), `UnreadCountBadge`, `ChatInputBar` (polje + attach + send, Enter šalje na web/desktopu).
- `widgets/message_bubble.dart` (166) – `MessageBubble` – balon 1:1 poruke (avatar, reply citat, slika, tekst, vreme, lajk dugme).
- `widgets/message_reply.dart` (215) – `SenderAvatar`, `ReplyQuote`, `ReplyComposeBanner`, enum `MessageAction` i `showMessageActionsSheet` (Odgovori / Prijavi / Otkaži).
- `widgets/dog_avatar.dart` (44) – `DogAvatar` (okrugla slika psa) i `ConversationTitle` (nekorišćen widget).
- `widgets/location_pin_bubble.dart` (109) – `LocationPinBubble` – balon za poruku tipa lokacija.
- `widgets/location_choice_chip.dart` (44) – `LocationChoiceChip` – kontrastni `ChoiceChip` za izbor lokacije.
- `widgets/location_picker_sheet.dart` (132) – `showLocationPickerSheet` / `LocationPickerSheet` – izbor lokacije (chip ili ručni unos) za slanje location pin poruke.
- `widgets/walk_invite_card.dart` (142) – `WalkInviteCard` – kartica poziva na šetnju (status, opciono broj prihvatanja za grupe, dugmad Prihvati/Odbij).
- `widgets/scheduled_walks_banner.dart` (98) – `ScheduledWalksBanner` – sklopivi baner „Zakazane šetnje (N)“ iznad tabova Mapa/Poruke.

#### lib/features/groups
- `lib/features/groups/domain/groups_models.dart` (334) – Modeli `BreedGroup`, `GroupMessage`, `GroupInboxThread`, enumi `GroupMessageType`, `GroupWalkInviteStatus` i apstraktni `GroupsRepository` (deli ga i event chat preko `GroupMessage`).
- `lib/features/groups/data/seed_breed_groups.dart` (133) – `SeedBreedGroups`: 9 predefinisanih grupa sa lažnim brojem članova, `firestoreData`, `sortByPopularity`.
- `lib/features/groups/data/firestore_groups_repository.dart` (455) – Firestore implementacija `GroupsRepository` (`breed_groups`, seeding/patch pri prvom `watchGroups`, transakcije za join/like, arrayUnion za walk invite odgovore).
- `lib/features/groups/data/local_groups_repository.dart` (320) – In-memory implementacija `GroupsRepository` + `seedIncomingMessage` (koristi se u testu).
- `lib/features/groups/presentation/groups_controller.dart` (224) – `GroupsController` (Notifier<List<BreedGroup>>) i provideri: repozitorijum, pending grupe (admin), poruke, lastRead, member id, joined thread-ovi, sortirane grupe.
- `lib/features/groups/presentation/group_chat_screen.dart` (843) – `GroupChatScreen` – zajednički ekran za grupni chat I chat događaja (`groupId` ili `eventId`), plus privatni `_GroupMessageBubble` i konverter `_groupWalkAsChat`.
- `lib/features/groups/presentation/groups_list_screen.dart` (248) – `GroupsListScreen` (lista grupa, pridruživanje, otvaranje chata) i `CreateGroupSheet` (forma za novu grupu koja ide na odobrenje).
- `lib/features/groups/presentation/group_unread_alerts.dart` (58) – `groupUnreadAlertsProvider` – kada poraste unread u grupi/događaju, poziva `pushControllerProvider.notifyGroupThread`.
- `lib/features/groups/presentation/groups_strings.dart` (58) – `GroupsStrings` – lokalizovani stringovi za grupe.
- `lib/features/groups/presentation/widgets/group_card.dart` (97) – `GroupCard` – kartica grupe (slika, naziv, broj članova, opis, dugme Pridruži se / Otvori chat).

#### lib/features/events
- `lib/features/events/domain/event_model.dart` (89) – Modeli `EventModel` (sa `isListed`, `listGrace` = 6h) i `EventInboxThread`.
- `lib/features/events/domain/events_repository.dart` (48) – Apstraktni `EventsRepository` (poruke koriste `GroupMessage` iz grupa).
- `lib/features/events/data/seed_events.dart` (140) – `EventVenues` (lista/koordinate novosadskih lokacija, `forCity`, `cityIdForEvent`) i `SeedEvents` (3 seed događaja sa dummy učesnicima, `firestoreData`).
- `lib/features/events/data/firestore_events_repository.dart` (454) – Firestore implementacija `EventsRepository` (`events`, seeding ako je kolekcija prazna, čišćenje stock CDN slika, join sa sistemskom porukom, createEvent sa `debugPrint` payload-a).
- `lib/features/events/data/local_events_repository.dart` (290) – In-memory implementacija + `EventsJoinCopy.joined` (tekst „X se pridružio/la šetnji! 🐾“).
- `lib/features/events/presentation/events_controller.dart` (277) – `EventsController`, `EventsCityFilter` i provideri (repozitorijum, city filter, venues, poruke, lastRead, member id, eventById, joined thread-ovi).
- `lib/features/events/presentation/events_screen.dart` (225) – `EventsScreen` – lista događaja sa filterima po gradu i (Svi/Predstojeći/Moje), dugme „Organizuj šetnju“.
- `lib/features/events/presentation/create_event_screen.dart` (416) – `showCreateEventSheet` / `CreateEventScreen` – forma za kreiranje događaja (naslov, grad, lokacija, datum/vreme, opis, opciona slika).
- `lib/features/events/presentation/events_strings.dart` (118) – `EventsStrings` – lokalizovani stringovi i formatiranje datuma (`when`, `timeAgo`, `interested`).
- `lib/features/events/presentation/widgets/event_card.dart` (167) – `EventCard` – kartica događaja (slika, badge, naslov, lokacija + grad, vreme, broj zainteresovanih, opis, Pridruži se / Otvori chat).
- `lib/features/events/presentation/widgets/events_promo_banner.dart` (47) – `EventsPromoBanner` – zeleni baner koji otvara `EventsScreen`. U `lib/` se nigde ne koristi (samo definicija).

### 2.3 Discover, psi (zdravlje, podsetnici), profil i podešavanja
#### discover (24)

- `lib/features/discover/domain/discover_profile.dart` (370) – Glavni prikazni model psa za Discover/Profil (`DiscoverProfile`) sa getterima za labele (starost, pol, veličina, energija, osobine, status šetnje), lokalizacijom osobina i `copyWith`.
- `lib/features/discover/domain/discover_repository.dart` (62) – Apstraktni `DiscoverRepository`, `DiscoverPage` (stranica za paginaciju) i `SuperLikeDailyLimitException`.
- `lib/features/discover/domain/compatibility.dart` (91) – `CompatibilityInsight` i `describeCompatibility()` – tekstualni opis kompatibilnosti (zajednička „voli” interesovanja + isti nivo energije); nema numeričkog skora.
- `lib/features/discover/domain/geo_query.dart` (28) – `GeoQuery` (origin + radius) – računa haversine udaljenost i filtrira profile po radijusu (klijentski).
- `lib/features/discover/data/firestore_discover_repository.dart` (470) – Firestore implementacija Discover feeda, swipe/like/unlike, Super Like (1/24h), kreiranje meča i chata, upis notifikacija.
- `lib/features/discover/data/local_discover_repository.dart` (125) – In-memory implementacija nad mock profilima; like/super like se čuvaju u `Set`/`Map`, nikad ne pravi meč.
- `lib/features/discover/data/dog_profile_mapper.dart` (307) – Mapiranja: Firestore mapa → `DiscoverProfile`, `Dog` → `DiscoverProfile`, `AppUser` → `DiscoverProfile`, `DiscoverProfile` → `Dog`/`UserDogProfile`; normalizacija pola/veličine/energije/temperamenta.
- `lib/features/discover/data/load_discover_profile.dart` (34) – One-shot učitavanje jednog psa iz `dogs` po `dogId` ili po `ownerId` (koriste ga chat, grupe, notifikacije – van slice-a).
- `lib/features/discover/data/mock_discover_profiles.dart` (158) – Hardkodovani mock psi: `mockMyDog` (Luna), `mockSecondDog` (Maks) i lista od 6 psa `mockDiscoverProfiles`.
- `lib/features/discover/presentation/discover_controller.dart` (403) – `DiscoverState`, `DiscoverController` (pretraga/kategorija/swipe), `DiscoverArea` + `discoverAreaProvider`, `DiscoverFeedController` (live prva stranica + `loadMore`) i ostali Discover provideri.
- `lib/features/discover/presentation/discover_screen.dart` (176) – Ekran „Psi u tvojoj blizini”: kategorijski čipovi, grid kartica sa beskonačnim skrolom, otvaranje detalja psa.
- `lib/features/discover/presentation/discover_strings.dart` (173) – Svi SR/EN stringovi Discover feature-a (`L10n.tr`) i pomoćne funkcije za format (godine, kg, lokacija).
- `lib/features/discover/presentation/discover_image.dart` (17) – `discoverImageFactoryProvider` (zamenljiv u testovima) i `discoverImageOf()`.
- `lib/features/discover/presentation/widgets/swipe_dog_card.dart` (1154) – Najveći fajl: neiskorišćeni `SwipeDogCard` + `DogDetailSheet` (detaljni profil psa) sa svim podwidgetima, like/super-like dugmićima, akcionim barom i vlasnikom.
- `lib/features/discover/presentation/widgets/directory_cards.dart` (184) – `DiscoverGridCard` – kartica psa u gridu (foto, status bedž, ime, starost, rasa, kvart).
- `lib/features/discover/presentation/widgets/compatibility_card.dart` (37) – `CompatibilityCard` – prikazuje `describeCompatibility(myDog, other).headline`.
- `lib/features/discover/presentation/widgets/match_dialog.dart` (164) – `showMatchDialogIfNeeded()` i `MatchDialog` (full-screen „Novi meč!” sa dve slike i dugmetom za poruku).
- `lib/features/discover/presentation/widgets/dog_photo_gallery.dart` (436) – `DogPhotoGallery` (PageView sa blur pozadinom, strelice, brojač), `BlurBackdropPhoto`, `showDogPhotoViewer()` i full-screen `DogPhotoViewer` sa pinch/double-tap zoom-om.
- `lib/features/discover/presentation/widgets/discover_dog_photo.dart` (33) – `DiscoverDogPhoto` – prva jedinstvena slika psa sa `Semantics`.
- `lib/features/discover/presentation/widgets/discover_empty_state.dart` (47) – Prazno stanje Discover-a sa dugmetom „Resetuj filtere”.
- `lib/features/discover/presentation/widgets/discover_filter_chip.dart` (92) – `DiscoverFilterStyle` (boje), `WalkStatusDot`, `DiscoverFilterChip`.
- `lib/features/discover/presentation/widgets/discover_filters_bottom_sheet.dart` (237) – Bottom sheet „Napredni filteri” (pol, veličina, energija, radius 1–20 km, starost 0–15, vakcinisan/sterilisan).
- `lib/features/discover/presentation/widgets/discover_search_sheet.dart` (100) – Bottom sheet pretrage (live `setQuery`).
- `lib/features/discover/presentation/widgets/discover_app_bar.dart` (75) – AppBar Discover taba (meni/drawer, pretraga, filteri, notifikacije sa bedžom).

#### dogs (41)

- `lib/features/dogs/domain/dog.dart` (95) – Entitet `Dog` (Firestore pas, enum polja) sa `location` getterom i `copyWith`.
- `lib/features/dogs/domain/dog_enums.dart` (35) – Enumi `DogGender`, `DogSize`, `DogEnergyLevel`, `DogTemperament` (svi sa `firestoreValue => name`).
- `lib/features/dogs/domain/dog_area.dart` (31) – `DogArea` (grad + naselje) sa `toMap`/`fromMap`.
- `lib/features/dogs/domain/dog_draft.dart` (91) – `DogDraft` – mutabilni nacrt psa tokom onboardinga.
- `lib/features/dogs/domain/dog_preference_tags.dart` (55) – Liste „voli”/„ne voli” tagova (srpski ključevi), `sanitize`, `localize`.
- `lib/features/dogs/domain/dogs_exception.dart` (11) – `DogsException` (podrazumevana poruka `AppStrings.dogSaveFailed`).
- `lib/features/dogs/domain/dogs_repository.dart` (17) – Apstraktni `DogsRepository` (watch/create/update/delete).
- `lib/features/dogs/domain/health_record.dart` (91) – `HealthCategory`, `HealthRecord` (status valid/expiring/expired), `HealthStatus`.
- `lib/features/dogs/domain/health_repository.dart` (10) – Apstraktni `HealthRepository`.
- `lib/features/dogs/domain/dog_reminder.dart` (276) – Enumi podsetnika (kategorija, tip, ponavljanje, jedinica, offset, hitnost) i model `DogReminder`.
- `lib/features/dogs/domain/reminder_repository.dart` (12) – Apstraktni `ReminderRepository`.
- `lib/features/dogs/domain/reminder_schedule.dart` (178) – Čiste funkcije za računanje sledećeg termina ponavljajućih podsetnika + ekstenzija `rolledForward`.
- `lib/features/dogs/data/dogs_repository_impl.dart` (399) – Firestore `DogsRepositoryImpl` (kolekcija `dogs`, plus upis u `users/{uid}` pri kreiranju prvog psa).
- `lib/features/dogs/data/local_dogs_repository.dart` (153) – In-memory `LocalDogsRepository` + `localDemoDog()` (Luna, `local-luna`).
- `lib/features/dogs/data/dog_photo_storage.dart` (50) – `DogPhotoStorage` – upload `XFile` u Storage folder `pets`; **nigde se ne koristi u `lib/`**.
- `lib/features/dogs/data/dog_photo_persist.dart` (11) – Uslovni import (io/web) za `persistDogPhotos`; **nigde se ne koristi**.
- `lib/features/dogs/data/dog_photo_persist_io.dart` (60) – Kopira slike u `{appDocs}/dog_photos/{dogId}/{i}.jpg` sa timeout fallbackom; **neiskorišćeno**.
- `lib/features/dogs/data/dog_photo_persist_web.dart` (8) – Web varijanta: vraća `file.path`; **neiskorišćeno**.
- `lib/features/dogs/data/firestore_health_repository.dart` (96) – Firestore `dogs/{dogId}/health_records`.
- `lib/features/dogs/data/local_health_repository.dart` (58) – In-memory zdravstveni zapisi (kad Firebase nije spreman).
- `lib/features/dogs/data/firestore_reminder_repository.dart` (146) – Firestore `dogs/{dogId}/reminders` sa legacy podrškom za `customIntervalDays`.
- `lib/features/dogs/data/local_reminder_repository.dart` (63) – In-memory podsetnici.
- `lib/features/dogs/presentation/dog_providers.dart` (145) – `dogsRepositoryProvider`, `LocalOwnerDogs` (optimistički overlay), `ownerDogsProvider` sa spajanjem remote+local.
- `lib/features/dogs/presentation/health/health_controller.dart` (107) – Provideri zdravstvenih zapisa i `HealthController` (save/delete + zakazivanje lokalne notifikacije).
- `lib/features/dogs/presentation/health/reminder_controller.dart` (160) – Provideri podsetnika i `ReminderController` (save, roll-forward, delete, notifikacije).
- `lib/features/dogs/presentation/health/dog_health_tab.dart` (404) – Kartica „🩺 Zdravlje i podsetnici” na Profilu (sažetak kartona + 2 naredna podsetnika).
- `lib/features/dogs/presentation/health/health_card_screen.dart` (219) – Ekran „Karton zdravlja” (poslednji zapis po kategoriji + dodavanje).
- `lib/features/dogs/presentation/health/health_record_sheet.dart` (272) – Bottom sheet za dodavanje/izmenu/brisanje zdravstvenog zapisa.
- `lib/features/dogs/presentation/health/health_strings.dart` (87) – Stringovi zdravstvenog kartona.
- `lib/features/dogs/presentation/health/add_reminder_sheet.dart` (114) – Bottom sheet izbora tipa podsetnika po kategorijama; definiše `typedef ReminderDogOption`.
- `lib/features/dogs/presentation/health/reminder_form_sheet.dart` (353) – Forma podsetnika (pas, naziv, datum, ponavljanje, prilagođeni interval, offset, napomena).
- `lib/features/dogs/presentation/health/reminders_screen.dart` (407) – Ekran „Podsetnici” (grupe PROŠLO / SLEDEĆE / KASNIJE, filter po psu, detalji, izmena, brisanje).
- `lib/features/dogs/presentation/health/reminder_strings.dart` (257) – Stringovi podsetnika, labele tipova/ponavljanja/offseta/hitnosti, formati datuma.
- `lib/features/dogs/presentation/onboarding/dog_onboarding_controller.dart` (293) – `DogOnboardingState` i `DogOnboardingController` (3 koraka, validacija, upload slika, submit, `applyCreatedDog`).
- `lib/features/dogs/presentation/onboarding/dog_onboarding_screen.dart` (165) – Ekran onboardinga psa (progress bar, koraci, nazad/dalje/kreiraj).
- `lib/features/dogs/presentation/onboarding/steps/basics_step.dart` (115) – Korak 1: ime, rasa (`BreedField`), pol, starost.
- `lib/features/dogs/presentation/onboarding/steps/personality_step.dart` (157) – Korak 2: veličina, težina, temperament, voli/ne voli, bio, vakcinisan/čipovan/sterilisan.
- `lib/features/dogs/presentation/onboarding/steps/photos_step.dart` (107) – Korak 3: dodavanje slika iz galerije/kamere, grid sa brisanjem.
- `lib/features/dogs/presentation/onboarding/steps/area_step.dart` (90) – Korak izbora grada/naselja; **nije uključen u onboarding** (nigde se ne koristi).
- `lib/features/dogs/presentation/onboarding/option_chips.dart` (73) – Generički `OptionChips<T>` + funkcije `genderLabel`, `sizeLabel`, `temperamentLabel`.
- `lib/features/dogs/presentation/widgets/preference_chip_group.dart` (60) – `PreferenceChipGroup` i `togglePreference()`.

#### profile (15)

- `lib/features/profile/domain/app_settings.dart` (46) – `AppSettings` (notifikacije, radius, mapa, jezik, tema).
- `lib/features/profile/domain/user_profile.dart` (77) – `UserProfile` (vlasnik + lista `DiscoverProfile` pasa) i hardkodovani `mockUserProfile`.
- `lib/features/profile/domain/matching_filters.dart` (122) – `FilterGender`, `FilterCity`, `FilterEnergy`, `MatchingFilters` sa `apply`/`matches`.
- `lib/features/profile/data/app_settings_store.dart` (52) – Čitanje/pisanje `AppSettings` u `SharedPreferences`.
- `lib/features/profile/presentation/profile_controller.dart` (416) – `ProfileController`, `MatchingFiltersController`, `AppSettingsController` i provideri (`profileControllerProvider`, `matchingFiltersProvider`, `appSettingsProvider`, `currentDiscoverDogProvider`).
- `lib/features/profile/presentation/profile_screen.dart` (661) – Profil tab: zaglavlje vlasnika (avatar upload), izbor psa, kartica psa, story highlights, `DogHealthTab`, dugmad „Dodaj psa” / „Izmeni profil”.
- `lib/features/profile/presentation/edit_profile_screen.dart` (569) – Izmena psa (sva polja + slike sa trenutnim upisom u Firestore).
- `lib/features/profile/presentation/edit_owner_profile_screen.dart` (285) – Izmena vlasnika (ime, grad/naselje, bio, avatar).
- `lib/features/profile/presentation/settings_screen.dart` (504) – Podešavanja (notifikacije, tema, jezik, radius, filteri, lokacija na mapi, pravni dokumenti, verzija).
- `lib/features/profile/presentation/profile_system_sheet.dart` (114) – Bottom sheet: Podešavanja, Administracija (ako admin), Odjava, Brisanje naloga.
- `lib/features/profile/presentation/matching_filters_sheet.dart` (187) – Bottom sheet „Filteri za pretragu” (veličina, pol, grad, radius 1–30).
- `lib/features/profile/presentation/delete_account_action.dart` (90) – `confirmAndDeleteAccount()` – dijalog + `authController.deleteAccount()`.
- `lib/features/profile/presentation/sign_out_action.dart` (123) – `confirmAndSignOut()` – dijalog + `authController.signOut()`.
- `lib/features/profile/presentation/profile_strings.dart` (291) – Stringovi profila/podešavanja + format helperi.
- `lib/features/profile/presentation/widgets/profile_ui.dart` (121) – `ProfileAvatar` i `ProfileMomentsGrid` (ovaj drugi **nigde se ne koristi**).

### 2.4 Mapa, mesta i alati (tool/)
#### `lib/features/map/data/`

| Fajl | Linija | Opis |
|---|---|---|
| `address_geocoder.dart` | 62 | `GeocodeSuggestion` + `AddressGeocoder`: slobodna pretraga adrese preko javnog OSM Nominatim API-ja (samo Srbija, max 6 rezultata). Koristi ga samo admin ekran `AddPlaceScreen`. |
| `belgrade_dog_places_seed.dart` | 1683 | **Generisan** fajl (skripta `tool/generate_belgrade_seed.ps1`): `BelgradeDogPlacesSeed.all` – 108 hardkodovanih `PoiModel` lokacija za Beograd, sve označene kao `verified`. |
| `cities_repository.dart` | 60 | `CitiesRepository` interfejs + `FirestoreCitiesRepository` (kolekcija `cities`, spajanje sa ugrađenim gradovima) + `LocalCitiesRepository` (samo seed gradovi). |
| `firestore_poi_repository.dart` | 152 | `FirestorePoiRepository` (čitanje/pisanje kolekcije `pois`, mapiranje dokument ⇄ `PoiModel`) + `LocalPoiRepository` (in-memory lista). |
| `firestore_walk_presence_repository.dart` | 108 | Upisuje „u šetnji“ prisustvo i lokaciju u `users/{uid}` i `dogs/{dogId}`; sluša pse sa `isWalking == true` (max 50). |
| `kragujevac_dog_places_seed.dart` | 428 | `KragujevacDogPlacesSeed.all` – 32 ručno pisane lokacije za Kragujevac (7 `verified`, 25 `unknown`). |
| `local_walk_presence_repository.dart` | 27 | No-op implementacija prisustva (kad Firebase nije spreman); `watchWalking` vraća praznu listu. |
| `mock_map_data.dart` | 122 | Konstante kamere (Novi Sad / Liman), 9 dodatnih hardkodovanih „katalog“ mesta u Novom Sadu (`catalogServicePlaces`), getter `mockMapPlaces` (sva seed mesta + katalog) i prazna lista `mockWalkingDogs`. |
| `nis_dog_places_seed.dart` | 494 | `NisDogPlacesSeed.all` – 35 lokacija za Niš (13 `verified`, 22 `unknown`), sa detaljnim komentarom o poreklu podataka. |
| `places_repository.dart` | 362 | `PlaceDraft` + `PlacesRepository` (admin „izvor istine“ `places`, sa atomskim WriteBatch preslikavanjem u `pois`) + `FirestorePlacesRepository` + `LocalPlacesRepository`. |
| `poi_seed_data.dart` | 598 | `PoiSeedData`: Novi Sad seed (39 mesta), Beograd „legacy“ (3 hitna veterinara + 7 ostalih) i agregacija svih gradova u `allVerified`. |
| `walk_history_repository.dart` | 146 | `WalkHistoryRepository`: čuvanje završenih šetnji (niz `walkHistory` u `users/{uid}` + podkolekcija `users/{uid}/walks`) i čitanje poslednjih N dana. Plus `LocalWalkHistoryRepository`. |

#### `lib/features/map/domain/`

| Fajl | Linija | Opis |
|---|---|---|
| `city_model.dart` | 108 | `CityModel` (grad iz Firestore `cities`) + `SeedCities` (4 ugrađena grada, `byId`, `mergeWith`). |
| `map_city.dart` | 50 | Enumi `MapCity` i `MapCityFocus`, ekstenzija `MapCityX` (label, kanonski `cityId`, kamera, `fromCityId`) i `MapCityCameras`. |
| `map_place.dart` | 199 | `MapPlace` – prikazni model mesta na mapi (`fromPoi`, `isOfficialDogPark`, `hasValidCoordinates`, `pinColor`, `copyWith`). |
| `map_place_type.dart` | 79 | Enum `MapPlaceType` (13 kategorija) + ikonica, boja pina i labela filtera. |
| `poi_repository.dart` | 7 | Apstraktni `PoiRepository` (`watchAll`, `upsert`). |
| `walking_dog_pin.dart` | 15 | `WalkingDogPin` – pin psa koji je trenutno u šetnji (profil + koordinate + status). |
| `walk_presence_repository.dart` | 32 | Apstraktni `WalkPresenceRepository` + DTO `WalkingPresence`. |
| `walk_record.dart` | 39 | `WalkRecord` – završena šetnja (trajanje, distanca, labela). |
| `walk_session.dart` | 113 | `WalkSession` – stanje aktivne šetnje (pauza, putanja, distanca, izvedene metrike). |
| `models/poi_model.dart` | 228 | Enumi `PoiCategory`, `PoiVerificationStatus`, ekstenzija `PoiVerificationStatusX` i glavni model `PoiModel` sa `copyWith`. |

#### `lib/features/map/presentation/`

| Fajl | Linija | Opis |
|---|---|---|
| `add_place_screen.dart` | 407 | `AddPlaceScreen` – admin ekran za dodavanje zvaničnog mesta (forma + Nominatim pretraga adrese + mini mapa za fino pomeranje pina) i helper `openAddPlaceScreen`. |
| `cities_controller.dart` | 90 | `MapRegionSelection`, `MapRegionController` i provideri: `mapRegionProvider`, `citiesRepositoryProvider`, `citiesProvider`, `placesRepositoryProvider`, `livePlacesProvider`; funkcija `mapRegionCenter`. |
| `maps_launcher.dart` | 36 | `MapsLauncher.openDirections` (Google Maps → Apple Maps → `geo:` URI) + `mapsLauncherProvider`. |
| `map_screen.dart` | 1441 | Glavni ekran „Mapa“ (tab 2 u `HomeShellScreen`): mapa, pretraga, filteri, gradovi, lista mesta, početak/kraj šetnje, pinovi šetača; plus privatni widgeti. |
| `map_strings.dart` | 400 | Enumi `MapLayerFilter`, `HotelAmenityFilter` sa ekstenzijama i `MapStrings` (svi tekstovi mape, SR/EN preko `L10n.tr`). |
| `poi_report_controller.dart` | 178 | `PoiReports` (prijava promene mesta → Firestore) i `PoiConfirmations` (lokalna potvrda), sa providerima. |
| `user_poi_controller.dart` | 136 | `poiRepositoryProvider`, `livePoisProvider`, Notifier `UserPoiSubmissions` (dodavanje/izmena/brisanje/odobravanje POI-ja) i `pendingPoisProvider`. |
| `walk_controller.dart` | 356 | `WalkController` (GPS šetnja, prisustvo, istorija) + `mapPlacesProvider` (spajanje svih izvora mesta) + provideri prisustva šetača. |
| `walk_history_controller.dart` | 22 | `walkHistoryRepositoryProvider` i `walkHistoryProvider` (poslednjih 7 dana). |
| `widgets/add_poi_sheet.dart` | 273 | `AddPoiSheet` – bottom sheet za predlog mesta od strane korisnika (status `pending`) + ekstenzija `PoiCategorySubmitLabel`. |
| `widgets/city_picker_sheet.dart` | 125 | Bottom sheet za izbor grada / „Moja lokacija“. |
| `widgets/mock_map_canvas.dart` | 162 | **Uprkos imenu, ovo nije mock**: `VauInteractiveMap` je prava `FlutterMap` mapa (OSM tile-ovi, polilinija rute, klasterovani markeri, ne-kulovani overlay markeri, OSM atribucija). |
| `widgets/osm_tile_layer.dart` | 40 | `buildOsmTileLayer` – zajednički OSM raster sloj sa retry HTTP klijentom i disk kešom (256 MB, 7 dana). |
| `widgets/place_sheet.dart` | 756 | `showPlaceSheet`/`PlacePreviewSheet` (detalji mesta), `_ReportChangeSheet` (prijava promene), `PlacePin` (marker), bedževi verifikacije/kategorije. |
| `widgets/walker_sheet.dart` | 201 | `showWalkerSheet`, `WalkerMiniCard`, `WalkerPin` – prikaz psa koji je u šetnji. |
| `widgets/walk_history_sheet.dart` | 214 | Bottom sheet „Istorija šetnji“ (poslednjih 7 dana, grupisano po danima, sumarno vreme i km). |
| `widgets/walk_stats_panel.dart` | 286 | `WalkStatsPanel` (vreme/km, pauza/nastavi, završi šetnju sa potvrdom) i `WalkGpsBanner`. |

#### `tool/`

| Fajl | Linija | Opis |
|---|---|---|
| `geocode_belgrade_places.ps1` | 104 | Geokodira `belgrade_places_raw.json` preko Photon API-ja (komoot) sa biasom na Beograd i bbox filterom; piše `belgrade_places_geocoded.json`. Probava 4 upita redom (puna adresa → ulica+opština → ulica → ime objekta). |
| `generate_belgrade_seed.ps1` | 95 | Čita `belgrade_places_geocoded.json` i **prepisuje** `lib/features/map/data/belgrade_dog_places_seed.dart` (sve stavke dobijaju `verificationStatus: verified`). |
| `geocode_places.ps1` | 83 | Generička Photon geokodiranje skripta za bilo koji grad (parametri: centar + bbox); beleži preciznost `house`/`street`/`feature`. Primer u komentaru je za Kragujevac. |
| `geocode_places_nominatim.ps1` | 54 | Nominatim *structured* pretraga (`street` + `city`), čuva samo rezultate sa tačnim kućnim brojem (`address.house_number`), pauza 1,2 s (Nominatim politika 1 req/s). |
| `belgrade_places_raw.json` | 116 | Ulazni spisak 108 beogradskih mesta (id, name, category, address, municipality, sourceUrl, opciono website/dogFriendly). Nema telefona. |
| `belgrade_places_geocoded.json` | 92 | Izlaz Photon geokodiranja – **trenutno samo 6 stavki** (vidi tehnički dug). |
| `kragujevac_places_raw.json` | 41 | 35 kandidata za Kragujevac (id, name, category, address, query, ponegde phone/website/sourceUrl). |
| `kragujevac_places_geocoded.json` | 266 | Photon rezultat (33 stavke, uglavnom preciznost `street`); fajl je sačuvan sa pokvarenim enkodingom ćirilice u `geocodeLabel` (mojibake). |
| `kragujevac_places_nominatim.json` | 210 | Nominatim rezultat sa kućnim brojem (26 stavki) – odavde potiču koordinate biznisa u Kragujevac seed-u. |
| `nis_places_raw.json` | 29 | 24 kandidata za Niš. |
| `nis_places_raw_extra.json` | 9 | 7 dodatnih kandidata za Niš (pansioni, dresura, ponovljen Dr Beli). |
| `nis_places_nominatim.json` | 170 | Nominatim rezultat za Niš (21 stavka sa kućnim brojem). |
| `nis_places_nominatim_extra.json` | 42 | Nominatim rezultat za extra listu (5 stavki). |
| `nis_geocode_log.txt` | 25 | Konzolni log `geocode_places_nominatim.ps1` za Niš (21 OK, 3 MISS). |
| `nis_geocode_log_extra.txt` | 8 | Log za extra listu (5 OK, 2 MISS). |
| `nis_nominatim_parks.txt` | 15 | Log slobodnih Nominatim upita za parkove/kej/tvrđavu u Nišu (OSM tip, id, koordinate). Skripta koja ga je proizvela **nije u repozitorijumu**. |
| `nis_nominatim_retry.txt` | 14 | Log ponovnih pokušaja za La Vie, Retro bar, Dr Beli, Pet Star, Hush Hush, Tramvaj itd. Skripta takođe **nije u repozitorijumu**. |
| `nis_osm_parks.json` | 170 | Sirov Overpass API odgovor (generator „Overpass API 0.7.62.11“, timestamp `2026-10-14T10:13:39Z`) sa 11 OSM elemenata (parkovi, `dog_park`). Overpass upit nije sačuvan. |
| `nis_osm_parks.txt` | 11 | Tabelarni sažetak istih 11 OSM elemenata (`way/422184755` je `dog_park`). |

### 2.5 Priče, izgubljeni psi, udomljavanje, moderacija, notifikacije, podrška, admin
#### moments (19 fajlova)
- `lib/features/moments/data/firestore_highlights_repository.dart` (160) – Firestore implementacija `HighlightsRepository`; istaknute priče se čuvaju kao mapa `storyHighlights` na dokumentu `dogs/{dogId}` (ne u posebnoj kolekciji).
- `lib/features/moments/data/firestore_moments_repository.dart` (320) – Firestore implementacija `MomentsRepository` nad kolekcijom `moments` i podkolekcijom `comments`; lajkovi kroz transakcije, paginacija, kreiranje i brisanje.
- `lib/features/moments/data/local_highlights_repository.dart` (72) – in-memory implementacija istaknutih sa broadcast `StreamController`-om.
- `lib/features/moments/data/local_moments_repository.dart` (190) – in-memory implementacija momenata; seed iz `SeedMoments` + jedan hardkodovan komentar (moment `moment-liman`, autor "Ana").
- `lib/features/moments/data/seed_moments.dart` (53) – 3 demo momenta (`moment-liman`, `moment-kamenicki`, `moment-tvrdjava`; autori `seed-nikola`, `seed-jelena`, `seed-stefan`).
- `lib/features/moments/domain/highlights_repository.dart` (22) – apstraktni interfejs + top-level funkcija `sortHighlights` (po `order`, pa `createdAt`).
- `lib/features/moments/domain/moments_repository.dart` (37) – apstraktni interfejs `MomentsRepository` i klasa `MomentsPage`.
- `lib/features/moments/domain/moment_model.dart` (90) – modeli `MomentModel` i `MomentComment`; konstanta `storyLifetime = 24h`.
- `lib/features/moments/domain/story_highlight.dart` (43) – model `StoryHighlight`; `maxTitleLength = 20`.
- `lib/features/moments/presentation/create_moment_sheet.dart` (343) – bottom sheet "Dodaj priču": izbor psa, grada, lokacije (preset ili ručno), opis, fotografija iz galerije, objava.
- `lib/features/moments/presentation/highlight_sheets.dart` (731) – full-screen stranice (bez animacije prelaza) za dodavanje u istaknuto, editor istaknutog, raspoređivanje (reorder), dijalog brisanja i `HighlightThumb` widget.
- `lib/features/moments/presentation/moments_controller.dart` (272) – `MomentsController` (Notifier, live stream + paginacija) i provideri `momentsRepositoryProvider`, `momentsControllerProvider`, `visibleMomentsProvider`, `momentCommentsProvider`, `momentsMemberIdProvider`.
- `lib/features/moments/presentation/moments_screen.dart` (295) – ekran "VauVau Moments": traka priča, grid aktivnih (24h) priča, beskonačni skrol.
- `lib/features/moments/presentation/moments_strings.dart` (127) – SR/EN stringovi preko `L10n.tr` i `timeAgo` helper.
- `lib/features/moments/presentation/pointer_safe.dart` (49) – `afterPointerSettles`: web workaround (2 frejma + 50 ms) da se izbegne assert `!_debugDuringDeviceUpdate`.
- `lib/features/moments/presentation/stories_controller.dart` (220) – `StoryGroup`, `activeStoryGroupsProvider`, `SeenStories`, `storyArchiveProvider`, `highlightsRepositoryProvider`, `dogHighlightsProvider`, `resolveHighlight`, `highlightCoverUrl`, `HighlightActions`.
- `lib/features/moments/presentation/story_viewer.dart` (684) – full-screen pregledač priča (Instagram stil): 6 s po priči, tap levo/desno, long-press pauza, swipe dole zatvara; lajk/komentar/istakni/obriši/prijavi; `openMomentDog`.
- `lib/features/moments/presentation/widgets/moment_comments_sheet.dart` (124) – bottom sheet komentara (visina 420): lista, unos, lajk komentara.
- `lib/features/moments/presentation/widgets/story_widgets.dart` (435) – `StoryRing`, `StoriesRail`, `StoryHighlightsRow` (profil sopstvenog psa, može da se uređuje), `DogStoriesSection` (tuđi pas, samo čitanje).

#### lost_dogs (12 fajlova)
- `lib/features/lost_dogs/data/firestore_lost_dog_repository.dart` (334) – Firestore implementacija nad `lost_dogs`; komentari kao niz `comments` u samom dokumentu + mapa `commentLikes`; upload slike preko `ImageUploadService` (folder `lost_dogs`).
- `lib/features/lost_dogs/data/local_lost_dog_repository.dart` (127) – in-memory implementacija, bez seed podataka (prazna lista), `currentUserId = 'local-user'`.
- `lib/features/lost_dogs/data/lost_dog_popup_store.dart` (21) – SharedPreferences flag `has_dismissed_lost_dog_popup` (globalan, jednom zauvek).
- `lib/features/lost_dogs/domain/lost_dog.dart` (134) – `LostDog`, `LostDogType`, `LostDogStatus`, `LostDogComment`.
- `lib/features/lost_dogs/domain/lost_dog_matcher.dart` (109) – heuristika poklapanja oglasa "pronađen" sa oglasima "izgubljen" (grad, kvart, rasa, ključne reči).
- `lib/features/lost_dogs/domain/lost_dog_repository.dart` (19) – apstraktni interfejs.
- `lib/features/lost_dogs/presentation/lost_dogs_controller.dart` (146) – `LostDogsController` (Notifier) i provideri.
- `lib/features/lost_dogs/presentation/lost_dogs_screen.dart` (508) – ekran sa 3 taba (Izgubljeni / Pronađeni / Svi), kartice, baner poklapanja, admin brisanje.
- `lib/features/lost_dogs/presentation/lost_dog_actions.dart` (466) – sheet "Javi vlasniku" (poziv/SMS), hitni dijalog, sheet profila, sheet komentara, `_callOwner`/`_smsOwner`.
- `lib/features/lost_dogs/presentation/lost_dog_emergency_host.dart` (55) – omotač oko home shell-a koji jednom prikaže hitni popup za psa nestalog u poslednja 24h.
- `lib/features/lost_dogs/presentation/lost_dog_strings.dart` (234) – SR/EN stringovi, `breedOptions`, `formatDate`, `timeAgo`, SMS tekstovi, klasa `LostDogMatchCopy`.
- `lib/features/lost_dogs/presentation/report_lost_dog_sheet.dart` (465) – izbor tipa prijave + forma za prijavu nestanka/pronalaska.

#### adoption (12 fajlova)
- `lib/features/adoption/data/firestore_adoption_repository.dart` (127) – Firestore implementacija nad `adoption_dogs`; upload više slika (folder `adoption`); `markAdopted`.
- `lib/features/adoption/data/local_adoption_repository.dart` (59) – in-memory implementacija, seed = `mockAdoptionDogs`.
- `lib/features/adoption/data/mock_adoption_dogs.dart` (58) – 3 mock oglasa (Bara, Džeki, Mili) sa izmišljenim telefonima i organizacijama.
- `lib/features/adoption/domain/adoption_dog.dart` (79) – model `AdoptionDog`.
- `lib/features/adoption/domain/adoption_repository.dart` (18) – apstraktni interfejs.
- `lib/features/adoption/presentation/adoption_controller.dart` (100) – `AdoptionController`, `adoptionRepositoryProvider`, `adoptionControllerProvider`.
- `lib/features/adoption/presentation/adoption_strings.dart` (106) – SR/EN stringovi, `sizeLabel`, `genderLabel`, `callLabel`, `timeAgo`.
- `lib/features/adoption/presentation/phone_launcher.dart` (27) – `PhoneLauncher` (`tel:` URI, uzima prvi broj iz stringa) + `phoneLauncherProvider`; koristi ga i lost_dogs.
- `lib/features/adoption/presentation/screens/adoption_detail_screen.dart` (292) – detalj oglasa: galerija, info čipovi, priča, vlasnik, dugmad poruka/poziv, "Označi kao udomljen" za vlasnika.
- `lib/features/adoption/presentation/screens/adoption_screen.dart` (104) – grid oglasa u 2 kolone (bez udomljenih), dugme + za novi oglas.
- `lib/features/adoption/presentation/widgets/add_adoption_dog_sheet.dart` (598) – forma za novi oglas (`AddAdoptionDogScreen` u bottom sheet-u od 92%).
- `lib/features/adoption/presentation/widgets/adoption_card.dart` (89) – kartica oglasa u gridu.
#### moderation (11 fajlova)
- `lib/features/moderation/data/firestore_blocked_users_repository.dart` (48) – blokirani korisnici u `users/{uid}/blocked_users/{blockedUid}`.
- `lib/features/moderation/data/firestore_report_repository.dart` (383) – prijave: primarni upis u niz `contentReports` na `users/{uid}`, zatim best-effort kopije u `notifications`, `reports/{id}`, `admin_notifications`; admin čitanje spaja `reports` + nizove iz SVIH `users` dokumenata.
- `lib/features/moderation/data/local_blocked_users_repository.dart` (36) – in-memory `Set`.
- `lib/features/moderation/data/local_report_repository.dart` (47) – in-memory lista.
- `lib/features/moderation/domain/blocked_users_repository.dart` (7) – interfejs `watchBlocked`/`block`/`unblock`.
- `lib/features/moderation/domain/content_report.dart` (94) – enumi `ReportContentType`, `ReportStatus`, model `ContentReport`, interfejs `ReportRepository`.
- `lib/features/moderation/presentation/block_controller.dart` (54) – provideri blokiranja i `BlockController`.
- `lib/features/moderation/presentation/moderation_strings.dart` (48) – stringovi i liste razloga prijave.
- `lib/features/moderation/presentation/report_controller.dart` (96) – `HiddenContent`, `reportRepositoryProvider`, `contentReportsProvider`, `activeReportsProvider`, `ReportController`.
- `lib/features/moderation/presentation/report_sheet.dart` (223) – `showContentReportSheet` + `_ReportSheet` (radio razlozi + detalji).
- `lib/features/moderation/presentation/safety_menu.dart` (176) – `SafetyMenuButton` (⋮ meni: Prijavi korisnika / Blokiraj) + dijalog `confirmAndBlockUser`.

#### notifications (12 fajlova)
- `lib/features/notifications/data/mock_notifications.dart` (4) – `seedNotifications(now)` vraća `const []`; nigde se ne koristi.
- `lib/features/notifications/data/push_notification_gateway.dart` (288) – `PushNotificationGateway`, `NoopPushNotificationGateway`, `FcmPushNotificationGateway` (FCM token, foreground/opened streamovi, lokalni prikaz, `queueForUser` u `fcmInbox` + `notifications`), `pushPayloadFromNotificationJson`, `pushNotificationGatewayProvider`, `fcmUidProvider`.
- `lib/features/notifications/data/push_platform.dart` (9) – `isPushPlatform = !kIsWeb && (android || iOS)`.
- `lib/features/notifications/domain/app_notification.dart` (53) – enum `NotificationKind` + model `AppNotification`.
- `lib/features/notifications/domain/push_payload.dart` (85) – enum `PushKind` + `PushPayload` (`data` mapa, `fromData`, `kindFrom`).
- `lib/features/notifications/presentation/notification_controller.dart` (266) – `NotificationController` (Firestore `notifications` gde je `toUserId == uid`, limit 100), označavanje pročitanim, `notificationUnreadCountProvider`.
- `lib/features/notifications/presentation/notification_routing.dart` (215) – `openAppNotification` / `openPushDestination`: navigacija po tipu (mapa, grupa, događaj, profil psa, chat).
- `lib/features/notifications/presentation/notification_screen.dart` (242) – `NotificationScreen` (nigde se ne otvara), `showNotificationsSheet` (78% visine), `NotificationsInbox`, kartice.
- `lib/features/notifications/presentation/notification_strings.dart` (64) – stringovi, tekstovi push poruka, `timeAgo`.
- `lib/features/notifications/presentation/push_bootstrap.dart` (59) – omotač home shell-a: inicijalizuje `pushControllerProvider` i pri prvom pokretanju jednom traži OS dozvolu.
- `lib/features/notifications/presentation/push_controller.dart` (214) – `PushController` (Notifier<bool> = da li je dozvola data): init, sinhronizacija tokena, slušanje poruka, `notifyMatch/Message/GroupThread/Walk`, `_dispatch`.
- `lib/features/notifications/presentation/push_navigation.dart` (4) – globalni `appNavigatorKey` (koristi ga `app.dart:40`).

#### support (19 fajlova)
- `lib/features/support/data/firestore_support_repository.dart` (31) – upis poruke korisnika u kolekciju `admin_feedback`.
- `lib/features/support/data/local_support_repository.dart` (11) – čuva poslate poruke u memorijskoj listi `submitted`.
- `lib/features/support/domain/admin_feedback.dart` (28) – model `AdminFeedback` + hardkodovane kategorije.
- `lib/features/support/domain/official_contacts.dart` (47) – `OfficialContactLink` + `OfficialContacts` (email, Instagram, Facebook).
- `lib/features/support/domain/support_repository.dart` (5) – interfejs `submitFeedback`.
- `lib/features/support/presentation/about_app_dialog.dart` (60) – dijalog "O aplikaciji" (opis, verzija, linkovi na politiku privatnosti/uslove, kontakti); otvara se iz `home_drawer.dart:94`.
- `lib/features/support/presentation/rules_and_support_screen.dart` (49) – ekran sa 4 taba: SOS, Saveti, Pravila, Piši Adminu.
- `lib/features/support/presentation/rules_content.dart` (531) – statički sadržaj pravila zajednice (liste `TipArticle`: daily/community/important), SR/EN.
- `lib/features/support/presentation/rules_tab.dart` (197) – prikaz pravila po blokovima + završna kartica; CTA "Piši Adminu" prebacuje na tab 3.
- `lib/features/support/presentation/sos_tab.dart` (321) – hardkodovana lista hitnih veterinarskih/zoohigijenskih kontakata za Novi Sad i Beograd; dugme za poziv.
- `lib/features/support/presentation/support_content.dart` (94) – `SupportGuide` model + `SupportContent.rules/tips` (stariji sadržaj, samo SR); nigde se ne koristi.
- `lib/features/support/presentation/support_controller.dart` (71) – `supportRepositoryProvider` + `SupportController.sendFeedback`.
- `lib/features/support/presentation/support_strings.dart` (94) – stringovi (uključujući hardkod "Verzija 1.0.0").
- `lib/features/support/presentation/tips_content.dart` (817) – enumi `TipCategory`/`TipCtaKind`, modeli `TipSection`/`TipArticle`, `TipsContent.articles` (15 statičkih članaka) + `byCategory`.
- `lib/features/support/presentation/tips_tab.dart` (216) – prikaz saveta po kategorijama, kartica "Nisi siguran šta da uradiš?" sa CTA ka SOS tabu; obrada CTA akcija.
- `lib/features/support/presentation/widgets/admin_feedback_form.dart` (163) – forma "Piši Adminu" (kategorija, naslov, poruka) + kontakt linkovi.
- `lib/features/support/presentation/widgets/official_contact_links.dart` (140) – red ikona ili kartice zvaničnih kontakata; `openOfficialContact`.
- `lib/features/support/presentation/widgets/support_guide_card.dart` (72) – `ExpansionTile` za `SupportGuide`; nigde se ne instancira.
- `lib/features/support/presentation/widgets/tip_article_card.dart` (354) – kartica članka (`ExpansionTile`): tačke/koraci/checklist (stanje se ne čuva), upozorenje, napomena, CTA dugme.

#### admin (14 fajlova)
- `lib/features/admin/data/firestore_admin_repository.dart` (124) – čitanje `admin_feedback` i cele `users` kolekcije, rešavanje/brisanje feedback-a, delegiranje CRUD-a zvaničnih mesta na `PlacesRepository`.
- `lib/features/admin/data/local_admin_repository.dart` (118) – in-memory implementacija sa seed feedback-om (2) i korisnicima (2) za lokalni rad i testove.
- `lib/features/admin/domain/admin_models.dart` (60) – modeli `FeedbackEntry` i `AdminUserEntry`.
- `lib/features/admin/domain/admin_repository.dart` (20) – apstraktni interfejs `AdminRepository`.
- `lib/features/admin/presentation/admin_controller.dart` (47) – `adminRepositoryProvider`, `adminFeedbackProvider`, `adminUsersProvider`, `newFeedbackCountProvider`.
- `lib/features/admin/presentation/admin_dashboard_screen.dart` (327) – admin panel sa 5 tabova (Statistika, Korisnici, Prijave, Sadržaj, Grupe na čekanju) + privatni tabovi statistike, sadržaja i POI predloga.
- `lib/features/admin/presentation/admin_strings.dart` (176) – SR/EN stringovi admin panela i helperi za datume.
- `lib/features/admin/presentation/tabs/admin_feedback_tab.dart` (182) – lista poruka korisnika sa akcijama "Označi kao rešeno" i "Obriši".
- `lib/features/admin/presentation/tabs/admin_groups_tab.dart` (150) – lista grupa koje čekaju odobrenje, akcije Odobri/Odbij (brisanje).
- `lib/features/admin/presentation/tabs/admin_moments_tab.dart` (112) – lista momenata sa brisanjem.
- `lib/features/admin/presentation/tabs/admin_reports_tab.dart` (395) – lista aktivnih prijava; akcije Obriši / Rešeno / Odbaci, za POI i "Izmeni i reši".
- `lib/features/admin/presentation/tabs/admin_users_tab.dart` (100) – samo-čitanje lista registrovanih korisnika (ime, email, datum, ADMIN bedž).
- `lib/features/admin/presentation/widgets/admin_confirm_dialog.dart` (27) – `confirmAdminDelete` dijalog potvrde brisanja.
- `lib/features/admin/presentation/widgets/admin_edit_poi_dialog.dart` (457) – bottom sheet editor mesta (POI): naziv, adresa, radno vreme, cena, telefon, sajt, koordinate, status, flegovi.

### 2.6 Platforme, konfiguracija, dokumentacija i testovi
#### Koren projekta (deo iz opsega)
- `README.md` – Kratak opis („A Flutter app for dog owners (Serbia first)“) i uputstvo za Firebase podešavanje (Email/Password + Google prijava, `flutterfire configure`, SHA-1/SHA-256, iOS reversed client ID). Ostatak je podrazumevani Flutter šablon tekst. Tvrdnja da je `lib/firebase_options.dart` „stub“ je zastarela – fajl sadrži stvarne opcije za projekat `vauvau-3195a`.
- `Gist` – Markdown tekst (bez ekstenzije) „Politika Privatnosti za aplikaciju VauVau“, datum 7. oktobar 2026, sa kontakt e-mailom koji se razlikuje od zvaničnih legal stranica (lični gmail umesto `vauvau.app@gmail.com`). Izgleda kao ostatak/nacrt za GitHub Gist.
- `.firebaserc` – Podrazumevani Firebase projekat `vauvau-3195a`.
- `firebase.json` – Konfiguracija za Firestore (rules + indexes), Storage (rules) i Hosting (`public/` sa rewrite-ovima za `/privacy` i `/terms`). Nema `functions` sekcije.
- `firebase.cmd` – Windows wrapper koji pokreće firebase-tools preko portabl Node 20.18.2 iz `%USERPROFILE%\.cache\firebase`, jer firepit `.exe` ne prosleđuje argumente.
- `storage-cors.json` – CORS pravilo za Firebase Storage bucket: svi origin-i (`*`), metode GET/HEAD/PUT/POST/DELETE/OPTIONS, maxAge 3600.
- `analysis_options.yaml` – Podrazumevani šablon: `include: package:flutter_lints/flutter.yaml`, bez dodatnih ili isključenih pravila.
- `.gitignore` – Standardni Flutter ignore + `/android/key.properties`, `*.jks`, `*.keystore`, `/release/`, `/docs/reels/ffmpeg/`, `/firebase.exe`, `/firebase-tools-instant-win.exe`, `/.firebase/`, `/moments_fail.txt`, `/flutter_*.png`, `*.iml`, `.idea/`.
- `.metadata` – Flutter metapodaci: revizija `924134a44c189315be2148659913dda1671cbe99`, kanal stable, sve platforme (android, ios, linux, macos, web, windows); `unmanaged_files`: `lib/main.dart`, `ios/Runner.xcodeproj/project.pbxproj`.

#### android/
- `android/.gitignore` – Ignoriše `gradle-wrapper.jar`, `/.gradle`, `/gradlew(.bat)`, `/local.properties`, `GeneratedPluginRegistrant.java`, `.cxx/`, `key.properties`, `**/*.keystore`, `**/*.jks`.
- `android/settings.gradle.kts` – Čita `flutter.sdk` iz `local.properties`, uključuje Flutter Gradle build; verzije pluginova: AGP `9.0.1`, Kotlin Android `2.3.20`, google-services `4.4.2`, Crashlytics Gradle plugin `3.0.3`, flutter-plugin-loader `1.0.0`.
- `android/build.gradle.kts` – Repozitorijumi google/mavenCentral, preusmerava build direktorijum na `../../build`, `clean` task.
- `android/gradle.properties` – JVM args `-Xmx8G -XX:MaxMetaspaceSize=4G …`, `android.useAndroidX=true`, `android.newDsl=false`, `android.builtInKotlin=false`.
- `android/gradle/wrapper/gradle-wrapper.properties` – Gradle `9.1.0-all`.
- `android/key.properties.example` – Šablon sa ključevima `storePassword`, `keyPassword`, `keyAlias` (=`upload`), `storeFile` i placeholder vrednostima; uputstvo da se ne komituje stvarni fajl.
- `android/key.properties` – **Postoji lokalno** (gitignored, nije u git-u); sadrži ključeve `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (vrednosti nisu prikazane).
- `android/local.properties` – Lokalno, gitignored: `sdk.dir`, `flutter.sdk`, `flutter.buildMode=release`, `flutter.versionName=1.0.0`, `flutter.versionCode=7` (generiše Flutter alat).
- `android/vauvau_android.iml` – IntelliJ modul fajl, lokalni i ignorisan (`*.iml`).
- `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/gradle-wrapper.jar` – Gradle wrapper skripte/jar, postoje lokalno ali su gitignored.
- `android/app/build.gradle.kts` – Glavna konfiguracija aplikacije: namespace/applicationId `com.vauvau.app`, Java/Kotlin 17, desugaring, strogo release potpisivanje iz `key.properties` (bez fallback-a na debug), R8 minify + shrink resources (detalji u sekciji Android).
- `android/app/google-services.json` – Firebase Android konfiguracija za projekat `vauvau-3195a`; sadrži **dva** klijenta: `com.example.vauvau` (2 OAuth klijenta) i `com.vauvau.app` (3 OAuth klijenta: 2× tip 1/Android, 1× tip 3/web), svaki sa po jednim API ključem (vrednosti nisu prikazane).
- `android/app/proguard-rules.pro` – Keep pravila za Flutter, Firebase/Play services, Crashlytics (SourceFile/LineNumberTable), geolocator, flutter_local_notifications i Google Sign-In.
- `android/app/src/main/AndroidManifest.xml` – Dozvole, `MainActivity`, FCM meta-data, geolocator foreground servis, receiver-i za lokalne notifikacije i `<queries>` (detalji ispod).
- `android/app/src/debug/AndroidManifest.xml` – Samo `INTERNET` dozvola (šablon, za hot reload).
- `android/app/src/profile/AndroidManifest.xml` – Samo `INTERNET` dozvola (šablon).
- `android/app/src/main/kotlin/com/vauvau/app/MainActivity.kt` – Prazna `class MainActivity : FlutterActivity()`, bez prilagođavanja.
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` – Generisan od Flutter alata, gitignored.
- `android/app/src/main/res/values/styles.xml` – `LaunchTheme` (Theme.Light.NoTitleBar, pozadina `@drawable/launch_background`, forceDark isključen, cutout `shortEdges`) i `NormalTheme` (pozadina `@color/splash_color`).
- `android/app/src/main/res/values-night/styles.xml` – Isto kao gore, ali parent `Theme.Black.NoTitleBar`.
- `android/app/src/main/res/values-v31/styles.xml` – Android 12+ splash: pozadina i pozadina ikonice `#0F172A`, animirana ikonica `@drawable/splash_icon_empty` (sakriva podrazumevanu „kocku“).
- `android/app/src/main/res/values-night-v31/styles.xml` – Isto kao v31, tamna varijanta.
- `android/app/src/main/res/values/colors.xml` – `splash_color` `#0F172A`, `ic_launcher_background` `#FFF8F0`.
- `android/app/src/main/res/drawable/launch_background.xml` i `drawable-v21/launch_background.xml` – Layer-list sa bitmapom `@drawable/background` (gravity fill).
- `android/app/src/main/res/drawable/splash_icon_empty.xml` – Prazan (transparentan) vektor 288×288dp.
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` – Adaptivna ikonica: pozadina `@color/ic_launcher_background`, foreground `ic_launcher_foreground` sa inset 16%.
- Binarni: `res/drawable/background.png`, `res/drawable-v21/background.png`, `res/drawable-{h,m,xh,xxh,xxxh}dpi/ic_launcher_foreground.png`, `res/mipmap-{h,m,xh,xxh,xxxh}dpi/ic_launcher.png` – splash pozadina i ikonice (generisane `flutter_native_splash` / `flutter_launcher_icons`).

#### ios/
- `ios/.gitignore` – Standardni Flutter iOS ignore (Pods, DerivedData, `Flutter/Generated.xcconfig`, `Flutter/ephemeral/`, `Runner/GeneratedPluginRegistrant.*` …).
- `ios/Flutter/AppFrameworkInfo.plist` – Šablonski plist Flutter framework-a (nema ključ `MinimumOSVersion`).
- `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig` – Samo `#include "Generated.xcconfig"` (nema CocoaPods include-a).
- `ios/Flutter/Generated.xcconfig`, `ios/Flutter/flutter_export_environment.sh` – Lokalno generisani, gitignored.
- `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` – Generisan (Swift Package Manager integracija pluginova), nije komitovan.
- `ios/Runner/Info.plist` – Display name „VauVau“, usage descriptions (kamera, galerija, lokacija), background modes, `LSApplicationQueriesSchemes`, scene manifest sa `SceneDelegate`, `FirebaseAppDelegateProxyEnabled=true`. Nema `CFBundleURLTypes`.
- `ios/Runner/AppDelegate.swift` – `FlutterAppDelegate` + `FlutterImplicitEngineDelegate`; registruje pluginove u `didInitializeImplicitFlutterEngine`. Bez Firebase/notifikacija prilagođavanja.
- `ios/Runner/SceneDelegate.swift` – Prazna `class SceneDelegate: FlutterSceneDelegate`.
- `ios/Runner/Runner-Bridging-Header.h` – `#import "GeneratedPluginRegistrant.h"`.
- `ios/Runner/GeneratedPluginRegistrant.h/.m` – Generisani, gitignored.
- `ios/Runner/GoogleService-Info.plist` – Firebase iOS konfiguracija: ključevi `CLIENT_ID`, `REVERSED_CLIENT_ID`, `ANDROID_CLIENT_ID`, `API_KEY`, `GCM_SENDER_ID`, `PLIST_VERSION`, `BUNDLE_ID` (=`com.example.vauvau`), `PROJECT_ID` (=`vauvau-3195a`), `STORAGE_BUCKET`, `IS_*` flagovi (ADS false, ANALYTICS false, APPINVITE/GCM/SIGNIN true), `GOOGLE_APP_ID`. **Nije referenciran u `project.pbxproj`** (vidi probleme).
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` – Launch ekran sa `LaunchBackground` (scaleToFill) i `LaunchImage` (center) slikama, bela pozadina view-a.
- `ios/Runner/Base.lproj/Main.storyboard` – Šablonski storyboard sa FlutterViewController-om.
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` – Spisak iOS ikonica.
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`, `LaunchBackground.imageset/Contents.json` – Spisak launch slika.
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` – Šablonsko uputstvo za zamenu launch slika.
- Binarni: `AppIcon.appiconset/Icon-App-*.png` (21 fajl), `LaunchImage.png/@2x/@3x`, `LaunchBackground.imageset/background.png`.
- `ios/Runner.xcodeproj/project.pbxproj` – Xcode projekat: bundle id `com.example.vauvau`, iOS 13.0, automatsko potpisivanje bez `DEVELOPMENT_TEAM`, Swift 5.0, device family 1,2.
- `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata`, `xcshareddata/IDEWorkspaceChecks.plist`, `xcshareddata/WorkspaceSettings.xcsettings` – Šablonski Xcode workspace metapodaci.
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` – Šablonska Runner šema.
- `ios/Runner.xcworkspace/contents.xcworkspacedata` – Referencira samo `Runner.xcodeproj` (nema `Pods.xcodeproj`).
- `ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`, `WorkspaceSettings.xcsettings` – Šablon.
- `ios/RunnerTests/RunnerTests.swift` – Prazan XCTest `testExample()` (šablon).
- Nema `ios/Podfile` niti `*.entitlements` fajla.

#### macos/
- `macos/.gitignore` – Šablon (ephemeral, Pods, xcuserdata).
- `macos/Flutter/Flutter-Debug.xcconfig`, `Flutter-Release.xcconfig` – Include `ephemeral/Flutter-Generated.xcconfig` (šablon).
- `macos/Flutter/GeneratedPluginRegistrant.swift` – Generisan; registruje audioplayers, cloud_firestore, file_selector, firebase_auth/core/crashlytics/messaging/storage, flutter_local_notifications, flutter_timezone, geolocator_apple, google_sign_in_ios, package_info_plus, shared_preferences, sqflite, url_launcher. Trenutno izmenjen u radnoj kopiji (git `M`).
- `macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` – Generisan, nije komitovan.
- `macos/Runner/AppDelegate.swift` – Šablon: gašenje posle zatvaranja poslednjeg prozora, secure restorable state.
- `macos/Runner/MainFlutterWindow.swift` – Šablon: FlutterViewController + registracija pluginova.
- `macos/Runner/Info.plist` – Šablon, bez usage descriptions.
- `macos/Runner/DebugProfile.entitlements` – app-sandbox, allow-jit, network.server.
- `macos/Runner/Release.entitlements` – Samo app-sandbox (nema `network.client`).
- `macos/Runner/Configs/AppInfo.xcconfig` – `PRODUCT_NAME = vauvau`, `PRODUCT_BUNDLE_IDENTIFIER = com.example.vauvau`, copyright „com.example“ (sa pogrešno kodiranim znakom ©: `Â©`).
- `macos/Runner/Configs/Debug.xcconfig`, `Release.xcconfig`, `Warnings.xcconfig` – Šablon.
- `macos/Runner/Base.lproj/MainMenu.xib` – Šablonski meni.
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` + binarni `app_icon_{16,32,64,128,256,512,1024}.png`.
- `macos/Runner.xcodeproj/project.pbxproj` – macOS deployment target 10.15; potpisivanje mešano Automatic/Manual po konfiguraciji (šablon); bundle id glavnog targeta dolazi iz `AppInfo.xcconfig`.
- `macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`, `xcshareddata/xcschemes/Runner.xcscheme`, `macos/Runner.xcworkspace/contents.xcworkspacedata`, `macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` – Šablonski Xcode metapodaci.
- `macos/RunnerTests/RunnerTests.swift` – Prazan XCTest (šablon).

#### windows/
- `windows/.gitignore` – Šablon (ephemeral, Visual Studio fajlovi).
- `windows/CMakeLists.txt` – `project(vauvau)`, `BINARY_NAME "vauvau"`, CMake ≥ 3.14 (šablon).
- `windows/flutter/CMakeLists.txt` – Šablon (sadrži Flutter-ov `# TODO: Move the rest of this into files in ephemeral` na liniji 9).
- `windows/flutter/generated_plugin_registrant.cc/.h`, `generated_plugins.cmake` – Generisani: audioplayers_windows, cloud_firestore, file_selector_windows, firebase_auth, firebase_core, firebase_storage, flutter_timezone, geolocator_windows, url_launcher_windows + FFI: flutter_local_notifications_windows, jni. `.cc` i `.cmake` izmenjeni u radnoj kopiji.
- `windows/runner/CMakeLists.txt`, `main.cpp`, `flutter_window.cpp/.h`, `win32_window.cpp/.h`, `utils.cpp/.h`, `resource.h` – Šablonski Win32 runner; naslov prozora `vauvau`.
- `windows/runner/Runner.rc` – Resursi: CompanyName `com.example`, ProductName `vauvau`, copyright „com.example“.
- `windows/runner/runner.exe.manifest` – Šablonski manifest (DPI awareness, podržani OS).
- Binarni: `windows/runner/resources/app_icon.ico`.

#### linux/
- `linux/.gitignore` – Šablon.
- `linux/CMakeLists.txt` – `BINARY_NAME "vauvau"`, `APPLICATION_ID "com.example.vauvau"`, CMake ≥ 3.13.
- `linux/flutter/CMakeLists.txt` – Šablon (isti Flutter TODO na liniji 9).
- `linux/flutter/generated_plugin_registrant.cc/.h`, `generated_plugins.cmake` – Generisani: audioplayers_linux, file_selector_linux, flutter_timezone, url_launcher_linux + FFI jni. `.cc` i `.cmake` izmenjeni u radnoj kopiji.
- `linux/runner/CMakeLists.txt`, `main.cc`, `my_application.cc/.h` – Šablonski GTK runner; naslov `vauvau`, podrazumevana veličina 1280×720.

#### web/
- `web/index.html` – Flutter web host stranica: `$FLUTTER_BASE_HREF`, opis na srpskom, meta `google-signin-client_id` (hardkodovan OAuth web client ID), PWA/iOS meta tagovi, CSS za splash, pozadina `#38BDF8`, učitava samo `flutter_bootstrap.js`.
- `web/manifest.json` – PWA manifest: ime „VauVau“, `display: standalone`, `background_color #FFF8F0`, `theme_color #EA580C`, `orientation: portrait-primary`, 4 ikonice (192/512 + maskable).
- Binarni: `web/favicon.png`, `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`.

#### public/ (Firebase Hosting)
- `public/index.html` – Jednostavna početna stranica „VauVau“ sa linkovima na `/privacy/` i `/terms/`.
- `public/privacy/index.html` – Politika privatnosti (SR/EN), ažurirano 12. oktobra 2026, kontakt `vauvau.app@gmail.com`; sadržajno ista kao `docs/privacy-policy.html` (razlika je samo link `/terms/` umesto `/terms` i jedna linija manje u `<style>`).
- `public/terms/index.html` – Uslovi korišćenja (SR/EN), 12. oktobar 2026; ista kao `docs/terms-of-service.html` osim linkova sa završnom kosom crtom.

#### docs/ (bez `docs/reels/ffmpeg`)
- `docs/play-launch-checklist.md` – Kontrolna lista za objavu na Google Play (detalji u sekciji Build).
- `docs/privacy-policy.html` – Politika privatnosti SR/EN: prikupljeni podaci (nalog, profili pasa, GPS tokom šetnje i dok je app otvorena, sadržaj, FCM token), svrha, deljenje (Firebase), lokacija (bez „uvek dozvoli“ na Androidu), prava (brisanje u aplikaciji ili e-mailom), deca < 13.
- `docs/terms-of-service.html` – Uslovi SR/EN: prihvatanje, nalog i ponašanje (zabrana govora mržnje, spama…), bezbednost (šetnje na sopstvenu odgovornost, nije veterinarska služba), kontakt.
- `docs/reels/CAPTION.txt` – Tekst za Instagram Reels najavu („VauVau stiže! Upari. Četuj. Šetaj.“, hashtagovi uključujući #NoviSad). Fajl je UTF-8, ali se u PowerShell `Get-Content` prikazuje sa pogrešno dekodiranim znakovima (mojibake) – sam sadržaj nije proveren u drugom editoru.
- `docs/reels/vauvau-reels-preview.html` – Lokalna HTML „slideshow“ stranica (9:16, ~13 s, 4 slajda po 3,2 s) za snimanje ekrana Reels najave; koristi `01_hook.jpg`…`04_cta.jpg`.
- Binarni: `docs/reels/01_hook.jpg`, `02_value.jpg`, `03_features.jpg`, `04_cta.jpg`, `vauvau-reels-najava.mp4` (marketinški materijal, komitovan u git).

#### scripts/
- `scripts/build_release.ps1` – PowerShell: `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build apk --release`, prekida na prvom neuspehu.
- `scripts/build_release.sh` – Bash ekvivalent (`set -euo pipefail`), isti koraci.

#### test/
- 38 test fajlova + 2 fake-a u `test/fakes/` (detalji u sekciji Testovi).

---
## 3. ARHITEKTURA

### Obrazac
- **Feature-first** struktura (`lib/features/<feature>/{domain,data,presentation}`) + zajednički `lib/core/` (servisi, tema, widgeti, lokalizacija, utili) i `lib/app/` (root widget, rute).
- **State management i DI: Riverpod 3** bez code-gen-a.
  - `Provider` za repozitorijume i servise.
  - `NotifierProvider` za kontrolere (npr. `ChatInbox`, `ProfileController`, `AppSettingsController`).
  - `StreamProvider` za Firestore tokove (npr. `authStateProvider`, `groupsStreamProvider`).
  - `.family` za stvari vezane za ID (poruke grupe/događaja, profil psa).
- **Repository pattern sa dve implementacije:** apstraktna klasa u `domain/` plus:
  - `Firestore…Repository` za produkciju;
  - `Local…Repository` (in-memory/seed) kada Firebase nije inicijalizovan ili u testovima.
  - Izbor se pravi u provideru preko `isFirebaseReady` (`lib/core/firebase/firebase_status.dart`).
  - Nema posebnog „use case“ sloja; kontroleri direktno zovu repozitorijume.
- **Clean-ish, ali ne striktno:** neki widgeti direktno koriste `FirebaseFirestore.instance`, na primer:
  - `swipe_dog_card.dart:790` (čita `users`);
  - `notification_controller.dart:18`;
  - `poi_report_controller.dart` (piše `users` i `notifications`).
- **Navigacija:** isključivo imperativni `Navigator.push(MaterialPageRoute)`.
  - `MaterialApp` nema `routes` ni `onGenerateRoute`; nijedan `pushNamed` ne postoji.
  - `lib/app/routes.dart` (`AppRoutes`) definiše konstante koje se **nigde ne koriste**.
  - Nema go_router-a ni deep-link rutiranja.
  - Tap na push notifikaciju otvara ekran preko `navigatorKey` (`main.dart`).
- **Lokalizacija:** sopstvena klasa `L10n` (`lib/core/l10n/`) sa mapama sr/en; nema `.arb` fajlova. Jezik i tema dolaze iz `AppSettingsController` (SharedPreferences).

### Tok pokretanja
1. `main()` (`lib/main.dart`), redom:
   1. `WidgetsFlutterBinding.ensureInitialized`.
   2. `installGlobalErrorHandlers()` (Crashlytics handleri).
   3. `NotificationService().initialize()` (lokalne notifikacije + timezone).
   4. U `try`:
      - `Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform)`;
      - Firestore `persistenceEnabled: true`, `cacheSizeBytes: unlimited`;
      - FCM background handler;
      - provera `projectId`;
      - `CrashReporting.init()`;
      - `runApp(ProviderScope(child: VauVauApp()))`.
   5. U `catch`: greška ide u Crashlytics, pa `runApp(FirebaseInitErrorApp(...))`, ekran sa porukom o grešci. **Aplikacija u produkciji ne radi bez Firebase-a.** `isFirebaseReady` (`Firebase.apps.isNotEmpty`) praktično bira Local repozitorijume samo u testovima.
2. `VauVauApp` (`lib/app/app.dart`) – `MaterialApp`:
   - `navigatorKey: appNavigatorKey`;
   - tema light/dark/system iz podešavanja;
   - `locale` iz podešavanja, Material/Cupertino lokalizacije;
   - `home: SplashScreen`;
   - sluša `authStateProvider` i postavlja Crashlytics userId.
3. `SplashScreen` (2 s) → `AuthGate`.
4. `AuthGate` (`auth_gate.dart`) gleda `authStateProvider` i profil psa:
   - nije prijavljen → `AuthScreen` (login/registracija);
   - prijavljen bez psa → `DogOnboardingScreen`;
   - prijavljen sa psom → `HomeShellScreen`.
5. `HomeShellScreen`:
   - 4 taba u `IndexedStack`: **Otkrij** (Discover), **Mapa**, **Poruke** (mečevi + inbox), **Profil**;
   - **Drawer** sa stavkama Grupe, Događaji, Priče (Moments), Izgubljeni psi, Udomi, Pravila, Podešavanja, Admin (samo za `role == 'admin'`);
   - pokreće globalne „watchere“: registraciju push tokena, hitni popup za izgubljene pse, zvuk dolazne poruke (`incomingMessageSoundProvider`), brojače nepročitanih na tabovima.

### Slojevi i tok podataka (uopšteno)
```
UI (ConsumerWidget / ConsumerStatefulWidget)
   │ ref.watch / ref.listen / ref.read(...notifier)
   ▼
Kontroleri (Notifier) i izvedeni Provider-i (filtriranje, sortiranje, brojači)
   │
   ▼
Repozitorijumi (apstraktni interfejs u domain/)
   ├── Firestore…Repository  → cloud_firestore snapshots / transakcije / FieldValue
   │                            firebase_storage (StorageService) za slike
   └── Local…Repository      → in-memory seed podaci (offline / testovi)
```
- Realtime: skoro svi ekrani slušaju Firestore `snapshots()`. Firestore offline keš daje i offline čitanje.
- Server-side logika: **ne postoji**. Svi derivirani podaci se pišu sa klijenta: mečevi, brojači nepročitanih, `memberCount`, lajkovi, notifikacioni dokumenti. Na tome počiva bezbednost (vidi sekcije 5 i 11).
- Sloj notifikacija: klijent upisuje dokument u `notifications` i `users/{uid}/fcmInbox`, ali **nema Cloud Functions koja bi ih poslala kao FCM push**. Push stiže samo ako ga pošalje neki spoljni sistem, a takav ne postoji u repou.

### Navigacija i tok pokretanja (detaljno)
#### Rute
- `lib/app/routes.dart`: `AppRoutes.login = '/login'` → `LoginScreen`, `AppRoutes.register = '/register'` → `RegisterScreen`. `AppRoutes.map` se **nigde ne koristi**; `MaterialApp` u `app.dart` nema `routes`/`onGenerateRoute`, samo `home: SplashScreen()` i `navigatorKey: appNavigatorKey` (definisan u `features/notifications/presentation/push_navigation.dart`, van slice-a).
- Imperativna navigacija u slice-u:
  - `SplashScreen._openApp` → `pushReplacement(PageRouteBuilder → AuthGate)`.
  - `AuthScreen` → `popUntil(isFirst)` posle prijave/registracije; `showForgotPasswordDialog` (showDialog).
  - `ForgotPasswordDialog` → ugnježdeni `showDialog`, zatvaranje oba dijaloga.
  - `LegalConsentText` → `openLegalDocument` → `push(MaterialPageRoute → LegalDocumentScreen)`.
  - `HomeDrawer._onItemTap` → `pop()` (drawer), `popUntil(isFirst)`, `push(MaterialPageRoute → ekran)`.
  - `showLocationProminentDisclosure` → `showDialog<bool>`.

#### Tok pokretanja
1. `main()` → `WidgetsFlutterBinding.ensureInitialized()` → `installGlobalErrorHandlers()` → `await NotificationService().initialize()`.
2. `Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform)` → Firestore `persistenceEnabled: true`, `CACHE_SIZE_UNLIMITED` → `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` → provera da `projectId` nije prazan → `CrashReporting.init()` → `runApp(ProviderScope(VauVauApp))`.
3. Na bilo koju grešku: `debugPrint('🔴 MAIN CATCH…')`, Crashlytics fatal, `runApp(FirebaseInitErrorApp)`.
4. `VauVauApp` → `SplashScreen` (2 s) → `AuthGate`.
5. `AuthGate` → `LoginScreen` (= `AuthScreen`) ako nema korisnika; `DogOnboardingScreen` ako korisnik nema pse; inače `HomeShellScreen`.

#### Tabovi `HomeShellScreen` (`IndexedStack`, `NavigationBar`)
| Index | Ekran | Labela | AppBar |
|---|---|---|---|
| 0 | `DiscoverScreen` | `DiscoverStrings.title` | `DiscoverAppBar` |
| 1 | `MapScreen` | `MapStrings.tabLabel` | `MapStrings.title` + banner zakazanih šetnji |
| 2 | `MatchesScreen` | `ChatStrings.tabLabel` (badge nepročitanih) | `ChatStrings.title` + banner zakazanih šetnji |
| 3 | `ProfileScreen` | `ProfileStrings.tabLabel` | `ProfileStrings.title` + dugme za sistemski sheet |
Tačne vrednosti stringova su van slice-a.

#### Drawer (`AppDrawerCatalog` → `HomeDrawer`)
| Sekcija | id | Labela (sr) | Ikona | `kind` | Cilj |
|---|---|---|---|---|---|
| 🐕 ZAJEDNICA | `groups` | 👥 Grupe | `groups_outlined` | groups | `GroupsListScreen` |
| 🐕 ZAJEDNICA | `events` | 📅 Događaji i šetnje | `event_available_outlined` | events | `EventsScreen` |
| 🐕 ZAJEDNICA | `moments` | 📸 VauVau Moments | `camera_alt_outlined` | moments | `MomentsScreen` |
| ❤️ POMOĆ PSIMA | `lostDogs` | 🚨 Izgubljeni psi (accent, bedž „HITNO“) | `emergency_share_outlined` | lostDogs | `LostDogsScreen` |
| ❤️ POMOĆ PSIMA | `adopt` | 🏠 Udomi | `home_outlined` | adopt | `AdoptionScreen` |
| sistem | `rules` | ❓ Pravila & Podrška | `help_outline` | rules | `RulesAndSupportScreen` |
| sistem | `settings` | ⚙️ Podešavanja | `settings_outlined` | settings | `SettingsScreen` |
| samo admin | `admin` | Admin Panel (badge `newFeedbackCountProvider`) | `admin_panel_settings` | admin | `AdminDashboardScreen` |
Plus na dnu: `OfficialContactLinks(compact: true, dark: true)` i „O aplikaciji“ → `showAboutAppDialog`.

Neiskorišćeno u katalogu: `home`, `profile`, `support`, `locationPin` getteri; `primaryItems` i `footerItems` („Legacy flat lists“); `items`; `DrawerItemKind.tab` i `page`.

### Tok podataka u četu, grupama i događajima (detaljno)
#### 1. Inicijalizacija 1:1 inbox-a
1. `chatRepositoryProvider` čeka auth (`authStateProvider` + `firestoreAuthReadyProvider`); dok nije spreman koristi `LocalChatRepository` sa praznim seed-om (u Firebase režimu) → `hasLoadedInbox == true` odmah, prazan inbox.
2. Kad je auth spreman, provider se rebuild-uje, kreira `FirestoreChatRepository` i poziva `start()`.
3. `_onRooms` gradi `_inbox` iz soba (poruke samo za sobe koje imaju aktivan message listener), gasi listenere za sobe koje više ne postoje, sinhronizuje walk-invite listenere za sve sobe.
4. Prvi snimak iz keša se zadržava do 1000 ms (`_cacheHoldTimer`) da se ne bi prikazao delimičan inbox; snimak sa servera odmah objavljuje (`_publishInitialInbox` → `_loadedController.add(true)`).
5. `ChatInboxController` sluša `watchInbox()`; `chatInboxLoadedProvider` se osvežava preko `_chatInboxLoadedStreamProvider`; `ChatListScreen` prelazi sa skeleton-a na listu.

#### 2. Otvaranje razgovora (attachRoom/detachRoom)
1. `ChatListScreen._openChat` → `ChatInboxController.markRead(id)` (lokalno unread=0 + Firestore merge + `notificationController.markChatMessagesRead`) → push `ChatDetailScreen`.
2. `ChatDetailScreen` u postFrame: čita `unreadCount` (već 0 ako se došlo iz liste – vidi dug), `attachRoom(id)` → repo `_roomAttachCounts[id]++` i `_ensureMessageSub` (limit 30, `timestamp desc`).
3. `_onMessages`: obrne listu u hronološki; ako soba još nije u `_inbox` → `_pendingMessages[id]`; inače spoji u razgovor i emituje sa debounce-om 80 ms.
4. Ekran u `ref.listen(chatInboxProvider)` poziva `_onMessagesUpdated` (inicijalni skrol na prvu nepročitanu ili na dno, zatim `markRead`) i `_clearUnreadWhileViewing` (markRead ako je app u `resumed`).
5. `dispose` → `detachRoom` (preko keširanog notifiera, ne preko `ref`) → ref-count−1; na 0 gasi listener i prazni `messages` (inbox preview koristi `lastMessagePreview`).

#### 3. Slanje 1:1 tekstualne poruke
1. UI: `ChatDetailScreen._send` – čisti polje i reply, fokus, `_scrollToEnd`, poziva `chatInboxProvider.notifier.sendMessage(id, text, replyTo)`.
2. Kontroler → `repo.sendMessage`.
3. Repo: trim; `peerId` iz `_inbox`; `_replyFields` (ime: `senderName` → `'Ti'`/`currentUserName` za moje → `ownerName` razgovora → `'Korisnik'`; tekst `clipReplyText(previewText)`); `_appendOptimistic` sa id `local-N` (`isRead: true`, `unreadCount: 0`, `isNewMatch: false`) → `_emitNow()` (UI odmah vidi poruku).
4. `_writeMessage`: zaštita – ako `senderId` nije ulogovani korisnik ili je `'local-user'` → uklanja optimističku poruku, `StateError('Poruka mora imati senderId ulogovanog korisnika.')`. Inače `chats/{id}/messages.add(payload)` pa `chats/{id}.set({lastMessage, lastMessageTimestamp, isNewMatch:false, unreadByUser:{me:0, peer:increment(1)}}, merge)`.
5. Greška → `developer.log`, `_removeOptimistic`, `CrashReporting` (mrežne greške se samo loguju), `rethrow` → UI vraća tekst u polje i prikazuje SnackBar.
6. Povratak: listener poruka (limit 30) dobija pravu poruku sa server id-jem; `_onMessages` **zamenjuje** celu listu poruka razgovora snimkom → lokalna `local-N` poruka nestaje jer snimak sadrži pravu. (Napomena: ako je soba otvorena ali snimak još ne sadrži novu poruku, optimistička poruka može nakratko nestati pri sledećem snimku – zamena je cela lista, nema spajanja po id-ju; ovo je zaključak iz koda `_merge`, nije testirano.) Room listener dobija novi `lastMessage`/`unreadByUser`; kod primaoca `unreadByUser[peer]` raste → `unreadCount` u inbox-u.
7. Push: posle uspešnog `await` kontroler poziva `pushControllerProvider.notifier.notifyMessage(senderName: authUser.displayName ?? chat.ownerName ?? 'Neko', preview, dogId, peerUserId, conversationId)`. U `PushController._dispatch` (van ovog dela, pročitano radi konteksta) `notifyMessage` ide sa `local: false` → samo `gateway.queueForUser(peerUserId, payload)`; implementacija `queueForUser` nije u ovom delu i nije proverena.

#### 4. Fotografija (1:1)
`ChatDetailScreen._pickPhoto` → izbor izvora → `ImagePicker.pickImage(imageQuality: 72)` → `_sendingPhoto = true` → `ChatInboxController.sendPhoto`: `ContentValidationService.validateImage` → `ImageUploadService.uploadFile(folderName: 'chats')` → `repo.sendPhoto` (optimistički, `text: ''`, `imageUrl`, `type: 'text'`, preview sobe `'📷 Fotografija'`) → `notifyMessage(preview: '📷 Fotografija')`. Optimistička poruka se dodaje tek POSLE uploada.

#### 5. Poziv na šetnju (1:1)
1. `showScheduleWalkSheet` → `onSend(walkTime, location)` → `ChatInboxController.sendWalkInvite` (tiho ignoriše prošlo vreme) → repo: optimistička poruka `walkInvite/pending`, Firestore `type: 'walk_invite'`, `status: 'pending'`, `walkTime: Timestamp`, `walkLocationName`, preview `'Poziv na šetnju: X'`.
2. Push: `notifyWalk(dogName: chat.dogName, ownerName: chat.ownerName, ...)` → `queueForUser(peer)`. Napomena: `dogName`/`ownerName` su podaci PEER-a (iz perspektive pošiljaoca), a payload ide peer-u – kako `NotificationStrings.pushWalkBody` to formuliše nije u ovom delu; vredi proveriti da li primalac dobija sopstveno ime psa.
3. Odgovor primaoca: `WalkInviteCard` (dugmad samo ako `pending`, nije moja, i `onAccept != null`) → `respondToWalkInvite` → optimistički status → `update({'status': ...})`, rollback na grešku.
4. Walk invite listeneri (`where type == 'walk_invite'`) za SVE sobe pune `_walkInvites` → `chatWalkInvitesProvider` → `scheduledWalksProvider` (samo `accepted` i u budućnosti, osvežava se i svakih 1h preko `scheduledWalksClockProvider`) → `ScheduledWalksBanner` u `HomeShellScreen`.

#### 6. Lokacija (1:1)
`showLocationPickerSheet` → `sendLocationPin` → optimistička poruka `locationPin` → Firestore `type: 'location_pin'`, `text: locationName`. Bez push-a.

#### 7. Lajkovi
- **1:1:** `MessageBubble`/`LocationPinBubble` (lajk samo tuđih poruka; prikaz brojača i kod svojih ako > 0) → `toggleMessageLike` → optimistički novi niz → `messages/{id}.update({'likes': nextLikes})` (ceo niz, ne `arrayUnion` – moguća trka ako dvoje istovremeno lajkuju), rollback na grešku. Ako poruka nije u hidratisanom `_inbox`-u, `previous` je null pa se piše niz samo sa mojim uid-om (prepisuje postojeće lajkove).
- **Grupe/događaji:** `_GroupMessageBubble` → `toggleMessageLike` → Firestore transakcija čita `likes` i radi `tx.set(merge)`. Bez optimističkog update-a; UI se osvežava preko listenera poruka. Vidi dug: `_stringList` vraća `const []` kad polje ne postoji → `ids.add` baca izuzetak.

#### 8. Unread brojači
- **1:1:** server-side mapa `unreadByUser` (`increment(1)` za peer-a pri svakoj poruci, `0` za pošiljaoca; `markRead` postavlja `0`). Fallback na zajednički `unreadCount`.
- **Grupe/događaji:** klijentski – `members/{uid}.lastReadTimestamp` vs `createdAt` poruka koje nisu moje (`GroupInboxThread.fromMessages`). Zahteva pun stream svih poruka svake grupe/događaja.
- **Agregat:** `totalUnreadChatCountProvider` broji thread-ove sa unread > 0 (badge na tabu Poruke u `HomeShellScreen`).
- **Zvuk:** `incomingMessageSoundProvider` (detektor: rast unread + aktivnost u poslednjih 60 s).
- **Lokalne notifikacije za grupe/događaje:** `groupUnreadAlertsProvider` → `notifyGroupThread(...)` (u `PushController` ide sa `local: true` i bez `peerUserId` → `present` lokalno, bez `queueForUser`). Push za grupne poruke drugim članovima se iz ovog koda NE šalje.

#### 9. Grupe – slanje i pridruživanje
`GroupsListScreen` „Pridruži se“ → `GroupsController.join` → transakcija (`memberIds`, `memberCount`) + `members/{uid}` → `GroupChatScreen(groupId)`. Slanje: `_sendText` → `GroupsController.sendText` → `messages.add` + update `lastMessage*` na grupi → listener `groupMessagesProvider(groupId)` → `ref.listen` u ekranu → skrol + `markRead`. Nema optimističkog prikaza (poruka se pojavljuje tek iz Firestore snimka; Firestore lokalni latency compensation će je verovatno brzo prikazati, ali sa `createdAt` = `DateTime.now()` dok serverTimestamp nije razrešen).

#### 10. Događaji – join i chat
`EventsScreen` „Pridruži se“ → `EventsController.join` → transakcija `participantUserIds` + `members/{uid}` + (ako je dodat) poruka „X se pridružio/la šetnji! 🐾“ poslata kao korisnik + `markRead` → `GroupChatScreen(eventId)`. Ostatak chata identičan grupama.

---
## 4. EKRANI I FUNKCIONALNOSTI
Status: **Završeno** = radi kraj-do-kraja u kodu; **Delimično** = radi uz navedena ograničenja; **Ne radi** = postoji bag koji blokira tok; **Placeholder** = UI bez prave logike. Status je procena iz koda, a ne iz ručnog testiranja na uređaju.
### 4.1 Core, app, servisi, auth, splash, legal, lokacija, home
#### `SplashScreen` – `lib/features/splash/presentation/screens/splash_screen.dart`
- Vidi: full-screen `assets/images/vauvau_splash.png` (`BoxFit.contain`) na boji `colorScheme.surface`. Nema interakcije.
- Ponašanje: postavlja transparentan status bar; posle `hold = 2 s` radi `Navigator.pushReplacement(PageRouteBuilder(AuthGate), fade 420 ms)`.
- Navigacija do njega: `MaterialApp.home`.
- Provideri: nema.
- Status: **završeno**. Napomena: konstanta `SplashScreen.tagline` i `background` se ne koriste u `build`; `SplashClouds`/`SplashMascot` postoje, ali se ne koriste (ostaci starijeg dizajna).

#### `AuthGate` – `lib/features/auth/presentation/auth_gate.dart`
- Vidi: spinner dok se učitava, zatim `LoginScreen`, `DogOnboardingScreen` (van slice-a) ili `HomeShellScreen`.
- Logika: `authStateProvider` loading → spinner; error → `LoginScreen`; null → `LoginScreen`; korisnik postoji → gleda `ownerDogsProvider` (van slice-a): greška bez vrednosti → `HomeShellScreen`; loading → spinner; prazna lista → `DogOnboardingScreen`; inače `HomeShellScreen`.
- Takođe drži živim `dogOnboardingControllerProvider.notifier` i sluša `appSettingsProvider.language`.
- Navigacija: iz `SplashScreen` (pushReplacement). Nije imenovana ruta – zamena sadržaja unutar iste rute.
- Status: **završeno**.

#### `AuthScreen` (+ `LoginScreen`, `RegisterScreen`) – `lib/features/auth/presentation/auth_screen.dart`
- Vidi: AppBar sa naslovom „Prijava“/„Registracija“ i `TabBar` sa dva taba.
- Tab **Prijava**: `BrandMark`, email, lozinka (prikaz/sakrij), „Zaboravljena lozinka?“ (otvara `ForgotPasswordDialog`), poruka greške, dugme „Prijava“ ili spinner.
- Tab **Registracija**: avatar za profilnu sliku vlasnika (upload odmah u Storage `users/{uid}`… — vidi napomenu niže), ime vlasnika, email, grad + naselje (`CityNeighborhoodFields`, uz slobodan unos), lozinka, potvrda lozinke, `LegalConsentText`, dugme „Napravi nalog“.
- Validacija: email samo `isEmpty || !contains('@')`; lozinka ≥ 6 karaktera; potvrda mora da se poklapa; ime obavezno; naselje obavezno (dodatno proverava i SnackBar-om).
- Posle uspeha: `Navigator.popUntil(isFirst)`; posle registracije ponovo poziva `saveOwnerCustomPhoto` („belt-and-suspenders“).
- Provideri: `authControllerProvider`, `authStateProvider`, `authRepositoryProvider`; direktno `FirebaseAuth.instance` i `StorageService()`.
- Greške: prikazuju se **dvaput** – SnackBar preko `ref.listen` i crveni tekst u formi; isti `error` iz kontrolera se prikazuje u oba taba.
- Navigacija: preko `AuthGate` (kao `LoginScreen`). `RegisterScreen` i imenovane rute `/login`, `/register` postoje u `AppRoutes`, ali se ne koriste.
- Status: **delimično** – email/lozinka prijava i registracija rade; Google prijava je namerno sakrivena (komentari `// Phase: Google Sign-In hidden` na linijama 19–20, 219–228, 319). Upload profilne slike pre registracije: `_pickOwnerPhoto` zove `StorageService.uploadImageFromGallery(folderName: 'users')` koji zahteva prijavljenog korisnika (`ownerFolder` baca `StateError` bez uid-a) – na ekranu registracije korisnik još nije prijavljen, pa će upload po kodu baciti grešku „Moraš biti prijavljen da bi poslao sliku.“ (osim ako je neki korisnik već prijavljen). Ovo je zaključak iz koda, nije testirano.

#### `ForgotPasswordDialog` – `lib/features/auth/presentation/forgot_password_dialog.dart`
- Vidi: dijalog sa objašnjenjem, poljem za email, „Otkaži“ i „Pošalji link“ (spinner tokom slanja). Posle uspeha – dijalog „Link je poslat“ sa adresom i savetom da proveri Spam; posle greške – dijalog sa porukom po kodu (`user-not-found`, `invalid-email`, `too-many-requests`, `network-request-failed`, ostalo).
- Regex: `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$` (TLD ograničen na 2–4 znaka).
- Servisi: `FirebaseAuth.instance.sendPasswordResetEmail` direktno (zaobilazi `AuthRepository`/`AuthController`).
- Navigacija: `showForgotPasswordDialog(context, initialEmail)` iz taba Prijava.
- Status: **završeno** (funkcionalno), ali zaobilazi repozitorijum i ne radi sa `LocalAuthRepository`.

#### `HomeShellScreen` – `lib/features/home/presentation/home_shell_screen.dart`
- Vidi: drawer (`HomeDrawer`), AppBar (na tabu 0 `DiscoverAppBar`, inače naslov + meni dugme + na tabu 3 dugme „više akcija“ (`showProfileSystemSheet`) + zvonce sa badge-om nepročitanih notifikacija (`showNotificationsSheet`)), `ScheduledWalksBanner` na tabovima 1 i 2, `IndexedStack` sa 4 ekrana, `NavigationBar` (badge nepročitanih chatova na tabu 2).
- Provideri: `homeTabIndexProvider`, `scheduledWalksProvider`, `notificationUnreadCountProvider`, `totalUnreadChatCountProvider`, `appSettingsProvider`, `groupUnreadAlertsProvider`, `incomingMessageSoundProvider` (svi osim prvog van slice-a); omotači `PushBootstrap`, `LostDogEmergencyHost`.
- Navigacija: iz `AuthGate`.
- Status: **završeno** u okviru slice-a (sadržaj tabova je van slice-a). Napomena: naslov za tab 0 u nizu `titles` je `''`, ali se na tabu 0 ionako koristi `DiscoverAppBar`.

#### `HomeDrawer` – `lib/features/home/presentation/home_drawer.dart`
- Vidi: tamna pozadina `0xFF111827`; zaglavlje „🐾 VauVau“ + avatar (`ownerAvatarUrl` ako počinje sa `http`, inače inicijal) + ime (prva reč `profile.ownerName`, ili deo pre `@`, ili „VauVau“); sekcije ZAJEDNICA, POMOĆ PSIMA, sistemske stavke, admin stavka (samo ako `isAdminProvider`) sa badge-om `newFeedbackCountProvider`; `OfficialContactLinks`; dugme „O aplikaciji“ (`showAboutAppDialog`).
- Na tap: zatvara drawer, `popUntil(isFirst)`, pa `Navigator.push(MaterialPageRoute)` na odgovarajući ekran.
- Provideri: `profileControllerProvider`, `authStateProvider`, `homeTabIndexProvider`, `isAdminProvider`, `newFeedbackCountProvider`.
- Status: **završeno**. Grananje za `DrawerItemKind.tab` i `selected` stanje nikad nisu aktivni (nijedna stavka nema `tabIndex` ni `kind: tab`).

#### `DrawerSectionScreen` – `home_drawer.dart` (362–385)
- Vidi: AppBar sa labelom i `destination.body` tekst.
- Navigacija: samo za `DrawerItemKind.page`; nijedna stavka u katalogu nema `kind: page`, pa je **nedostupan**.
- Status: **placeholder** (generički ekran sa tekstom, `body` podrazumevano `''`).

#### `LegalDocumentScreen` – `lib/features/legal/presentation/legal_document_screen.dart`
- Vidi: naslov (Politika privatnosti / Uslovi korišćenja), „Poslednje ažuriranje: 12. oktobar 2026.“, sekcije teksta, kontakt, dugme „Otvori u pregledaču“ (i u AppBar-u).
- Servisi: `externalLinkLauncherProvider`; SnackBar `linkError` ako link ne može da se otvori.
- Navigacija: `openLegalDocument(context, kind)` → `Navigator.push(MaterialPageRoute)`; poziva se iz `LegalConsentText` (registracija) i (van slice-a) verovatno iz podešavanja.
- Status: **završeno** (sadržaj je statičan, ugrađen u aplikaciju).

#### `FirebaseInitErrorApp` – `lib/app/firebase_init_error_app.dart`
- Vidi: centriran tekst „Firebase nije pokrenut. Pokrenite flutterfire configure i pokušajte ponovo.“ + `error.toString()`.
- Status: **završeno** kao fallback, ali tekst je developerski (krajnji korisnik vidi instrukciju za `flutterfire configure` i sirovu grešku).

#### Dijalog lokacije – `showLocationProminentDisclosure` (`location_disclosure.dart`)
- Vidi: „Upotreba lokacije“, objašnjenje GPS-a tokom šetnje i dok je app otvorena; „Ne sada“ / „Nastavi“.
- Poziva se (van slice-a) iz `map_screen.dart`.
- Status: **završeno**.

### 4.2 Chat, grupe, događaji
#### `ChatListScreen` – `chat/presentation/chat_list_screen.dart` (preko `MatchesScreen` → `ChatsScreen`)
- **Navigacija:** tab index 2 („Poruke“) u `HomeShellScreen` (`IndexedStack` sa `MatchesScreen()`); `ScheduledWalksBanner` se prikazuje iznad tabova 1 i 2.
- **Prikaz:** traka „Novi lajkovi 🐾“ (ako inbox učitan i ima lajkova; tap → `DogDetailSheet`), polje za pretragu (po imenu psa/vlasnika; za grupe po naslovu; za događaje po naslovu i lokaciji), skeleton (7 redova) dok `chatInboxLoadedProvider` nije true, prazno stanje sa dugmetom „Pronađi društvo“ → `homeTabIndexProvider.showDiscover()`, „Nema razgovora za tu pretragu.“, horizontalna lista „Novi mečevi“ (`PulseBadge`), lista „Aktivna ćaskanja“ – spojeni 1:1, grupe (badge „👥 Grupa“) i događaji (badge „📅 Šetnja“), sortirano po `lastActivityAt`, sa vremenom i `UnreadCountBadge`.
- **Akcije:** tap → 1:1: `markRead` pa `ChatDetailScreen`; grupa: `groupsController.markRead` pa `GroupChatScreen(groupId)`; događaj: `eventsController.markRead` pa `GroupChatScreen(eventId)`. Long press (samo 1:1 i novi mečevi) → `showContentReportSheet(ReportContentType.dog)`.
- **Provideri:** `chatInboxLoadedProvider`, `visibleConversationsProvider`, `joinedGroupThreadsProvider`, `joinedEventThreadsProvider`, `incomingLikesProvider`, `chatNowProvider`, `homeTabIndexProvider`, `chatInboxProvider`, `groupsControllerProvider`, `eventsControllerProvider`.
- **Status: završeno** – sve grane UI-ja su implementirane i povezane sa providerima. Napomena: „Prazno stanje“ uslov proverava `conversations` (svi, ne filtrirani), a lista novih mečeva nema prikaz unread-a. Vidi dug o `markRead` pre otvaranja (poništava skok na prvu nepročitanu).

#### `ChatDetailScreen` – `chat/presentation/chat_detail_screen.dart`
- **Navigacija:** iz `ChatListScreen._openChat`; iz `notification_routing.dart:139`; preko omotača `ChatScreen` iz `match_dialog.dart:44`, `swipe_dog_card.dart:712`, `map_screen.dart:933`, `adoption_detail_screen.dart:256`.
- **Prikaz:** AppBar sa avatarom psa, naslovom `'Pas (Vlasnik)'`, podnaslovom (`peerSubtitle`: „U šetnji“ zeleno ako `profile.walking`, inače rasa · lokacija, ili „Novi meč“/„Razgovor“) – rasa/lokacija/walking se dohvataju `loadDiscoverProfile`. Akcije: ikona šape (zakaži šetnju), `SafetyMenuButton` (blokiranje → `pop`). Lista poruka: `WalkInviteCard`, `LocationPinBubble`, `MessageBubble`. `ReplyComposeBanner`, `LinearProgressIndicator` pri slanju slike, `ChatInputBar`. Ako razgovor nije u inbox-u → „Razgovor nije pronađen.“
- **Akcije:** slanje teksta (pri grešci vraća tekst i reply u polje + `showNetworkErrorSnackBar`), long press → Odgovori / Prijavi (`showContentReportSheet(ReportContentType.message)`), lajk tuđe poruke, Prihvati/Odbij poziv, tap na avatar/naslov → `DogDetailSheet` (fallback profil iz razgovora), attach meni: Fotografija (galerija/kamera, `imageQuality: 72`), Zakaži šetnju (`showScheduleWalkSheet`), Pošalji lokaciju (`showLocationPickerSheet`).
- **Životni ciklus:** postFrame u `initState`: pamti `_openUnreadCount`, `attachRoom`; `dispose` → `detachRoom` preko keširanog notifiera. Posle inicijalnog skrola → `markRead`; nove poruke dok je ekran otvoren i app `resumed` → `markRead`.
- **Provideri/servisi:** `chatInboxProvider`, `chatNowProvider`, `authStateProvider`, `loadDiscoverProfile`, `ImagePicker`.
- **Status: završeno** – sve akcije imaju implementaciju i obradu grešaka. Ograničenje: učitava se samo poslednjih 30 poruka (`messagePageSize`), nema paginacije/„učitaj starije“ (nema koda za to).

#### `ChatScreen` (`chat_screen.dart`), `MatchesScreen` (`matches_screen.dart`), `ChatsScreen` (`screens/chats_screen.dart`)
Čisti omotači/alias-i bez logike. **Status: završeno** (ali suvišni slojevi – vidi dug).

#### `ScheduleWalkBottomSheet` / `showScheduleWalkSheet` – `chat/presentation/schedule_walk_sheet.dart`
- **Navigacija:** iz `ChatDetailScreen` (ikona šape i attach meni) i iz `GroupChatScreen` (attach meni).
- **Prikaz/akcije:** naslov „Zakaži zajedničku šetnju“, datum (default sutra, `showDatePicker` od danas do +60 dana), vreme (default 18:00), chipovi 3 lokacije iz `scheduledWalkLocations`, polje za sopstvenu lokaciju, Otkaži / Pošalji poziv. Prošlo vreme → SnackBar; pri izboru datuma u prošlosti vreme se pomera na sledeći pun sat.
- **Napomena:** `onSend` je `void Function`, sheet ga poziva i odmah `pop()` – ne čeka async rezultat.
- **Status: završeno.**

#### `LocationPickerSheet` / `showLocationPickerSheet` – `widgets/location_picker_sheet.dart`
- **Navigacija:** samo iz `ChatDetailScreen` attach menija (grupe/događaji nemaju location pin).
- **Prikaz/akcije:** chipovi 3 lokacije, ručni unos, Otkaži / Pošalji (vraća string).
- **Status: završeno** (lokacija je samo tekst, nema koordinata/mape).

#### `showMessageActionsSheet` – `widgets/message_reply.dart`
Sheet sa „Odgovori na poruku“, opciono „Prijavi poruku“, „Otkaži“. U grupnom chatu se zove sa `canReport: false`. Tekstovi nisu lokalizovani. **Status: završeno.**

#### `ScheduledWalksBanner` – `widgets/scheduled_walks_banner.dart`
Prikazuje „Zakazane šetnje (N)“, na tap proširuje listu `pas · lokacija · d.M. HH:mm`. Navigacija: `HomeShellScreen` za tab 1 i 2. Samo prihvaćeni 1:1 pozivi (iz `scheduledWalksProvider`), ne grupni/event pozivi. **Status: završeno.**

#### `GroupChatScreen` – `groups/presentation/group_chat_screen.dart`
- **Navigacija:** `GroupsListScreen` (posle join-a ili „Otvori chat“), `EventsScreen` (posle join-a ili „Otvori chat“), `ChatListScreen` (tap na grupu/događaj), `notification_routing.dart:88,100`.
- **Prikaz:** AppBar sa slikom, naslovom (fallback `GroupsStrings.title` dok se grupa/događaj ne učita), „N članova“ (za događaj `participantCount`). Prazno: „Još nema poruka. Reci zdravo čoporu!“. Poruke: `WalkInviteCard` (sa `acceptedCount` i ličnim statusom preko `_groupWalkAsChat`) ili `_GroupMessageBubble` (ime pošiljaoca, reply, slika, tekst, vreme, lajk). Reply banner, progress pri slanju slike, `ChatInputBar`.
- **Akcije:** slanje teksta, attach meni (Zakaži šetnju, Fotografija), long press → samo „Odgovori“ (bez prijave), lajk, Prihvati/Odbij poziv (po korisniku), tap na avatar → `loadDiscoverProfile(ownerId: senderId)` → `DogDetailSheet` (fallback profil sa `size: 'srednji'`, `location: 'Srbija'`).
- **markRead:** posle inicijalnog skrola i pri SVAKOJ novoj poruci dok je ekran otvoren (bez provere lifecycle-a, za razliku od 1:1).
- **Provideri:** za grupu `groupByIdProvider`, `groupMessagesProvider`, `groupLastReadProvider`, `joinedGroupThreadsProvider`, `groupsControllerProvider`; za događaj `eventByIdProvider`, `eventMessagesProvider`, `eventLastReadProvider`, `joinedEventThreadsProvider`, `eventsControllerProvider`; `groupsMemberIdProvider` (i za događaje).
- **Status: delimično** – funkcionalno radi, ali: `_sendText` (l. 264–291), `_openScheduleWalk` (l. 332–352) i `_respondToWalk` (l. 425–442) nemaju `try/catch` → pri grešci (npr. `StateError('Morate biti prijavljeni.')`) tekst je već obrisan iz polja i greška nije prikazana; nema prijave poruka; nema provere članstva (ekran se može otvoriti iz notifikacije bez da je korisnik član – da li rules to blokiraju, ne može se utvrditi iz ovog koda); učitavaju se SVE poruke bez limita; `_jumpToEndWithRetry` nema `scheduleFrame()` koji 1:1 verzija ima uz komentar da bez toga callback (i `markRead`) „would otherwise never run“ kod kratkog chata.

#### `GroupsListScreen` – `groups/presentation/groups_list_screen.dart`
- **Navigacija:** iz `HomeDrawer` (`DrawerItemKind.groups`, home_drawer.dart:131).
- **Prikaz:** AppBar „Grupe za šetnju i rase“ + dugme „Napravi novu grupu“; podnaslov; `GroupCard` za svaku odobrenu grupu.
- **Akcije:** „+ Pridruži se“ → `join` pa otvara chat; „💬 Otvori chat“; dugme u AppBar-u → `CreateGroupSheet`.
- **Provideri:** `groupsControllerProvider`, `groupsMemberIdProvider`.
- **Status: delimično** – nema loading ni prazno/greška stanja (početno stanje kontrolera je `const []`, prikazuje se samo podnaslov); `_join` (l. 51–61) nema `try/catch` (Firestore `joinGroup` baca `StateError` ako korisnik nije prijavljen).

#### `CreateGroupSheet` – `groups/presentation/groups_list_screen.dart:81`
- Forma: naziv (obavezan + `ContentValidationService.validateTitle`), opis (opciono). „Pošalji na pregled“ → `createGroup` (uvek pending) → dijalog „Zahtev poslat“ (zatvara i sheet) ili dijalog „Greška“ sa porukom izuzetka.
- **Status: završeno** (odobravanje radi admin preko `pendingGroupsProvider` / `approveGroup` u `admin_groups_tab.dart`, van ovog dela).

#### `EventsScreen` – `events/presentation/events_screen.dart`
- **Navigacija:** iz `HomeDrawer` (`DrawerItemKind.events`, home_drawer.dart:132) i iz `EventsPromoBanner` (koji se ne koristi nigde).
- **Prikaz:** naslov „VauVau Događaji“, baner tekst, chipovi gradova („Svi gradovi“ + `SerbiaLocations.cities`), chipovi Svi/Predstojeći/Moje, dugme „📅 Organizuj šetnju“, lista `EventCard` (samo `isListed` – do 6h posle početka), prazna poruka po filteru.
- **Akcije:** Pridruži se → `join` pa `GroupChatScreen(eventId)`; Otvori chat; Organizuj → `showCreateEventSheet`.
- **Provideri:** `eventsControllerProvider`, `eventsMemberIdProvider`, `eventsCityFilterProvider`.
- **Status: delimično** – nema loading stanja (dok stream ne stigne prikazuje „Nema događaja za ovaj filter.“); `_join` (l. 164–174) bez `try/catch`.

#### `CreateEventScreen` / `showCreateEventSheet` – `events/presentation/create_event_screen.dart`
- **Navigacija:** iz `EventsScreen` (ikona u AppBar-u i veliko dugme).
- **Prikaz:** Naslov (obavezan), Grad (dropdown), Lokacija (dropdown iz `eventVenuesProvider(cityId)`, opcija „Ostalo / Ručni unos“ otvara tekstualno polje), datum (do +365 dana) i vreme (24h), pun prikaz `EventsStrings.when`, Opis (obavezan), dugme za fotografiju (samo galerija; nema pregleda slike, samo promena teksta dugmeta u „Fotografija (opciono)“), „Objavi šetnju“.
- **Akcije:** validacija, provera budućeg vremena, `eventsController.create(...)` → dijalog „Uspešno kreirano“ (zatvara sheet) ili „Greška“.
- **Status: završeno** (funkcionalno). Sitnica: tekst dugmeta za sliku posle izbora je „Fotografija (opciono)“ – ne pokazuje da je slika izabrana na jasan način.

#### `EventCard`, `GroupCard`, `EventsPromoBanner`
Prezentacioni widgeti (opisani u Fajlovima). `EventsPromoBanner` – **status: nekorišćen** (nema reference u `lib/`). `ConversationTitle` (dog_avatar.dart:35) – **nekorišćen**.

### 4.3 Discover, psi (zdravlje, podsetnici), profil i podešavanja
| Ekran / sheet | Fajl / klasa | Šta korisnik vidi i radi | Provideri / servisi | Navigacija | Status |
|---|---|---|---|---|---|
| Discover | `discover_screen.dart` / `DiscoverScreen` | Naslov „Psi u tvojoj blizini”, bedž „{grad} · {radius} km”, čipovi Svi/U šetnji/Mali/Srednji/Veliki, 2-kolonski grid `DiscoverGridCard`, infinite scroll (učitava kad je <400 px do kraja), tap → `DogDetailSheet`, long-press → prijava sadržaja (`showContentReportSheet`), prazno stanje | `discoverControllerProvider`, `matchingFiltersProvider`, `discoverFeedControllerProvider` | Tab 0 u `HomeShellScreen` (`IndexedStack`), AppBar = `DiscoverAppBar` | **Završeno**, uz napomene: bedž prikazuje `filters.radiusKm`, a ne efektivni `DiscoverArea.radiusKm` (koji može biti 30 kad je grad izabran); `isMine` grana je praktično mrtva jer `discoverFeedProvider` već izbacuje sopstvene pse; grad u bedžu je `myDog.cityName`, koji za mock psa daje „Novi Sad”. |
| Discover AppBar | `discover_app_bar.dart` / `DiscoverAppBar` | Meni (drawer), naslov aplikacije, pretraga, filteri, notifikacije sa brojem | `notificationUnreadCountProvider` | `HomeShellScreen` kad je tab 0 | **Završeno** |
| Pretraga | `discover_search_sheet.dart` / `_DiscoverSearchSheet` | TextField sa autofokusom, live filtriranje, brisanje | `discoverControllerProvider` | `showDiscoverSearchSheet` iz AppBar-a | **Završeno** |
| Napredni filteri | `discover_filters_bottom_sheet.dart` / `DiscoverFiltersBottomSheet` | Pol, veličina, energija, radius 1–20 km, starost 0–15, samo vakcinisani/sterilisani, Poništi/Primeni | `matchingFiltersProvider` | `showDiscoverFiltersSheet` iz AppBar-a | **Delimično**: radius slider ide do 20, a Podešavanja i drugi filter sheet do 30 (vrednost 30 se prikazuje klampovano na 20); nema izbora grada (postoji samo u `MatchingFiltersSheet`); „ god.” je hardkodovano (`:188`); filteri osim radiusa se gube pri restartu. |
| Prazno stanje | `discover_empty_state.dart` / `DiscoverEmptyState` | Ikona, „Nema više pasa…”, dugme Resetuj filtere | `discoverControllerProvider` | Unutar `DiscoverScreen` | **Završeno** |
| Detalji psa | `swipe_dog_card.dart` / `DogDetailSheet` | `DraggableScrollableSheet` 92%: galerija, ime + pol + status, rasa/starost, lokacija, metrike (starost/veličina/pol), energija (3 trake), težina, `CompatibilityCard`, „O psu”, priče (`DogStoriesSection`), zdravlje (vakc./steril./čip.), osobine, slaganje, voli/ne voli, vlasnik (avatar iz `users/{ownerId}`), meni bezbednosti (prijava/blokiranje), akcioni bar: Zatvori, Like/Unlike, Super Like, „Pošalji poruku” | `authStateProvider`, `discoverControllerProvider`, `discoverRepositoryProvider`, `chatInboxProvider`, direktno `FirebaseFirestore.instance` | Iz Discover-a, `chat_detail_screen`, `chat_list_screen`, `group_chat_screen`, `story_viewer`, `notification_routing` | **Završeno** uz napomene: Super Like dugme ne proverava unapred da li je dnevni limit iskorišćen niti da li je ovaj pas već super-lajkovan (`_sent` je samo lokalni state); greške lajka koje nisu mrežne se samo loguju i UI ostaje „lajkovano” (`:950-963`); `_OwnerRow` zove Firestore direktno iz widgeta (`:789`). |
| Swipe kartica | `swipe_dog_card.dart` / `SwipeDogCard` | Kartica sa slikom, indikatorima slika, distancom, imenom, osobinama, bio | – | **Nigde se ne koristi** | **Placeholder / mrtav kod** |
| Match dijalog | `match_dialog.dart` / `MatchDialog` | Tamni overlay „Novi meč!”, „{moj pas} + {njihov pas}”, dve slike, kompatibilnost, „Pošalji poruku”, „Nastavi sa pretragom” | `discoverControllerProvider`, `chatInboxProvider` | `showMatchDialogIfNeeded` nakon like/super like koji vrati `true` | **Završeno** (u lokalnom režimu se nikad ne prikazuje jer local repo uvek vraća `false`). |
| Super Like popup / limit dijalog | `swipe_dog_card.dart` / `_SuperLikeButtonState._showSuccessPopup`, `_showDailyLimitDialog` | Popup sa zvezdom koji se zatvara posle 2,5 s; AlertDialog „Dnevni Super Like” | – | Iz `_SuperLikeButton` | **Završeno** |
| Galerija / viewer | `dog_photo_gallery.dart` / `DogPhotoGallery`, `DogPhotoViewer` | Swipe kroz slike, strelice, brojač, tap/ikona → full-screen viewer sa pinch i double-tap zoomom, vraća poslednji indeks | – | Iz `DogDetailSheet`; `showDogPhotoViewer` i iz chat/grupa | **Završeno** |
| Profil | `profile_screen.dart` / `ProfileScreen` | Zaglavlje vlasnika (avatar sa upload-om iz galerije/kamere, ime, lokacija, bio, metrike psi/momenti/rasa), „Moji psi” čipovi, kartica psa (avatar, metrike, bedževi, lokacija, kg, bio, temperament, thumbnailovi → fullscreen galerija, Obriši psa (ako >1), Izmeni psa), `StoryHighlightsRow`, `DogHealthTab`, dugmad Dodaj psa / Izmeni profil | `profileControllerProvider`, `authStateProvider`, `momentsControllerProvider`, `StorageService` | Tab 3 u `HomeShellScreen`; AppBar ikonica → `showProfileSystemSheet` | **Završeno** uz napomene: `PageController` za galeriju se kreira u builderu i ne dispose-uje (`:263`); broj momenata zavisi od toga šta `momentsControllerProvider` trenutno drži (van slice-a). |
| Izmena psa | `edit_profile_screen.dart` / `EditProfileScreen` | Ime, rasa, bio, godine/meseci, pol, veličina, težina, vakc./čip./steril., temperament, voli/ne voli, slike (dodavanje/brisanje odmah upisuje u Firestore), Sačuvaj | `profileControllerProvider`, `ownerDogsProvider`, `StorageService` | `ProfileScreen._openDogEditor` (vraća `true` → snackbar) | **Završeno**, napomene: polja godine/težine nemaju `digitsOnly` niti validaciju opsega; nema izbora nivoa energije (polje se ne menja); ako se pas nađe samo u `ownerDogsProvider` a ne u `profile.dogs`, `_save` tiho ne radi ništa (`:163-165`). |
| Izmena vlasnika | `edit_owner_profile_screen.dart` / `EditOwnerProfileScreen` | Avatar (samo galerija), ime, email (read-only), grad/naselje (`CityNeighborhoodFields`, uključujući custom naselje), bio, Sačuvaj | `profileControllerProvider`, `authStateProvider`, `StorageService` | Dugme „Izmeni profil” na Profilu | **Završeno**; napomena: koristi `NetworkImage` direktno (`:198`), a čuvanje menja lokaciju svih pasa. |
| Sistemski sheet | `profile_system_sheet.dart` / `showProfileSystemSheet` | Podešavanja, Administracija (+ADMIN bedž ako `isAdminProvider`), Odjava, Obriši nalog | `isAdminProvider` | Ikonica podešavanja u AppBar-u Profila | **Završeno** |
| Podešavanja | `settings_screen.dart` / `SettingsScreen` | Omogući obaveštenja (traži dozvolu), prekidači šetnje/poruke/mečevi, tema (tamno plava/svetla), jezik (SR/EN), radius 1–30 km, link na filtere, „Prikaži moju lokaciju na mapi”, politika privatnosti, uslovi, verzija | `appSettingsProvider`, `matchingFiltersProvider`, `pushControllerProvider` | Iz sistemskog sheeta i iz drawer-a (`home_drawer.dart:136`) | **Završeno** uz napomenu: verzija je hardkodovana „VauVau v1.0.0”; da li se prekidači notifikacija poštuju na serveru (Cloud Functions) nije vidljivo iz ovog koda – čuvaju se samo lokalno. |
| Filteri za pretragu | `matching_filters_sheet.dart` / `MatchingFiltersSheet` | Veličina, pol, grad (Novi Sad/Beograd/Niš/Kragujevac/„Moj grad”), radius 1–30, Primeni | `matchingFiltersProvider` | Iz Podešavanja | **Završeno** (filteri nisu perzistentni osim radiusa). |
| Odjava | `sign_out_action.dart` | Dijalog sa ikonom, Otkaži/Odjavi se | `authControllerProvider` | Sistemski sheet | **Završeno** |
| Brisanje naloga | `delete_account_action.dart` | AlertDialog sa upozorenjem i linkom na politiku | `authControllerProvider` | Sistemski sheet | **Završeno** (sama logika brisanja van slice-a) |
| Onboarding psa | `dog_onboarding_screen.dart` / `DogOnboardingScreen` | „{naslov} (x/3)”, progress bar, koraci, greška, Nazad/Dalje/Kreiraj profil psa, overlay tokom upload-a; posle uspeha dijalog „Pas sačuvan”, prebacivanje na Profil tab | `dogOnboardingControllerProvider`, `homeTabIndexProvider`, `authControllerProvider` | `AuthGate` kad korisnik nema pasa (tada je dostupno „Odjavi se”); dugme „Dodaj psa” na Profilu | **Završeno** uz napomene: korak oblasti (`AreaStep`) nije uključen; nivo energije se ne bira; uploadovane slike ostaju u Storage-u ako korisnik odustane. |
| Korak 1 | `steps/basics_step.dart` / `BasicsStep` | Ime, rasa (`BreedField` sa custom rasom), pol (Mužjak/Ženka), starost (samo cifre) | – | Korak 0 | **Završeno** |
| Korak 2 | `steps/personality_step.dart` / `PersonalityStep` | Veličina (Mali/Srednji/Veliki), težina, temperament (5), voli/ne voli, bio, vakcinisan/čipovan/sterilisan | – | Korak 1 | **Završeno** (energija nedostaje) |
| Korak 3 | `steps/photos_step.dart` / `PhotosStep` | Dugmad galerija/kamera, brojač, grid sa „X” | – | Korak 2 | **Završeno** |
| Korak oblast | `steps/area_step.dart` / `AreaStep` | Grad i naselje sa porukom o privatnosti | – | Nigde | **Ne koristi se (mrtav kod)** |
| Zdravlje i podsetnici (kartica) | `health/dog_health_tab.dart` / `DogHealthTab` | Karton: prazno → „Dodaj zdravstveni zapis”, inače broj vakcina/zaštita + „Otvori karton”; podsetnici: prazno → „+ Dodaj prvi podsetnik”, inače 2 naredna, broj aktivnih, „+ Dodaj podsetnik”, „Prikaži sve →” | `activeDogRemindersProvider`, `healthRecordsProvider`, `latestHealthRecordsProvider` | Ugrađeno u `ProfileScreen` za izabranog psa | **Završeno**; „Pregledi” brojač je rezervisan i uvek 0 (`:61-62`); labele kategorija su ovde hardkodovane samo na srpskom (`:180-184`). |
| Karton zdravlja | `health/health_card_screen.dart` / `HealthCardScreen` | Uvod, lista poslednjeg zapisa po kategoriji sa statusom (🟢/🟡/🔴/⚪), datumi, tap → izmena, „Dodaj zdravstveni zapis” (izbor kategorije) | `latestHealthRecordsProvider` | Iz `DogHealthTab` | **Završeno** (prikazuje samo najnoviji zapis po kategoriji, istorija nije vidljiva). |
| Zapis zdravlja | `health/health_record_sheet.dart` / `HealthRecordSheet` | Naziv/preparat, datum primene, sledeći rok (sa brisanjem), prekidač podsetnika (09:00), napomena, Sačuvaj, Obriši (za postojeći) | `healthControllerProvider` | `showHealthRecordSheet` iz kartice/kartona | **Završeno**; `_delete` nema try/catch (`:203-213`). |
| Izbor tipa podsetnika | `health/add_reminder_sheet.dart` / `_AddReminderTypeSheet` | 4 kategorije (ZDRAVLJE/NEGA/ISHRANA/OSTALO) sa 19 tipova | – | `showAddReminderTypeSheet` iz kartice/ekrana podsetnika | **Završeno** |
| Forma podsetnika | `health/reminder_form_sheet.dart` / `ReminderFormSheet` | Pas (ako ih je više), naziv, datum, ponavljanje (8 opcija), custom „Svakih N dana/nedelja/meseci”, „Podseti me” (na dan/1/3/7 dana ranije), napomena, Sačuvaj | `reminderControllerProvider` | Posle izbora tipa ili „Izmeni” u detaljima | **Završeno** uz greške: pri izmeni i promeni psa stari dokument ostaje kod starog psa (`:315-316`); `lastCompletedDate` se gubi pri izmeni; „Broj”/„Jedinica” nisu lokalizovani; prazan naslov tiho ne radi ništa (`:300-302`). |
| Podsetnici | `health/reminders_screen.dart` / `RemindersScreen` | Filter po psu (Svi + imena), grupe PROŠLO/SLEDEĆE/KASNIJE, tile sa hitnošću i „Za N dana”, detalji (sheet) sa Izmeni/Obriši (potvrda) | `activeDogRemindersProvider`, `reminderControllerProvider` | „Prikaži sve →” iz `DogHealthTab` | **Završeno**; nema označavanja kao završeno; „Svi” hardkodovano (`:79`). |

### 4.4 Mapa, mesta i alati (tool/)
#### 1. `MapScreen` – `presentation/map_screen.dart:40`
- **Navigacija:** drugi tab (`index 1`) u `IndexedStack` u `HomeShellScreen` (`home/presentation/home_shell_screen.dart:95`); tab labela `MapStrings.tabLabel`.
- **Korisnik vidi:** OSM mapu preko celog ekrana (`VauInteractiveMap`) sa klasterovanim pinovima mesta (`PlacePin`), plavom tačkom korisnika (pulsira) ili markerom šetnje, startnom zastavicom i polilinijom rute tokom šetnje, pinovima pasa u šetnji (`WalkerPin`).
- **Gornji deo:** polje za pretragu (ime, adresa, opština, kategorija); dugme „Dozvoli lokaciju“ (pulsira) kad je lokacija fallback; čipovi gradova Novi Sad / Beograd / Niš / Kragujevac + „Izaberi grad“ (otvara `CityPickerSheet`); čipovi filtera `Sve`, `☕ Kafići`, `🐕 Parkovi`, `Psi u šetnji`, `⚙️ Više filtera`, `Lista/Mapa`; kad je izabran Pansion/Smeštaj – drugi red čipova za pogodnosti (prenoćište, dnevni boravak, dvorište, 0-24h). Prazno stanje: „Još nema lokacija u ovoj kategoriji.“
- **„Više filtera“ sheet:** „+ Dodaj mesto / lokal“ (svi korisnici → `AddPoiSheet`), „Dodaj mesto (Admin)“ (samo admin → `AddPlaceScreen`), i 12 dodatnih filtera.
- **Lista mesta** (`_PlacesListPanel`): grupisano po tipu, sa udaljenošću od korisnika i dugmetom za navigaciju.
- **Desno:** FAB zoom +/− (zoom ograničen 10–18) i „Moja lokacija“ (traži dozvolu sa disclosure dijalogom, pomera kameru na zoom 15.6).
- **Dole:** „🟢 Započni šetnju“ (dijalog sa statusom i čipovima „U šetnji / Odmaram / Tražim društvo za igru“) i „Moje šetnje“ (`WalkHistorySheet`). Tokom šetnje: `WalkGpsBanner` i `WalkStatsPanel`.
- **Tap na mesto:** pomera kameru na zoom 16 i otvara `PlacePreviewSheet` (sa akcijama: pridruži se → start šetnje sa statusom „Šetamo se kod <ime>“, navigacija, poziv, prijava neprikladnog sadržaja preko `showContentReportSheet`).
- **Tap na šetača:** `WalkerSheet` → „Pridruži se u šetnji“ šalje push (`pushControllerProvider.notifyWalk`) i otvara chat; „Poruka“ otvara chat (`chatInboxProvider.openFromMatch` + prebacuje tab na poruke + `ChatScreen`).
- **Lokacija odbijena:** `AlertDialog` sa opcijama „Koristi <grad>“, „Otvori podešavanja“ / „Dozvoli lokaciju“.
- **Provideri:** `walkControllerProvider`, `userLocationProvider`, `mapRegionProvider`, `mapPlacesProvider`, `walkingDogsProvider`, `citiesProvider`, `isAdminProvider`, `homeCityProvider`, `locationClientProvider`, `phoneLauncherProvider`, `mapsLauncherProvider`, `pushControllerProvider`, `chatInboxProvider`, `homeTabIndexProvider`.
- **Status: završeno** (svi tokovi su povezani na stvarne providere i Firestore). Ograničenja: sortiranje samo po sponzorstvu (`:556-561`), nijedno seed mesto nije sponzorisano; „U blizini“ = fiksno 3 km (`:537`).

#### 2. `AddPlaceScreen` (admin) – `presentation/add_place_screen.dart:18`
- **Navigacija:** `openAddPlaceScreen` iz „Više filtera“ (samo admin; ne-admin dobija SnackBar). Može se pozvati i iz drugih delova (u ovom delu koda samo iz mape).
- **Korisnik vidi/radi:** naziv, kategorija (samo 4 opcije: `pet_shop`, `park`, `vet`, `cafe` – `:44-49`), grad (iz `citiesProvider`), adresa sa dugmetom za Nominatim pretragu i listom predloga, radno vreme, telefon, mini OSM mapa (tap pomera pin), prikaz koordinata, „Sačuvaj mesto“.
- **Čuvanje:** `adminRepositoryProvider.createPlace(PlaceDraft)` → `places` + `pois` batch; invalidira `livePlacesProvider`; SnackBar „Mesto je dodato na mapu.“
- **Validacija:** `ContentValidationService.validateTitle/validateText`.
- **Status: završeno** za 4 kategorije; ostale kategorije (hotel, grooming, restoran…) se ne mogu dodati ovim ekranom.

#### 3. `AddPoiSheet` (predlog korisnika) – `presentation/widgets/add_poi_sheet.dart:31`
- **Navigacija:** „+ Dodaj mesto / lokal“ u „Više filtera“; inicijalni grad = trenutni region (ili Novi Sad).
- **Korisnik vidi/radi:** naziv, kategorija (svih 15), grad (`MapCity` enum uključujući „Drugo“), adresa (tekst), telefon, prekidači 24/7, hitne intervencije, prenoćište, dnevni boravak, dvorište, cena po noćenju.
- **Čuvanje:** `userPoiSubmissionsProvider.add(PoiModel(id: 'user-<ms>', verificationStatus: pending, source: 'VauVau Zajednica'))` → `pois/{id}`. SnackBar „Mesto je dodato na mapu.“ se prikazuje odmah, a `add` se ne čeka (`await` ne postoji, greške se ne prikazuju).
- **Koordinate:** **centar izabranog grada** (`_city.camera`), a GPS korisnika samo za „Drugo“ (`:224-226`). Adresa se ne geokodira. Sva korisnička mesta istog grada dobijaju istu tačku.
- **Status: delimično** – tok radi, ali lokacija pina je netačna po dizajnu koda; mesto se odmah pojavljuje na mapi sa bedžom „Na čekanju“.

#### 4. `CityPickerSheet` – `widgets/city_picker_sheet.dart`
- „Moja lokacija 📍“ + lista gradova (`citiesProvider`; na grešku ili praznu listu – `SeedCities.all`), podnaslov „Radius N km“. Tap → `mapRegionProvider.selectCity/selectMyLocation`, `MapScreen` animira kameru (`_flyTo`, 12 koraka × 16 ms).
- **Status: završeno.**

#### 5. `PlacePreviewSheet` + `_ReportChangeSheet` – `widgets/place_sheet.dart`
- **Vidi:** naziv, bedž kategorije (ili „🚨 DEŽURNO 0-24H“), bedž verifikacije („✓ Potvrđeno · dd.mm.yyyy“, „Prijavljeno“, „Na čekanju“, „Nije provereno“), sponzorski bedž, bedževi pogodnosti (dog friendly, unutra, outdoor, voda, prenoćište, dnevni boravak, dvorište, cena), opština, adresa + km, radno vreme.
- „Otvori profil“ samo **proširuje** isti sheet (izvor, ocena, „N aktivnih pasa u blizini“, „Pridruži se“) – nema posebnog ekrana profila mesta.
- Dugmad: „Pokreni navigaciju“, „Sajt“ (ako postoji), „Pozovi odmah“ (ako postoji telefon), „Prijavi promenu“, „Prijavi“ (moderacija).
- **Prijava promene:** tipovi „Potvrđujem da je objekat proveren“, „Pogrešno radno vreme“, „Objekat je zatvoren“, „Netačna lokacija“, „Ostalo“ + opis (max 500). Poziva `submitChangeRequest`; za potvrdu dodatno `poiConfirmationsProvider.confirm` (svako → lokalno postaje „✓ Potvrđeno“ u toj sesiji) i, ako je admin, `approve` (radi samo za mesta u `pois`).
- **Status: završeno**, uz napomenu da su potvrde/prijave u UI samo za tekuću sesiju; „N aktivnih pasa u blizini“ prikazuje hardkodovanu vrednost (`nearbyDogs: 1`) za katalog mesta – nije živ podatak.

#### 6. `WalkerSheet` / `WalkerMiniCard` / `WalkerPin` – `widgets/walker_sheet.dart`
- Mini kartica psa (avatar, `headline`, `subtitle`, status) i dugmad „Pridruži se u šetnji“ / „Poruka“. Pin prikazuje ime i `profile.distanceKm` (odakle tačno dolazi ta vrednost za šetače – zavisi od `discoverProfileFromMap`, van ovog dela; nije jasno da li je ažurna).
- **Status: završeno.**

#### 7. `WalkStatsPanel` + `WalkGpsBanner` – `widgets/walk_stats_panel.dart`
- Vreme (`elapsedLabel`) i km, link „Moje šetnje“, „Pauza/Nastavi“, „Završi šetnju“ (potvrda u dijalogu). Posle završetka SnackBar „Šetnja je sačuvana. <vreme> · <km> km“.
- **Status: završeno**, ali poruka „Šetnja je sačuvana“ se prikazuje i kada se šetnja **ne čuva** (< 30 s i < 50 m, ili lokalni korisnik) i pre nego što async upis uspe (`:185-208`); string `walkSaveFailed` se nigde ne koristi.

#### 8. `WalkHistorySheet` – `widgets/walk_history_sheet.dart`
- `DraggableScrollableSheet`: „Istorija šetnji“, „Poslednjih 7 dana“, sumarno vreme i km, grupe „Danas“/„Juče“/datum, kartice sa trajanjem, km, statusom i vremenskim opsegom.
- Greška pri učitavanju se prikazuje kao prazno stanje (ista poruka).
- **Status: završeno.**

#### 9. Dijalozi u `MapScreen`
- `_promptStartWalk` (`:938-1025`) – status šetnje; **završeno**.
- `_showLocationDialog` (`:800-850`) – **završeno**.
- `_openMoreFilters` (`:673-746`) – **završeno**.

### 4.5 Priče, izgubljeni psi, udomljavanje, moderacija, notifikacije, podrška, admin
#### Moments
| Fajl / klasa | Šta korisnik vidi i radi | Provideri | Navigacija | Status |
|---|---|---|---|---|
| `moments_screen.dart` / `MomentsScreen` | AppBar sa +; shimmer pri učitavanju; greška sa retry; `StoriesRail`; hint "Priče nestaju posle 24h…"; grid 2 kolone (`_StoryTile`: naslovna, prsten, broj priča, ime psa, opis, vreme); beskonačni skrol 420 px pre kraja | `momentsControllerProvider`, `activeStoryGroupsProvider`, `seenStoriesProvider` | Drawer (`DrawerItemKind.moments`); tap → `openStoryViewer` | Završeno (uz napomene o isteku) |
| `create_moment_sheet.dart` / `CreateMomentSheet` | Izbor psa (bez pasa: "Prvo dodajte profil psa." i dugme onemogućeno), grad (`SerbiaLocations.cities`), lokacija (preset ili ručni unos), opis, foto **samo iz galerije**; dijalog uspeha/greške | `profileControllerProvider`, `eventVenuesProvider(cityId)`, `homeCityProvider`, `momentsControllerProvider` | AppBar + i "Tvoja priča" u traci | Završeno |
| `story_viewer.dart` / `StoryViewerScreen`, `StoryGroupView` | PageView po grupama; 6 s po priči; tap levih 30% = nazad; long-press pauza; swipe dole zatvara; moje: istakni, obriši; tuđe: `SafetyMenuButton` **samo ako !kIsWeb**; lajk, komentari; tap na avatar → `openMomentDog` (`DogDetailSheet`) | `momentsControllerProvider`, `seenStoriesProvider`, `highlightActionsProvider` | Iz MomentsScreen, StoriesRail, istaknutog | Završeno |
| `moment_comments_sheet.dart` / `_CommentsSheet` | Lista komentara, unos, lajk; nema brisanja ni prijave komentara | `momentCommentsProvider` | `showMomentCommentsSheet` | Završeno (osnovno) |
| `highlight_sheets.dart` / `_AddToHighlightPage` | Lista istaknutih psa + "Novo istaknuto"; tap uključuje/isključuje; uklanjanje poslednjeg momenta briše istaknuto | `dogHighlightsProvider`, `highlightActionsProvider` | Iz pregledača priča | Završeno |
| `highlight_sheets.dart` / `_HighlightEditorPage` | Naziv (max 20), izbor naslovne, grid arhive 3 kolone (9/16), brisanje | `storyArchiveProvider`, `highlightActionsProvider` | Iz istaknutog/profila | Završeno |
| `highlight_sheets.dart` / `_ArrangeHighlightsPage` | `ReorderableListView` (`onReorderItem`), odmah poziva `reorder` | `highlightActionsProvider` | "Rasporedi" (ako >1) | Završeno |
| `story_widgets.dart` / `StoryHighlightsRow` | Red istaknutih na profilu; long-press Uredi/Obriši | `dogHighlightsProvider` | `profile_screen.dart:85` | Završeno |
| `story_widgets.dart` / `DogStoriesSection` | Priče/istaknuto tuđeg psa | isti | `swipe_dog_card.dart:567` | Završeno |

#### Lost dogs
| Fajl / klasa | Šta korisnik vidi i radi | Provideri | Navigacija | Status |
|---|---|---|---|---|
| `lost_dogs_screen.dart` / `LostDogsScreen` | 3 taba sa brojačima; crveni/zeleni baner; kartice (slika, bedževi HITNO/IZGUBLJEN ili PRONAĐEN, rasa, mesto, datum, opis 3 reda, `_MatchBanner` za found); dugmad Prijavi viđenje/Kontaktiraj, Ostavi komentar; za vlasnika ili admina "Pas je pronađen"/"Označi kao rešeno"; za admina "Obriši prijavu". Rešeni oglasi se ne prikazuju nigde | `lostDogsControllerProvider`, `activeLostDogsProvider`, `activeFoundDogsProvider`, `isAdminProvider`, `lostDogReporterIdProvider` | Drawer (`DrawerItemKind.lostDogs`) | Završeno |
| `report_lost_dog_sheet.dart` (izbor + forma) | Izbor tipa; polja: ime (obavezno za lost; za found podrazumevano "Nepoznat pas"), rasa (dropdown, "Drugo" → tekst), grad (`adoptionCities`), kvart, datum (posl. 30 dana), opis (obavezan), telefon (obavezan, bez validacije formata), foto (galerija, obavezna samo za found) | `lostDogsControllerProvider`, `homeCityProvider` | + u AppBar-u | Završeno |
| `lost_dog_actions.dart` / sighting sheet | Poziv ili SMS (`sms:` sa tekstom) | `phoneLauncherProvider` | Sa kartice / iz popupa | Završeno |
| `lost_dog_actions.dart` / profile sheet | Profil oglasa (uvek koristi naslov "nestao") | – | Iz `_MatchBanner` | Završeno |
| `lost_dog_actions.dart` / `_LostDogCommentsSheet` | Lista (visina 440), lajk, slanje; poruke za permission-denied; nema brisanja/prijave | `lostDogCommentsProvider` | Sa kartice | Završeno |
| `lost_dog_emergency_host.dart` + dijalog | Jednokratni hitni popup | `recentMissingLostDogsProvider` | Automatski | Delimično (jednom zauvek, bez filtera po gradu) |

#### Adoption
| Fajl / klasa | Šta korisnik vidi i radi | Provideri | Navigacija | Status |
|---|---|---|---|---|
| `adoption_screen.dart` / `AdoptionScreen` | Podnaslov, grid `AdoptionCard` (bedž "Udomljava se", ime·starost, rasa, lokacija, vreme); + → forma → SnackBar | `adoptionControllerProvider` | Drawer (`DrawerItemKind.adopt`) | Završeno |
| `adoption_detail_screen.dart` / `AdoptionDetailScreen` | Galerija 280 px, čipovi (rasa, starost, veličina, vakcinisan/sterilisan), priča, kartica vlasnika, "Pošalji poruku", "Pozovi vlasnika" (onemogućeno bez telefona), vlasnik: "Označi kao udomljen". Pol se ne prikazuje; vlasnik vidi i dugme za poruku sebi; nema prijave ni admin akcija | `adoptionControllerProvider`, `chatInboxProvider`, `phoneLauncherProvider` | MaterialPageRoute iz grida; poruka → `ChatScreen` | Završeno uz napomene |
| `add_adoption_dog_sheet.dart` / `AddAdoptionDogScreen` | Ime, rasa (`BreedField`), starost (slobodan tekst), pol (podrazumevano mužjak), veličina (srednji), priča, grad, naselje, telefon, vakcinisan (true), sterilisan (false), slike (galerija multi ili kamera; nisu obavezne) | `adoptionControllerProvider`, `profileControllerProvider`, `homeCityProvider` | Bottom sheet 92% | Završeno |

#### Moderation
| Fajl / klasa | Opis | Status |
|---|---|---|
| `report_sheet.dart` / `showContentReportSheet` | Radio razlozi (`reasons` ili `dogReasons` za psa), opcioni detalji, Pošalji/Otkaži; uspeh: zeleni SnackBar 4 s. Pozivaoci: `discover_screen.dart:148`, `chat_detail_screen.dart:297`, `chat_list_screen.dart:152, 327`, `map_screen.dart:871`, `safety_menu.dart:78` | Završeno |
| `safety_menu.dart` / `SafetyMenuButton` | ⋮ meni: Prijavi korisnika (crveno), Blokiraj. Koristi se u `story_viewer.dart:463` (samo !kIsWeb), `chat_detail_screen.dart:398`, `swipe_dog_card.dart:248` | Završeno |
| `safety_menu.dart` / `confirmAndBlockUser` | Dijalog potvrde; prazan userId → SnackBar | Završeno |
| Odblokiranje | Ne postoji UI | Ne postoji |

#### Notifications
| Fajl / klasa | Opis | Status |
|---|---|---|
| `notification_screen.dart` / `showNotificationsSheet` | Bottom sheet 78%: naslov, "Označi sve kao pročitano" (ako ima nepročitanih), `NotificationsInbox`; otvara se zvonom u `home_shell_screen.dart:76` i `discover_app_bar.dart:64` | Završeno |
| `notification_screen.dart` / `_NotificationCard` | Ikona po tipu, naslov, telo (po 1 red), vreme, tačka nepročitano; tap → `markRead` + `openAppNotification` | Završeno |
| `notification_screen.dart` / `_EmptyNotifications` | "Nemate novih obaveštenja." | Završeno |
| `notification_screen.dart` / `NotificationScreen` | Full-screen varijanta; nigde se ne otvara | Mrtav kod |
| `push_bootstrap.dart` / `PushBootstrap` | Nevidljiv; jednokratni OS prompt (`AppSettings.pushPrompted`); stringovi `enableTitle/enableBody/enableConfirm/later` se ne koriste | Završeno |

#### Support
| Fajl / klasa | Opis | Provideri / navigacija | Status |
|---|---|---|---|
| `rules_and_support_screen.dart` / `RulesAndSupportScreen({initialTab = 0})` | 4 taba; prvi naziv "SOS" hardkodovan; `initialTab` se nigde ne prosleđuje | Drawer (`DrawerItemKind.rules`) | Završeno |
| `sos_tab.dart` / `SosTab` | 7 kontakata (4 Novi Sad, 3 Beograd), grupisano po gradu, grad korisnika prvi; dugme poziva prvi broj; adresa je uglavnom samo ime grada; za ostale gradove nema kontakata | `homeCityProvider`, `phoneLauncherProvider` | Završeno (statičan i ograničen sadržaj) |
| `tips_tab.dart` / `TipsTab` | Naslov, uvod, disclaimer, kartica "Nisi siguran…" (→ SOS), 3 bloka članaka, napomena o izvorima. CTA: sosVets → tab 0; findWalk → `pop()` + `homeTabIndexProvider.showDiscover()`; dogProfile → `pop()` + `showProfile()`; writeAdmin → tab 3 | `homeTabIndexProvider` | Završeno |
| `rules_tab.dart` / `RulesTab` | Naslov, uvod, napomena o lokalnim pravilima, 3 bloka, završna kartica; CTA writeAdmin → tab 3 | – | Završeno |
| `admin_feedback_form.dart` / `AdminFeedbackForm` | Kontakt linkovi; dropdown kategorije; naslov (obavezan, max 120); poruka (min 10, max 2000); uspeh → dijalog "Hvala! 🐾" i čišćenje forme; greška → `showNetworkErrorSnackBar` | `supportControllerProvider` | Završeno |
| `about_app_dialog.dart` / `showAboutAppDialog` | Opis, "Verzija 1.0.0" (hardkod), Politika privatnosti / Uslovi (`openLegalDocument`), kontakt linkovi | Drawer (`home_drawer.dart:94`) | Završeno |
| `official_contact_links.dart` / `OfficialContactLinks` | Kompaktni red ikona (drawer) ili kartice (forma, "O aplikaciji") | `externalLinkLauncherProvider` | Završeno |
| `support_guide_card.dart` / `SupportGuideCard` | Nigde se ne koristi | – | Mrtav kod |

#### Admin
| Fajl / klasa | Šta admin vidi i radi | Provideri | Status |
|---|---|---|---|
| `admin_dashboard_screen.dart` / `AdminDashboardScreen` | Provera `isAdminProvider`; 5 tabova: Statistika, Korisnici, Prijave, Sadržaj, Grupe na čekanju | `isAdminProvider` | Završeno |
| `admin_dashboard_screen.dart` / `_StatsTab` | 4 pločice: Korisnici (broj iz `adminUsersProvider`), "Aktivni psi" (unija `discoverProfilesProvider` + sopstvenih pasa – **nije ukupan broj pasa u bazi**), Prijave (`activeReportsProvider`), POI na čekanju (`pendingPoisProvider`); ispod: sekcija "📩 Poruke & Feedback" (`AdminFeedbackTab`) | `adminUsersProvider`, `discoverProfilesProvider`, `profileControllerProvider`, `activeReportsProvider`, `pendingPoisProvider` | Završeno (statistika pasa nepouzdana) |
| `admin_feedback_tab.dart` / `AdminFeedbackTab` | Kartice: ime, oznaka Novo/Rešeno, email ili "Bez email adrese", kategorija, vreme, naslov, poruka; "✓ Označi kao rešeno" (samo nerešene), "🗑️ Obriši" (uz potvrdu) | `adminFeedbackProvider`, `adminRepositoryProvider` | Završeno |
| `admin_users_tab.dart` / `AdminUsersTab` | "Ukupno registrovanih: N", lista: avatar (početno slovo), ime, ADMIN bedž, email, datum pristupanja. Nema akcija | `adminUsersProvider` | Završeno (samo čitanje) |
| `admin_reports_tab.dart` / `AdminReportsTab`, `_ReportCard` | Prijavio/Prijavljen (prikazuju se **sirovi uid-ovi**), vreme, razlog, `targetType • targetId` (za POI naziv + ID), detalji; za POI dugme "Izmeni i reši"; dugmad Obriši / Rešeno / Odbaci; bedž je uvek "Na čekanju" (`_StatusBadge` bez parametara) | `activeReportsProvider`, `reportControllerProvider`, `hiddenContentProvider`, `userPoiSubmissionsProvider`, `momentsControllerProvider` | Delimično (za user/message/dog/chat "Obriši" ne briše sadržaj) |
| `admin_dashboard_screen.dart` / `_ContentTab` | Podtabovi "Momenti" i "Predlozi mesta" | – | Završeno |
| `admin_moments_tab.dart` / `AdminMomentsTab` | Kartice: slika 140 px, "pas • autor", lokacija • vreme, opis; "🗑️ Obriši momenat" uz potvrdu | `momentsControllerProvider` | Delimično (vidi samo učitanih 15, bez paginacije) |
| `admin_dashboard_screen.dart` / `_PendingPoisTab` | Naziv, adresa, kategorija (`category.name`, enum ime, nelokalizovano); "✓ Odobri" (verified), "✏️ Izmeni" (editor), "🗑️ Odbij" (status rejected) | `pendingPoisProvider`, `userPoiSubmissionsProvider` | Završeno |
| `admin_groups_tab.dart` / `AdminGroupsTab` | Naslov, opis, "Predložio: <uid>", datum; "✓ Odobri" (`approveGroup`), "✗ Odbij" (`deleteGroup` – brisanje bez potvrde) | `pendingGroupsProvider`, `groupsControllerProvider` | Završeno |
| `admin_edit_poi_dialog.dart` / `showAdminEditPoiDialog` | Kontekst prijave (razlog/detalji); polja naziv, adresa, radno vreme, cena po noći, telefon, sajt, lat/lng, status provere (dropdown), prekidači 00–24h, dežurna, prenoćište, dnevni boravak, dvorište, pet-friendly, zvanični park za pse (samo za `park`); dugmad "Sačuvaj i označi rešeno" (ako `offerResolve`), "Samo sačuvaj izmene", "Otkaži". Validacija: `ContentValidationService`, koordinate (`PoiSeedData.hasValidCoordinates`), cena. Snima preko `userPoiSubmissionsProvider.updatePoi`; `lastVerified = now` samo za verified | `userPoiSubmissionsProvider` | Završeno |
| `admin_confirm_dialog.dart` / `confirmAdminDelete` | "Obrisati?" + Otkaži/Obriši | – | Završeno |

---
## 5. BACKEND I BAZA

### Firebase servisi u upotrebi (projekat `vauvau-3195a`, `.firebaserc` → `default`)
| Servis | Upotreba | Gde |
|---|---|---|
| Authentication | Email/lozinka (aktivno), Google (implementirano, sakriveno u UI) | `lib/features/auth/data/` |
| Cloud Firestore | Glavna baza, realtime snapshots, offline keš (neograničen) | svi `features/*/data/firestore_*` |
| Cloud Storage | Slike (psi, korisnici, četovi, priče, oglasi, grupe, događaji) | `lib/services/storage_service.dart` |
| Cloud Messaging (FCM) | Samo klijent: token u `users/{uid}`, foreground/opened handleri, background handler | `lib/features/notifications/` |
| Crashlytics | Globalni error handleri, userId | `lib/core/crash/crash_reporting.dart` |
| Hosting | Samo pravne stranice `/privacy` i `/terms` iz `public/` (ne web build aplikacije) | `firebase.json`, `public/` |
| **Cloud Functions** | **NE POSTOJE.** Nema `functions/` foldera, `firebase.json` nema `functions` ključ. | – |
| Remote Config, Analytics, App Check, Dynamic Links | **Ne koriste se** (nisu u zavisnostima) | – |

Posledice nepostojanja Cloud Functions:
- **Push ne stiže kada je aplikacija zatvorena.** Klijent upisuje `notifications` i `users/{uid}/fcmInbox` dokumente, ali ništa ih ne šalje kao FCM.
- Mečevi, brojači (`memberCount`, `unreadByUser`, `likesCount`), lajkovi i kaskadno brisanje naloga rade se sa klijenta. Integritet zavisi isključivo od Firestore pravila.

### Firestore kolekcije (sve što kod čita/piše, + ono što postoji samo u pravilima)
| Kolekcija / putanja | Ko piše (kod) | Svrha |
|---|---|---|
| `users/{uid}` | auth, profil, push (fcmToken), prijave (`contentReports[]`), mapa (`placeChangeRequests[]`, lokacija/`isWalking`) | Profil vlasnika, ugnježden `dog` map, uloga `role` |
| `users/{uid}/fcmInbox/{id}` | `push_notification_gateway.dart` | „Red“ za push koji niko ne obrađuje |
| `users/{uid}/blocked_users/{blockedUid}` | moderacija | Blokirani korisnici |
| `users/{uid}/walks/{id}` | `walk_history_repository.dart` | Završene šetnje (trajanje, distanca) |
| `users/{uid}/place_change_requests/{id}` | samo u pravilima i brisanju naloga | Kod danas koristi niz `placeChangeRequests` u `users/{uid}`, ne ovu podkolekciju |
| `dogs/{dogId}` (+ `likes/{uid}`, `health_records`, `reminders`) | psi, discover, mapa (lokacija/šetnja), highlights | Profil psa, lajkovi, zdravstveni karton, podsetnici; istaknute priče su u samom dokumentu psa |
| `swipes/{id}` | discover | Levo/desno |
| `super_likes/{id}` | discover | Super lajk |
| `matches/{id}` | discover | Meč dva psa/vlasnika |
| `chats/{chatId}` (+ `messages/{id}`) | chat | 1:1 sobe: `participantIds`, `unreadByUser`, `lastMessage…`; poruke tipa tekst/slika/lokacija/walk_invite, `likes[]` |
| `breed_groups/{id}` (+ `messages`, `members/{uid}`) | grupe | Grupe po rasama/temama, grupni čet, `lastReadTimestamp` po članu |
| `events/{id}` (+ `messages`, `members/{uid}`) | događaji | Događaji/šetnje, čet događaja |
| `moments/{id}` (+ `comments`) | priče | Priče (24h) |
| `highlights/{id}` | samo brisanje naloga („legacy“) | Stara kolekcija istaknutih priča |
| `lost_dogs/{id}` | izgubljeni psi | Oglasi; komentari kao **niz u dokumentu** (`comments[]`, `commentLikes`). Podkolekcija `comments` postoji u pravilima i u brisanju naloga |
| `adoption_dogs/{id}` | udomljavanje | Oglasi za udomljavanje |
| `pois/{id}` | mapa | Korisnički i seed POI |
| `places/{id}` | mapa / admin | Zvanična (admin) mesta |
| `cities/{id}` | mapa | Gradovi (`cities_repository.dart`) |
| `notifications/{id}` | discover, chat, moderacija, mapa, push gateway | In-app notifikacije (`toUserId`/`recipientId`) |
| `reports/{id}` | moderacija | Prijave sadržaja (paralelno i u `users/{uid}.contentReports[]`) |
| `admin_notifications/{id}` | moderacija | Obaveštenja za admina |
| `admin_feedback/{id}` | podrška → admin | Poruke korisnika adminu |
| `change_requests/{id}` | `poi_report_controller.dart:130` (pokušaj upisa) | Predlozi izmena mesta |
| `support/{id}` | **samo u pravilima** (javno čitanje, admin upis); kod je ne koristi | – |

Šema polja po kolekciji: vidi podsekcije „Firestore struktura“ ispod (po modulima) i sekciju 6.

### Indeksi (`firestore.indexes.json`, 76 linija)
Pun sadržaj je dat ispod. Upiti u kodu koji koriste `where` + `orderBy` na različitim poljima zahtevaju kompozitne indekse. **Nije provereno** da li su svi indeksi stvarno deployovani u Firebase projektu; to se vidi samo u konzoli.

### Bezbednosni rizici u pravilima (iz `firestore.rules` i `storage.rules`)
1. `users/{uid}` – `allow read: if isAuthenticated()` (l. 24).
   - Svaki prijavljeni korisnik čita email, `fcmToken`, `contentReports[]` (ko je koga prijavio) i lokaciju (`lastKnownLocation`) svih korisnika.
2. `notifications` – `allow create: if isAuthenticated()` (l. 62).
   - Bilo ko može da napravi notifikaciju bilo kome (spam/phishing).
   - Isto važi za `users/{uid}/fcmInbox` create (l. 34).
3. `events` – `allow create, update: if isAuthenticated()` (l. 342–343).
   - Bilo koji korisnik menja bilo koji događaj (naslov, organizatora, članove).
4. `breed_groups`:
   - `allow update: if isAuthenticated()` (l. 308): bilo ko može da postavi `isApproved: true`, menja naslov ili `memberIds`.
   - Create dozvoljava `isApproved == true` ako je `createdBy == ''` (l. 302–305). Svako može da napravi „odobrenu“ grupu i zaobiđe moderaciju.
5. `matches` – `allow create: if isAuthenticated()` (l. 197) bez provere učesnika.
   - `swipes` – `read, create` bez provere `fromUserId` (l. 209).
6. `lost_dogs`:
   - update pravila (l. 251–258) dozvoljavaju prepisivanje celog niza `comments` iste dužine, tj. izmenu tuđih komentara;
   - `commentsCount` može da se postavi proizvoljno (l. 264–266).
7. `chats/{id}` update (l. 166–168): učesnik može da menja bilo koje polje sobe, uključujući `participantIds`.
8. Storage:
   - **sve putanje su javno čitljive** (`allow read: if true`), uključujući `chats/` (slike iz privatnih četova);
   - `storage-cors.json` dozvoljava `origin: *` za GET/PUT/POST/DELETE.
9. `isAdmin()` radi dodatni `get()` na `users/{uid}` po svakoj proveri, što povećava trošak čitanja. Nema custom claims-a.

> Pravila **nisu menjana niti deployovana** tokom ovog pregleda. Nije poznato da li je deployovana verzija identična lokalnoj.

### `firestore.rules` (pun sadržaj)
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isSignedIn() {
      return isAuthenticated();
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Admin is granted via users/{uid}.role == 'admin' (set in Firestore).
    // Do not hardcode a placeholder email here — rotate via the users doc.
    function isAdmin() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId)
        && request.resource.data.role == 'user';
      allow update: if isOwner(userId)
        && request.resource.data.role == resource.data.role;
      allow update: if isAdmin();
      allow delete: if isOwner(userId) || isAdmin();

      match /fcmInbox/{msgId} {
        allow read, update, delete: if isOwner(userId);
        allow create: if isAuthenticated();
      }

      match /blocked_users/{blockedUserId} {
        allow read, write: if isOwner(userId) || isAdmin();
      }

      // Map place corrections saved under the reporter until top-level
      // change_requests rules are deployed everywhere.
      match /place_change_requests/{requestId} {
        allow create: if isOwner(userId)
          && request.resource.data.reportedByUserId == request.auth.uid
          && request.resource.data.status == 'pending';
        allow read: if isOwner(userId) || isAdmin();
        allow update, delete: if isAdmin();
      }

      // Completed walk sessions (duration + distance) for the owner.
      match /walks/{walkId} {
        allow read, create: if isOwner(userId);
        allow update, delete: if isOwner(userId) || isAdmin();
      }
    }

    match /notifications/{notificationId} {
      allow read, update, delete: if isAuthenticated() &&
        (resource.data.toUserId == request.auth.uid ||
          resource.data.recipientId == request.auth.uid);
      allow create: if isAuthenticated();
    }

    match /super_likes/{superLikeId} {
      allow read: if isAuthenticated() &&
        (resource.data.fromUserId == request.auth.uid ||
          resource.data.targetOwnerId == request.auth.uid ||
          isAdmin());
      allow create: if isAuthenticated() &&
        request.resource.data.fromUserId == request.auth.uid;
      allow delete: if isAuthenticated() &&
        resource.data.fromUserId == request.auth.uid;
      allow update, delete: if isAdmin();
    }

    match /pois/{poiId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update, delete: if isAdmin();
    }

    // Dynamic map cities (Novi Sad, Beograd, …).
    match /cities/{cityId} {
      allow read: if true;
      allow create, update, delete: if isAdmin();
    }

    // Admin-managed places (also mirrored into pois for map markers).
    match /places/{placeId} {
      allow read: if true;
      allow create, update, delete: if isAdmin();
    }

    match /reports/{reportId} {
      allow create: if isAuthenticated() &&
        request.resource.data.reporterId == request.auth.uid &&
        request.resource.data.status == 'pending';
      allow read, update, delete: if isAdmin();
    }

    // Map place corrections from the community (hours, closed, location…).
    match /change_requests/{requestId} {
      allow create: if isAuthenticated() &&
        request.resource.data.reportedByUserId == request.auth.uid &&
        request.resource.data.status == 'pending' &&
        request.resource.data.placeId is string &&
        request.resource.data.changeType is string;
      allow read, update, delete: if isAdmin();
    }

    match /admin_notifications/{notificationId} {
      allow create: if isAuthenticated() &&
        request.resource.data.reportedByUserId == request.auth.uid &&
        request.resource.data.status == 'pending';
      allow read, update, delete: if isAdmin();
    }

    match /support/{docId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /dogs/{dogId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
        request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if isAuthenticated() &&
        (resource.data.ownerId == request.auth.uid || isAdmin());
      // Allow likers to bump likesCount / superLikesCount without editing
      // other dog fields.
      allow update: if isAuthenticated() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['likesCount']);
      allow update: if isAuthenticated() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['superLikesCount']);
      allow update: if isAuthenticated() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['likesCount', 'superLikesCount']);

      match /likes/{userId} {
        allow read: if isAuthenticated();
        allow create, update, delete: if isOwner(userId);
      }

      match /health_records/{recordId} {
        allow read, write: if isAuthenticated() &&
          get(/databases/$(database)/documents/dogs/$(dogId)).data.ownerId ==
            request.auth.uid;
        allow read, write: if isAdmin();
      }

      match /reminders/{reminderId} {
        allow read, write: if isAuthenticated() &&
          get(/databases/$(database)/documents/dogs/$(dogId)).data.ownerId ==
            request.auth.uid;
        allow read, write: if isAdmin();
      }
    }

    match /chats/{chatId} {
      allow read: if isAuthenticated() && request.auth.uid in resource.data.participantIds;
      allow create: if isAuthenticated() && request.auth.uid in request.resource.data.participantIds;
      // Participants may leave (account deletion removes self from participantIds).
      allow update: if isAuthenticated() &&
        (request.auth.uid in resource.data.participantIds ||
          request.auth.uid in request.resource.data.participantIds);
      allow delete: if isAdmin();

      match /messages/{messageId} {
        allow read: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
        allow create: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds &&
          request.resource.data.senderId == request.auth.uid;
        // Peer may accept/decline a walk invite (status only).
        allow update: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds &&
          resource.data.type == 'walk_invite' &&
          request.auth.uid != resource.data.senderId &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status']) &&
          request.resource.data.status in ['accepted', 'declined'];
        // Participants may like / unlike any message (likes array only).
        allow update: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes']) &&
          request.resource.data.likes is list;
        // Sender may delete own messages (account deletion cascade).
        allow delete: if isAuthenticated() &&
          resource.data.senderId == request.auth.uid;
        allow update, delete: if isAdmin();
      }
    }

    match /matches/{matchId} {
      allow read, create: if isAuthenticated();
      allow delete: if isAuthenticated() &&
        (
          (resource.data.userIds is list &&
            request.auth.uid in resource.data.userIds) ||
          (resource.data.participantIds is list &&
            request.auth.uid in resource.data.participantIds)
        );
      allow update, delete: if isAdmin();
    }

    match /swipes/{swipeId} {
      allow read, create: if isAuthenticated();
      allow update, delete: if isAuthenticated() &&
        resource.data.fromUserId == request.auth.uid;
      allow update, delete: if isAdmin();
    }

    match /adoption_dogs/{dogId} {
      allow read: if true;
      allow create: if isAuthenticated() &&
        request.resource.data.uploaderUserId == request.auth.uid;
      allow update, delete: if isAuthenticated() &&
        request.auth.uid == resource.data.uploaderUserId;
      allow update, delete: if isAdmin();
    }

    match /lost_dogs/{dogId} {
      allow read: if true;
      allow create: if isAuthenticated() &&
        request.resource.data.uploaderUserId == request.auth.uid;
      // Owner or admin may update (e.g. mark resolved).
      allow update: if isAuthenticated() &&
        (request.auth.uid == resource.data.uploaderUserId || isAdmin());
      // Anyone signed in may append sighting comments (array + count only).
      allow update: if isAuthenticated() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['comments', 'commentsCount']) &&
        request.resource.data.comments is list &&
        (
          !('comments' in resource.data) ||
          request.resource.data.comments.size() ==
            resource.data.comments.size() + 1
        );
      allow update: if isAuthenticated() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['comments']) &&
        request.resource.data.comments is list &&
        (
          !('comments' in resource.data) ||
          request.resource.data.comments.size() ==
            resource.data.comments.size() + 1
        );
      // Anyone signed in may toggle likes on existing comments (same array size).
      allow update: if isAuthenticated() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['comments']) &&
        request.resource.data.comments is list &&
        ('comments' in resource.data) &&
        resource.data.comments is list &&
        request.resource.data.comments.size() ==
          resource.data.comments.size();
      // Preferred like storage: map commentId -> [userIds] (avoids rewriting comments).
      allow update: if isAuthenticated() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['commentLikes']) &&
        request.resource.data.commentLikes is map;
      allow update: if isAuthenticated() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['commentsCount']);
      // Only admins may permanently delete listings.
      allow delete: if isAdmin();

      match /comments/{commentId} {
        allow read: if true;
        allow create: if isAuthenticated() &&
          request.resource.data.authorUserId == request.auth.uid;
        allow update: if isAuthenticated() &&
          request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['likes']);
        allow update, delete: if isAuthenticated() &&
          resource.data.authorUserId == request.auth.uid;
        allow delete: if isAdmin();
      }
    }

    match /breed_groups/{groupId} {
      allow read: if isAuthenticated();
      // User-created groups must be pending (isApproved == false).
      // Seed presets may create approved docs with empty createdBy.
      allow create: if isAuthenticated() &&
        request.resource.data.keys().hasAll([
          'title',
          'description',
          'memberIds',
          'memberCount',
          'isApproved',
          'createdBy',
        ]) &&
        (
          (
            request.resource.data.isApproved == false &&
            request.resource.data.createdBy == request.auth.uid &&
            request.auth.uid in request.resource.data.memberIds
          ) ||
          (
            request.resource.data.isApproved == true &&
            request.resource.data.createdBy == ''
          ) ||
          isAdmin()
        );
      allow update: if isAuthenticated();
      allow delete: if isAdmin();

      match /messages/{messageId} {
        allow read: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/breed_groups/$(groupId)).data.memberIds;
        allow create: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/breed_groups/$(groupId)).data.memberIds &&
          request.resource.data.senderId == request.auth.uid;
        // Members may accept/decline group walk invites.
        allow update: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/breed_groups/$(groupId)).data.memberIds &&
          resource.data.type == 'walk_invite' &&
          request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['acceptedByUserIds', 'declinedByUserIds', 'status']);
        // Members may like / unlike any message (likes array only).
        allow update: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/breed_groups/$(groupId)).data.memberIds &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes']) &&
          request.resource.data.likes is list;
        allow delete: if isAuthenticated() &&
          resource.data.senderId == request.auth.uid;
        allow update, delete: if isAdmin();
      }

      match /members/{userId} {
        allow read: if isOwner(userId);
        allow create, update, delete: if isOwner(userId);
        allow delete: if isAdmin();
      }
    }

    match /events/{eventId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated() &&
        resource.data.organizerUserId == request.auth.uid;
      allow delete: if isAdmin();

      match /messages/{messageId} {
        allow read: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/events/$(eventId)).data.participantUserIds;
        allow create: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/events/$(eventId)).data.participantUserIds &&
          request.resource.data.senderId == request.auth.uid;
        // Participants may accept/decline event walk invites.
        allow update: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/events/$(eventId)).data.participantUserIds &&
          resource.data.type == 'walk_invite' &&
          request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['acceptedByUserIds', 'declinedByUserIds', 'status']);
        // Participants may like / unlike any message (likes array only).
        allow update: if isAuthenticated() &&
          request.auth.uid in get(/databases/$(database)/documents/events/$(eventId)).data.participantUserIds &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes']) &&
          request.resource.data.likes is list;
        allow delete: if isAuthenticated() &&
          resource.data.senderId == request.auth.uid;
        allow update, delete: if isAdmin();
      }

      match /members/{userId} {
        allow read: if isOwner(userId);
        allow create, update, delete: if isOwner(userId);
        allow delete: if isAdmin();
      }
    }

    match /admin_feedback/{feedbackId} {
      allow create: if isAuthenticated() &&
        request.resource.data.userId == request.auth.uid &&
        request.resource.data.status == 'new';
      allow read, update, delete: if isAdmin();
    }

    // Field is authorUserId in the app (not authorId).
    match /moments/{momentId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
        request.resource.data.authorUserId == request.auth.uid;
      allow update: if isAuthenticated() &&
        request.resource.data.authorUserId == resource.data.authorUserId &&
        (resource.data.authorUserId == request.auth.uid || isAdmin() ||
          request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['likes', 'commentsCount']));
      allow delete: if isAuthenticated() &&
        (resource.data.authorUserId == request.auth.uid || isAdmin());

      match /comments/{commentId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() &&
          request.resource.data.authorUserId == request.auth.uid;
        allow update: if isAuthenticated() &&
          request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['likes']);
        allow update, delete: if isAuthenticated() &&
          resource.data.authorUserId == request.auth.uid;
        allow delete: if isAdmin();
      }
    }

    // Highlights are stored on dogs/{dogId}.storyHighlights (owner update
    // rules on /dogs cover writes). Kept for any legacy top-level docs.
    match /highlights/{highlightId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
        request.resource.data.ownerId == request.auth.uid &&
        request.resource.data.title is string &&
        request.resource.data.title.size() <= 40 &&
        request.resource.data.momentIds is list;
      allow update: if isAuthenticated() &&
        resource.data.ownerId == request.auth.uid &&
        request.resource.data.ownerId == resource.data.ownerId &&
        request.resource.data.dogId == resource.data.dogId &&
        request.resource.data.title.size() <= 40;
      allow delete: if isAuthenticated() &&
        (resource.data.ownerId == request.auth.uid || isAdmin());
    }
  }
}
```

### `storage.rules` (pun sadržaj)
```js
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Public read for Image.network / CachedNetworkImage.
    // Writes require auth + image content type + max 8MB.
    // Deletes/writes are owner-scoped: {root}/{userId}/...
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isValidImage() {
      return request.resource.size < 8 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    function ownerImageWrite(userId) {
      return isOwner(userId) && isValidImage();
    }

    match /pets/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /users/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /moments/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /events/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /groups/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /adoption/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /lost_dogs/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /uploads/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /chats/{userId}/{allPaths=**} {
      allow read: if true;
      allow create, update: if ownerImageWrite(userId);
      allow delete: if isOwner(userId);
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### `firestore.indexes.json` (pun sadržaj)
```json
{
  "indexes": [
    {
      "collectionGroup": "swipes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "fromUserId", "order": "ASCENDING" },
        { "fieldPath": "toDogId", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "toUserId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "toUserId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "chats",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "participantIds", "arrayConfig": "CONTAINS" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "chats",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "participantIds", "arrayConfig": "CONTAINS" },
        { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": [
    {
      "collectionGroup": "comments",
      "fieldPath": "authorUserId",
      "indexes": [
        {
          "order": "ASCENDING",
          "queryScope": "COLLECTION"
        },
        {
          "order": "DESCENDING",
          "queryScope": "COLLECTION"
        },
        {
          "arrayConfig": "CONTAINS",
          "queryScope": "COLLECTION"
        },
        {
          "order": "ASCENDING",
          "queryScope": "COLLECTION_GROUP"
        },
        {
          "order": "DESCENDING",
          "queryScope": "COLLECTION_GROUP"
        },
        {
          "arrayConfig": "CONTAINS",
          "queryScope": "COLLECTION_GROUP"
        }
      ]
    }
  ]
}
```

### `firebase.json`, `.firebaserc`, `storage-cors.json`
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "/privacy",
        "destination": "/privacy/index.html"
      },
      {
        "source": "/terms",
        "destination": "/terms/index.html"
      }
    ]
  }
}
```
```json
{
  "projects": {
    "default": "vauvau-3195a"
  }
}
```
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"],
    "maxAgeSeconds": 3600,
    "responseHeader": [
      "Content-Type",
      "Authorization",
      "Content-Length",
      "User-Agent",
      "x-goog-resumable",
      "x-goog-meta-*"
    ]
  }
]
```

### Cloud Functions
Ne postoje (nema `functions/` foldera, nema `functions` ključa u `firebase.json`, nema `package.json` za funkcije).
### Firestore struktura po modulima (polja kako ih kod čita/piše)
#### Core / auth / home
##### Firestore – upisi i čitanja u slice-u

**`users/{uid}`** (`userCollection = 'users'`)
- Čitanje (`AppUser.fromAuthAndDocument`, `ownerPhotoFromDocument`, `_upsertUser`): `email` (String), `name` (String), `customPhotoUrl` (String), `photoUrl` (String), `cityName` (String), `city` (String), `cityId` (String), `neighborhoodId` (String), `neighborhoodName` (String), `bio` (String), `role` (String: `'admin'` ili ostalo), `dog` (Map), `createdAt` (proverava se samo da li je null).
- Upis (`userDocumentPayload`): `uid`, `email` (`?? ''`), `name` (`?? ''`), `city` (= cityName), `cityId`, `cityName`, `neighborhoodId`, `neighborhoodName`, `bio`, `updatedAt` (serverTimestamp); opciono `photoUrl` + `customPhotoUrl` (ista vrednost), `role` (`'user'`/`'admin'`), `createdAt` (serverTimestamp), `dog` (Map – `UserDogProfile.toMap()`: `id, name, breed, age (int), gender, bio, size, temperament (List), likesTags (List), dislikesTags (List), photoUrl, imageUrl, photos, photoUrls, galleryUrls`).
- `saveOwnerCustomPhoto`: novi doc `{uid, role:'user', photoUrl, customPhotoUrl, createdAt, updatedAt}`; postojeći `update {photoUrl, customPhotoUrl, updatedAt}`.
- Pretplata: `users/{uid}.snapshots()` u `watchUser()`.

**`dogs/{dogId}`** (`saveUserProfile`, `set merge`)
- `id`, `ownerId`, `name`, `breed`, `age` (int), `ageYears` (int, ista vrednost), `gender`, `bio`, `photoUrl`, `imageUrl`, `photos`, `photoUrls`, `galleryUrls`, `size`, `temperament` (List<String>), `ownerName`, `location` (`locationLabel`), `cityId`, `cityName`, `neighborhoodId`, `neighborhoodName`, `updatedAt`.

**Lokacijska polja** (`firestoreLocationFields`, koristi ih kod van slice-a): `isWalking` (bool, samo ako nije null – null-aware element `?isWalking`), `lastKnownLocation` (GeoPoint), `geohash` (String, preciznost 7), `latitude` (double), `longitude` (double). `geoCoordFromMap` čita `lastKnownLocation` pa `latitude`/`longitude`.

**Brisanje naloga** (`AccountDeletionService.deleteAllUserData`, redom):
1. `dogs` where `ownerId == uid` → podkolekcije `health_records`, `reminders`, `likes` → doc.
2. `moments` where `authorUserId == uid` (polje fotke `momentPhotoUrl`) → podkolekcija `comments` → doc.
3. collectionGroup `comments` where `authorUserId == uid` (greške progutane).
4. `adoption_dogs` where `uploaderUserId == uid` → `comments` → doc (+ `imageUrl`).
5. `lost_dogs` where `uploaderUserId == uid` → `comments` → doc (+ `imageUrl`).
6. `swipes` where `fromUserId`; `super_likes` where `fromUserId`.
7. `matches` where `userIds` arrayContains; `matches` where `participantIds` arrayContains.
8. `notifications` where `toUserId`; where `recipientId`; where `fromUserId`.
9. `events` where `organizerUserId == uid` → `messages`, `members` → doc (+ `imageUrl`); zatim `events` where `participantUserIds` arrayContains → `arrayRemove`.
10. `breed_groups` where `memberIds` arrayContains → `arrayRemove`, `memberCount: increment(-1)`, brisanje `members/{uid}`.
11. `highlights` where `ownerId` („Legacy top-level highlights“).
12. collectionGroup `messages` where `senderId == uid` (skuplja `imageUrl`; greške progutane).
13. `chats` where `participantIds` arrayContains → `update {participantIds: bez uid, unreadByUser: bez uid ključa}`.
14. `users/{uid}`: skuplja `photoUrl`, `customPhotoUrl`; podkolekcije `fcmInbox`, `blocked_users`, `walks`, `place_change_requests`; brisanje dokumenta.
15. Storage: `tryDeleteImageByUrl` za sve skupljene URL-ove.

Napomena: nigde u slice-u se ne čita Firestore kolekcija za admin ulogu osim polja `role` na `users/{uid}`.

##### Storage
- Putanje: `{root}/{uid}/[podfolder/]{millisSinceEpoch}{.jpg|.png|.webp|.gif}`; dozvoljeni root-ovi (`ownerScopedRoots`): `pets`, `users`, `moments`, `events`, `groups`, `adoption`, `lost_dogs`, `uploads`, `chats`. Nepoznat root → `uploads/{uid}/{folder}`.
- Registracija: `folderName: 'users'` → `users/{uid}/{millis}.ext`.
- Metadata: `contentType` (sniff), `cacheControl: 'public,max-age=31536000'`.
- Download limit `8 * 1024 * 1024` bajtova, keš 48 stavki.
- Bucket iz `firebase_options.dart` (`storageBucket`), prepoznavanje URL-a: `firebasestorage.googleapis.com`, `firebasestorage.app`, `.appspot.com`, `gs://`.

##### Firebase Auth / Google
- `signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, `updateDisplayName`, `updatePhotoURL`, `reload`, `signInWithCredential(GoogleAuthProvider.credential)`, `signOut`, `sendPasswordResetEmail`, `user.delete()`, `getIdToken`.
- GoogleSignIn scopes: `['email', 'profile']` (definisano na 2 mesta: `auth_providers.dart:20` i default u `firebase_auth_datasource.dart:16`).

##### Firebase Messaging
- `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` – handler samo inicijalizuje Firebase (`main.dart:15–27`).

##### HTTP / eksterni URL-ovi
- Nema direktnih HTTP API poziva (nema `http`/`Dio`) u slice-u.
- `LegalUrls.privacyPolicy` = `https://vauvau-3195a.web.app/privacy`, `LegalUrls.termsOfService` = `https://vauvau-3195a.web.app/terms` (otvaraju se preko `url_launcher`).
- `LegalUrls.privacyContact` = `OfficialContacts.emailUri` (van slice-a).
- Prikazne ilustracije: 10 `https://images.unsplash.com/photo-...?auto=format&fit=crop&w=800&q=80` URL-ova u `fallback_image_helper.dart:16–25` (učitavaju se preko `CachedNetworkImage`).
- Firebase Storage download URL-ovi preko `Image.network`/`CachedNetworkImage`/HTML `<img>`.

##### SharedPreferences
- U ovom slice-u **nema** SharedPreferences ključeva (koriste se van slice-a: `profile/data/app_settings_store.dart`, `lost_dogs/data/lost_dog_popup_store.dart`).

##### Platform kanali / nativne integracije
- Nema direktnih `MethodChannel`/`EventChannel` poziva.
- Web: `ui_web.platformViewRegistry.registerViewFactory` sa viewType `'vauvau-fb-img-<url.hashCode hex>-<fit.name>'` (`firebase_web_image_web.dart:18–19`).
- Lokalne notifikacije: Android kanali `'vauvau_health'` („Zdravlje i podsetnici“) i `'vauvau_alerts'` („VauVau obaveštenja“, `Importance.high`), groupKey `'vauvau_alerts_group'`, tag `'vauvau_{type}_{id}'`, ikona `'@mipmap/ic_launcher'`. Data ključevi u payload-u: `conversationId`, `chatId`, `groupId`, `eventId`, `type`.
- Geolocator foreground servis: naslov `'VauVau Šetnja u toku'`, tekst `'Vaša lokacija se prati u pozadini radi preciznog merenja rute.'`, ikona `AndroidResource(name: 'launch_background')`, kanal `'VauVau šetnja'`, wake lock, ongoing.
- Asseti: `assets/images/vauvau_splash.png`, `sounds/message.wav` (audioplayers `AssetSource`).

##### Ključevi / tajne
- Firebase API ključ (Android i iOS) je hardkodovan u `lib/firebase_options.dart`, polje `apiKey` u `DefaultFirebaseOptions.android` (linija 21) i `DefaultFirebaseOptions.ios` (linija 30). Tu su i `appId`, `messagingSenderId`, `projectId` (`vauvau-3195a`), `storageBucket`. Vrednost ključa ovde nije navedena.

#### Chat / grupe / događaji
##### `chats/{chatId}` (chatId = `'${sortedUid0}_${sortedUid1}'`)
**Upis (`_createRoom`, firestore_chat_repository.dart:455, `set(..., merge: true)`):**
| Polje | Tip |
|---|---|
| `id` | String |
| `participantIds` | Array<String> `[myUserId, peerId]` |
| `dogIds` | Array<String> `[myDogId, peerDogId]` |
| `peerUserId` | String (peer iz perspektive kreatora) |
| `dogId`, `dogName`, `ownerName`, `breed`, `location`, `photoUrl` | String (podaci PEER-a iz perspektive kreatora) |
| `dogNames` | Map<uid, String> |
| `ownerNames` | Map<uid, String> |
| `breeds` | Map<uid, String> |
| `photoUrls` | Map<uid, String> |
| `lastMessage` | String `''` |
| `lastMessageTimestamp` | `FieldValue.serverTimestamp()` |
| `unreadCount` | int `0` (legacy/zajednički) |
| `unreadByUser` | Map<uid, int> `{me: 0, peer: 0}` |
| `isNewMatch` | bool `true` |

Za `_createRoom` se čita i `dogs/{myDogId}`: `name`, `ownerName`, `breed` i foto polja preko `collectPhotoUrls`.

**Upis posle poruke (`_writeMessage`, l. 924, merge):** `lastMessage` (preview String), `lastMessageTimestamp` (serverTimestamp), `isNewMatch: false`, `unreadByUser: {me: 0, peer: FieldValue.increment(1)}`.
**Upis `markRead` (l. 489, merge):** `unreadCount: 0`, `unreadByUser: {me: 0}`.
**Čitanje (`_conversationFromRoom`):** `participantIds`, `dogIds`, `peerUserId` (fallback), `dogNames[peer]`→`dogName`, `ownerNames[peer]`→`ownerName`, `breeds[peer]`→`breed`, `location`, `photoUrls[peer]`→`photoUrl`, `dogId` (fallback), `lastMessageTimestamp` (Timestamp), `isNewMatch`, `unreadByUser[me]` (int) → fallback `unreadCount`, `lastMessage`.
**Upit/listener:** `chats.where('participantIds', arrayContains: uid).snapshots()` – jedan u `start()` i drugi (zaseban) u `watchRooms()`.

##### `chats/{chatId}/messages/{messageId}` (auto id preko `add`)
**Upis (tekst, `sendMessage`):** `senderId`, `receiverId`, `senderName`, `senderAvatarUrl`, `text` (String), `timestamp` (serverTimestamp), `isRead: false` (bool), `type: 'text'`, opciono `replyToMessageId`, `replyToText` (isečeno na 120), `replyToSenderName`.
**Fotografija (`sendPhoto`):** isto + `imageUrl` (String), `text: ''`, `type: 'text'`.
**Poziv (`sendWalkInvite`):** + `type: 'walk_invite'`, `status: 'pending'`, `walkTime` (`Timestamp.fromDate`), `walkLocationName` (String), `text: 'Poziv na šetnju: $lokacija'`.
**Lokacija (`sendLocationPin`):** `type: 'location_pin'`, `text: locationName` (nema koordinata).
**Update:** `likes` (Array<String>, ceo niz preko `update`), `status` (`'accepted'|'declined'`).
**Čitanje (`_messageFromDoc`):** `senderId`, `type`, `status` (null → `pending` za walk invite), `receiverId`, `senderName`, `senderAvatarUrl`, `text`, `imageUrl`, `timestamp` (Timestamp/DateTime; null → `DateTime.now()`), `isRead`, `walkTime`, `walkLocationName`, `replyToMessageId`, `replyToText`, `replyToSenderName`, `likes`.
**Upiti/listeneri:**
- po otvorenoj sobi (attachRoom): `.orderBy('timestamp', descending: true).limit(30).snapshots()`;
- za SVAKU sobu u inbox-u: `.where('type', isEqualTo: 'walk_invite').snapshots()` (bez limita);
- `watchMessages` (nekorišćen): isto kao attach upit.
- `isRead` se piše uvek kao `false` i u Firestore-u se nikad ne ažurira na `true`.

##### `swipes` (čitanje, incoming_likes.dart)
Upit `swipes.where('toDogId', isEqualTo: myDogId).snapshots()`. Čita: `type` (default `'like'`), `fromUserId`, `fromDogId` → fallback `senderDogId`, `createdAt` → fallback `timestamp` (Timestamp). Upis u `swipes` nije u ovom delu.

##### `breed_groups/{groupId}`
**Seed upis (`ensureSeeded`):** novi doc: `title, description, imageUrl, memberIds (Array), memberCount (int), sortOrder (int), lastMessage, isApproved (bool), createdBy`. Postojeći (merge): `title, description, imageUrl, isApproved: true, sortOrder, createdBy` + (ako nema članova) `memberCount`, `memberIds: []`. Brisanje `breed_groups/vlasnici-malih-pasa-novi-sad`.
**createGroup:** `title, description, imageUrl: '', memberIds: [uid], memberCount: 1, sortOrder: 999, lastMessage: '', isApproved: bool, createdBy: uid, createdAt: serverTimestamp`.
**joinGroup (transakcija, `update`):** `memberIds` (ceo niz), `memberCount` (int).
**approveGroup:** `isApproved: true` (merge). **deleteGroup:** `delete()` (podkolekcije ostaju).
**Posle poruke (merge):** `lastMessage`, `lastMessageAt` (serverTimestamp), `lastMessageSenderId` (piše se, nigde se ne čita).
**Čitanje (`tryFromMap`):** `memberIds`, `memberCount` | `membersCount`, `title`, `description`, `imageUrl`, `sortOrder`, `lastMessage`, `lastMessageAt`, `isApproved`, `createdBy`, `createdAt`.
**Upit:** `breed_groups.snapshots()` – cela kolekcija, filter `isApproved` na klijentu (dva paralelna listenera ako je admin: approved i pending).

##### `breed_groups/{groupId}/members/{uid}`
`lastReadTimestamp` (serverTimestamp) – piše se pri join/create/markRead; čita se listenerom `doc.snapshots()` u `watchLastRead`.

##### `breed_groups/{groupId}/messages/{messageId}`
**Upis tekst/slika:** `senderId, senderName, senderAvatarUrl, text, imageUrl, createdAt (serverTimestamp)`, opciono `replyToMessageId, replyToText (isečeno 120), replyToSenderName (fallback 'Član')`. Bez polja `type` za obične poruke.
**Walk invite:** + `type: 'walk_invite'`, `status: 'pending'`, `walkTime` (Timestamp), `walkLocationName`, `acceptedByUserIds: []`, `declinedByUserIds: []`.
**Odgovor:** `update` – `acceptedByUserIds`/`declinedByUserIds` preko `FieldValue.arrayUnion`/`arrayRemove`, `status: 'pending'`.
**Lajk (transakcija):** `tx.set({'likes': [...]}, merge)`.
**Čitanje:** `createdAt` (Timestamp; inače `DateTime.now()`), `type`, `status`, `walkTime`, `senderId`, `senderName`, `senderAvatarUrl`, `text`, `imageUrl`, `replyTo*`, `walkLocationName`, `acceptedByUserIds`, `declinedByUserIds`, `likes`.
**Upit:** `.orderBy('createdAt').snapshots()` bez limita – po jedan listener za svaku grupu gde je korisnik član (preko `joinedGroupThreadsProvider`).

##### `events/{eventId}`
**Seed upis (batch, samo ako je kolekcija prazna):** `title, locationName, dateTime (Timestamp), description, imageUrl, organizerUserId ('vauvau'), organizerName ('VauVau'), participantUserIds (dummy 'seed-N'), createdAt (Timestamp), lastMessage, cityId`.
**Scrub:** `update({'imageUrl': ''})` za stock CDN URL-ove.
**createEvent (`add`):** `title, locationName, dateTime (Timestamp), description, imageUrl, organizerUserId, organizerName, participantUserIds: [uid], createdAt (serverTimestamp), lastMessage: ''`, opciono `cityId`.
**joinEvent (transakcija):** `participantUserIds` (ceo niz).
**Posle poruke (merge):** `lastMessage`, `lastMessageAt` (serverTimestamp).
**Čitanje (`_fromDoc`):** `participantUserIds`, `title`, `locationName`, `dateTime` (Timestamp ili ISO String; inače `DateTime.now()`), `description`, `imageUrl`, `organizerUserId`, `organizerName`, `createdAt`, `lastMessage`, `lastMessageAt`, `cityId`.
**Upit:** `events.orderBy('dateTime').snapshots()` (bez filtera po datumu/gradu – sve se filtrira na klijentu); `events.limit(1).get()` i `events.get()` (cela kolekcija) u `ensureSeeded`.

##### `events/{eventId}/members/{uid}` – `lastReadTimestamp` (serverTimestamp), kao kod grupa.
##### `events/{eventId}/messages/{messageId}` – ista šema kao `breed_groups/.../messages` (bez `lastMessageSenderId` na roditelju; `replyToText` nije isečen). Upit `.orderBy('createdAt')` bez limita.

##### Storage (posredno)
`ImageUploadService.uploadFile(file, folderName: 'chats' | 'groups' | 'events')` – implementacija je van ovog dela.

#### Discover / psi / profil
##### `dogs/{dogId}`
**Upis pri kreiranju** (`DogsRepositoryImpl.createFirstDog`): `id: String`, `ownerId: String`, `name: String`, `breed: String`, `gender: String` (`male`/`female`/`unknown`), `age: int`, `ageYears: int`, `size: String` (`small`/`medium`/`large`/`xlarge`), `bio: String`, `isVaccinated: bool`, `isMicrochipped: bool`, `isSterilized: bool`, `location: String` („Grad - Naselje”), `cityId`, `cityName`, `neighborhoodId`, `neighborhoodName: String`, `weightKg: double?`, `energyLevel: String` (`low`/`moderate`/`high`), `temperament: List<String>`, `likesTags`, `dislikesTags: List<String>`, `area: Map<String,String>` (ako postoji), `ownerName: String`, `createdAt`, `updatedAt: serverTimestamp`, `isWalking: bool(false)`, `lastKnownLocation: GeoPoint`, `geohash: String`, `latitude`, `longitude: double`, `photoUrl`, `imageUrl: String`, `photos`, `photoUrls`, `galleryUrls: List<String>`, `primaryPhotoUrl: String`.

**Upis pri izmeni** (`updateDog`, merge): ista polja bez `createdAt`, `ownerName`, geo polja; plus `ageMonths: int`, `location` u formatu „Grad, Naselje”.

**Brojači** (`FirestoreDiscoverRepository`, merge): `likesCount: increment(±1)`, `superLikesCount: increment(1)`.

**Čitanje** (`discoverProfileFromMap`, `_dogFromDoc`): sve gore + legacy `vaccinated`, `chipped`, `sterilized` (samo mapper), `traits`, `image`, `walkStatus`, `activityStatus`, `goodWithDogs/Cats/Kids`, `friendlyWithDogs/Cats/Kids`. Polja `goodWith*`, `walkStatus`, `isWalking=true` se **u ovom slice-u ne upisuju** (verovatno ih piše map/walk modul – nije provereno).

**Upiti**: `orderBy('createdAt', desc).limit(n)` (+ `startAfterDocument`); `where('ownerId', ==).snapshots(includeMetadataChanges)`; `where('ownerId', ==).get()` (brisanje); `where('ownerId', ==).limit(1)` (`loadDiscoverProfile`). Geohash se upisuje, ali se **ne koristi u upitima** – geo filtriranje je klijentsko.

##### `dogs/{dogId}/likes/{userId}`
`userId: String`, `type: String` (`like`/`superLike`), `createdAt: serverTimestamp`. Čita se (`hasLiked`, `_recordLike`), briše (`unlike`).

##### `dogs/{dogId}/health_records/{recordId}`
`id: String`, `dogId: String`, `category: String` (`vaccineRabies`/`vaccineCore`/`deworming`/`tickProtection`), `title: String`, `administeredDate: Timestamp`, `nextDueDate: Timestamp?`, `notes: String` (prazan string ako nema), `notificationId: int?`, `updatedAt: serverTimestamp`. Čitanje toleriše i `String` datume. Bez upita – ceo snapshot podkolekcije.

##### `dogs/{dogId}/reminders/{reminderId}`
`id`, `dogId`, `title: String`, `type: String` (ReminderType.name), `category: String`, `date: Timestamp`, `repeatType: String`, `reminderOffset: String`, `note: String`, `isCompleted: bool`, `notificationId: int?`, `repeatDayOfMonth: int`, `customIntervalCount: int`, `customIntervalUnit: String`, `lastCompletedDate: Timestamp?`, `updatedAt: serverTimestamp`, `createdAt: serverTimestamp` (samo za novi). Legacy čitanje: `customIntervalDays: int`.

##### `swipes/{userId}_{dogId}`
`fromUserId`, `fromDogId`, `toDogId: String`, `type: String` (`like`/`superLike`/druga akcija), `timestamp`, `createdAt: serverTimestamp`. Upit za meč: `where('fromUserId', ==).where('toDogId', ==).limit(5)` (verovatno traži kompozitni indeks – iz koda se ne vidi da li postoji).

##### `super_likes/{autoId}`
`fromUserId`, `targetDogId`, `targetOwnerId: String`, `createdAt: serverTimestamp`. Upit: `where('fromUserId', ==).limit(25)`.

##### `matches/{uidA}_{uidB}` (sortirani uid-ovi)
`id: String`, `dogIds: List<String>` [mojPas, njihovPas], `userIds: List<String>`, `createdAt`.

##### `chats/{uidA}_{uidB}`
`id`, `participantIds: List<String>`, `dogIds: List<String>`, `dogId`, `dogName`, `ownerName`, `breed`, `location`, `photoUrl`, `peerUserId: String`, `lastMessage: String('')`, `lastMessageTimestamp: serverTimestamp`, `isNewMatch: bool(true)`, `unreadCount: int(0)`.

##### `notifications/{autoId}`
- Like: `fromUserId`, `senderUserId`, `toUserId`, `title` („Novi lajk! 🐾”), `body`, `type: 'like'`, `isRead: false`, `createdAt`, `dogId` (= **pas pošiljaoca**), `senderDogId`; fallback bez `senderUserId/dogId/senderDogId`.
- Super Like: `recipientId`, `toUserId`, `senderId`, `fromUserId`, `senderUserId`, `type: 'SUPER_LIKE'`, `title` („⭐ Super Like!”), `message`, `body`, `dogId` (= **target pas**), `senderDogId`, `createdAt`, `isRead: false`.

##### `users/{uid}`
- Čitanje: `name`, `email` (ime za notifikacije), `customPhotoUrl`, `photoUrl` (avatar vlasnika u `DogDetailSheet`).
- Upis (createFirstDog, merge, neawaitovano): `uid`, `name`, `email`, `city`, `cityId`, `cityName`, `neighborhoodId`, `neighborhoodName`, `primaryDogId`, `updatedAt`, `createdAt`, `dog: {id, name, breed, age, gender, bio, size, temperament, likesTags, dislikesTags, photoUrl, imageUrl, photos, photoUrls, galleryUrls}`.
- Ostali upisi idu preko `authRepositoryProvider.saveUserProfile(...)` i `saveOwnerCustomPhoto(...)` – implementacija van slice-a.

##### Firebase Storage
- Slike pasa: `folderName: 'pets'` preko `StorageService` (van slice-a). Prema `StorageService.ownerFolder` i `_putBytes` putanja je `pets/{uid}/{millisecondsSinceEpoch}{ext}`; vraća se HTTPS download URL.
- Avatar vlasnika: `folderName: 'users'` → `users/{uid}/{timestamp}{ext}`; prethodna slika se briše `tryDeleteImageByUrl`.
- Brisanje slike psa: `tryDeleteImageByUrl(url)` u onboardingu i izmeni psa.
- `DogPhotoStorage` (neiskorišćen) takođe koristi `pets`.
- Lokalni fajl sistem (neiskorišćeno): `{applicationDocuments}/dog_photos/{dogId}/{i}.jpg`.

##### SharedPreferences (`AppSettingsStore`)
| Ključ | Tip | Default |
|---|---|---|
| `vauvau.settings.notifyWalkRequests` | bool | true |
| `vauvau.settings.notifyMessages` | bool | true |
| `vauvau.settings.notifyNewMatches` | bool | true |
| `vauvau.settings.radiusKm` | double | 20 |
| `vauvau.settings.showLocationOnMap` | bool | true |
| `vauvau.settings.pushPrompted` | bool | false |
| `vauvau.settings.language` | String (`AppLanguage.code`) | serbian |
| `vauvau.settings.themePreference` | String (`AppThemePreference.code`) | dark |

`MatchingFilters` (osim radiusa), lokalni repozitorijumi (psi, zapisi, podsetnici, lajkovi) i izabrani pas **nisu perzistentni**.

#### Mapa
##### `cities` (samo čitanje)
- Upit: cela kolekcija, `snapshots()` (bez filtera/limita).
- Polja: `id: String?` (fallback doc.id), `name: String`, `lat|latitude: num`, `lng|longitude: num`, `radiusKm: num` (def. 15), `sortOrder: num` (def. 0), `isActive: bool` (def. true).
- Ko piše u `cities` – nije u ovom delu koda.

##### `pois`
- Čitanje: cela kolekcija `snapshots()` bez limita (`FirestorePoiRepository.watchAll`).
- Pisanje: `set(merge: true)` iz `upsert` (korisnički predlozi + bilo koji `PoiModel`), batch iz `createPlace`/`updatePlace`, `delete` iz `deletePlace`.
- Polja (`_toMap`): `id, name, category (enum name), address: String`, `latitude, longitude: double`, `phone: String`, `website: String?`, `is24_7, isEmergencyService, overnightStay, dayCare, hasYard: bool`, `pricePerNight: double?`, `openingHours: String`, `petFriendly: bool`, `dogFriendlyIndoor, dogFriendlyOutdoor, waterAvailable, isDogPark: bool?`, `municipality, description: String`, `imageUrl: String?`, `sourceUrl: String`, `city: String (MapCity name)`, `cityId: String`, `verificationStatus: String`, `lastVerified: Timestamp`, `source: String`, `rating: double?`, `isSponsored: bool`, `sponsorName: String`, `sponsoredUntil: Timestamp?`, `sponsorBadge: String`, `sponsorPriority: int`.
- Dodatno iz `createPlace`: `createdBy: String`, `createdAt: serverTimestamp`, `lastVerified: serverTimestamp`, `source: 'Admin'`. Iz `updatePlace`: `updatedAt: serverTimestamp`.

##### `places` (admin SoT)
- Čitanje: cela kolekcija `snapshots()`.
- `createPlace` polja: `id, name, category (snake_case ključ), cityId, cityName, address: String`, `location: GeoPoint`, `latitude, longitude: double`, `openingHours, phone, createdBy: String`, `createdAt: serverTimestamp`, `isVerified: true`, `verificationStatus: 'verified'`.
- `updatePlace` polja: gore navedeno (bez `createdBy/createdAt`) + `website, is24_7, isEmergencyService, overnightStay, dayCare, hasYard, pricePerNight, petFriendly, isDogPark`, `isVerified: bool`, `verificationStatus: String`, `updatedAt: serverTimestamp`. (`cityName` se upisuje kao `poi.city.name`, npr. `noviSad`, a ne ljudsko ime grada.)
- Brisanje: `places/{id}` + `pois/{id}` u istom batch-u.

##### `users/{uid}`
- Prisustvo (merge): `isWalking: bool`, `lastKnownLocation: GeoPoint`, `geohash: String`, `latitude, longitude: double`, `walkStartedAt: serverTimestamp | delete`, `walkStatus: String`.
- `walkHistory: array<map>` (`arrayUnion`) – mapa: `id, userId, dogId: String`, `distanceKm: double`, `durationSeconds: int`, `statusMessage: String`, `startedAt, endedAt: Timestamp`.
- `placeChangeRequests: array<map>` (`arrayUnion`) – `id ('pcr-<ms>'), placeId, placeName, reportedByUserId, changeType, description: String`, `createdAt: Timestamp`, `status: 'pending'`.

##### `users/{uid}/walks/{walkId}`
- Isti payload kao stavka `walkHistory`. Upit: `where endedAt >= cutoff`, `orderBy endedAt desc`, `limit 50`. Komentar u kodu kaže da je upis „best-effort when nested rules are deployed“ – da li su pravila deploy-ovana, nije poznato iz ovog dela koda.

##### `dogs/{dogId}`
- Isti presence payload kao `users/{uid}`.
- Upiti: `where isWalking == true limit 50` (snapshots); `where ownerId == uid` (get, kad `dogId` nije poznat).
- Čitaju se i polja za `discoverProfileFromMap` (van ovog dela) i `walkStatus`.

##### `notifications` (add, best-effort)
`type: 'PLACE_CHANGE_REQUEST'`, `title: 'Prijava promene lokacije'`, `message`, `body`, `recipientId = toUserId = senderId = fromUserId = reportedByUserId = uid` (**primalac je sam prijavilac** – `poi_report_controller.dart:111-115`), `placeId, placeName, changeType, description, requestId`, `createdAt: serverTimestamp`, `isRead: false`, `status: 'pending'`.

##### `change_requests`, `admin_notifications`, `reports` (add, best-effort)
Bazni `entry` + `createdAt: serverTimestamp`; za `reports` dodatno `reporterId, reportedBy, reportedUserId: '', targetType: 'poi', targetId, reason, details, timestamp`; za `admin_notifications` dodatno `type: 'PLACE_CHANGE_REQUEST', targetId, targetType: 'poi', reason, details`.

##### Spoljni HTTP endpointi
U aplikaciji:
- Nominatim (geokodiranje adrese): `https://nominatim.openstreetmap.org/search?q=<upit>&format=json&addressdetails=0&limit=6&countrycodes=rs`, header `User-Agent: VauVauApp/1.0 (map place admin)`.
- OSM tile-ovi: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
- Navigacija: `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>&travelmode=walking`, `http://maps.apple.com/?daddr=<lat>,<lng>`, `geo:<lat>,<lng>?q=<label>`.
- Linkovi u podacima (`sourceUrl`/`website`) – otvaraju se samo kao „Sajt“ (website); `sourceUrl` se ne prikazuje u UI (prikazuje se samo `source` tekst).

U alatima (`tool/`):
- Photon: `https://photon.komoot.io/api/?q=<upit>&lat=<lat>&lon=<lon>&limit=3&lang=en` (Beograd) i `…&limit=5&lang=en` (generička skripta).
- Nominatim structured: `https://nominatim.openstreetmap.org/search?format=jsonv2&addressdetails=1&limit=3&countrycodes=rs&street=<ulica>&city=<grad>`.
- Overpass API – samo rezultat (`nis_osm_parks.json`), bez sačuvanog upita/skripte.

#### Priče / izgubljeni psi / udomljavanje / moderacija / admin
| Putanja | Polja (iz koda) | Ko piše / čita |
|---|---|---|
| `moments/{momentId}` | authorUserId, authorName, dogId, dogName, dogBreed, dogPhotoUrl, momentPhotoUrl (https), caption, locationName (String); likes (List<String>); commentsCount (int); createdAt (serverTimestamp) | Upit `orderBy('createdAt', desc).limit(15)` + `startAfterDocument`. Admin briše |
| `moments/{id}/comments/{commentId}` | authorUserId, authorName, text, likes (List<String>), createdAt (serverTimestamp) | `orderBy('createdAt')` |
| `dogs/{dogId}.storyHighlights` | Map<id, {ownerId (samo pri kreiranju), title, momentIds (List<String>), coverMomentId, order (int), createdAt (Timestamp)}> | set merge / FieldValue.delete |
| `lost_dogs/{id}` | dogName, breed, type (`lost`/`found`), city, neighborhood, lostDate (Timestamp), foundDate (Timestamp), description, imageUrl, photoUrl (duplikat), contactPhone, uploaderUserId, status (`active` → `resolved`; legacy `missing`/`found`), comments (List<Map>), commentLikes (Map<String, List<String>>), commentsCount (int), createdAt (serverTimestamp) | Upit `limit(40)` bez orderBy. Element komentara: `{id 'c-<micros>', authorUserId, authorName, text, likes [], createdAt (klijentski Timestamp)}` |
| `adoption_dogs/{id}` | name, breed, age, gender, size, location (`'city, neighborhood'`), city, neighborhood, description; imageUrls (List), photos (List, duplikat), photoUrl (prva); contactPhone, uploaderUserId, uploaderName; isVaccinated, isSterilized (bool); status (`available` → `adopted`); createdAt (serverTimestamp) | `orderBy('createdAt', desc).limit(20)` |
| `users/{uid}/blocked_users/{blockedUid}` | blockedAt (serverTimestamp) | vlasnik |
| `users/{uid}.contentReports` | List<Map>: id, reporterId, reportedBy, reportedByUserId, reportedUserId, targetType (`user`/`moment`/`message`/`dog_profile`/`poi`/`chat`), targetId, reason, details, status, createdAt, timestamp; admin dodaje status/reviewedAt | `arrayUnion`; admin prepisuje ceo niz |
| `users/{uid}.placeChangeRequests` | čita ga moderation (description, changeType, placeId, placeName…); piše ga map feature (van obuhvata) | – |
| `reports/{reportId}` | entry + timestamp/createdAt (serverTimestamp); admin: status, reviewedAt | kopija prijave |
| `admin_notifications/{auto}` | type `REPORT_POST_OR_PROFILE`, targetId, targetType, reportedByUserId, reportedUserId, reason, details, reportId, createdAt, status `pending` | samo se piše; u obuhvatu se nigde ne čita |
| `notifications/{auto}` | (a) iz `queueForUser`: type, title, body, dogId, fromUserId, senderUserId, conversationId, groupId, eventId, toUserId, isRead, createdAt, data; (b) iz prijave: type `CONTENT_REPORT`, title, message, body, recipientId, toUserId, senderId, fromUserId, reportedByUserId, reportedUserId, targetType, targetId, reason, details, reportId, createdAt, isRead, status | `where('toUserId' == uid).limit(100)`; update isRead; delete pri čitanju chata |
| `users/{uid}` (push) | fcmToken (String), fcmTokenUpdatedAt (serverTimestamp) | set merge |
| `users/{uid}/fcmInbox/{auto}` | isti dokument kao (a) gore | samo se piše; u repou ga niko ne čita |
| `users/{uid}` (admin čitanje) | name, email, role (`user`/`admin`), uid, createdAt | admin čita celu kolekciju |
| `admin_feedback/{auto}` | userId, userName, userEmail, category (npr. "💡 Predlog"), subject, message, createdAt (serverTimestamp), status (`new` → `resolved`), resolvedAt (serverTimestamp) | korisnik kreira; admin čita/menja/briše |
| `breed_groups/{id}.isApproved` | admin postavlja `true` (set merge) ili briše dokument | `pendingGroupsProvider` |
| `places` / `pois` | admin piše preko `PlacesRepository` (izvor istine `places`, kopija u `pois`; implementacija van obuhvata) | – |

Relevantna pravila (`firestore.rules`, van obuhvata): `admin_feedback` create samo ako `userId == auth.uid` i `status == 'new'`, read/update/delete samo admin (377–382); `moments` delete autor ili admin (394–395); `users/{userId}` read dozvoljen svakom prijavljenom korisniku – zato su `fcmToken` i niz `contentReports` čitljivi svim prijavljenim korisnicima; `breed_groups` `allow update: if isAuthenticated()` (308) – **bilo koji prijavljeni korisnik može da menja grupu, pa i da postavi `isApproved: true`**, tako da admin odobravanje nije zaštićeno na serveru.

**Storage** (tačne putanje su u servisima van obuhvata):
- moments: `StorageService().uploadXFile(file, folderName: 'moments')`.
- lost_dogs: `ImageUploadService.uploadFile(photo, folderName: 'lost_dogs')`.
- adoption: `ImageUploadService.uploadFile(file, folderName: 'adoption')`.
- Brisanje momenta/oglasa ne briše fajlove iz Storage-a.

**SharedPreferences:** `has_dismissed_lost_dog_popup` (bool); `AppSettings.pushPrompted` i podešavanja `notifyNewMatches/notifyMessages/notifyWalkRequests` (implementacija van obuhvata).

### Podaci o lokacijama (seed mesta, izvori, šta je provereno)
#### Broj seed mesta po gradu (iz koda)

| Grad | Izvor u kodu | Ukupno | `verified` | `unknown` |
|---|---|---|---|---|
| Novi Sad | `PoiSeedData.verifiedNoviSad` (11 kafića, 14 parkova za pse, 3 hitna veterinara, 9 pansiona, 2 čuvanja) | 39 | 39 | 0 |
| Novi Sad | `catalogServicePlaces` u `mock_map_data.dart` (3 pet shopa, 5 groomera, 1 veterinar) | 9 | 0 | 9 |
| Beograd | `BelgradeDogPlacesSeed.all` (14 parkova, 36 pet shopova, 18 groomera, 2 veterinara, 30 restorana, 6 kafića, 2 poslastice) | 108 | 108 | 0 |
| Beograd | `belgradeEmergencyVets` (3) + `belgradeLegacyExtras` (3 parka, 2 kafića, 2 pansiona) | 10 | 10 | 0 |
| Niš | `NisDogPlacesSeed.all` (5 parkova + 2 „other“ (kej, trg), 1 park za pse, 8 pet shopova, 4 veterinara, 6 groomera, 4 kafića + 1 restoran, 2 dresure, 2 pansiona) | 35 | 13 | 22 |
| Kragujevac | `KragujevacDogPlacesSeed.all` (4 parka + 1 trg, 3 pet parka, 5 pet shopova + 1 perionica, 11 veterinara, 3 groomera, 4 kafića) | 32 | 7 | 25 |
| **Ukupno u `mockMapPlaces`** | | **233** | **177** | **56** |

Napomena: id-jevi legacy Beograd stavki se ne preklapaju sa novim korpusom (proverom stringova), pa se svih 118 beogradskih mesta prikazuje. Ime `PoiSeedData.allVerified` (`poi_seed_data.dart:29`) je zavaravajuće – uključuje i 47 `unknown` stavki iz Niša i Kragujevca.

#### Polja koja postoje u seed podacima

| Polje | Novi Sad (39) | NS katalog (9) | Beograd korpus (108) | Beograd legacy (10) | Niš (35) | Kragujevac (32) |
|---|---|---|---|---|---|---|
| telefon | 12 (vet, pansioni, čuvanje) | 0 | 0 | 6 | 4 | 4 (kafići) |
| radno vreme | 0 | 0 | 0 | 0 | 2 (OFF Cafe, La Vie) | 0 |
| ocena (`rating`) | 11 (svi kafići, 4.5–4.8) | 0 | 0 | 2 (kafići) | 0 | 0 |
| website | 0 | 0 | 15 (svi `https://www.pet-centar.rs`) | 0 | 5 | 3 |
| opština | 0 | 0 | 108 | 0 | 0 | 0 |
| opis | 0 | 0 | 0 | 0 | 19 | 13 |
| `sourceUrl` | 0 | 0 | 108 (Google Maps *search* URL-ovi) | 0 | 16 (OSM, kurir.rs, planplus, zvanični sajtovi) | 8 (OSM, rtk.co.rs, kragujevac.ls.gov.rs, infokg.rs, planplus) |
| 24/7 / hitno | 5 / 3 (3 veterinara + 2 pansiona 24/7) | 2 pet shopa sa `is24_7: true` | 0 | 3 / 3 | 0 | 0 |
| pogodnosti hotela | prenoćište 9, dvorište 5, dnevni boravak 4 (2 pansiona + 2 čuvanja), cena 1 (Dogs Empire 2000 RSD) | – | – | prenoćište/dvorište 2 | – | – |
| dog policy | `petFriendly` default `true` | default `true` | `petFriendly: true` eksplicitno na 36 kafića/restorana; ostali default `true` | default `true` | `petFriendly: false` za Tvrđavu, Bubanj, Hush Hush, Tramvaj; `dogFriendlyOutdoor: true` (OFF), `waterAvailable: true` (La Vie); `isDogPark` eksplicitno (5×false, 1×true) | `petFriendly: false` za sva 4 kafića; `isDogPark` false za 4 parka, true za 3 pet parka |
| `dogFriendlyIndoor` | nigde | nigde | nigde | nigde | nigde | nigde |
| sponzorstvo | nigde | nigde | nigde | nigde | nigde | nigde |

#### Kako je označena verifikacija
- Status je **hardkodovan u kodu** kroz `verificationStatus`. Ništa u kodu ne dokazuje da je provera stvarno izvršena; postoje samo tvrdnje u komentarima i datumi.
- **Novi Sad + Beograd legacy** (`PoiSeedData._verified`): svi `verified`, `source = 'PetZone / VauVau Baza'`, `lastVerified = 2026-08-12`. U kodu nema objašnjenja šta je „PetZone“ niti kako su provereni podaci, ocene i telefoni. Adrese parkova su samo nazivi naselja (npr. „Satelit“, „Podbara“), bez kućnog broja – izvor koordinata nije dokumentovan i u `tool/` ne postoji skripta za Novi Sad. PetGuards ima adresu „Novi Sad“ i koordinate `45.2551, 19.8451` – iste kao konstanta centra grada `noviSadLat/noviSadLng` (placeholder tačka).
- **NS katalog** (`catalogServicePlaces`): `unknown`, izvori „VauVau Zajednica“ / „Google Places“, hardkodovano `nearbyDogs: 1` kod 5 mesta.
- **Beograd korpus**: svi `verified` jer ih generator tako upisuje (`generate_belgrade_seed.ps1:81`), `source = 'VauVau Belgrade Seed / OSM Photon'`, `lastVerified = 2026-10-06`. Komentar kaže „geokodirano iz proverenih uličnih adresa“; međutim:
  - 14 grupa koordinata deli 2–5 različitih objekata (npr. `44.8195106,20.4122663` = `bg-park-bulevar-zd`, `bg-park-blok-30`, `bg-gr-leo`, `bg-cafe-barka`, `bg-cafe-sushidream`; `44.8178131,20.4568974` = `bg-park-katiceva`, `bg-park-pasterova`, `bg-park-tasmajdan`, `bg-gr-mimilend`). To ukazuje da je geokoder pao na nivo ulice/oblasti ili na fallback upit – te koordinate su verovatno približne.
  - Skripta prihvata i upit samo po ulici ili po imenu objekta (`geocode_belgrade_places.ps1:60-65`), bez beleženja preciznosti.
  - `sourceUrl` su Google Maps *search* linkovi, a ne konkretni zapisi.
- **Niš / Kragujevac**: dvostepeno – OSM/gradski izvori su `verified`, a biznisi „kandidati“ su `unknown` sa `source = 'VauVau kandidat (adresa geokodirana, nije potvrđeno)'`, `lastVerified = 2026-10-14`. Komentari jasno navode da operativni status nije potvrđen. Kafići su ostavljeni sa `petFriendly: false` jer politika prema psima nije potvrđena. „Poligon za pse Metino brdo“ je `unknown` jer je po izvoru bio u izgradnji.
- U UI: `verified` → „✓ Potvrđeno · dd.mm.yyyy“, `reported` → „Prijavljeno“, `pending/userSubmitted` → „Na čekanju“, ostalo → „Nije provereno“.

#### Šta rade alati u `tool/` (tok podataka)
1. **Beograd:** `belgrade_places_raw.json` (108) → `geocode_belgrade_places.ps1` (Photon, bbox 44.55–45.05 / 19.95–20.75, pauza 0,7 s, 3 pokušaja) → `belgrade_places_geocoded.json` → `generate_belgrade_seed.ps1` → `belgrade_dog_places_seed.dart` (dedup po `ime|adresa`). Telefon iz JSON-a se ne prenosi u Dart.
2. **Kragujevac:** `kragujevac_places_raw.json` (35) → `geocode_places.ps1` (Photon, primer parametara u komentaru) → `kragujevac_places_geocoded.json` (33, uglavnom `street` preciznost) i → `geocode_places_nominatim.ps1` → `kragujevac_places_nominatim.json` (26, kućni broj). Koordinate biznisa u Dart seed-u se poklapaju sa Nominatim fajlom (npr. `kg-vet-kragujvet` 44.013181, 20.912876). Parkovi u seed-u **ne odgovaraju** Photon koordinatama (npr. Veliki park 44.0176323/20.9038528 vs 44.017661/20.904234), a „Ekopark Ilina voda“ i „Pivarski park“ uopšte nisu u raw fajlu – njihovo poreklo (verovatno OSM, prema `sourceUrl`) nije pokriveno skriptama. Seed je **ručno pisan**, ne generisan.
3. **Niš:** `nis_places_raw.json` (24) + `nis_places_raw_extra.json` (7) → `geocode_places_nominatim.ps1` → `nis_places_nominatim*.json` + logovi `nis_geocode_log*.txt`. Parkovi iz Overpass (`nis_osm_parks.json/.txt`) i slobodnih Nominatim upita (`nis_nominatim_parks.txt`). Ispravke (`nis_nominatim_retry.txt`): La Vie – Nominatim je vratio pogrešnih `43.375459` (log), a seed koristi `43.3227007, 21.8989006` iz retry loga; Retro bar, Hush Hush, Tramvaj – OSM tačke iz retry loga. Seed je **ručno pisan**.
4. Kandidati uspešno geokodirani, ali **izostavljeni iz seed-a bez objašnjenja u kodu**: Niš – `nis-groom-frizer-romanijska`, `nis-hotel-happy-paws`; Kragujevac – `kg-vet-vetland` (ima Nominatim pogodak). Izostavljeni bez pogotka: Niš – `nis-vet-dr-beli`, `nis-groom-pet-star`, `nis-hotel-stevanovic`; Kragujevac – `kg-route-kej-lepenice`, `kg-shop-pet-centar-save-kovacevica`, `kg-shop-flokica`, `kg-groom-molly`.

### Firebase konfiguracija po platformama
#### `.firebaserc`
```json
{
  "projects": {
    "default": "vauvau-3195a"
  }
}
```

#### `firebase.json` (ceo sadržaj)
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "/privacy",
        "destination": "/privacy/index.html"
      },
      {
        "source": "/terms",
        "destination": "/terms/index.html"
      }
    ]
  }
}
```
- Firestore: rules `firestore.rules`, indeksi `firestore.indexes.json` (oba postoje u korenu; sadržaj je van ovog dela).
- Storage: `storage.rules` (postoji u korenu).
- Hosting: služi statički `public/` (legal stranice), **ne** Flutter web build (`build/web`). Live URL-ovi prema checklisti: `https://vauvau-3195a.web.app/privacy` i `/terms`.
- **Nema `functions` sekcije**; **folder `functions/` ne postoji** (provereno). Nema ni `emulators` sekcije.

#### `storage-cors.json`
- Jedno pravilo: `origin: ["*"]`, metode `GET, HEAD, PUT, POST, DELETE, OPTIONS`, `maxAgeSeconds: 3600`, response headeri `Content-Type, Authorization, Content-Length, User-Agent, x-goog-resumable, x-goog-meta-*`.
- Primenjuje se ručno (`gsutil cors set …`); u repou nema skripte koja ga primenjuje – nije poznato da li je primenjen.

#### `firebase.cmd`
- Wrapper oko `%USERPROFILE%\.cache\firebase\real-node\node-v20.18.2-win-x64\node.exe` + `…\firebase-tools\lib\bin\firebase.js`; javlja grešku ako nešto nedostaje. Koristi se u checklisti (`.\firebase.cmd deploy --only …`).
- U korenu postoje i `firebase.exe` i `firebase-tools-instant-win.exe` (~259 MB svaki), **gitignored**, nisu komitovani.

#### Firebase projekat
- ID `vauvau-3195a`, isti u `.firebaserc`, `google-services.json`, `GoogleService-Info.plist` i `lib/firebase_options.dart`.
- Uključeni servisi po Gradle/plist: Auth (Email + Google), Firestore, Storage, Messaging (FCM), Crashlytics. Analytics je u iOS plist-u `IS_ANALYTICS_ENABLED=false`. App Check nije konfigurisan (u checklisti „optional later“).

---
## 6. MODELI PODATAKA
Sva polja, tipovi i `fromMap`/`toMap` mapiranja po modulima. Pun kod najvažnijih modela je u sekciji 12.
### 6.1 Core, app, servisi, auth, splash, legal, lokacija, home
#### `AppUser` – `lib/features/auth/domain/app_user.dart`
Polja (sve `final`):
| Polje | Tip | Default |
|---|---|---|
| `uid` | `String` | required |
| `email` | `String?` | `null` |
| `displayName` | `String?` | `null` |
| `photoUrl` | `String` | `''` (Auth/Google avatar) |
| `customPhotoUrl` | `String` | `''` (vlasnikova uploadovana slika iz Firestore-a) |
| `city` | `String` | `''` |
| `cityId` | `String` | `''` |
| `neighborhoodId` | `String` | `''` |
| `neighborhoodName` | `String` | `''` |
| `bio` | `String` | `''` |
| `role` | `UserRole` | `UserRole.user` |
| `dog` | `UserDogProfile` | `const UserDogProfile()` |

- Konstruktor: `const AppUser({required uid, ...})`.
- Getteri: `isAdmin` (`role == UserRole.admin`), `cityName` (= `city`), `locationLabel` (`SerbiaLocations.formatPlace(cityName, neighborhoodName)`), `ownerAvatarUrl` (custom ako nije prazan, inače `photoUrl`).
- `copyWith(...)` – sva polja osim `uid`.
- `static ownerPhotoFromDocument(Map? data, {String authPhotoUrl = ''})` – vraća `customPhotoUrl` iz dokumenta; ako ga nema, vraća Firestore `photoUrl` samo ako je Auth foto prazan ili različit od njega; inače `''`.
- `static fromAuthAndDocument({uid, email, displayName, photoUrl, data})` – Firestore vrednosti imaju prednost: `email` (ako nije prazan), `name` → displayName, `cityName` pa `city`, `cityId`, `neighborhoodId`, `neighborhoodName`, `bio`, `role` (`UserRoleX.fromString`), `dog` (`UserDogProfile.fromMap(doc['dog'])`). Nema `toMap` – serijalizacija je u `userDocumentPayload`.

#### `UserRole` (enum) – isti fajl
Vrednosti: `user`, `admin`. Ekstenzija `UserRoleX`: `firestoreValue` (= `name`), `static fromString(String?)` – `'admin'` → admin, sve ostalo → user.

#### `UserDogProfile` – `lib/features/auth/domain/user_dog_profile.dart`
| Polje | Tip | Default |
|---|---|---|
| `id` | `String` | `''` |
| `name` | `String` | `''` |
| `breed` | `String` | `''` |
| `age` | `int` | `0` |
| `gender` | `String` | `''` |
| `bio` | `String` | `''` |
| `photoUrls` | `List<String>` | `const []` |
| `size` | `String` | `''` |
| `temperament` | `List<String>` | `const []` |
| `likesTags` | `List<String>` | `const []` |
| `dislikesTags` | `List<String>` | `const []` |

- Getter `hasProfile` = `id.isNotEmpty && name.isNotEmpty`.
- `toMap()` – ključevi `id, name, breed, age, gender, bio, size, temperament, likesTags, dislikesTags` + `firestorePhotoFields(photoUrls)` (`photoUrl, imageUrl, photos, photoUrls, galleryUrls`).
- `static fromMap(Object? raw)` – ako nije `Map` vraća prazan profil; `age` iz `num`; fotografije kroz `collectPhotoUrls(data)`; liste kroz `_strings` (`toString()` svakog elementa).
- Nema `copyWith`.

#### `AuthErrorCode` (enum) i `AuthException` – `lib/features/auth/domain/auth_exception.dart`
- Vrednosti: `invalidEmail, wrongPassword, userNotFound, weakPassword, emailInUse, cancelled, network, requiresRecentLogin, unknown`. (`userNotFound` se nigde ne emituje – mapira se na `wrongPassword`.)
- `AuthException(this.code, [this.message = 'Prijava nije uspela.'])`, `toString()` → `message`.

#### `AuthBusy` (enum) – `auth_controller.dart`
Vrednosti: `none, email, google`.

#### `AuthMode` (enum) – `auth_screen.dart`
Vrednosti: `signIn, signUp`.

#### `Neighborhood`, `CityLocation` – `lib/core/constants/serbia_locations.dart`
- `Neighborhood({required String id, required String name})`.
- `CityLocation({required String id, required String name, required List<Neighborhood> neighborhoods})`.
- Gradovi: `novi_sad` (24 naselja), `beograd` (56), `nis` (14), `kragujevac` (15).

#### `GeoCoord` – `lib/core/geo/geo.dart`
- `const GeoCoord(double latitude, double longitude)`; `==`/`hashCode` po obe koordinate.
- Konstante: `noviSad (45.2551, 19.8451)`, `belgrade (44.8176, 20.4569)`, `nis (43.3209, 21.8958)`, `kragujevac (44.0128, 20.9114)`.
- `static forCityName(String)` – prefiks `beograd`/`niš`/`nis`/`kragujevac`, inače Novi Sad.
- `static forCityId(String)` – `beograd|belgrade`, `nis|niš`, `kragujevac`, inače Novi Sad.

#### `UserLocation` – `lib/features/location/domain/user_location.dart`
- Polja: `coord: GeoCoord` (required), `access: LocationAccess` (required), `isFallback: bool = false`.
- Getteri `latitude`, `longitude`; `static const noviSadFallback` (Novi Sad, `unavailable`, `isFallback: true`); `copyWith`.

#### `LocationAccess` (enum) – `location_access.dart`
Vrednosti: `granted, denied, permanentlyDenied, servicesDisabled, unavailable`. Ekstenzija `canTrack` = `== granted`.

#### `HomeCity` – `lib/features/location/presentation/home_city_provider.dart`
- Polja: `id: String`, `name: String`, `coord: GeoCoord` (svi required).
- Getter `mapCityId` = `id.replaceAll('_', '-')` (komentar: odgovara id-u u map `cities` kolekciji / `SeedCities`, van slice-a).
- `==`/`hashCode` samo po `id`.

#### `AppLanguage` (enum) – `lib/core/l10n/app_language.dart`
- `serbian('sr', 'Srpski', 'Serbian')`, `english('en', 'English', 'English')`.
- Polja `code`, `labelSr`, `labelEn`; getteri `locale`, `label`; `supported = values`; `static fromCode(String?)` (default `serbian`).

#### `AppThemePreference` (enum) – `lib/core/theme/app_theme_preference.dart`
- `dark` (podrazumevano), `light`; `code` (= `name`), `themeMode`, `static fromCode(String?)` (`'light'` → light, sve ostalo → dark).

#### `StatusBadgeTone` (enum) – `app_cards.dart`
`urgent, warning, success, neutral, primary`.

#### `AppDrawerDestination` – `lib/features/home/domain/app_drawer_catalog.dart`
- Polja: `id: String` (req), `label: String` (req), `icon: IconData` (req), `body: String = ''`, `tabIndex: int? = null`, `kind: DrawerItemKind = DrawerItemKind.page`, `accent: bool = false`, `destructive: bool = false`.

#### `DrawerItemKind` (enum)
`tab, lostDogs, adopt, groups, events, moments, rules, admin, settings, page`.

#### `LegalSection` – `legal_document_bodies.dart`
`LegalSection({required String title, required String body})`.

#### `LegalDocumentKind` (enum) – `legal_document_screen.dart`
`privacy, terms`.

#### `NetworkFailure` – `lib/core/network/network_failure.dart`
`NetworkFailure([String? message])`, polje `message` (default `AppStrings.networkProblem`), `toString()` → message.

#### `localDemoUser` (konstanta) – `local_auth_repository.dart`
`AppUser(uid: 'local-user', email: 'aleksandar@vauvau.local', displayName: 'Aleksandar', city: 'Novi Sad')`.

### 6.2 Chat, grupe, događaji
#### `ChatMessageType` (enum) – `chat/domain/chat_message.dart`
Vrednosti: `text`, `walkInvite`, `locationPin`.
String ključevi (Firestore `type`): `'text'`, `'walk_invite'`, `'location_pin'`.

#### `WalkInviteStatus` (enum) – `chat/domain/chat_message.dart`
Vrednosti: `pending`, `accepted`, `declined`. Ključevi: `'pending'`, `'accepted'`, `'declined'`.

#### `ChatMessage` – `chat/domain/chat_message.dart`
Konstruktor `const ChatMessage({...})`:
| Polje | Tip | Default |
|---|---|---|
| `id` | `String` | required |
| `text` | `String` | required |
| `sentAt` | `DateTime` | required |
| `isMine` | `bool` | required |
| `senderId` | `String` | `''` |
| `receiverId` | `String` | `''` |
| `senderName` | `String` | `''` |
| `senderAvatarUrl` | `String` | `''` |
| `imageUrl` | `String` | `''` |
| `isRead` | `bool` | `false` |
| `type` | `ChatMessageType` | `ChatMessageType.text` |
| `status` | `WalkInviteStatus?` | `null` |
| `walkTime` | `DateTime?` | `null` |
| `walkLocationName` | `String?` | `null` |
| `replyToMessageId` | `String` | `''` |
| `replyToText` | `String` | `''` |
| `replyToSenderName` | `String` | `''` |
| `likes` | `List<String>` | `const []` (uid-ovi koji su lajkovali) |

Getteri / metode:
- `timestamp` → `sentAt`.
- `hasImage` → `imageUrl.trim().isNotEmpty`.
- `hasReply` → `replyToMessageId.isNotEmpty || replyToText.trim().isNotEmpty`.
- `likeCount` → `likes.length`.
- `isLikedBy(String uid)` → `uid.isNotEmpty && likes.contains(uid)`.
- `previewText` → trimovan tekst; ako je prazan a postoji slika → `'📷 Fotografija'`; inače `''`.
- `typeKey` → `'text' | 'walk_invite' | 'location_pin'`.
- `statusKey` → `'pending' | 'accepted' | 'declined' | null`.
- `isWalkInvite`, `isLocationPin`.
- `copyWith({bool? isRead, WalkInviteStatus? status, String? senderAvatarUrl, String? imageUrl, List<String>? likes})` – samo ova polja se mogu menjati.
- `static typeFromKey(String?)` – nepoznato → `text`.
- `static statusFromKey(String?)` – nepoznato → `null`.
- `static clipReplyText(String raw, [int max = 120])` – trim; ako duže od `max` → seče i dodaje `…`.
- `static likesFrom(Object?)` – ako nije `List` → `const []`; inače `'$item'` za ne-null, ne-prazne.
- Nema `fromMap/toMap` – mapiranje radi `FirestoreChatRepository._messageFromDoc` i inline mape u `send*`.

#### `ChatConversation` – `chat/domain/chat_conversation.dart`
| Polje | Tip | Default |
|---|---|---|
| `id` | `String` | required |
| `dogId` | `String` | required (peer pas) |
| `dogName` | `String` | required |
| `ownerName` | `String` | required |
| `breed` | `String` | required |
| `location` | `String` | required |
| `photoUrl` | `String` | required |
| `messages` | `List<ChatMessage>` | required |
| `lastActivityAt` | `DateTime` | required |
| `participantIds` | `List<String>` | `const []` |
| `dogIds` | `List<String>` | `const []` |
| `peerUserId` | `String` | `''` |
| `isNewMatch` | `bool` | `false` |
| `unreadCount` | `int` | `0` |
| `lastMessagePreview` | `String` | `''` (iz `lastMessage` sobe kada poruke nisu hidratisane) |

Getteri/metode:
- `title` → `'$dogName ($ownerName)'`.
- `room` → `ChatRoom(id, participantIds, dogIds: dogIds.isEmpty ? [dogId] : dogIds, lastMessage: lastSnippet, lastMessageTimestamp: lastActivityAt, unreadCount)`.
- `lastSnippet` → ako ima poruka: za walk invite vraća `last.text` (ternarni izraz na l. 55–58 vraća `last.text` u obe grane – suvišan), inače `last.previewText`; bez poruka → `lastMessagePreview`.
- `copyWith({participantIds, dogIds, peerUserId, messages, lastActivityAt, isNewMatch, unreadCount, lastMessagePreview})` – `id, dogId, dogName, ownerName, breed, location, photoUrl` se ne mogu menjati.

#### `ChatRoom` – `chat/domain/chat_room.dart`
Polja: `id: String` (req), `participantIds: List<String>` (req), `dogIds: List<String>` (req), `lastMessage: String = ''`, `lastMessageTimestamp: DateTime? = null`, `unreadCount: int = 0`. Metoda `copyWith({participantIds, dogIds, lastMessage, lastMessageTimestamp, unreadCount})`. Koristi se samo u `watchRooms()` i getteru `ChatConversation.room`; `watchRooms()` se nigde u `lib/` ne poziva.

#### `ScheduledWalk` – `chat/domain/scheduled_walk.dart`
Sva polja required: `id: String`, `conversationId: String`, `dogName: String`, `ownerName: String`, `locationName: String`, `walkTime: DateTime`. Nema metoda.

#### `ThreadActivity` – `chat/presentation/incoming_message_sound.dart`
`unreadCount: int` (req), `lastActivityAt: DateTime` (req).

#### `IncomingMessageDetector` – `chat/presentation/incoming_message_sound.dart`
Konstruktor `IncomingMessageDetector({Duration freshness = const Duration(minutes: 1)})`. Privatno: `Map<String,int> _unread`, `bool _primed`. Metoda `bool update(Map<String, ThreadActivity> threads, DateTime now)` – vraća `true` ako je (posle prvog „priming“ poziva) neki thread povećao unread i `now - lastActivityAt <= freshness`.

#### `IncomingLike` – `chat/presentation/incoming_likes.dart`
`fromUserId: String`, `profile: DiscoverProfile`, `createdAt: DateTime` (sva required).

#### `_InboxEntry` / `_InboxKind` (privatno) – `chat/presentation/chat_list_screen.dart`
`_InboxKind { direct, group, event }`. `_InboxEntry` polja: `id, title, subtitle, photoUrl: String`, `lastActivityAt: DateTime`, `unreadCount: int`, `kind: _InboxKind`, `reportTargetId: String`, `reportUserId: String = ''`. Fabrike `_InboxEntry.direct(ChatConversation)` (subtitle `'${ownerName} · ${lastSnippet}'`), `.group(GroupInboxThread)` (subtitle poslednja poruka ili opis grupe), `.event(EventInboxThread)` (subtitle poslednja poruka ili `locationName`). Getter `badge` → `ChatStrings.groupBadge` / `eventBadge` / `''`.

#### `_ChatAttachAction` (privatni enum) – `chat_detail_screen.dart:731`: `photo, scheduleWalk, sendLocation`.
#### `MessageAction` (enum) – `widgets/message_reply.dart:180`: `reply, report`.
#### `_GroupAttachAction` (privatni enum) – `group_chat_screen.dart:672`: `scheduleWalk, photo`.
#### `_EventsFilter` (privatni enum) – `events_screen.dart:13`: `all, upcoming, joined`.

#### `BreedGroup` – `groups/domain/groups_models.dart`
| Polje | Tip | Default |
|---|---|---|
| `id` | `String` | required |
| `title` | `String` | required |
| `description` | `String` | required |
| `imageUrl` | `String` | required |
| `memberIds` | `List<String>` | required |
| `memberCount` | `int` | required |
| `sortOrder` | `int` | `0` |
| `lastMessage` | `String` | `''` |
| `lastMessageAt` | `DateTime?` | `null` |
| `isApproved` | `bool` | `true` |
| `createdBy` | `String` | `''` |
| `createdAt` | `DateTime?` | `null` |

Metode:
- `displayMemberCount` → `memberCount >= memberIds.length ? memberCount : memberIds.length`.
- `isMember(String uid)` → `uid.isNotEmpty && memberIds.contains(uid)`.
- `static BreedGroup? tryFromMap(String id, Map<String,dynamic>? raw)` – čita `memberIds` (samo ne-prazni String), `memberCount` → fallback `membersCount` → fallback `memberIds.length`, `title`, `description`, `imageUrl`, `sortOrder`, `lastMessage`, `lastMessageAt`, `isApproved` (ako nije `bool` → `true`), `createdBy`, `createdAt`; na izuzetak vraća `null`.
- Privatni `_asList`, `_asInt` (int/num), `_asDateTime` (DateTime ili duck-typing `.toDate()` za Timestamp).
- `copyWith({memberIds, memberCount, lastMessage, lastMessageAt, isApproved, createdBy, title, description, imageUrl, sortOrder, createdAt})`.

#### `GroupMessageType` (enum): `text`, `walkInvite`. (Nema `locationPin` – grupe/događaji ne podržavaju location pin.)
#### `GroupWalkInviteStatus` (enum): `pending`, `accepted`, `declined`.

#### `GroupMessage` – `groups/domain/groups_models.dart` (koristi se i za poruke događaja)
| Polje | Tip | Default |
|---|---|---|
| `id` | `String` | required |
| `senderId` | `String` | required |
| `senderName` | `String` | required |
| `senderAvatarUrl` | `String` | required |
| `text` | `String` | required |
| `imageUrl` | `String` | required |
| `createdAt` | `DateTime` | required |
| `isMine` | `bool` | required |
| `replyToMessageId` | `String` | `''` |
| `replyToText` | `String` | `''` |
| `replyToSenderName` | `String` | `''` |
| `type` | `GroupMessageType` | `GroupMessageType.text` |
| `status` | `GroupWalkInviteStatus?` | `null` |
| `walkTime` | `DateTime?` | `null` |
| `walkLocationName` | `String?` | `null` |
| `acceptedByUserIds` | `List<String>` | `const []` |
| `declinedByUserIds` | `List<String>` | `const []` |
| `likes` | `List<String>` | `const []` |

Getteri/metode: `likeCount`, `isLikedBy(uid)`, `hasImage`, `isWalkInvite`, `acceptedCount` (= `acceptedByUserIds.length`), `hasReply`, `hasUserResponded(userId)` (u accepted ili declined), `preview` (walk invite → `'Poziv na šetnju'` / `'Poziv na šetnju: $place'`; tekst; `'📷 Fotografija'`; `''`), `copyWith({status, acceptedByUserIds, declinedByUserIds, likes})`. Nema `fromMap/toMap` (mapiranje je u repozitorijumima).

#### `GroupInboxThread` – `groups/domain/groups_models.dart`
Polja (sva required): `group: BreedGroup`, `lastMessage: String`, `lastActivityAt: DateTime`, `unreadCount: int`.
`static fromMessages({required BreedGroup group, required List<GroupMessage> messages, DateTime? lastRead})`:
- `cutoff = lastRead ?? DateTime.now()` → ako nema lastRead, unread je praktično 0.
- `unread` = broj poruka gde `!isMine && createdAt.isAfter(cutoff)`.
- `lastMessage` = `last?.preview ?? group.lastMessage`; `lastActivityAt` = `last?.createdAt ?? group.lastMessageAt ?? epoch 0`.

#### `EventModel` – `events/domain/event_model.dart`
| Polje | Tip | Default |
|---|---|---|
| `id` | `String` | required |
| `title` | `String` | required |
| `locationName` | `String` | required |
| `dateTime` | `DateTime` | required |
| `description` | `String` | required |
| `imageUrl` | `String` | required |
| `organizerUserId` | `String` | required |
| `organizerName` | `String` | required |
| `participantUserIds` | `List<String>` | required |
| `createdAt` | `DateTime` | required |
| `lastMessage` | `String` | `''` |
| `lastMessageAt` | `DateTime?` | `null` |
| `cityId` | `String` | `''` (id iz `SerbiaLocations`: `novi_sad`, `beograd`, `nis`, `kragujevac`; prazno za stare događaje) |

Metode: `participantCount`, `isJoined(uid)`, `static const listGrace = Duration(hours: 6)`, `isListed([DateTime? now])` → `dateTime + 6h > now`, `copyWith({title, locationName, dateTime, description, imageUrl, participantUserIds, lastMessage, lastMessageAt, cityId})` (organizer i createdAt nepromenljivi). Nema `fromMap/toMap` u modelu.

#### `EventInboxThread` – `events/domain/event_model.dart`
`event: EventModel`, `lastMessage: String`, `lastActivityAt: DateTime`, `unreadCount: int` (sva required). Pravi se u `_threadFor` (events_controller.dart:252) tako što se događaj pretvori u privremeni `BreedGroup` i pozove `GroupInboxThread.fromMessages`.

#### `EventVenues` (abstract final) – `events/data/seed_events.dart`
- `customOption = 'Ostalo / Ručni unos'`.
- `names` – `['Limanski park', 'Kamenički park', 'Dunavski park', 'Petrovaradinska tvrđava', 'Železnički park', 'Šandora Petefija (Telep)', customOption]`.
- `coordinates` – `Map<String, LatLng>` za gornjih 6 + `'Kej Žrtava Racije'`.
- `isCustom(value)`, `latLngFor(name)`.
- `forCity(String cityId, Iterable<MapPlace> places)` – za `novi_sad` vraća legacy imena + mesta sa mape tipa `park`/`other` za taj grad (cityId sa `_` ili `-`), sortirano, uvek se završava `customOption`.
- `cityIdForEvent(EventModel)` – eksplicitni `cityId`, ili `novi_sad` ako je venue u `coordinates`, ili `SerbiaLocations.cityIdForLabel(locationName)`.

#### `SeedEvents` (abstract final) – `events/data/seed_events.dart`
- `_dummies` = `'seed-1'..'seed-11'`.
- `static final all` – 3 događaja (`event-liman`, `event-malenici`, `event-tvrdjava`), organizator `'vauvau'`/`'VauVau'`, datumi relativni na `DateTime.now()` u trenutku prvog pristupa (+1d5h, +3d2h, +7d3h), `participantUserIds` = 11 / 8 / 5 dummy id-jeva, `cityId: novi_sad`, `imageUrl: ''`.
- `firestoreData(EventModel)` → mapa sa `title, locationName, dateTime (ISO string), description, imageUrl, organizerUserId, organizerName, participantUserIds, createdAt (ISO string), lastMessage, cityId`.

#### `SeedBreedGroups` (abstract final) – `groups/data/seed_breed_groups.dart`
- `defaultDescription = 'Šetnje, dogovori za playdate i saveti za negu'`, `parkDescription = 'Lokalna park grupa — dogovorite šetnje, susrete i igru u parku.'`, `removedSmallDogsId = 'vlasnici-malih-pasa-novi-sad'`.
- `all` – 9 grupa: `aktivne-setnje-playdate` (45), `kej-zezeljev-most` (42), `labradori-novi-sad` (41), `limanski-park` (38), `pomeranci-novi-sad` (34), `petrovaradinska-tvrdjava` (31), `futoski-park` (29), `francuski-buldozi-novi-sad` (28), `kamenicki-park` (22) – broj u zagradi je hardkodovan `memberCount`, `memberIds: []`, `imageUrl: ''`, `sortOrder` 1–9.
- `firestoreData(BreedGroup)` → `title, description, imageUrl, memberIds, memberCount, sortOrder, lastMessage, isApproved, createdBy`.
- `sortByPopularity(Iterable<BreedGroup>)` – opadajuće po `displayMemberCount`, pa po `title`.

#### `EventsJoinCopy` (abstract final) – `events/data/local_events_repository.dart:288`
`joined(String name)` → `'$name se pridružio/la šetnji! 🐾'` (nije lokalizovano preko `L10n`).

#### String klase
`ChatStrings`, `GroupsStrings`, `EventsStrings` – svi getteri koriste `L10n.tr(sr, en)`. Pored toga `EventsStrings` ima `weekdays`, `dateOnly`, `timeOnly`, `when`, `cardMeta`, `interested`, `timeAgo`; `ChatStrings` ima `peerSubtitle(...)` i `walkAcceptedCount(int)`; `GroupsStrings` ima `createErrorBody`, `memberCount(int)`.

### 6.3 Discover, psi (zdravlje, podsetnici), profil i podešavanja
#### `DiscoverProfile` – `discover/domain/discover_profile.dart`
Konstruktor `const DiscoverProfile({...})`. Polja:

| Polje | Tip | Default |
|---|---|---|
| id | `String` | required |
| name | `String` | required |
| ownerName | `String` | required |
| breed | `String` | required |
| ageYears | `int` | required |
| gender | `String` | required (normalizovano `mužjak`/`ženka`/`''`) |
| size | `String` | required (`mali`/`srednji`/`veliki`) |
| location | `String` | required (format „Grad - Naselje” ili „Grad · Naselje”) |
| bio | `String` | required |
| photoUrls | `List<String>` | required |
| energyLevel | `String` | `'umerena'` |
| vaccinated | `bool` | **`true`** |
| chipped | `bool` | **`true`** |
| sterilized | `bool` | `false` |
| ageMonths | `int` | `0` |
| traits | `List<String>` | `const []` |
| distanceKm | `double` | `0` |
| weightKg | `double` | `0` |
| walking | `bool` | `false` |
| activityStatus | `String` | `''` |
| ownerId | `String` | `''` |
| latitude / longitude | `double?` | `null` |
| goodWithDogs / goodWithCats / goodWithKids | `bool` | `false` |
| likesTags / dislikesTags | `List<String>` | `const []` |
| createdAt | `DateTime?` | `null` |

Statičke metode: `compareFeedOrder(a, b)` (najnoviji `createdAt` prvi, zatim manja `distanceKm`), `decorateWalkStatus(raw)` (sadrži „šetnj/walk” → walkingBadge; „tražim/looking/play” → lookingForPlay; „odmar/rest” → resting; inače raw), `localizeTrait(raw)` (mapira ~30 SR/EN varijanti na lokalizovane labele, inače vraća raw), privatne `_count` (srpska množina) i `_countEn`.

Getteri: `imageUrl`/`photoUrl` (prva slika ili `''`), `photos`, `headline` (`"$name, $ageLabel"`), `subtitle` (`"$breed • $cityName"`), `conversationTitle`, `cityName`/`neighborhoodName` (split po `' · '`, inače po `' - '` – **ne po `', '`**, vidi tehnički dug), `distanceLabel` (naselje, inače grad – ne prikazuje km), `statusBadge` (activityStatus → `decorateWalkStatus`, inače walking ? „🟢 U šetnji” : „Odmaram”), `ageLabel` (ako `ageYears<=0 && ageMonths>0` → meseci; inače godine, gde se `ageYears<=0` prikazuje kao **1 godina**), `genderLabel`, `sizeLabel` (prazno → „Srednji”), `energyLabel`, `traitLabels`, `getsAlongLabels`, `likeLabels`, `dislikeLabels`, `coord` (`GeoCoord?`). `copyWith` za sva polja (bez mogućnosti brisanja nullable polja).

#### `DiscoverPage` – `discover/domain/discover_repository.dart`
`items: List<DiscoverProfile>` (required), `nextCursor: Object?` (Firestore `DocumentSnapshot` ili `int` u local impl), `hasMore: bool = false`.

#### `SuperLikeDailyLimitException` – isti fajl
`const` konstruktor, `toString()` → `'SuperLikeDailyLimitException'`.

#### `CompatibilityInsight` – `discover/domain/compatibility.dart`
`headline: String`, `sharedLikes: List<String>`, `similarEnergy: bool`. Fabrika `describeCompatibility({mine, other})`: `shared` = tagovi iz `mine.likesTags` koji su u `other.likesTags` i nisu u `other.dislikesTags`; `similarEnergy` = `mine.energyLabel == other.energyLabel`. Headline ima 4 varijante (energija+voli, samo voli, samo energija, generička „mogu da se dopune”). `_likePhrase` prevodi 6 poznatih „voli” tagova, ostale lowercase. **Ne postoji numerički skor kompatibilnosti.**

#### `GeoQuery` – `discover/domain/geo_query.dart`
`origin: GeoCoord`, `radiusKm: double`. `locate(profile)` → upisuje `distanceKm = haversineKm(origin, coord)` (ako nema koordinata, profil ostaje nepromenjen, `distanceKm` ostaje 0 → prolazi radius). `withinRadius`, `apply(list)`.

#### `DiscoverCategory` (enum) – `discover/presentation/discover_controller.dart`
`all, walking, small, medium, large`.

#### `DiscoverState` – isti fajl
`catalog: List<DiscoverProfile>` (req), `myDog: DiscoverProfile` (req), `query: String = ''`, `category: DiscoverCategory = all`. Getter `visible`: filter po kategoriji (`walking` → `profile.walking`; veličine po `'mali'/'srednji'/'veliki'`) i po tekstu (ime, rasa, lokacija, vlasnik – case-insensitive `contains`). `isEmpty`, `copyWith`.

#### `DiscoverArea` – isti fajl
`origin: GeoCoord`, `radiusKm: double`, `cityId: String?`; `static const cityReachKm = 30`. `geo` → `GeoQuery`. `allows(profile)`: ako `cityId == null` → true; inače `SerbiaLocations.cityIdForLabel(profile.location)` mora biti `null` ili jednak. Prepisani `==`/`hashCode`.

#### `Dog` – `dogs/domain/dog.dart`
`id, ownerId, name, breed: String` (req), `gender: DogGender`, `ageYears: int`, `size: DogSize`, `energyLevel: DogEnergyLevel`, `temperament: List<DogTemperament>`, `area: DogArea`, `photoUrls: List<String>` (sve req), `weightKg: double?`, `ageMonths: int = 0`, `bio: String = ''`, `vaccinated/chipped/sterilized: bool = false`, `likesTags/dislikesTags: List<String> = []`. Getteri: `location` = `SerbiaLocations.formatPlace(cityName, neighborhoodName)` (format „Grad, Naselje”), `photoUrl`. `copyWith` (sa `clearWeight`; `id`/`ownerId` se ne menjaju).

#### Enumi – `dogs/domain/dog_enums.dart`
- `DogGender { female, male, unknown }`
- `DogSize { small, medium, large, xlarge }` (`xlarge` se ne nudi u UI; mapira se na „Veliki”)
- `DogEnergyLevel { low, moderate, high }`
- `DogTemperament { friendly, playful, calm, shy, protective }`
Svi imaju `firestoreValue => name`.

#### `DogArea` – `dogs/domain/dog_area.dart`
`cityId, cityName, neighborhoodId, neighborhoodName: String` (sve req). `toMap()` → `Map<String,String>`; `factory DogArea.fromMap(map)` (nedostajuće → `''`).

#### `DogDraft` – `dogs/domain/dog_draft.dart`
`name=''`, `breed=''`, `gender: DogGender?`, `ageYears: int?`, `size: DogSize?`, `weightKg: double?`, `energyLevel: DogEnergyLevel?`, `temperament=[]`, `cityId: String? = SerbiaLocations.noviSadId`, `neighborhoodId: String?`, `customNeighborhoodName=''`, `photos: List<String>=[]`, `vaccinated/chipped/sterilized=false`, `bio=''`, `likesTags/dislikesTags=[]`. `copyWith` sa `clearWeight` i `clearNeighborhood`. Napomena: `energyLevel` se nigde u onboarding UI ne postavlja → uvek `moderate` pri kreiranju.

#### `DogPreferenceTags` – `dogs/domain/dog_preference_tags.dart`
`likes = ['Šetnje','Trčanje','Igru','Male pse','Velike pse','Mirne pse']`, `dislikes = ['Gužvu','Mačke','Velike pse','Decu','Buku']`. `sanitize(raw, allowed)` (nigde u slice-u se ne poziva), `localize(raw)`.

#### `DogsException` – `dogs/domain/dogs_exception.dart`
`DogsException([String? message])`, `message` default `AppStrings.dogSaveFailed`, `toString() => message`.

#### `HealthCategory` + `HealthCategoryX` – `dogs/domain/health_record.dart`
Vrednosti: `vaccineRabies, vaccineCore, deworming, tickProtection`. `firestoreValue => name`, `static fromString(String?) → HealthCategory?`.

#### `HealthRecord` – isti fajl
`id: String`, `dogId: String`, `category: HealthCategory`, `title: String`, `administeredDate: DateTime` (sve req), `nextDueDate: DateTime?`, `notes: String?`, `notificationId: int?`. `static const expiringSoonDays = 30`. `statusAt(now)`: nema roka → `unknown`; rok pre danas → `expired`; ≤30 dana → `expiringSoon`; inače `valid`. `copyWith` (sa `clearNextDueDate`, `clearNotificationId`; `dogId` i `category` nepromenljivi). `static notificationIdFor(recordId) = recordId.hashCode & 0x7fffffff`.

#### `HealthStatus` (enum) – `valid, expiringSoon, expired, unknown`.

#### Podsetnici – `dogs/domain/dog_reminder.dart`
- `ReminderCategory { health, care, food, other }`
- `ReminderType { vaccineRabies, vaccineOther, infectiousProtection, internalParasites, ticksFleas, vetCheckup, therapyMeds, dentalCheck, weightCheck, grooming, bathing, nailTrim, teethBrushing, foodShopping, foodChange, supplements, birthday, documentation, custom }` – `ReminderTypeX.category`: prvih 9 → health; grooming/bathing/nailTrim/teethBrushing → care; foodShopping/foodChange/supplements → food; birthday/documentation/custom → other. `fromString`.
- `ReminderRepeat { once, daily, weekly, monthly, every3Months, every6Months, yearly, custom }` (+ `fromString`)
- `CustomRepeatUnit { days, weeks, months }` (+ `fromString`)
- `ReminderOffset { onDay, oneDayBefore, threeDaysBefore, sevenDaysBefore }` – `daysBefore` = 0/1/3/7 (+ `fromString`)
- `ReminderUrgency { upcoming, today, tomorrow, soon, overdue }`

`DogReminder`: `id, dogId, title: String`, `type: ReminderType`, `date: DateTime` (req), `repeatType = ReminderRepeat.once`, `reminderOffset = ReminderOffset.threeDaysBefore`, `note: String?`, `isCompleted = false`, `notificationId: int?`, `repeatDayOfMonth: int?`, `customIntervalCount = 2`, `customIntervalUnit = CustomRepeatUnit.weeks`, `lastCompletedDate: DateTime?`, `createdAt: DateTime?`, `updatedAt: DateTime?`. Konstante: `defaultCustomIntervalCount = 2`, `defaultCustomIntervalUnit = weeks`, `defaultCustomIntervalDays = 14` (legacy, ne koristi se u slice-u). Getteri: `category`, `notifyDate` (= dan `date` minus offset), `urgencyAt(now)` (<0 overdue, 0 today, 1 tomorrow, ≤14 soon, inače upcoming), `isActive = !isCompleted`. `copyWith` (sa `clearNote`, `clearNotificationId`, `clearLastCompletedDate`). `static notificationIdFor(id) = 'reminder_$id'.hashCode & 0x7fffffff`.

#### `ReminderSchedule` + `DogReminderScheduleX` – `dogs/domain/reminder_schedule.dart`
- `isRepeating(repeat, {customIntervalCount})` – `once` false; `custom` ako count>0; ostali true.
- `nextOccurrence(from, repeat, {dayOfMonth, count, unit})` – kalendarska aritmetika (daily +1 dan, weekly +7, monthly/3/6 meseci preko `addMonths`, yearly `addYears`, custom preko `addCustomInterval`).
- `addCustomInterval`, `addMonths` (čuva „31.” semantiku – klampuje na broj dana u mesecu), `addYears`.
- `advanceToUpcoming(...)` – ponavlja `nextOccurrence` dok nije ≥ danas (guard 10000) – **u slice-u se ne poziva**.
- Ekstenzija: `effectiveRepeatDayOfMonth` (`repeatDayOfMonth ?? date.day`), `effectiveCustomIntervalCount`, `rolledForward(now)` – za aktivne ponavljajuće podsetnike čiji je datum prošao pomera `date` na prvi budući termin i upisuje `lastCompletedDate` = poslednji prošli termin.

#### `DogOnboardingState` – `dogs/presentation/onboarding/dog_onboarding_controller.dart`
`step: int = 0`, `draft: DogDraft = DogDraft()`, `submit: AsyncValue<void> = AsyncData(null)`, `uploadingPhotos: bool = false`; getter `isSubmitting`; `copyWith`.

#### `HealthSaveResult` (`recordId: String`, `reminderSet: bool`), `ReminderSaveResult` (`reminderId`, `reminderSet`), `ReminderDogRef` (`id`, `name` – **nigde se ne koristi**), `typedef ReminderDogOption = ({String id, String name})` (`add_reminder_sheet.dart`).

#### `AppSettings` – `profile/domain/app_settings.dart`
`notifyWalkRequests = true`, `notifyMessages = true`, `notifyNewMatches = true`, `radiusKm: double = 20`, `showLocationOnMap = true`, `pushPrompted = false`, `language: AppLanguage = AppLanguage.serbian`, `themePreference: AppThemePreference = AppThemePreference.dark`. `copyWith`.

#### `UserProfile` – `profile/domain/user_profile.dart`
`ownerName, ownerBio: String`, `dogs: List<DiscoverProfile>`, `selectedDogId: String` (req), `ownerEmail=''`, `ownerLocation=''`, `ownerCityId=''`, `ownerNeighborhoodId=''`, `ownerNeighborhoodName=''`. Getter `dog`: **ako je lista prazna vraća `mockMyDog`**, inače pas sa `selectedDogId` ili prvi. `personalityTags => dog.traits`. `copyWith`. Top-level `final mockUserProfile` (Aleksandar, `aleksandar@vauvau.local`, Novi Sad · Liman 3, psi `[mockMyDog, mockSecondDog]`).

#### `MatchingFilters` + enumi – `profile/domain/matching_filters.dart`
- `FilterGender { any, male, female }`, `FilterCity { any, noviSad, beograd, nis, kragujevac }`, `FilterEnergy { any, low, medium, high }`.
- Polja: `sizes: Set<String> = {'mali','srednji','veliki'}`, `gender = any`, `city = any`, `radiusKm: double = 20`, `energy = any`, `minAge: double = 0`, `maxAge: double = 15`, `vaccinatedOnly = false`, `sterilizedOnly = false`. `copyWith`.
- `apply(list)`, `matches(profile)`: veličina u skupu (prazan skup = sve), pol (`'mužjak'`/`'ženka'`), grad (`SerbiaLocations.cityIdForLabel(location) == cityId`), radius **samo kad je `city == any`** (`distanceKm > radiusKm` → izbaci), `ageYears` u [minAge, maxAge], vakcinisan/sterilisan, energija (`niska`→low, `visoka`→high, ostalo→medium).
- Getter `cityId`: any→null, noviSad→`SerbiaLocations.noviSadId`, beograd→**literal `'beograd'`**, nis→`nisId`, kragujevac→`kragujevacId`.

#### Mock podaci – `discover/data/mock_discover_profiles.dart`
`mockMyDog` (id `my-dog`, Luna, Zlatni retriver, 3 god., ženka, veliki, Novi Sad - Liman, visoka energija, vakc./čip./steril., osobine `['Energičan','Druželjubiv','Voli loptice']`, likes `['Šetnje','Igru','Velike pse']`, dislikes `['Gužvu']`, 0.4 km, 27 kg, „Tražim društvo za igru”), `mockSecondDog` (id `maks`, Maks, Mešanac, 2 god. 4 mes., mužjak, srednji…), `mockDiscoverProfiles` – 6 pasa: `bobi`, `lola`, `rex` (Reks), `maza`, `djole` (Đole, Beograd - Novi Beograd), `kiki`. Svi `photoUrls: []`, bez `ownerId`, bez `createdAt`/koordinata; većina se oslanja na default `vaccinated=true`, `chipped=true`.

`localDemoDog({ownerId = 'local-user'})` – `dogs/data/local_dogs_repository.dart`: id `local-luna`, Luna, Zlatni retriver, ženka, 3 god., large, high, `[friendly, playful]`, Novi Sad / Liman 1.

#### Mapper funkcije – `discover/data/dog_profile_mapper.dart`
- `discoverProfileFromMap(id, data)` – čita (sa fallbackom na legacy ključeve): `ownerId`, `name`, `ownerName` (default **`'Vlasnik'`**), `breed`, `ageYears`→`age`, `ageMonths`, `gender` (normalizovan), `size` (normalizovan; nepoznato → `srednji`), `location` ili `"${area.cityName} - ${area.neighborhoodName}"`, `bio`, slike preko `collectPhotoUrls` (`photoUrl`, `imageUrl`, `image`, `photos`, `galleryUrls`, `photoUrls`), `energyLevel`, `isVaccinated`→`vaccinated`, `isMicrochipped`→`chipped`, `isSterilized`→`sterilized` (default false), `temperament`→`traits`, `weightKg`, `isWalking`, `walkStatus`→`activityStatus`, koordinate iz `lastKnownLocation` (GeoPoint) ili `latitude/longitude`, **inače centar grada preko `GeoCoord.forCityName(location)`**, `goodWithDogs`→`friendlyWithDogs` (isto za mačke/decu), `likesTags`, `dislikesTags`, `createdAt` (Timestamp/DateTime/String).
- `normalizeDogGender` / `normalizeDogSize` (javni omotači).
- `_gender`: male/mužjak/muzjak→`mužjak`; female/ženka/zenka→`ženka`; inače `''`. `_size`: small/mali→`mali`; medium/srednji→`srednji`; xlarge/gigantski/large/veliki→`veliki`; default `srednji`. `_energy`: low/niska→`niska`, high/visoka→`visoka`, default `umerena`.
- `discoverProfileFromDog(dog, {ownerName})` – ako `ownerName` prazan, upisuje **`dog.ownerId`** kao ime vlasnika; ne prenosi `createdAt`, koordinate, `walking`.
- `discoverProfileFromUserDog(user)` – iz legacy `user.dog`; id fallback `'user-dog'`; **ne postavlja `vaccinated/chipped` → ostaju default `true`**.
- `dogFromDiscover(profile, {ownerId, area})` → `Dog` (weight 0 → null, enum mapiranja).
- `temperamentFromStored(raw)` → lista `DogTemperament` bez duplikata (poredi `firestoreValue` i lokalizovane labele).
- `userDogFromDiscover(profile)` → `UserDogProfile` (auth domen).

### 6.4 Mapa, mesta i alati (tool/)
#### `PoiCategory` (enum) – `domain/models/poi_model.dart:4`
Vrednosti: `cafe, restaurant, park, petShop, groomer, vet, lodging, training, dogHotel, selfWash, dogTreats, shelter, water, petSitter, other`.

#### `PoiVerificationStatus` (enum) – `poi_model.dart:22`
Vrednosti: `verified, userSubmitted, pending, reported, unknown, rejected`.

Ekstenzija `PoiVerificationStatusX`:
- `bool get isAwaitingReview` – `true` za `pending` ili `userSubmitted`.
- `String get firestoreValue` – `name` enuma.
- `static PoiVerificationStatus fromString(String?)` – mapira string; sve nepoznato (uključujući `null`) → `unknown`.

#### `PoiModel` – `poi_model.dart:50`
`const` konstruktor. Polja (tip, podrazumevana vrednost):

| Polje | Tip | Default |
|---|---|---|
| `id` | `String` | required |
| `name` | `String` | required |
| `category` | `PoiCategory` | required |
| `address` | `String` | required |
| `latitude` / `longitude` | `double` | required |
| `phone` | `String` | `''` |
| `website` | `String?` | `null` |
| `is24_7` | `bool` | `false` |
| `isEmergencyService` | `bool` | `false` |
| `overnightStay` | `bool` | `false` |
| `dayCare` | `bool` | `false` |
| `hasYard` | `bool` | `false` |
| `pricePerNight` | `double?` | `null` |
| `openingHours` | `String` (slobodan tekst, npr. „Pon–Pet 09–20“) | `''` |
| `petFriendly` | `bool` | `true` |
| `dogFriendlyIndoor` / `dogFriendlyOutdoor` / `waterAvailable` | `bool?` | `null` |
| `isDogPark` | `bool?` (null = nije postavljeno; legacy pravilo po imenu) | `null` |
| `municipality` | `String` | `''` |
| `description` | `String` | `''` |
| `imageUrl` | `String?` | `null` |
| `sourceUrl` | `String` | `''` |
| `city` | `MapCity` | `MapCity.noviSad` |
| `cityId` | `String` | `''` |
| `verificationStatus` | `PoiVerificationStatus` | `unknown` |
| `lastVerified` | `DateTime` | required |
| `source` | `String` | required |
| `rating` | `double?` | `null` |
| `isSponsored` | `bool` | `false` |
| `sponsorName` | `String` | `''` |
| `sponsoredUntil` | `DateTime?` | `null` |
| `sponsorBadge` | `String` | `''` |
| `sponsorPriority` | `int` | `0` |

Getteri / metode:
- `MapPlaceType get mapPlaceType` – 1:1 mapiranje `PoiCategory` → `MapPlaceType`.
- `String get resolvedCityId` – `cityId` ako nije prazan, inače `city.cityId` (kanonski, npr. `novi-sad`).
- `copyWith({...})` – sva polja osim `id`; dodatni flagovi `clearWebsite` i `clearPricePerNight` za postavljanje na `null`. Napomena: `imageUrl` i `sponsoredUntil` se ne mogu obrisati na `null` kroz `copyWith`.
- Nema `fromJson/toMap` u modelu – mapiranje je u `FirestorePoiRepository._fromDoc/_toMap` i `FirestorePlacesRepository`.

#### `MapPlace` – `domain/map_place.dart:7`
Prikazni model mesta. `const` konstruktor sa istim poljima kao `PoiModel` osim: `category` → `type: MapPlaceType`, `address` → `neighborhood: String` (getter `address` vraća `neighborhood`), plus:
- `nearbyDogs: int` (default `0`) – koristi se samo u `catalogServicePlaces` (hardkodovano 1).
- `lastVerified: DateTime?` (nullable, za razliku od `PoiModel`).
- `source: String` default `''`; `cityId` default `''`; `city` default `MapCity.noviSad`; `verificationStatus` default `unknown`.

Metode:
- `factory MapPlace.fromPoi(PoiModel)` – kopira sva polja; `cityId = poi.resolvedCityId`.
- `bool get isOfficialDogPark` – samo za `type == park`; ako je `isDogPark` postavljen vraća njega, inače `true` ako ime sadrži „park za pse“, „pet park“ ili „poligon za pse“.
- `bool get hasValidCoordinates` – `false` za NaN, (0,0) i van opsega.
- `Color get pinColor` – crvena `0xFFDC2626` ako je `isEmergencyService`, inače `type.pinColor`.
- `bool get isHotel` – `dogHotel` ili `lodging` (nigde se ne koristi).
- `copyWith({verificationStatus, petFriendly, lastVerified})` – samo ta tri polja.

#### `MapPlaceType` (enum) – `domain/map_place_type.dart:7`
Vrednosti: `park, cafe, restaurant, petShop, groomer, vet, lodging, training, dogHotel, selfWash, dogTreats, shelter, water, petSitter, other`. Ekstenzija `MapPlaceTypeVisuals`: `icon` (Material ikone), `pinColor` (hardkodovane boje), `filterLabel` (npr. „Parkovi“, „Pansion“, „Čuvanje“).

#### `MapCity` / `MapCityFocus` – `domain/map_city.dart`
- `MapCity { noviSad, belgrade, nis, kragujevac, other }`.
- `MapCityFocus { noviSad, belgrade, nis, kragujevac, myLocation }` – **nigde se ne koristi**.
- `MapCityX`: `label` (npr. „Niš“, „Drugo“), `cityId` (`novi-sad`, `beograd`, `nis`, `kragujevac`, `''` za other), `camera` (`LatLng?`), `static fromCityId(String)` – trim + lowercase; prihvata `beograd|belgrade`, `novi-sad|novi_sad|novisad`, `nis|niš`, `kragujevac`, sve ostalo → `other`.
- `MapCityCameras`: Novi Sad `45.2671, 19.8335`, Beograd `44.8125, 20.4612`, Niš `43.3209, 21.8958`, Kragujevac `44.0128, 20.9114`, `cityZoom = 13.0`.

#### `CityModel` – `domain/city_model.dart:4`
Polja: `id: String`, `name: String`, `latitude/longitude: double` (required), `radiusKm: double = 15`, `sortOrder: int = 0`, `isActive: bool = true`. Getter `LatLng get center`. `copyWith` (sve osim `id`).

`SeedCities` (abstract final): `noviSad` (`novi-sad`, r=15, sort 1), `belgrade` (`beograd`, r=35 – „Beograd + neposredna okolina“, sort 2), `nis` (`nis`, r=15, sort 3), `kragujevac` (`kragujevac`, r=15, sort 4); `all`; `byId(id, [available])` – prvo traži u Firestore listi pa u seed listi; `mergeWith(remote)` – ako je remote prazan vraća seed, inače remote + seed gradovi koje remote ne definiše, sortirano po `sortOrder`.

#### `WalkSession` – `domain/walk_session.dart:3`
Polja: `isActive: bool` (req), `now: DateTime` (req), `startedAt: DateTime?`, `planned: Duration = 30 min`, `statusMessage: String?`, `isPaused: bool = false`, `pausedAt: DateTime?`, `pausedTotal: Duration = zero`, `path: List<GeoCoord> = []`, `distanceKm: double = 0`.
Getteri: `elapsed` (now − startedAt − pauze, nikad negativno), `elapsedLabel` (`mm:ss` ili `hh:mm:ss`), `speedKmh`, `paceMinPerKm` (0 ako < 10 m), `caloriesEstimate` (`distanceKm * 55`), `remainingMinutes` (planned − elapsed). `copyWith` sa `clearStatus` i `clearPausedAt`. **`speedKmh`, `paceMinPerKm`, `caloriesEstimate`, `remainingMinutes` i `planned` se nigde ne koriste u UI.**

#### `WalkRecord` – `domain/walk_record.dart:1`
Polja: `id, userId, dogId: String`, `distanceKm: double`, `durationSeconds: int`, `startedAt, endedAt: DateTime` (sva required), `statusMessage: String = ''`. Getteri: `duration` (nekorišćen), `durationLabel` (`Xh MMm` / `Xm SSs` / `Xs`), `distanceLabel` (`0.00 km`). Putanja (path) šetnje se **ne čuva**.

#### `WalkingDogPin` – `domain/walking_dog_pin.dart`
`profile: DiscoverProfile`, `latitude/longitude: double`, `status: String` (sve required).

#### `WalkingPresence` – `domain/walk_presence_repository.dart:22`
`profile: DiscoverProfile`, `coord: GeoCoord`, `status: String`.

#### `PlaceDraft` – `data/places_repository.dart:11`
`name, category (string ključ, npr. 'pet_shop'), cityId, cityName, address: String`, `latitude/longitude: double`, `openingHours = ''`, `phone = ''`, `createdBy: String`.

#### `GeocodeSuggestion` – `data/address_geocoder.dart:5`
`label: String`, `latitude/longitude: double`.

#### `MapRegionSelection` – `presentation/cities_controller.dart:13`
Konstruktori `.myLocation()` i `.city(CityModel)`. Polja `city: CityModel?`, `isMyLocation: bool`. Getteri: `label` („Moja lokacija“ / ime grada / „Grad“ – hardkodovano, ne kroz L10n), `cityId`, `radiusKm` (25 za moju lokaciju, inače `city.radiusKm` ili 15), `zoom` (14.5 / 13.0). Nema `==` override – poređenje `previous == next` u `MapScreen` je po referenci.

#### `MapLayerFilter` (enum) – `presentation/map_strings.dart:4`
Vrednosti: `all, nearby, parks, petShops, groomers, vets, emergency, cafes, restaurants, lodging, training, hotels, selfWash, dogTreats, shelter, water, sitters, walkers`. Ekstenzija `MapLayerFilterX`: `label`, `placeType` (null za `all`, `nearby`, `emergency`, `walkers`; `hotels` → `dogHotel`), `showsPlaces`/`showsWalkers` (nekorišćeni), `isExtraPlaceFilter`, `primary = [all, cafes, parks, walkers]`, `extra` = ostalih 12.

#### `HotelAmenityFilter` (enum) – `map_strings.dart:25`
`overnight, dayCare, yard, allDay`, sa `label`.

### 6.5 Priče, izgubljeni psi, udomljavanje, moderacija, notifikacije, podrška, admin
#### Moments
**`MomentModel`** (`moments/domain/moment_model.dart`) – const konstruktor, sva polja required:
| polje | tip |
|---|---|
| id, authorUserId, authorName, dogId, dogName, dogBreed, dogPhotoUrl, momentPhotoUrl, caption, locationName | String |
| likes | List<String> |
| commentsCount | int |
| createdAt | DateTime |

- `static const Duration storyLifetime = Duration(hours: 24)`
- `likeCount` = `likes.length`; `isActiveStory(now)` = `now.difference(createdAt) < storyLifetime`; `isLikedBy(uid)` = `uid.isNotEmpty && likes.contains(uid)`.
- `copyWith({likes, commentsCount})` – samo ta dva polja. Nema `fromJson/toMap` (mapiranje je u repozitorijumu).

**`MomentComment`**: `id`, `authorUserId`, `authorName`, `text` (String), `createdAt` (DateTime) – required; `likes` List<String> = `const []`. `likeCount`, `isLikedBy`, `copyWith({likes})`.

**`StoryHighlight`** (`story_highlight.dart`): `id`, `ownerId`, `dogId`, `title` (String), `momentIds` (List<String>), `createdAt` (DateTime) – required; `coverMomentId` = `''`, `order` = `0`. `static const maxTitleLength = 20`. `copyWith({title, momentIds, coverMomentId, order})`. Komentar u kodu: highlight referencira samo ID-eve momenata, pa priča ostaje vidljiva i posle 24h.

**`MomentsPage`**: `items` List<MomentModel> (required), `nextCursor` Object? (null), `hasMore` bool = false.

**`StoryGroup`** (`stories_controller.dart`): `dogId`, `dogName`, `dogPhotoUrl`, `authorUserId` (String), `moments` List<MomentModel> (required), `title` String? (postavljen kada je grupa istaknuto). `StoryGroup.fromMoments(moments, {title})` uzima podatke iz prvog momenta. `latest` = `moments.last.createdAt`; `coverUrl` = `moments.last.momentPhotoUrl`.

**`SeenStories`** (Notifier<Set<String>>) – `markSeen(momentId)`; stanje samo u memoriji sesije (nije perzistentno).

#### Lost dogs
**`LostDog`** (`lost_dogs/domain/lost_dog.dart`): required `id`, `dogName`, `city`, `neighborhood` (String), `lostDate` (DateTime), `description`, `imageUrl`, `contactPhone`, `uploaderUserId`, `status` (String), `createdAt` (DateTime); opciono `type` = `LostDogType.lost`, `breed` = `''`, `foundDate` DateTime? = null.
- Getteri: `isLostListing` (type != found), `isFoundListing` (type == found), `isActive` (status `'active'` ili `'missing'`), `isMissing` (isLostListing && isActive), `eventDate` (za found: `foundDate ?? lostDate`, inače `lostDate`), `placeLabel` (`'$city – $neighborhood'`, ili jedno ako je drugo prazno).
- `copyWith` svih polja (`foundDate` se kroz copyWith ne može vratiti na null).

**`LostDogType`** (abstract final, String konstante): `lost = 'lost'`, `found = 'found'`.
**`LostDogStatus`**: `active = 'active'`, `resolved = 'resolved'`, `legacyMissing = 'missing'`, `legacyFound = 'found'`.
**`LostDogComment`**: `id`, `authorUserId`, `authorName`, `text`, `createdAt` (required); `likes` = `const []`; `likeCount`, `isLikedBy`, `copyWith({likes})`.
**`LostDogMatchCopy`** (`lost_dog_strings.dart`): `name`, `breed`, `neighborhood` (String).

#### Adoption
**`AdoptionDog`** (`adoption/domain/adoption_dog.dart`): required `id`, `name`, `breed`, `age` (String, slobodan tekst npr. "6 meseci"), `gender` (String `'mužjak'`|`'ženka'`), `size` (String `'mali'`|`'srednji'`|`'veliki'`), `location`, `description` (String), `imageUrls` (List<String>), `contactPhone`, `uploaderUserId`, `uploaderName` (String), `isVaccinated`, `isSterilized` (bool), `createdAt` (DateTime); `status` String = `'available'`.
- `isAdopted` (status == `'adopted'`), `photoUrl` (prvi iz `imageUrls` ili `''`), `copyWith` svih polja. Nema `fromJson`.
- Model nema polja `city`/`neighborhood` iako se ona upisuju u Firestore.

**`PhoneLauncher`**: `call(phone)` → uzima deo pre prvog `\n , /`, uklanja razmake, otvara `tel:` URI (`LaunchMode.externalApplication`); greška → `false`.

#### Moderation
- `enum ReportContentType { user, moment, message, dog, poi, chat }`
- `enum ReportStatus { pending, reviewed, actionTaken, dismissed }`
- `enum SafetyAction { report, block }` (`safety_menu.dart`)

**`ContentReport`**: required `id`, `reporterId`, `targetType` (ReportContentType), `targetId`, `reason` (String), `timestamp` (DateTime); `reportedUserId` = `''`, `targetName` = `''` (ljudski naziv, npr. naziv POI), `details` String? = null, `status` = `pending`.
- `isActive` = status == pending; `copyWith({status, targetName})`; `targetTypeKey` = `targetType.name`; `statusKey`.
- `statusKeyOf`: `actionTaken → 'action_taken'`, ostali po imenu.
- `typeFromKey`: `'user','moment','message','poi','chat'`; `'dog'|'dog_profile'` → dog; **nepoznato ili null → dog**.
- `statusFromKey`: `'reviewed'|'resolved'` → reviewed (legacy `'resolved'`), `'action_taken'`, `'dismissed'`, sve ostalo → pending.

#### Notifications
- `enum NotificationKind { match, walkRequest, chatMessage, like, superLike, groupMessage, eventMessage }`
- **`AppNotification`**: required `id`, `kind`, `title`, `body`, `createdAt`; `isRead` = false; `dogId`, `fromUserId`, `conversationId`, `groupId`, `eventId` (String?, null). `copyWith({isRead})`.
- `enum PushKind { match, message, walk, group, event }`
- **`PushPayload`**: required `kind`, `title`, `body`; opciono `dogId`, `peerUserId`, `conversationId`, `groupId`, `eventId`.
  - `typeName`: `'match'|'message'|'walk'|'group'|'event'`.
  - `data` (Map<String,String>): `type`, `title`, `body` + null-aware unosi (`'dogId': ?dogId` itd. – Dart 3.8+ sintaksa).
  - `fromData(map)`: spaja ugnježdenu mapu `data` (preko `putIfAbsent` – **mutira ulaznu mapu**); `dogId ← dogId|senderDogId|fromDogId`; `peerUserId ← peerUserId|fromUserId|senderUserId`; `conversationId ← conversationId|chatId|matchId`.
  - `kindFrom`: `'message','walk','group','event'`; sve ostalo (i null) → `match`.

#### Support
- **`AdminFeedback`**: required `userId`, `userName`, `userEmail`, `category`, `subject`, `message` (String); `status` = `statusNew`. `static const statusNew = 'new'`; `static const categories = ['💡 Predlog', '🐛 Prijava problema', '❤️ Pohvala', '❓ Pitanje']` (samo SR; emoji je deo vrednosti koja ide u Firestore).
- **`OfficialContactLink`**: `id`, `title`, `subtitle` (String), `uri` (Uri) – svi required.
- **`OfficialContacts`** (abstract final): `emailAddress`, `instagramHandle`, `facebookName`, `emailUri` (mailto), `instagramUri`, `facebookUri`, `all` (lista od 3 linka).
- **`SupportGuide`**: `icon`, `color`, `title`, `points` (List<String>) – mrtav kod.
- `enum TipCategory { urgent, prevention, daily }`; `enum TipCtaKind { sosVets, findWalk, dogProfile, writeAdmin }`.
- **`TipSection`**: required `title`; `bullets` = `const []`, `steps` = `const []`, `warning` String?, `isChecklist` = false.
- **`TipArticle`**: required `id`, `category`, `icon`, `accent`, `title`, `summary`, `sections`; `footerNote` String?, `cta` TipCtaKind?, `ctaLabel` String?, `initiallyExpanded` = false.
- **`TipsContent`**: boje `urgentAccent 0xFFDC2626`, `preventionAccent 0xFF0D9488`, `dailyAccent = AppColors.primary`; `articles` – urgent: `urgent-vet` (inicijalno otvoren, CTA sosVets), `heatstroke`, `first-aid`, `poisoning`, `human-meds`; prevention: `parasites`, `vaccines`, `teeth`, `weight`, `checklist` (isChecklist); daily: `walk` (CTA findWalk), `car`, `behavior`, `home-safety`, `id` (CTA dogProfile). `byCategory(cat)`.
- **`RulesContent`**: daily: `rule-clean-up`, `rule-leash`, `rule-park`, `rule-other-dogs`; community: `rule-owners`, `rule-app-culture`, `rule-posts`, `rule-not-allowed`; important: `rule-lost-found`, `rule-adoption`, `rule-report` (CTA writeAdmin).
- **`_SosContact`** (privatno, `sos_tab.dart`): `city`, `title`, `phone` (može sadržati više brojeva odvojenih `\n`), `address`, `kind` (`_SosKind { vet, shelter, local }`); `primaryPhone` = prvi red.

#### Admin
- **`FeedbackEntry`** (`admin/domain/admin_models.dart`): required `id`, `userId`, `userName`, `userEmail`, `category`, `subject`, `message`, `status` (String), `createdAt` (DateTime). Konstante `statusNew = 'new'`, `statusResolved = 'resolved'`. `isResolved`, `copyWith({status})`.
- **`AdminUserEntry`**: required `uid`, `name`, `email`, `role` (String), `createdAt` (DateTime?). `isAdmin` = `role == 'admin'`.
- **`AdminEditPoiResult`** (enum, `admin_edit_poi_dialog.dart`): `cancelled`, `saved`, `savedAndResolved`.

---
## 7. SERVISI I POMOĆNE KLASE
### 7.1 Core, app, servisi, auth, splash, legal, lokacija, home
#### `AuthRepository` (apstraktno) – `lib/features/auth/domain/auth_repository.dart`
- `Stream<AppUser?> watchUser()`
- `Future<AppUser> signInWithEmailAndPassword({required String email, required String password})`
- `Future<AppUser> signUpWithEmailAndPassword({required email, required password, required name, String city = '', String cityId = '', String neighborhoodId = '', String neighborhoodName = '', String bio = '', String customPhotoUrl = ''})`
- `Future<AppUser> signInWithGoogle()`
- `Future<void> signOut()`
- `Future<void> sendPasswordResetEmail(String email)`
- `Future<void> deleteAccount()`
- `Future<void> saveUserProfile({required AppUser user, UserDogProfile? dog, String? city, String? name, String? bio, String? cityId, String? neighborhoodId, String? neighborhoodName, bool writeDog = true})`
- `Future<void> saveOwnerCustomPhoto({required String uid, required String customPhotoUrl})`

#### `AuthRepositoryImpl` – `lib/features/auth/data/auth_repository_impl.dart`
Konstruktor `AuthRepositoryImpl(FirebaseAuthDatasource, {firestore})` (privatni imenovani parametar `this._firestore`, poziva se kao `firestore:`). Ako je `_firestore == null`, sve Firestore operacije su no-op.
- `watchUser()` – `authStateChanges().asyncExpand`: za null emituje null; inače odmah emituje korisnika iz Auth-a, pa sluša `users/{uid}.snapshots()` i emituje obogaćenog `AppUser`-a (ignoriše snapshot ako se trenutni uid promenio). Na grešku streama: `debugPrint` i emituje `null` samo ako Auth više nema korisnika.
- `signInWithEmailAndPassword` – prijava pa `_upsertUser(user)` (transakcija nad `users/{uid}`).
- `signUpWithEmailAndPassword` – `createUserWithEmailAndPassword`, `updateDisplayName`, `_upsertUser` sa gradom/naseljem/bio/fotom, best-effort `updatePhotoURL(ownerPhoto)`.
- `signInWithGoogle` – Google kredencijal pa `_createDefaultProfileIfNew` (kreira `users/{uid}` samo ako ne postoji).
- `signOut`, `sendPasswordResetEmail` – delegiraju datasource-u.
- `deleteAccount` – `AccountDeletionService.deleteAllUserData(uid)` **pa tek onda** `user.delete()`.
- `saveUserProfile` – `set(merge)` na `users/{uid}` (bez `role`, bez `createdAt`, bez owner foto; `dog` samo ako `writeDog`), zatim ako `writeDog` i `dog.id` nije prazan – `set(merge)` na `dogs/{dogId}`.
- `saveOwnerCustomPhoto` – transakcija: ako doc ne postoji, `set` sa `uid, role:'user', photoUrl, customPhotoUrl, createdAt, updatedAt`; inače `update` samo `photoUrl, customPhotoUrl, updatedAt`; zatim best-effort `updatePhotoURL` + `reload`.
- Privatno: `_mapFirebase` (mapiranje kodova: `invalid-email`; `wrong-password|invalid-credential|user-not-found|INVALID_LOGIN_CREDENTIALS` → wrongPassword; `weak-password`; `email-already-in-use|account-exists-with-different-credential` → emailInUse; `network-request-failed`; `requires-recent-login`; ostalo → unknown), `_upsertUser` (čuva postojeće vrednosti grada/naselja/bio/foto/role/dog; `role` i `dog` piše samo za nov dokument), `_createDefaultProfileIfNew`.

#### `LocalAuthRepository` – `lib/features/auth/data/local_auth_repository.dart`
In-memory mock (broadcast `StreamController`). `signInWithEmailAndPassword` uvek vraća `uid 'local-user'`, `displayName 'Aleksandar'`, `city 'Novi Sad'` (lozinka se ignoriše); `signUp` postavlja prosleđene vrednosti; `signInWithGoogle` → `localDemoUser`; `signOut`/`deleteAccount` → null; `sendPasswordResetEmail` prazno telo; `saveUserProfile`/`saveOwnerCustomPhoto` menjaju lokalnog korisnika.

#### `FirebaseAuthDatasource` – `lib/features/auth/data/firebase_auth_datasource.dart`
- `authStateChanges()`, `currentUser`, `signInWithEmailAndPassword`, `signUpWithEmailAndPassword`, `updateDisplayName(name)` (+ `reload`).
- `signInWithGoogle()` – `GoogleSignIn(scopes: ['email','profile']).signIn()`; null nalog ili `PlatformException` sa „cancel“/`error_aborted_by_user` → `AuthException(cancelled)`; ostale `PlatformException` → `unknown`.
- `signOut()` – `FirebaseAuth.signOut()` pa (bez čekanja) Google `signOut()` sa timeout-om 2 s.
- `sendPasswordResetEmail(email)` – normalizuje (`trim().toLowerCase()`), `debugPrint` sa email adresom.
- `deleteCurrentUser()` – `user.delete()`.

#### `AccountDeletionService` – `lib/features/auth/data/account_deletion_service.dart`
Javna metoda: `Future<void> deleteAllUserData(String uid)` – videti tačan redosled u sekciji Autentifikacija/Firestore. Batch brisanje po 400 dokumenata. Samo `_deleteCollectionGroup` i operacije „napuštanja“ (`_leaveChats`, `_leaveArrayMembership`) hvataju greške; ostali upiti (`_deleteQuery`, `_deleteSubcollection`, `_deleteOwnedDocs`) bacaju grešku i prekidaju ceo proces.

#### `AuthController` – `lib/features/auth/presentation/auth_controller.dart`
`Notifier<AsyncValue<void>>`, provider `authControllerProvider` (`NotifierProvider`).
- `AuthBusy get busy` – trenutna vrsta operacije dok je state loading (nema poziva van fajla).
- `Future<bool> signInWithEmail({email, password})` – repo prijava + `sessionSignedOut=false`.
- `Future<bool> register({name, email, password, city, cityId, neighborhoodId, neighborhoodName, bio, customPhotoUrl})` – repo registracija + `sessionSignedOut=false`.
- `Future<bool> signInWithGoogle()` – repo Google + `sessionSignedOut=false` (UI ga trenutno ne poziva).
- `Future<({bool success, Object? error})> signOut()` – `walkControllerProvider.notifier.stopForSignOut()` (greške progutane), `sessionSignedOut=true`, repo `signOut`; na neuspeh vraća `sessionSignedOut=false`; na uspeh invalidira `authStateProvider`, `walkControllerProvider`, `liveWalkingDogsProvider`.
- `Future<bool> sendPasswordResetEmail(String)` – postoji, ali se **ne koristi** (dijalog zove Firebase direktno).
- `Future<({bool success, Object? error})> deleteAccount()` – zaustavlja šetnju, repo `deleteAccount`, `sessionSignedOut=true`.
- `_run` – `AuthException(cancelled)` → `AsyncData` i `false` (bez greške); ostale greške → `AsyncError` (ne-AuthException se umotava u `AuthException(unknown, error.toString())`).

#### Auth provideri – `lib/features/auth/presentation/auth_providers.dart`
- `authRepositoryProvider` – `Provider<AuthRepository>`: **ako `!isFirebaseReady` → `LocalAuthRepository(user: localDemoUser)`**, inače `AuthRepositoryImpl(FirebaseAuthDatasource(FirebaseAuth.instance, googleSignIn: GoogleSignIn(scopes: ['email','profile'])), firestore: FirebaseFirestore.instance)`. U praksi, `main.dart` pokreće `VauVauApp` samo posle uspešnog `Firebase.initializeApp`, pa se lokalna implementacija koristi samo ako se `VauVauApp` pokrene bez Firebase-a (npr. testovi).
- `SessionSignedOut` / `sessionSignedOutProvider` – `NotifierProvider<SessionSignedOut, bool>`, default `false`, `setSignedOut(bool)`.
- `authStateProvider` – `StreamProvider<AppUser?>`: ako je `sessionSignedOut` → `Stream.value(null)`, inače `repo.watchUser()`.
- `isAdminProvider` – `Provider<bool>`: `authStateProvider.asData?.value?.isAdmin ?? false`.

#### `FirestoreAuthGuard` + `firestoreAuthReadyProvider` – `lib/core/firebase/firestore_auth_guard.dart`
- `currentUser`, `isSignedIn`.
- `Future<User?> ensureReady({bool forceRefresh = false})` – `getIdToken(forceRefresh)`; greška se loguje u Crashlytics (`reason: 'firestore_auth_token'`), ali korisnik se ipak vraća.
- `bool isPermissionDenied(Object)` – `FirebaseException.code == 'permission-denied'`, `PlatformException` analiza code/message/details, ili tekstualno.
- `bool isSoftFailError(Object)` – permission-denied ili mrežni tekstovi (`socketexception`, `clientexception`, `failed host lookup`…).
- `void logPermissionDenied(error, stack, {label})` – debugPrint + Crashlytics non-fatal + log.
- `Future<T> run<T>({action, fallback, label})` – vraća `fallback` kad nema korisnika ili na permission-denied.
- `Stream<T> guardedStream<T>({create, empty, label})` – čeka Auth; bez korisnika emituje `empty` i zatvara; na **bilo koju** grešku emituje `empty` (ne propagira grešku).
- `firestoreAuthReadyProvider` – `FutureProvider<bool>`: true samo ako nije `sessionSignedOut`, Firebase spreman, `authStateProvider` ima korisnika i `ensureReady()` vrati istog uid-a.

#### `StorageService` – `lib/services/storage_service.dart`
Konstruktor `StorageService({FirebaseStorage? storage, ImagePicker? picker, String? Function()? currentUserId})`.
- `String ownerFolder(String folderName, {String ownerId = ''})` – gradi `{root}/{uid}[/rest]`; baca `StateError('Moraš biti prijavljen da bi poslao sliku.')` bez uid-a; nepoznat root → `uploads/{uid}/{folder}`; prazan → `uploads/{uid}`.
- `static bool isFirebaseStorageUrl(url)`, `static bool isHttpsDownloadUrl(url)` (prihvata i `http://`), `static bool isGsUri(url)`.
- `Future<Uint8List> downloadBytes(url)` – `ref.getData(8 MB)`, statički keš do 48 slika (FIFO izbacivanje).
- `Future<String> resolveDownloadUrl(url)` – `gs://` → HTTPS.
- `Future<String?> uploadImageFromGallery({folderName, ownerId})`, `Future<String?> uploadImageFromCamera(...)` – `pickImage(imageQuality: 70, maxWidth: 1080)`; null ako korisnik otkaže.
- `Future<List<String>> uploadImagesFromGallery({folderName, required int limit, ownerId})` – `pickMultiImage`.
- `Future<String?> uploadXFile({file, folderName, ownerId})` – null za prazan fajl.
- `Future<String> uploadBytes({bytes, folderName, fileName = 'upload.jpg', mimeType, ownerId})` – putanja `{ownerFolder}/{millisSinceEpoch}{ext}`, content-type po magic bajtovima → MIME → ekstenziji, `cacheControl: 'public,max-age=31536000'`; vraća samo HTTPS URL.
- `Future<void> deleteImageByUrl(url)` (rethrow), `Future<void> tryDeleteImageByUrl(String?)` (best-effort).
- Poruke grešaka na srpskom, uključujući uputstvo za developera („U Console → Storage → Rules objavi pravila iz storage.rules.“) koje se prikazuje krajnjem korisniku.

#### `ImageUploadService` – `lib/core/images/image_upload_service.dart`
`const ImageUploadService()`; statički `upload(bytes, {folderName, fileName, ownerId})`, `uploadFile(XFile, {folderName, ownerId})`; instance `uploadImage`, `uploadXFile` (baca `StateError('Upload na Firebase Storage nije uspeo.')` ako rezultat nije http(s)), `uploadAll(List<XFile>, {folderName})`. Koriste ga (van slice-a) groups, chat, adoption, lost_dogs, events.

#### `NotificationService` + `notificationServiceProvider` – `lib/core/services/notification_service.dart`
- `isSupported` – samo Android/iOS (ne web).
- `initialize()` – timezone (`FlutterTimezone`), plugin init (Android ikona `@mipmap/ic_launcher`, iOS bez automatskog traženja dozvola), `onDidReceiveNotificationResponse` → `onNotificationTap?.call(payload)`, kreira Android kanal `vauvau_alerts`.
- `Future<bool> requestPermissions()` – Android 13+ / iOS.
- `static int alertIdFor(Map<String,String>?)`, `static String alertTagFor(Map?)` – id/tag iz `conversationId|chatId|groupId|eventId|type`.
- `showPushAlert({title, body, data})` – heads-up notifikacija na kanalu `vauvau_alerts`, payload = JSON `data`.
- `dismissTrayAlerts({conversationId, groupId, eventId, allAlerts})` – briše po id/tag i (Android) prolazi kroz aktivne notifikacije.
- `Future<bool> scheduleHealthReminder({notificationId, title, body, scheduledDate})` – `zonedSchedule` u 09:00 lokalno, `inexactAllowWhileIdle`, kanal `vauvau_health`.
- `cancelReminder(int)`, `static ensureTimeZonesReady()`, `static reminderInstant(DateTime)`.
- Provider: `Provider<NotificationService>` (nova instanca); `main.dart` pravi **posebnu** instancu `NotificationService().initialize()`.

#### `MessageSoundPlayer` / `AudioMessageSoundPlayer` / `messageSoundPlayerProvider`
`play()` – lazy `AudioPlayer`, `ReleaseMode.stop`, `mixWithOthers`, `respectSilence: true`, `AssetSource('sounds/message.wav')`, volume 0.8; greške samo `debugPrint`. `dispose()`. Provider `Provider<MessageSoundPlayer>` sa `ref.onDispose`.

#### `ExternalLinkLauncher` / `externalLinkLauncherProvider`
`Future<bool> open(Uri)` – `launchUrl(uri, mode: LaunchMode.externalApplication)`.

#### `CrashReporting` (statički)
`init()` (uključuje kolekciju i u debug-u), `setUserId(String?)`, `recordFlutterError(details)` (fatal), `recordError(error, stack, {fatal=false, reason})`, `log(message)`.

#### `ContentValidationService` (statički)
`validateText(raw, {allowEmpty=false, minLetters=2})`, `validateTitle(raw)` (minLetters 3), `Future<String?> validateImage(XFile)`, `validateImageBytes(Uint8List)`.

#### Lokacija
- `LocationClient` (apstraktno): `isServiceEnabled`, `checkPermission`, `requestPermission`, `currentPosition` (Future<GeoCoord?>), `watchPosition` (Stream), `watchWalkPosition` (Stream), `openAppSettings`.
- `GeolocatorLocationClient` – `currentPosition` (high, timeout 8 s); foreground stream: distanceFilter 12 m, Android interval 5 s, iOS bez background-a; walk stream: distanceFilter 5 m, Android `forceLocationManager: true`, interval 3 s, foreground notifikacija; iOS `allowBackgroundLocationUpdates: true`, `showBackgroundLocationIndicator: true`. Sve greške se gutaju.
- `FallbackLocationClient` – sve vraća false/unavailable/null/prazan stream.
- `locationClientProvider` – `Provider<LocationClient>`: web/Android/iOS → `GeolocatorLocationClient`, ostalo (desktop) → `FallbackLocationClient`.
- `LocationController` / `userLocationProvider` – `NotifierProvider<LocationController, UserLocation>`. `build()` uzima fallback koordinatu iz `homeCityProvider` (ili Novi Sad), zakazuje `refresh(requestPermission: false)` u microtask-u. Metode: `Future<LocationAccess> refresh({required bool requestPermission})`, `Future<LocationAccess> requestPermission()`, `void setCoord(GeoCoord)`.
- `homeCityProvider` – `Provider<HomeCity?>`: iz `authStateProvider` (`cityId`, `cityName`) preko `SerbiaLocations.resolveCityId`.
- `showLocationProminentDisclosure(context)` → `Future<bool>`; `requestLocationPermissionWithDisclosure({context, ref})` → `Future<LocationAccess>` (preskače dijalog kad je već granted ili kad sistemski dijalog neće ni izaći).

#### Home
- `HomeTabIndex` / `homeTabIndexProvider` – `NotifierProvider<HomeTabIndex, int>`, default 0; `setIndex(int)`, `showDiscover()` (0), `showMap()` (1), `showMessages()` (2), `showProfile()` (3).

### 7.2 Chat, grupe, događaji
#### Izbor implementacije (Firebase vs lokalno)
| Domen | Provider | Firestore kada | Lokalno kada | Seed u lokalnom |
|---|---|---|---|---|
| Chat | `chatRepositoryProvider` (chat_inbox.dart:221) | `isFirebaseReady && user != null && uid.isNotEmpty && firestoreAuthReadyProvider == true` | u svim ostalim slučajevima (uključujući Firebase spreman ali auth još nije) | `isFirebaseReady ? const [] : chatSeedProvider` → mock razgovori samo kada Firebase NIJE spreman |
| Grupe | `groupsRepositoryProvider` (groups_controller.dart:126) | `isFirebaseReady` (čak i bez prijavljenog korisnika, `uid = ''`) | `!isFirebaseReady` | `SeedBreedGroups.all` |
| Događaji | `eventsRepositoryProvider` (events_controller.dart:167) | `isFirebaseReady` (čak i bez korisnika) | `!isFirebaseReady` | `SeedEvents.all` |

Napomena: i Firestore implementacije grupa i događaja **pišu seed podatke u produkcijsku bazu** (`ensureSeeded`) – vidi tehnički dug.

#### `ChatRepository` (abstract) – `chat/domain/chat_repository.dart`
| Član | Potpis | Opis |
|---|---|---|
| `currentInbox` | `List<ChatConversation> get` | trenutni snimak inbox-a |
| `hasLoadedInbox` | `bool get` | true posle prvog upotrebljivog snimka |
| `watchInbox()` | `Stream<List<ChatConversation>>` | |
| `watchInboxLoaded()` | `Stream<bool>` | emituje kad `hasLoadedInbox` postane true (i trenutnu vrednost) |
| `watchRooms()` | `Stream<List<ChatRoom>>` | (nekorišćeno u UI) |
| `watchMessages(String roomId)` | `Stream<List<ChatMessage>>` | (koristi ga samo `chatMessagesProvider`, koji se nigde ne koristi) |
| `currentWalkInvites` | `Map<String, List<ChatMessage>> get` | walk invite poruke po razgovoru, za sve sobe |
| `watchWalkInvites()` | `Stream<Map<String, List<ChatMessage>>>` | |
| `attachRoom(String)` / `detachRoom(String)` | `void` | pokretanje/gašenje listenera poruka za otvoren razgovor |
| `openFromMatch({required DiscoverProfile profile, required String myUserId, required String myDogId})` | `String` | vraća id razgovora, kreira ga ako ne postoji |
| `markRead(String conversationId)` | `void` | |
| `sendMessage(String conversationId, String rawText, {ChatMessage? replyTo})` | `Future<void>` | |
| `sendWalkInvite({conversationId, walkTime, walkLocationName})` | `Future<void>` | |
| `sendLocationPin({conversationId, locationName})` | `Future<void>` | |
| `sendPhoto({conversationId, imageUrl, ChatMessage? replyTo})` | `Future<void>` | |
| `respondToWalkInvite({conversationId, messageId, WalkInviteStatus status})` | `Future<void>` | |
| `toggleMessageLike({conversationId, messageId})` | `Future<void>` | |
| `dispose()` | `void` | |

#### `FirestoreChatRepository` – `chat/data/firestore_chat_repository.dart`
Konstruktor: `FirestoreChatRepository({required this._firestore, required this.currentUserId, this.currentUserName = '', this.currentUserAvatarUrl = ''})` (privatni imenovani parametar `this._firestore`; provider ga poziva kao `firestore:`). Konstanta `messagePageSize = 30`.
Javne metode:
- `void start()` – ako je uid prazan ili `'local-user'` → `_publishEmptyInbox()`; inače `_startGuarded()`: čeka `FirestoreAuthGuard.ensureReady()`, proverava da je `user.uid == currentUserId`, pa sluša `chats.where('participantIds', arrayContains: uid).snapshots()`. Permission-denied → prazan inbox; ostale greške → `developer.log` + `CrashReporting.recordError`.
- `currentInbox`, `hasLoadedInbox`, `watchInbox()` (prvo `currentInbox`, pa broadcast stream), `watchInboxLoaded()`.
- `watchRooms()` – zaseban, `FirestoreAuthGuard.guardedStream` nad istim upitom, mapira u `ChatRoom`.
- `watchMessages(roomId)` – `guardedStream` nad `chats/{roomId}/messages.orderBy('timestamp', descending: true).limit(30)`, obrnuto u hronološki redosled.
- `currentWalkInvites` / `watchWalkInvites()` – iz `_walkInvites` mape koju pune listeneri `_syncWalkInviteSubs`.
- `attachRoom(roomId)` – ref-count `_roomAttachCounts[id]++`, `_ensureMessageSub(id)` (limit 30, newest first).
- `detachRoom(roomId)` – smanjuje ref-count; na 0 otkazuje listener, briše pending poruke i prazni `messages` za taj razgovor u inbox-u (preview ostaje iz `lastMessagePreview`).
- `openFromMatch(...)` – id = sortirani `'${uidA}_${uidB}'`; ako postoji u `_inbox` vrati ga; inače ubaci optimistički placeholder (`isNewMatch: true`) na vrh inbox-a, emituj, i `unawaited(_createRoom(...))`.
- `markRead(conversationId)` – lokalno `unreadCount: 0` + `set({'unreadCount': 0, 'unreadByUser': {uid: 0}}, merge)` (fire-and-forget).
- `sendMessage`, `sendWalkInvite`, `sendLocationPin`, `sendPhoto` – optimistički dodaju poruku sa id `local-N`, zatim `_writeMessage` (vidi Tok podataka).
- `toggleMessageLike` – optimistički menja `likes`, zatim `messages/{id}.update({'likes': nextLikes})`; na grešku vraća prethodno stanje (ako je postojalo), prijavljuje i `rethrow`.
- `respondToWalkInvite` – optimistički status, zatim `update({'status': 'accepted'|'declined'})`; na grešku rollback na prethodni (ili `pending`), log, prijava, `rethrow`.
- `dispose()` – gasi tajmere, sve listenere i kontrolere.

#### `LocalChatRepository` – `chat/data/local_chat_repository.dart`
Konstruktor: `LocalChatRepository({required List<ChatConversation> seed, required this.currentUserId, this.currentUserName = 'Ti', this.currentUserAvatarUrl = ''})`.
- `hasLoadedInbox` → uvek `true`; `watchInboxLoaded()` → jedan `true`.
- `currentWalkInvites`/`watchWalkInvites()` – izvedeno iz poruka u inbox-u.
- `watchRooms()` – mapira inbox na `chat.room`.
- `watchMessages(roomId)` – poslednjih 30 poruka iz inbox-a.
- `attachRoom`/`detachRoom` – prazne (no-op).
- `openFromMatch` – traži razgovor po `dogId`; inače pravi `chat-${profile.id}` sa peer-om `'owner-${profile.id}'`.
- `markRead` – `unreadCount: 0` i `isRead: true` za sve poruke.
- `send*` – dodaje poruku lokalno (id `local-N`), `respondToWalkInvite`/`toggleMessageLike` – lokalna izmena; `dispose()` zatvara stream.

#### `ChatInboxController` (`Notifier<List<ChatConversation>>`) – `chat/presentation/chat_inbox.dart`
`build()` – `ref.watch(chatRepositoryProvider)`, pretplata na `watchInbox()` → `state`, vraća `repo.currentInbox`.
Javni članovi:
- `List<ChatConversation> get newMatches` – `isNewMatch == true`.
- `List<ChatConversation> get threads` – ne-novi, sortirano po `lastActivityAt` opadajuće.
- `ChatConversation? byId(String id)`.
- `String openFromMatch(DiscoverProfile profile)` – poziva repo sa `chatUserIdProvider` i `currentDiscoverDogProvider.id`.
- `void markRead(String conversationId)` – repo + `notificationControllerProvider.notifier.markChatMessagesRead(conversationId, peerUserId)`.
- `void attachRoom(String)`, `void detachRoom(String)`.
- `Future<void> sendMessage(String conversationId, String rawText, {ChatMessage? replyTo})` – repo, pa `pushControllerProvider.notifier.notifyMessage(senderName, preview, dogId, peerUserId, conversationId)` (unawaited).
- `Future<void> sendWalkInvite({conversationId, walkTime, walkLocationName})` – tiho odbacuje ako `walkTime` nije u budućnosti; repo; `notifyWalk(dogName, ownerName, dogId, peerUserId, conversationId)`.
- `Future<void> sendLocationPin({conversationId, locationName})` – bez push-a.
- `Future<void> sendPhoto(String conversationId, XFile file, {ChatMessage? replyTo})` – `ContentValidationService.validateImage` (greška → `DogsException`), `ImageUploadService.uploadFile(folderName: 'chats')`, repo `sendPhoto`, `notifyMessage(preview: '📷 Fotografija')`.
- `Future<void> respondToWalkInvite({conversationId, messageId, status})`, `Future<void> toggleMessageLike({conversationId, messageId})` – bez push-a.

#### `ChatWalkInvitesController` (`Notifier<Map<String, List<ChatMessage>>>`) – chat_inbox.dart:299
`build()` – pretplata na `repo.watchWalkInvites()`, vraća `repo.currentWalkInvites`. Nema javnih metoda.

#### Top-level provideri – chat
| Provider | Tip | Šta radi |
|---|---|---|
| `chatSeedProvider` | `Provider<List<ChatConversation>>` | `seedChatConversations(DateTime.now())` |
| `chatUserIdProvider` | `Provider<String>` | uid ili `'local-user'` |
| `chatRepositoryProvider` | `Provider<ChatRepository>` | izbor Firestore/Local (vidi tabelu); `start()` + `onDispose(dispose)` |
| `chatInboxProvider` | `NotifierProvider<ChatInboxController, List<ChatConversation>>` | |
| `chatInboxLoadedProvider` | `Provider<bool>` | `repo.hasLoadedInbox`, rebuild preko privatnog `_chatInboxLoadedStreamProvider` (`StreamProvider<bool>`) |
| `visibleConversationsProvider` | `Provider<List<ChatConversation>>` | inbox bez razgovora sa `blockedUserIdsProvider` |
| `chatNowProvider` | `Provider<DateTime>` | `DateTime.now()` – izračunava se jednom (vidi dug) |
| `scheduledWalksClockProvider` | `StreamProvider<DateTime>` | now, pa svakih 1h |
| `chatMessagesProvider` | `StreamProvider.family<List<ChatMessage>, String>` | `repo.watchMessages(roomId)` – **nigde se ne koristi u lib/** |
| `chatWalkInvitesProvider` | `NotifierProvider<ChatWalkInvitesController, Map<...>>` | |
| `scheduledWalksProvider` | `Provider<List<ScheduledWalk>>` | spaja walk invite iz `chatWalkInvitesProvider` i (svežije, optimističke) iz `chat.messages`; uzima samo `accepted` sa `walkTime > now`; sort rastuće |
| `totalUnreadChatCountProvider` | `Provider<int>` | broj **thread-ova** (ne poruka) sa unread > 0: 1:1 (iz `chatInboxProvider`, ne iz `visibleConversationsProvider`) + `joinedGroupThreadsProvider` + `joinedEventThreadsProvider` |
| `systemMessageAlertsAudibleProvider` | `Provider<bool>` | `notificationService.isSupported && pushControllerProvider` |
| `incomingMessageSoundProvider` | `Provider<void>` | sluša `visibleConversationsProvider`, `joinedGroupThreadsProvider`, `joinedEventThreadsProvider`; pušta `messageSoundPlayerProvider.play()` (min razmak 1500 ms, samo ako `appSettings.notifyMessages`); za grupe/događaje samo ako sistemske notifikacije NISU čujne |
| `rawIncomingLikesProvider` | `StreamProvider<List<IncomingLike>>` | `swipes.where('toDogId', isEqualTo: myDogId)`; filtrira `type == 'like'` (default `'like'`), sort po vremenu, dedup po `fromUserId`, za svaki `loadDiscoverProfile` (N dodatnih čitanja); prazno ako Firebase nije spreman, auth nije spreman, uid prazan ili `myDogId == 'local-luna'` |
| `incomingLikesProvider` | `Provider<List<IncomingLike>>` | izbacuje lajkove od korisnika sa kojima već postoji razgovor |

`incomingMessageSoundProvider` i `groupUnreadAlertsProvider` se aktiviraju sa `ref.watch` u `HomeShellScreen` (home_shell_screen.dart:40–41).

#### `GroupsRepository` (abstract) – `groups/domain/groups_models.dart:282`
`watchGroups()`, `watchPendingGroups()` → `Stream<List<BreedGroup>>`; `watchMessages(groupId)` → `Stream<List<GroupMessage>>`; `watchLastRead(groupId)` → `Stream<DateTime?>`; `joinGroup(groupId)`, `markRead(groupId)` → `Future<void>`; `createGroup({required title, required description, bool approveImmediately = false})` → `Future<BreedGroup>`; `approveGroup(groupId)`, `deleteGroup(groupId)`; `sendMessage({required groupId, required text, String imageUrl = '', GroupMessage? replyTo})`; `sendPhoto({groupId, imageUrl, replyTo})`; `sendWalkInvite({groupId, walkTime, walkLocationName})`; `respondToWalkInvite({groupId, messageId, GroupWalkInviteStatus status})`; `toggleMessageLike({groupId, messageId})` – sve `Future<void>`.

#### `FirestoreGroupsRepository` – `groups/data/firestore_groups_repository.dart`
Konstruktor: `({required firestore, required currentUserId, required senderName, required senderAvatarUrl})`.
- `Future<void> ensureSeeded()` (javna) – jednom po instanci: za svaku od 9 seed grupa `get`; ako ne postoji → `set(firestoreData)`; ako postoji → `set(merge)` patch `title, description, imageUrl, isApproved: true, sortOrder, createdBy` i, ako niko nije član (`memberIds` prazno), još `memberCount` (lažni broj) i `memberIds: []`. Briše dokument `vlasnici-malih-pasa-novi-sad` ako postoji.
- `watchGroups()` – `await ensureSeeded()`, pa `guardedStream` nad **celom** kolekcijom `breed_groups.snapshots()`, filtrira `isApproved` na klijentu, sort po popularnosti.
- `watchPendingGroups()` – isto, ali `!isApproved`, sort po `createdAt` opadajuće.
- `watchMessages(groupId)` – `breed_groups/{id}/messages.orderBy('createdAt')` – **bez limita**.
- `joinGroup` – `StateError('Morate biti prijavljeni.')` ako nema uid; transakcija: doda uid u `memberIds`, `memberCount = stored + 1`; zatim kreira `members/{uid}` sa `lastReadTimestamp` ako ne postoji.
- `watchLastRead` – sluša `members/{uid}` → `lastReadTimestamp` (Timestamp → DateTime, inače null).
- `markRead` – `members/{uid}.set({'lastReadTimestamp': serverTimestamp}, merge)`.
- `createGroup` – validira, `description` fallback `defaultDescription`, novi doc sa `isApproved: approveImmediately`, `sortOrder: 999`, `memberIds: [uid]`, `memberCount: 1`, `createdBy`, `createdAt: serverTimestamp`; best-effort `members/{uid}`; vraća lokalno konstruisan `BreedGroup` (createdAt = `DateTime.now()`).
- `approveGroup` – `set({'isApproved': true}, merge)`. `deleteGroup` – `delete()` samo glavnog dokumenta.
- `sendMessage` – `messages.add({...})` + `set(merge)` na grupi `lastMessage`, `lastMessageAt`, `lastMessageSenderId`. `sendPhoto` → `sendMessage(text: '', imageUrl)`.
- `sendWalkInvite` – `messages.add` sa `type: 'walk_invite'`, `status: 'pending'`, `walkTime: Timestamp`, `acceptedByUserIds: []`, `declinedByUserIds: []` + update grupe.
- `respondToWalkInvite` – `update` sa `arrayUnion`/`arrayRemove` na `acceptedByUserIds`/`declinedByUserIds` i uvek `'status': 'pending'` (status je po korisniku u nizovima).
- `toggleMessageLike` – transakcija: čita `likes`, dodaje/uklanja uid, `tx.set({'likes': ids}, merge)`.

#### `LocalGroupsRepository` – `groups/data/local_groups_repository.dart`
Konstruktor `({required currentUserId, senderName = 'Ti', senderAvatarUrl = '', List<BreedGroup>? seed})` (default `SeedBreedGroups.all`). Javno i van interfejsa: `void dispose()`, `void seedIncomingMessage({required groupId, required GroupMessage message})` (koristi se u `test/group_inbox_test.dart`). Sve operacije u memoriji; id poruka `gmsg-${millisecondsSinceEpoch}`, id grupa `user-${millisecondsSinceEpoch}`; `markRead`/`joinGroup` postavljaju `_lastRead = DateTime.now()`.

#### `GroupsController` (`Notifier<List<BreedGroup>>`) – `groups/presentation/groups_controller.dart`
`build()` – pretplata na `repo.watchGroups()` (greška → `debugPrint`), početno `const []`.
Metode: `markRead(groupId)`, `join(groupId)`, `createGroup({title, description})` (uvek `approveImmediately: false`), `approveGroup(groupId)`, `deleteGroup(groupId)`, `sendText(groupId, text, {replyTo})`, `sendPhoto(groupId, XFile file, {replyTo})` (validacija + upload u folder `'groups'`), `sendWalkInvite({groupId, walkTime, walkLocationName})`, `respondToWalkInvite({groupId, messageId, status})`, `toggleMessageLike({groupId, messageId})` – sve `Future`. **Nijedna grupna akcija ne poziva `pushControllerProvider`** (osim posredno kroz `groupUnreadAlertsProvider` na strani primaoca).

#### Top-level provideri – grupe
| Provider | Tip | Šta radi |
|---|---|---|
| `groupsRepositoryProvider` | `Provider<GroupsRepository>` | Firestore/Local; ime pošiljaoca fallback `'Član'` (lokalno `'Ti'`) |
| `groupsControllerProvider` | `NotifierProvider<GroupsController, List<BreedGroup>>` | |
| `pendingGroupsProvider` | `StreamProvider<List<BreedGroup>>` | prazno ako `!isAdminProvider`; koristi ga `admin_groups_tab.dart` |
| `groupMessagesProvider` | `StreamProvider.family<List<GroupMessage>, String>` | |
| `groupsMemberIdProvider` | `Provider<String>` | uid, ili `''` (Firebase) / `'local-user'` |
| `groupByIdProvider` | `Provider.family<BreedGroup?, String>` | |
| `groupLastReadProvider` | `StreamProvider.family<DateTime?, String>` | |
| `joinedGroupThreadsProvider` | `Provider<List<GroupInboxThread>>` | za svaku grupu gde je korisnik član watch-uje `groupMessagesProvider(id)` (pun stream poruka) i `groupLastReadProvider(id)` |
| `sortedGroupsProvider` | `Provider<List<BreedGroup>>` | **nigde se ne koristi** |
| `groupUnreadAlertsProvider` | `Provider<void>` (group_unread_alerts.dart) | posle prvog snimka, kad unread grupe/događaja poraste → `notifyGroupThread(groupTitle, count, groupId/eventId)` |

#### `EventsRepository` (abstract) – `events/domain/events_repository.dart`
`watchEvents()`, `watchMessages(eventId)`, `watchLastRead(eventId)`, `joinEvent(eventId)`, `markRead(eventId)`, `sendMessage({required eventId, required text, String imageUrl = '', String? senderId, String? senderName, GroupMessage? replyTo})`, `sendPhoto({eventId, imageUrl, replyTo})`, `sendWalkInvite({eventId, walkTime, walkLocationName})`, `respondToWalkInvite({eventId, messageId, GroupWalkInviteStatus status})`, `toggleMessageLike({eventId, messageId})`, `Future<String> createEvent(EventModel event)`.

#### `FirestoreEventsRepository` – `events/data/firestore_events_repository.dart`
- `ensureSeeded()` (javna) – jednom po instanci: `events.limit(1).get()`; ako je prazno → batch upis 3 `SeedEvents` (sa `Timestamp` za `dateTime`/`createdAt`); inače `_scrubStockCdnImages()` – čita **celu** `events` kolekciju i postavlja `imageUrl: ''` za stock CDN URL-ove (batch po 400).
- `watchEvents()` – `await ensureSeeded()`, `events.orderBy('dateTime').snapshots()` (bez filtera/limita).
- `watchMessages(eventId)` – `events/{id}/messages.orderBy('createdAt')` bez limita.
- `watchLastRead`, `markRead` – kao kod grupa, na `events/{id}/members/{uid}`.
- `joinEvent` – transakcija dodaje uid u `participantUserIds` (bez brojača); kreira `members/{uid}`; ako je dodat → šalje sistemsku poruku `EventsJoinCopy.joined(senderName)` **kao sam korisnik** (komentar: rules zahtevaju `senderId == auth.uid`); na kraju `markRead`.
- `sendMessage` – parametar `senderId` se ignoriše (uvek `currentUserId`); `senderName` override samo ako nije prazan; upis poruke + `lastMessage`/`lastMessageAt` na događaju (bez `lastMessageSenderId`). `replyToText` se NE seče (za razliku od grupa).
- `sendPhoto`, `sendWalkInvite`, `respondToWalkInvite`, `toggleMessageLike` – identično grupama.
- `createEvent(EventModel)` – uid iz `FirebaseAuth.instance.currentUser` ili `currentUserId`; ime iz Auth `displayName` → `event.organizerName` → `senderName` → `'Korisnik'`; validacija naslova/lokacije (StateError); `imageUrl` prazan → `kFallbackDogPhotoUrl` (koji je u `core/images/dog_photo_urls.dart:2` definisan kao `''`); `debugPrint` celog payload-a; `_col.add(payload)` + `members/{uid}`; vraća `doc.id`.

#### `LocalEventsRepository` – `events/data/local_events_repository.dart`
Konstruktor `({required currentUserId, senderName = 'Ti', senderAvatarUrl = '', List<EventModel>? seed})` (default `SeedEvents.all`). `dispose()`. `joinEvent` šalje sistemsku poruku sa `senderId: 'vauvau-system'`, `senderName: 'VauVau'`. `createEvent` ubacuje na početak, id `event-${ms}`. Id poruka `emsg-${ms}`.

#### `EventsController` (`Notifier<List<EventModel>>`) – `events/presentation/events_controller.dart`
`build()` – pretplata na `repo.watchEvents()` (greška → `debugPrint`), početno `const []`.
Metode: `join(eventId)`, `markRead(eventId)`, `sendText(eventId, text, {replyTo})`, `sendPhoto(eventId, XFile, {replyTo})` (upload u `'events'`), `sendWalkInvite({eventId, walkTime, walkLocationName})`, `respondToWalkInvite({eventId, messageId, status})`, `toggleMessageLike({eventId, messageId})`, `Future<String> create({required title, required locationName, required dateTime, required description, String cityId = '', XFile? photo})` – validira/uploaduje sliku, određuje uid/ime (Auth fallback), poziva `createEvent`; greške loguje `debugPrint` i `rethrow`.

#### `EventsCityFilter` (`Notifier<String?>`) – events_controller.dart:196
`build()` → `homeCityProvider?.id`; `select(String? cityId)`.

#### Top-level provideri – događaji
| Provider | Tip | Šta radi |
|---|---|---|
| `eventsRepositoryProvider` | `Provider<EventsRepository>` | Firestore/Local; ime fallback `'Korisnik'` (lokalno `'Ti'`) |
| `eventsControllerProvider` | `NotifierProvider<EventsController, List<EventModel>>` | |
| `eventsCityFilterProvider` | `NotifierProvider<EventsCityFilter, String?>` | null = svi gradovi |
| `eventVenuesProvider` | `Provider.family<List<String>, String>` | `EventVenues.forCity(cityId, mapPlacesProvider)` |
| `eventMessagesProvider` | `StreamProvider.family<List<GroupMessage>, String>` | |
| `eventLastReadProvider` | `StreamProvider.family<DateTime?, String>` | |
| `eventsMemberIdProvider` | `Provider<String>` | identičan `groupsMemberIdProvider` |
| `eventByIdProvider` | `Provider.family<EventModel?, String>` | |
| `joinedEventThreadsProvider` | `Provider<List<EventInboxThread>>` | za SVAKI događaj u kom je korisnik (i prošle – nema `isListed` filtera) watch-uje poruke i lastRead |

### 7.3 Discover, psi (zdravlje, podsetnici), profil i podešavanja
#### Izbor implementacije (Firebase vs lokalno)
Svi provideri biraju po `isFirebaseReady` (`core/firebase/firebase_status.dart`, van slice-a):

| Provider | Firebase spreman | Inače |
|---|---|---|
| `discoverRepositoryProvider` | `FirestoreDiscoverRepository(FirebaseFirestore.instance)` | `LocalDiscoverRepository(seed: discoverProfilesProvider)` = mock 6 pasa |
| `dogsRepositoryProvider` | `DogsRepositoryImpl(firestore: instance)` | `LocalDogsRepository(dogs: [localDemoDog()])` |
| `healthRepositoryProvider` | `FirestoreHealthRepository` | `LocalHealthRepository()` (+ `onDispose` zatvara stream) |
| `reminderRepositoryProvider` | `FirestoreReminderRepository` | `LocalReminderRepository()` |
| `loadDiscoverProfile` | čita Firestore | vraća `null` |
| `ProfileController.build` | iz `ownerDogsProvider`/auth | `mockUserProfile` ako nema kreiranih pasa (osim `local-luna`) |

#### `DiscoverRepository` (apstraktni) – `discover/domain/discover_repository.dart`
- `Stream<List<DiscoverProfile>> watchProfiles({required String excludeOwnerId, GeoQuery? geo, int limit = 15})`
- `Future<DiscoverPage> fetchProfilesPage({required String excludeOwnerId, GeoQuery? geo, Object? cursor, int limit = 15})`
- `Future<bool> swipe({required String userId, required String myDogId, required DiscoverProfile target, required String action, String likerName = ''})` – vraća `true` ako je nastao meč.
- `Future<bool> hasLiked({required String userId, required String dogId})`
- `Future<void> unlike({required String userId, required String dogId})`
- `Future<bool> sendSuperLike({required userId, required myDogId, required target, String likerName = ''})` – baca `SuperLikeDailyLimitException`.
- `Future<bool> hasUsedSuperLikeToday({required String userId})`

#### `FirestoreDiscoverRepository` – `discover/data/firestore_discover_repository.dart`
- **`watchProfiles`**: `dogs.orderBy('createdAt', desc).limit(limit).snapshots()` umotano u `FirestoreAuthGuard.guardedStream` (label `discover.watchProfiles`, empty `[]`). Zatim klijentski `_filterProfiles`: mapira dokumente, izbacuje `ownerId == excludeOwnerId`, primenjuje `geo.apply` (haversine radius), sortira `compareFeedOrder`. Napomena: filtriranje je **posle** `limit`, pa prva stranica može imati manje od 15 (ili 0) pasa.
- **`fetchProfilesPage`**: `FirestoreAuthGuard.run` (fallback prazna stranica). Sa geo filterom „oversample” `limit*3`; do 3 pokušaja (`startAfterDocument(cursor)`) dok se ne skupi `limit`; dedup po id; `nextCursor` = poslednji sirovi dokument (null ako je iscrpljeno i stranica nepotpuna); `hasMore = !rawExhausted || collected.length > limit`.
- **`swipe`**: `'superLike'` → `sendSuperLike`; `'like'` → `_recordLike` + `_tryCreateMatch`; svaka druga akcija → `swipes/{uid}_{dogId}` set (merge) sa `type: action`, vraća `false`. (U UI se poziva samo `'like'`.)
- **`_recordLike`**: (1) čita/piše `swipes/{uid}_{dogId}` (`fromUserId, fromDogId, toDogId, type, timestamp, createdAt`); (2) čita/piše `dogs/{dogId}/likes/{uid}` (`userId, type, createdAt`); (3) ako like dokument nije postojao → `dogs/{dogId}.likesCount += 1`; (4) `print('DOG LIKE SUCCESS…')`; (5) ako swipe dokument nije postojao i tip nije superLike → `_notifyLike` (greška samo `debugPrint`).
- **`_notifyLike`**: preskače ako vlasnik prazan ili sam korisnik; ime pošiljaoca = `likerName` ili `users/{uid}.name` ili `.email` ili `'Neko'`; `notifications.add({fromUserId, senderUserId, toUserId, title:'Novi lajk! 🐾', body, type:'like', isRead:false, createdAt, dogId: myDogId, senderDogId: myDogId})`; pri grešci retry bez `dogId/senderDogId/senderUserId`.
- **`_tryCreateMatch`** (logika meča): upit `swipes.where(fromUserId == target.ownerId).where(toDogId == myDogId).limit(5)`; meč postoji ako bilo koji ima `type` null/`like`/`superLike`. Tada `matchId = sort([userId, target.ownerId]).join('_')` → **jedan meč/chat po paru korisnika, nezavisno od pasa**. Upis `matches/{matchId}` (`id, dogIds:[myDogId, target.id], userIds, createdAt`) i `chats/{matchId}` (`id, participantIds, dogIds, dogId, dogName, ownerName, breed, location, photoUrl (resolvedDogPhotoUrl), peerUserId, lastMessage:'', lastMessageTimestamp, isNewMatch:true, unreadCount:0`), oba merge. Polja chata su iz perspektive onoga ko je lajkovao (podaci o target psu). Greške → `debugPrint`, vraća `false`.
- **Super Like**: `hasUsedSuperLikeToday` – `super_likes.where(fromUserId == uid).limit(25)` bez `orderBy`, pa klijentski proverava da li je neki `createdAt` u poslednjih 24h; na grešku vraća `false`. `sendSuperLike`: prazan uid → `StateError('Morate biti prijavljeni.')`; ako je iskorišćen → `SuperLikeDailyLimitException`; `super_likes.add({fromUserId, targetDogId, targetOwnerId, createdAt})`; `dogs/{id}.superLikesCount += 1`; `_recordLike(type:'superLike')`; `_notifySuperLike` (`notifications.add({recipientId, toUserId, senderId, fromUserId, senderUserId, type:'SUPER_LIKE', title:'⭐ Super Like!', message, body, dogId: target.id, senderDogId: myDogId, createdAt, isRead:false})`); zatim `_tryCreateMatch`. Limit je samo klijentski (da li Firestore pravila to brane – nije vidljivo iz ovog koda).
- **`hasLiked`**: postoji `dogs/{dogId}/likes/{uid}` ILI `swipes/{uid}_{dogId}` sa tipom null/like/superLike.
- **`unlike`**: briše `likes/{uid}` i `swipes/{uid}_{dogId}` (greške ignorisane), a ako je like postojao `likesCount -= 1`. Ne briše `super_likes`, notifikacije, mečeve ni chat.

#### `LocalDiscoverRepository` – `discover/data/local_discover_repository.dart`
Konstruktor `({List<DiscoverProfile>? seed})` (default `mockDiscoverProfiles`). `watchProfiles` → `Stream.value` (jednokratno), `fetchProfilesPage` sa `int` kursorom, like u `Set<'uid:dogId'>`, super like sa 24h limitom u memoriji, `print(...)` logovi. `swipe`/`sendSuperLike` **uvek vraćaju `false`** (nema mečeva lokalno). `_superLikedDogs` se puni ali nikad ne čita.

#### `loadDiscoverProfile({String? dogId, String? ownerId, FirebaseFirestore? firestore})` – `discover/data/load_discover_profile.dart`
`null` ako Firebase nije spreman; prvo `dogs/{dogId}`, inače `dogs.where(ownerId ==).limit(1)`.

#### Discover provideri i kontroleri – `discover/presentation/discover_controller.dart`

| Provider | Tip | Opis |
|---|---|---|
| `discoverAreaProvider` | `Provider<DiscoverArea>` | Kombinuje `userLocationProvider` (GPS ili fallback), `matchingFiltersProvider` i auth korisnika. Grad = eksplicitni filter grada ili grad korisnika (`SerbiaLocations.resolveCityId`). Bez grada → GPS + radius filtera. Sa gradom: origin = GPS ako nije fallback i ≤30 km od centra grada, inače centar grada; radius = `max(radius, 30)` ako je grad eksplicitno izabran, inače radius filtera. |
| `discoverProfilesProvider` | `Provider<List<DiscoverProfile>>` | **Uvek vraća `mockDiscoverProfiles`** (seed za lokalni repo). |
| `discoverRepositoryProvider` | `Provider<DiscoverRepository>` | Vidi tabelu gore. |
| `discoverFeedControllerProvider` | `NotifierProvider<DiscoverFeedController, List<DiscoverProfile>>` | Paginacija. |
| `liveDiscoverProfilesProvider` | `Provider<List<DiscoverProfile>>` | Samo prosleđuje feed kontroler. |
| `discoverFeedProvider` | `Provider<List<DiscoverProfile>>` | Feed minus sakriveni sadržaj (`hiddenContentProvider`), blokirani vlasnici (`blockedUserIdsProvider`), sopstveni psi (po uid i po `ownerDogsProvider` id-jevima); sortirano `compareFeedOrder`. |
| `discoverControllerProvider` | `NotifierProvider<DiscoverController, DiscoverState>` | Stanje ekrana. |

`DiscoverFeedController` (`pageSize = 15`): javni getteri `hasMore`, `isLoadingMore`. `build()` resetuje paging pri promeni oblasti/auth-a; ako `firestoreAuthReadyProvider` nije `true` ili nema uid → `[]` (**što znači da se i u lokalnom/mock režimu feed prikazuje samo ako postoji prijavljen korisnik i auth-ready je true – vrednost tog providera u lokalnom režimu je van slice-a, nije provereno**). Sluša `watchProfiles`, permission-denied loguje i prazni. `Future<void> loadMore()`: pri prvom pozivu dohvati „seed” stranicu samo da dobije kursor posle prve stranice (dupli read prvih 15), zatim sledeću stranicu, dedup i dodaje u `_older`.

`DiscoverController`:
- `build()`: `myDog = currentDiscoverDogProvider` (ako je šetnja aktivna u `walkControllerProvider` → `walking: true`, `activityStatus` = statusMessage ili `'U šetnji'`); `catalog = matchingFilters.apply(discoverFeed).where(area.allows)`.
- `void setQuery(String)`, `void setCategory(DiscoverCategory)`.
- `Future<bool> swipe(DiscoverProfile target, String action)` – uid iz auth ili **`'local-user'`**, likerName = displayName ili email ili `'Neko'`, `myDogId = state.myDog.id`.
- `Future<bool> sendSuperLike(DiscoverProfile target)` – isto.
- `void resetFilters()` – briše query/kategoriju i postavlja `MatchingFilters()` (time i radius 20 → sinhronizuje AppSettings).

#### `discoverImageFactoryProvider` – `discover/presentation/discover_image.dart`
`Provider<DiscoverImageFactory>` → `appImageProvider`. U `lib/` se ne koristi (ni `discoverImageOf`); override-uje se u testovima (`test/discover_test.dart`, `profile_test.dart`, `chat_test.dart`, `map_test.dart`, `adoption_test.dart`, `nis_places_test.dart`, `widget_test.dart`).

#### `showMatchDialogIfNeeded({context, ref, matched, isMatch})` – `match_dialog.dart`
Pre async-a hvata `myDog`, `chatInboxProvider.notifier`, `Navigator`; prikazuje `MatchDialog`; „Pošalji poruku” → `chatInbox.openFromMatch(matched)` → push `ChatScreen(conversationId)`.

#### `DogsRepository` – `dogs/domain/dogs_repository.dart`
- `Stream<List<Dog>> watchByOwner(String ownerId)`
- `Future<Dog> createFirstDog({required AppUser owner, required DogDraft draft})`
- `Future<void> updateDog(Dog dog, {int ageMonths = 0})`
- `Future<void> deleteDog(String dogId, {required String ownerId})`

#### `DogsRepositoryImpl` – `dogs/data/dogs_repository_impl.dart`
- `watchByOwner`: prazan id → `[]`; `dogs.where(ownerId ==).snapshots(includeMetadataChanges: true)` filtrira prazne snapshote iz keša; guarded (`dogs.watchByOwner`).
- `createFirstDog`: oblast iz vlasnika (`cityId`+`neighborhoodId`), inače iz drafta (`_resolveArea`, baca `DogsException('Izaberite grad i naselje.')`), inače samo grad vlasnika, inače `null`. Koordinate = **centar grada** (`GeoCoord.forCityId`), ne GPS. Upisuje novi `dogs/{autoId}` (sva polja – vidi Firestore sekciju), `location` u formatu **„Grad - Naselje”**, `isWalking: false`, `energyLevel` default `moderate`. Zatim **neawaitovano** `users/{uid}` merge (uid, name, email, city, cityId, cityName, neighborhoodId/Name, `primaryDogId`, updatedAt, **`createdAt` prepisuje se svaki put**, ugnježden `dog` objekat). Svaka greška osim `DogsException` se guta i baca generički `DogsException()`.
- `updateDog`: merge set na `dogs/{id}` sa svim poljima, `location = dog.location` (format **„Grad, Naselje”** iz `SerbiaLocations.formatPlace`), `ageMonths` (parametar ako >0), `area`, foto polja, `updatedAt`.
- `deleteDog`: čita sve `dogs where ownerId == ownerId`, briše one čiji je doc.id ili polje `id` jednak traženom (batch). **Ne briše podkolekcije** (`likes`, `health_records`, `reminders`) niti otkazuje zakazane notifikacije.
- `_dogFromDoc`: parsiranje sa legacy fallbackom; nepoznat temperament → **`friendly`**; `sterilized` čita samo `isSterilized` (za razliku od mappera koji čita i `sterilized`).

#### `LocalDogsRepository` – `dogs/data/local_dogs_repository.dart`
In-memory lista + broadcast stream; `createFirstDog` id `local-{millis}`, oblast iz vlasnika ili drafta (fallback Novi Sad / Liman 1 ili prvo naselje grada); `updateDog` upsert; `deleteDog` ignoriše `ownerId`.

#### `dog_providers.dart`
- `dogsRepositoryProvider` – `Provider<DogsRepository>`.
- `localOwnerDogsProvider` – `NotifierProvider<LocalOwnerDogs, List<Dog>>`; metode `replace(List<Dog>)`, `upsert(Dog)`, `remove(String)`. Služi kao optimistički overlay.
- `ownerDogsProvider` – `StreamProvider<List<Dog>>`: bez korisnika `[]`; dok Firebase auth token nije spreman vraća samo lokalne; inače `_mergeOwnerDogs(remote, local)` – lokalni overlay pobeđuje kad god se bilo koje polje razlikuje (`_preferLocalOverlay`). Napomena: overlay se uklanja samo eksplicitno (`remove`), pa ako se Firestore vrednost kasnije promeni sa drugog uređaja, lokalni overlay i dalje pobeđuje dok provider živi.

#### `HealthRepository` / implementacije
- Apstraktno: `watchRecords(dogId)`, `Future<String> saveRecord(HealthRecord)` (create ili replace, vraća id), `deleteRecord({dogId, recordId})`.
- `FirestoreHealthRepository({required firestore})`: `dogs/{dogId}/health_records`, sortirano po `administeredDate` desc; `saveRecord` merge set (vidi polja niže) sa `debugPrint` na grešku i rethrow; `_fromDoc` – nepoznata kategorija → `vaccineRabies`, nedostajući `administeredDate` → `DateTime.now()`.
- `LocalHealthRepository({seed})`: id `health-{n}`, `dispose()`.

#### `ReminderRepository` / implementacije
- Apstraktno: `watchReminders(dogId)`, `Future<String> saveReminder(DogReminder)`, `deleteReminder({dogId, reminderId})`.
- `FirestoreReminderRepository`: `dogs/{dogId}/reminders`, sortirano po `date` asc; `saveReminder` merge set (vidi polja), `createdAt` samo za novi; legacy `customIntervalDays` → count u danima.
- `LocalReminderRepository({seed})`: id `reminder-{n}`, postavlja `createdAt`/`updatedAt`, `dispose()`.

#### Zdravstveni karton – `dogs/presentation/health/health_controller.dart`
| Provider | Tip |
|---|---|
| `healthRepositoryProvider` | `Provider<HealthRepository>` |
| `healthRecordsProvider` | `StreamProvider.family<List<HealthRecord>, String>` (po dogId) |
| `latestHealthRecordsProvider` | `Provider.family<Map<HealthCategory, HealthRecord>, String>` – najnoviji zapis po kategoriji (po `administeredDate`) |
| `healthControllerProvider` | `Provider<HealthController>` |

`HealthController`:
- `Future<HealthSaveResult> save({required HealthRecord record, required String dogName, required bool withReminder})` – sačuva zapis, izračuna `notificationId = notificationIdFor(recordId)`, otkaže staru notifikaciju, ako je `withReminder && nextDueDate != null` zakazuje `notificationService.scheduleHealthReminder` (prema `NotificationService`, van slice-a: u **09:00 na dan roka**) sa naslovom „🐾 {pas} — podsetnik” i telom „{pas}: danas je rok za "{title}".”; ako se stanje „ima podsetnik” promenilo, ponovo upisuje zapis sa/bez `notificationId`.
- `Future<void> delete(HealthRecord record)` – otkazuje notifikaciju, briše zapis.

#### Podsetnici – `dogs/presentation/health/reminder_controller.dart`
| Provider | Tip |
|---|---|
| `reminderRepositoryProvider` | `Provider<ReminderRepository>` |
| `dogRemindersProvider` | `StreamProvider.family<List<DogReminder>, String>` – stream repozitorijuma kroz `asyncMap(controller.rollForwardDueReminders)` |
| `activeDogRemindersProvider` | `Provider.family<List<DogReminder>, String>` – samo `isActive`, sortirano po datumu |
| `reminderControllerProvider` | `Provider<ReminderController>` |

`ReminderController`:
- `Future<ReminderSaveResult> save({required DogReminder reminder, required String dogName})` – normalizuje (`repeatDayOfMonth ?? date.day`, custom count >0), sačuva, otkaže staru notifikaciju, ako nije završen zakazuje `scheduleHealthReminder` za `notifyDate` (datum − offset; u 09:00 prema NotificationService) sa naslovom `typeShortLabel(type)` i telom „{pas}: {naslov} — {datum}”; zatim drugi upis sa `notificationId` (uvek za novi podsetnik ili kad se stanje promenilo).
- `Future<List<DogReminder>> rollForwardDueReminders(List<DogReminder> items, {DateTime? now, String dogName = ''})` – za svaki ponavljajući podsetnik čiji je datum prošao računa `rolledForward` i ako se datum promenio poziva `save` (upis + nova notifikacija). Pošto se poziva iz `dogRemindersProvider` bez `dogName`, telo notifikacije posle roll-forward-a počinje sa „: …” (bez imena psa).
- `Future<void> delete(DogReminder reminder)` – otkazuje notifikaciju, briše.

Napomena: u UI-ju slice-a **ne postoji akcija „označi kao završeno”** (`isCompleted: true` se nigde ne postavlja), pa jednokratni podsetnici ostaju u grupi „PROŠLO” dok se ručno ne obrišu.

#### Onboarding psa – `dogs/presentation/onboarding/dog_onboarding_controller.dart`
`dogOnboardingControllerProvider` – `NotifierProvider<DogOnboardingController, DogOnboardingState>`. `stepCount = 3`. `build()` gleda uid (reset pri promeni korisnika). Interno `StorageService()`.

Javne metode:
- `void updateDraft(DogDraft)` – takođe briše grešku.
- `String? validateCurrentStep()` – korak 0: ime, rasa, pol obavezni, starost 0–30, `ContentValidationService.validateText` za ime i rasu; korak 1: veličina i bar jedan temperament; korak 2: greška samo ako je slika više od `AppStrings.maxDogPhotos` (slike nisu obavezne, a poruka je `dogPhotosRequired`).
- `bool nextStep()`, `void previousStep()`.
- `Future<void> addPhotos()` – `uploadImagesFromGallery(folderName:'pets', limit: preostalo)`; slike se **odmah** uploaduju u Storage (pre nego što pas postoji).
- `Future<void> addFromCamera()` – `uploadImageFromCamera('pets')`; nije u try/catch (izuzetak iz storage-a bi ostavio `uploadingPhotos = true`).
- `void removePhoto(int index)` – uklanja iz drafta i neawaitovano briše iz Storage-a.
- `void toggleTemperament(DogTemperament)`, `void toggleLike(String)`, `void toggleDislike(String)`.
- `Future<Dog?> submit()` – validira, zahteva prijavljenog korisnika (`AppStrings.mustBeSignedIn`), seed-uje grad/naselje vlasnika u draft, `createFirstDog(...).timeout(20s)`.
- `void applyCreatedDog(Dog dog)` – dodaje u `localOwnerDogsProvider`, pretvara u `DiscoverProfile` i poziva `profileController.save(...)` sa novim psom kao izabranim (što u Firebase režimu ponovo upisuje profil vlasnika i poziva `updateDog` za **sve** pse u profilu).

Koraci: 0 `BasicsStep`, 1 `PersonalityStep`, 2 `PhotosStep`. `AreaStep` postoji ali nije u toku (oblast se uzima iz vlasnika).

#### Profil – `profile/presentation/profile_controller.dart`

| Provider | Tip |
|---|---|
| `profileControllerProvider` | `NotifierProvider<ProfileController, UserProfile>` |
| `matchingFiltersProvider` | `NotifierProvider<MatchingFiltersController, MatchingFilters>` |
| `appSettingsProvider` | `NotifierProvider<AppSettingsController, AppSettings>` |
| `currentDiscoverDogProvider` | `Provider<DiscoverProfile>` – izabrani pas; **ako korisnik nema pasa vraća `mockUserProfile.dog` (mock Luna, id `my-dog`)** |

`ProfileController` (`_localDemoDogId = 'local-luna'`):
- `build()`: lokalni režim → `mockUserProfile` ako nema kreiranih pasa; Firebase bez korisnika → prazan profil; sa psima → `_fromDogs`; bez pasa ali sa legacy `user.dog.hasProfile` → profil iz `users.dog`; inače prazan.
- `void selectDog(String dogId)`.
- `void save(UserProfile profile)` – postavlja state; u Firebase režimu neawaitovano `authRepository.saveUserProfile(user, city, name, bio, cityId, neighborhoodId, neighborhoodName, writeDog:false)` i za **svaki** pas `dogsRepository.updateDog(dogFromDiscover(dog, area: oblast vlasnika))` – tj. izmena vlasnika menja lokaciju svih pasa.
- `void saveDog(DiscoverProfile dog)` – normalizuje pol/veličinu, ažurira state, upisuje optimistički overlay u `localOwnerDogsProvider`, neawaitovano `updateDog`, a ako je to primarni pas (`user.dog.id`) ili nema primarnog → `saveUserProfile(dog: …, writeDog:true)`.
- `Future<void> deleteDog(String dogId)` – ne dozvoljava brisanje poslednjeg psa; optimistički uklanja, `deleteDog(...).timeout(20s)`, pri grešci vraća stanje i rethrow; uklanja overlay; ako je obrisan primarni pas, ažurira `users.dog` na sledećeg.
- `Future<void> saveOwnerCustomPhoto(String url)` – `authRepository.saveOwnerCustomPhoto(uid, customPhotoUrl)` + `ref.invalidate(authStateProvider)`.

`MatchingFiltersController`: `build()` → `MatchingFilters()` (**nije perzistentno**, osim radiusa preko AppSettings); `void apply(MatchingFilters)` – postavlja i `appSettings.syncRadiusFromFilters(radius)`.

`AppSettingsController` (perzistencija podešavanja):
- `build()` vraća default i pokreće asinhrono `_hydrate()` iz `AppSettingsStore.read()`; posle čitanja postavlja jezik (`L10n.setLanguage`) i sinhronizuje radius u filtere.
- `Future<void> ensureReady()` – čeka prvo čitanje.
- `void update(AppSettings)` – postavlja jezik, state, sinhronizuje radius, neawaitovano `AppSettingsStore.write`.
- `void setLanguage(AppLanguage)`, `void setThemePreference(AppThemePreference)`.
- `void syncRadiusFromFilters(double)` – upis samo posle hidracije.

#### `AppSettingsStore` – `profile/data/app_settings_store.dart`
`static Future<AppSettings> read()` (greška → default) i `static Future<void> write(AppSettings)` (greške se gutaju). Ključevi u sekciji Firestore/Storage niže. Notifikacioni prekidači se čuvaju **samo lokalno** (u slice-u nema upisa u Firestore); koriste ih `push_controller.dart`, `incoming_message_sound.dart`, `walk_controller.dart` (van slice-a).

#### Akcije naloga
- `confirmAndSignOut(BuildContext, WidgetRef)` – dijalog, `authControllerProvider.notifier.signOut()`, `popUntil(isFirst)`, snackbar na grešku.
- `confirmAndDeleteAccount(BuildContext, WidgetRef)` – dijalog (sa linkom na politiku privatnosti), `auth.deleteAccount()`, `popUntil(isFirst)`; šta se tačno briše implementirano je u auth modulu (van slice-a); tekst dijaloga tvrdi da se brišu psi, slike, momenti, poruke, mečevi, oglasi, događaji i podešavanja – nije provereno u ovom delu.

### 7.4 Mapa, mesta i alati (tool/)
#### Pregled providera

| Provider | Fajl | Tip | Šta vraća |
|---|---|---|---|
| `mapRegionProvider` | `cities_controller.dart:57` | `NotifierProvider<MapRegionController, MapRegionSelection>` | izabrani region mape |
| `citiesRepositoryProvider` | `cities_controller.dart:62` | `Provider<CitiesRepository>` | Firestore ili Local (po `isFirebaseReady`) |
| `citiesProvider` | `cities_controller.dart:69` | `StreamProvider<List<CityModel>>` | aktivni gradovi |
| `placesRepositoryProvider` | `cities_controller.dart:73` | `Provider<PlacesRepository>` | Firestore ili Local |
| `livePlacesProvider` | `cities_controller.dart:80` | `StreamProvider<List<MapPlace>>` | admin mesta iz `places` |
| `mapsLauncherProvider` | `maps_launcher.dart:34` | `Provider<MapsLauncher>` | launcher navigacije |
| `poiReportsProvider` | `poi_report_controller.dart:164` | `NotifierProvider<PoiReports, Set<String>>` | id-jevi prijavljenih mesta (samo u memoriji) |
| `poiConfirmationsProvider` | `poi_report_controller.dart:177` | `NotifierProvider<PoiConfirmations, Set<String>>` | id-jevi potvrđenih mesta (samo u memoriji) |
| `poiRepositoryProvider` | `user_poi_controller.dart:12` | `Provider<PoiRepository>` | Firestore ili Local |
| `livePoisProvider` | `user_poi_controller.dart:19` | `StreamProvider<List<PoiModel>>` | svi dokumenti `pois` |
| `userPoiSubmissionsProvider` | `user_poi_controller.dart:126` | `NotifierProvider<UserPoiSubmissions, List<PoiModel>>` | svi `pois` (ne samo korisnički!) |
| `pendingPoisProvider` | `user_poi_controller.dart:131` | `Provider<List<PoiModel>>` | `pois` sa statusom `pending`/`userSubmitted` (koristi admin dashboard) |
| `walkControllerProvider` | `walk_controller.dart:254` | `NotifierProvider<WalkController, WalkSession>` | aktivna šetnja |
| `mapPlacesProvider` | `walk_controller.dart:257` | `Provider<List<MapPlace>>` | finalna, spojena lista mesta za mapu (koristi i `events_controller.dart:208`) |
| `walkPresenceRepositoryProvider` | `walk_controller.dart:305` | `Provider<WalkPresenceRepository>` | Firestore ili Local |
| `liveWalkingDogsProvider` | `walk_controller.dart:312` | `StreamProvider.autoDispose<List<WalkingDogPin>>` | živi šetači (samo kad je tab Mapa aktivan) |
| `walkingDogsProvider` | `walk_controller.dart:339` | `Provider<List<WalkingDogPin>>` | šetači filtrirani po radijusu oko korisnika |
| `walkHistoryRepositoryProvider` | `walk_history_controller.dart:9` | `Provider<WalkHistoryRepository>` | Firestore ili Local |
| `walkHistoryProvider` | `walk_history_controller.dart:16` | `FutureProvider.autoDispose<List<WalkRecord>>` | šetnje poslednjih 7 dana za ulogovanog korisnika |

#### `MapRegionController` (`cities_controller.dart:34`)
- `build()` – čita `homeCityProvider`; ako nema domaćeg grada → `myLocation`. Inače `SeedCities.byId(home.mapCityId, available)` gde je `available` iz `ref.read(citiesProvider)` (**read, ne watch** – ne rebuild-uje se kad gradovi stignu iz Firestore-a). `mapCityId` (u `home_city_provider.dart:17`) pretvara `_` u `-` (npr. `novi_sad` → `novi-sad`).
- `void selectMyLocation()`; `void selectCity(CityModel city)`.
- Funkcija `GeoCoord mapRegionCenter(MapRegionSelection, GeoCoord userCoord)` – centar grada ili korisnikova koordinata.

#### `CitiesRepository`
- `Stream<List<CityModel>> watchActive()`.
- `FirestoreCitiesRepository`: sluša celu kolekciju `cities` (kroz `FirestoreAuthGuard.guardedStream`, fallback `SeedCities.all`), mapira dokument (`lat`|`latitude`, `lng`|`longitude`, default 0; `radiusKm` default 15; `isActive` default true), uzima aktivne, spaja sa seed gradovima (`mergeWith`) i **izbacuje seed grad ako u Firestore-u postoji isti id sa `isActive: false`**.
- `LocalCitiesRepository`: emituje `SeedCities.all`.

#### `PoiRepository` / `FirestorePoiRepository` (`firestore_poi_repository.dart`)
- `Stream<List<PoiModel>> watchAll()` – `pois.snapshots()` bez upita/limita; fallback prazna lista.
- `Future<void> upsert(PoiModel poi)` – `pois/{id}.set(_toMap, merge: true)`.
- Mapiranje: nepoznata kategorija → `PoiCategory.park` (`:126`); nepoznat `city` → `MapCity.noviSad` (`:135`); ako `lastVerified` nije `Timestamp` → `DateTime.now()` (`:65`, posledica: bedž „✓ Potvrđeno · <današnji datum>“); `source` default `'VauVau'`; `petFriendly` default `true`.
- `LocalPoiRepository`: in-memory; `watchAll` vraća `Stream.value` snimka liste (ne emituje kasnije izmene).

#### `PlacesRepository` / `FirestorePlacesRepository` (`places_repository.dart`)
Komentar (`:38-40`): `places` je „source of truth“, svaka izmena se preslikava u `pois` istim WriteBatch-om.
- `Stream<List<MapPlace>> watchPlaces()` – `places.snapshots()`; preskače dokumente bez imena. `_fromDoc` čita samo: `id, name, latitude, longitude` (ili `location` GeoPoint), `category`, `cityId`, `isVerified` (**default `true`**), `verificationStatus`, `address`, `phone`, `openingHours`, `isDogPark`. `lastVerified` = `DateTime.now()`, `source` = `'Admin'`.
- `Future<String> createPlace(PlaceDraft)` – novi auto-id; batch: `places/{id}` (sa `isVerified: true`, `verificationStatus: 'verified'`, `createdAt` server timestamp) i `pois/{id}` (merge, `source: 'Admin'`, `lastVerified` server timestamp). Vraća id.
- `Future<void> updatePlace(PoiModel)` – baca `ArgumentError` ako je id prazan; batch merge u `places/{id}` (podskup polja + `isVerified`, `updatedAt`) i `pois/{id}` (sva polja + `updatedAt`).
- `Future<void> deletePlace(String placeId)` – batch delete u obe kolekcije.
- Kategorije: `places.category` je snake_case ključ (`pet_shop`, `dog_hotel`, `self_wash`, `dog_treats`, `pet_sitter`), a `pois.category` je enum ime (`petShop`…). `_categoryFromKey` prihvata i srpske sinonime (`kafic`, `restoran`, `veterinar`, `dresura`, `pansion`, `perionica`, `hrana`, `azil`, `voda`); nepoznato → `park`.
- `LocalPlacesRepository`: in-memory + broadcast StreamController.
- Admin repozitorijumi (`admin/data/firestore_admin_repository.dart:74-80`, `local_admin_repository.dart:60-66`) samo delegiraju `createPlace/updatePlace/deletePlace` na ovaj repozitorijum.

#### `UserPoiSubmissions` (`user_poi_controller.dart:23`)
- `build()` – ako Firebase nije spreman `[]`, inače **cela lista `pois`** iz `livePoisProvider` (ime „submissions“ je zavaravajuće).
- `Future<void> add(PoiModel)` – bez admin provere; sa Firebase-om `poiRepository.upsert` (direktno u `pois`), inače lokalno u state.
- `Future<void> updatePoi(PoiModel)` – samo admin (`StateError('Admin only')`); poziva `adminRepository.updatePlace` (places + pois batch).
- `Future<void> deletePoi(String id)` – samo admin; `adminRepository.deletePlace`.
- `PoiModel? findById(String id)` – prvo `pois`, pa `PoiSeedData.allVerified`.
- `Future<void> approve(String id)` – traži **samo u state (`pois`)**; ako ne nađe → tiho ne radi ništa (seed mesta se ne mogu odobriti ovim putem). Postavlja `verified` + `lastVerified = now`.
- `Future<void> reject(String id)` – samo admin; status `rejected`.

#### `PoiReports` / `PoiConfirmations` (`poi_report_controller.dart`)
- `PoiReports.report(String id)` – dodaje id u lokalni Set (nije perzistentno).
- `PoiReports.submitChangeRequest({placeId, placeName, changeType, description, markAsReported = true})` – zahteva prijavljenog korisnika (`FirebaseAuth.instance.currentUser`), inače `StateError('Morate biti prijavljeni…')`. Bez Firebase-a samo `debugPrint` + lokalni report. Sa Firebase-om: (1) `users/{uid}.placeChangeRequests` `arrayUnion(entry)` (brza putanja), (2) lokalni `report(id)` ako `markAsReported`, (3) u pozadini (`unawaited`) dodaje dokumente u `notifications`, `change_requests`, `admin_notifications`, `reports` – greške samo loguje.
- `PoiConfirmations.confirm(String id)` – lokalni Set (nije perzistentno).

#### `WalkController` (`walk_controller.dart:30`) – šetnja
- `build()` – registruje dispose tajmera/GPS stream-a i sluša `appSettingsProvider.showLocationOnMap`: ako se promeni tokom aktivne šetnje → `setWalking(isWalking: share, …)`.
- `void start({String? statusMessage})` – resetuje stanje sa početnom tačkom = trenutna `userLocationProvider.coord`; tajmer od 1 s osvežava `now`; **uvek** poziva `setWalking(isWalking: true, location: startCoord, statusMessage)` (komentar `:83-85`: status se uvek objavljuje zbog Discover kartica; deljenje *živih* ažuriranja zavisi od `showLocationOnMap`). Pretplaćuje se na `locationClientProvider.watchWalkPosition()`; prihvaćene tačke ažuriraju `userLocationProvider` i, ako je deljenje uključeno, `updateLocation`.
- `void pause()` / `void resume()` – pauza računa `pausedTotal`; tokom pauze tačke se ignorišu.
- `Future<void> stopForSignOut()` – zaustavlja sve i briše `isWalking` u Firestore-u pre odjave (poziva `auth_controller.dart:85,111`).
- `void end()` – gasi tajmer i GPS, `setWalking(isWalking: false)`, i ako je `userId` stvaran (nije `'local-user'`) i (trajanje ≥ 30 s ili distanca ≥ 0,05 km) čuva `WalkRecord` (`id = 'walk-<ms>'`) i invalidira `walkHistoryProvider`.
- `_appendPoint` – odbacuje skokove < 4 m (`step < 0.004` km) kao GPS šum; distanca je zbir haversine koraka.
- `_userId` = Firebase uid ili `'local-user'`; `_dogId` = `currentDiscoverDogProvider.id`.

#### Walk presence – „ko je trenutno u šetnji“
- `FirestoreWalkPresenceRepository.setWalking({userId, dogId?, isWalking, location, statusMessage?})` – piše `firestoreLocationFields` (`isWalking`, `lastKnownLocation` GeoPoint, `geohash`, `latitude`, `longitude`) + `walkStartedAt` (server timestamp / `FieldValue.delete()`) + `walkStatus`. Piše u `users/{uid}` i u `dogs/{dogId}`; ako `dogId` nije dat, upitom `dogs where ownerId == uid` piše u **sve** pse vlasnika.
- `updateLocation({userId, dogId?, location})` – isto, samo lokacijska polja.
- `watchWalking({excludeUserId})` – `dogs where isWalking == true limit 50` (`maxLiveWalkers = 50`); preskače dokumente bez koordinata i pse trenutnog korisnika; profil se gradi preko `discoverProfileFromMap`; prazan status → `'<ime> je u šetnji.'` (hardkodovano, ne L10n).
- `liveWalkingDogsProvider` – aktivan samo kad je `homeTabIndexProvider == 1` (tab Mapa, hardkodovan indeks) i kad je Firestore auth spreman.
- `walkingDogsProvider` – filtrira pinove po `GeoQuery(origin: korisnikova lokacija, radiusKm: matchingFiltersProvider.radiusKm)`. Bez Firebase-a koristi `mockWalkingDogs` (prazna lista). `MapScreen` zatim dodatno filtrira po radijusu izabranog regiona – ako je izabran drugi grad, šetači oko korisnika praktično ne prolaze oba filtera (posledica koda; nije testirano).
- Ne postoji automatsko „isticanje“ prisustva (TTL) u ovom kodu: ako aplikacija padne tokom šetnje, `isWalking: true` ostaje u Firestore-u dok se ne pozove `end`/`stopForSignOut`. (Da li postoji serverska Cloud Function za čišćenje – nije u ovom delu koda, nepoznato.)

#### Walk history (`walk_history_repository.dart`)
- `save(WalkRecord)` – (1) `users/{uid}.walkHistory` `arrayUnion(payload)` (komentar: „pouzdana putanja, radi sa trenutnim pravilima“), (2) best-effort `users/{uid}/walks/{walkId}.set(payload)` (greška samo `debugPrint`).
- `fetchRecent({userId, days = 7})` – čita podkolekciju (`endedAt >= cutoff`, `orderBy endedAt desc`, `limit 50`) i niz `walkHistory` iz user dokumenta, spaja po id-u, sortira opadajuće. Niz `walkHistory` u user dokumentu nema ograničenje rasta.
- `LocalWalkHistoryRepository` – in-memory.

#### Spajanje mesta (`mapPlacesProvider`, `walk_controller.dart:257-303`)
Redosled (poslednji pobeđuje po `id`):
1. **Seed** – `mockMapPlaces` = `PoiSeedData.allVerified` (Novi Sad + Beograd + Niš + Kragujevac) + 9 `catalogServicePlaces` (Novi Sad).
2. **`pois`** iz Firestore-a (`userPoiSubmissionsProvider`) – i korisnički predlozi (`pending`) i admin mirror-i i bilo šta drugo u kolekciji.
3. **`places`** (admin SoT, `livePlacesProvider`).

Na svako mesto se primenjuju „community flagovi“ iz tekuće sesije: ako je id u `poiConfirmationsProvider` → `verified` + `lastVerified = now`; inače ako je u `poiReportsProvider` → `reported` + `petFriendly = false`. Funkcija `put` preskače mesta sa statusom `rejected`, sakrivena (`hiddenContentProvider`, moderacija) i sa nevažećim koordinatama.

Bitne posledice logike:
- `pending`/`userSubmitted`/`reported`/`unknown` mesta se **prikazuju** na mapi (samo sa drugačijim bedžom); filtrira se samo `rejected`.
- `put` za `rejected` samo „preskoči“ – **ne briše** prethodni unos sa istim id-em. Ako admin odbije ili obriše mesto koje postoji i u seed-u, seed verzija ostaje na mapi.
- Admin izmena seed mesta kreira `places/{id}`; pošto `places._fromDoc` ne čita `website`, `is24_7`, `isEmergencyService`, `overnightStay`, `dayCare`, `hasYard`, `pricePerNight`, `petFriendly`, `municipality`, `description`, `sourceUrl`, `rating`, sponzorska polja – ta polja **nestaju sa prikaza** za to mesto, iako su upisana u Firestore.

#### Rukovanje gradovima (city id)
- Kanonski id-jevi: `novi-sad`, `beograd`, `nis`, `kragujevac` (`SeedCities`, `MapCityX.cityId`).
- `MapCityX.fromCityId` toleriše varijante `novi_sad`, `novisad`, `belgrade`, `niš`.
- `homeCity.mapCityId` menja `_` u `-`.
- `MapScreen._placeInRegion` (`map_screen.dart:565-582`): mesto je u regionu ako `place.cityId == region.cityId` (tačno poređenje stringa), ili ako `place.city != other` i `place.city.cityId == region.cityId`, inače ako je unutar `region.radiusKm` od centra grada. Zato POI sa `cityId: 'novi_sad'` i `city: noviSad` ipak upada u Novi Sad; POI sa `city: other` zavisi samo od udaljenosti.
- Gradovi dodati samo u Firestore (`cities`) mapiraju se u `MapCity.other` u POI modelu (`'city': 'other'` u `pois`).

#### Geokodiranje
- U aplikaciji: `AddressGeocoder.search(String query)` → `Future<List<GeocodeSuggestion>>`. Upit < 3 znaka → `[]`; HTTP greška ili ne-lista → `[]`. Koristi ga samo `AddPlaceScreen._searchAddress` (upit = `adresa, ime grada, Srbija`), samo na klik dugmeta (nema debounce/autocomplete). Nema keširanja ni ograničenja broja zahteva.
- Van aplikacije: PowerShell skripte u `tool/` (vidi „Podaci o lokacijama“).

#### Map tiles
`buildOsmTileLayer` (`osm_tile_layer.dart:15`): `urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'`, `userAgentPackageName: 'com.vauvau.app'`, `maxZoom` 19 (18 u admin mini-mapi), `RetryClient` (1 ponovni pokušaj za status ≥ 500), `silenceExceptions: true`, `BuiltInMapCachingProvider` 256 MB, `overrideFreshAge` 7 dana; greške tile-ova se samo loguju u debug modu. Koristi se direktno javni OSM tile server (nema API ključa, nema alternativnog provajdera).

#### Maps launcher
`MapsLauncher.openDirections({latitude, longitude, label?})` → `Future<bool>`: redom pokušava
1. `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>&travelmode=walking`
2. `http://maps.apple.com/?daddr=<lat>,<lng>`
3. `geo:<lat>,<lng>?q=<label (lat,lng)>`

Svaki se otvara sa `LaunchMode.externalApplication`. `label` se koristi samo u `geo:` varijanti.

### 7.5 Priče, izgubljeni psi, udomljavanje, moderacija, notifikacije, podrška, admin
Opšti obrazac u svim modulima: `*RepositoryProvider` vraća Firestore implementaciju ako je `isFirebaseReady`, inače Local (in-memory) implementaciju.

#### Moments

**`MomentsRepository`** (interfejs): `watchMoments({limit = 20})`, `fetchMomentsPage({cursor, limit = 20})`, `watchComments(momentId)`, `toggleLike`, `toggleCommentLike(momentId, commentId)`, `addComment(momentId, text)`, `createMoment(MomentModel) → Future<String>`, `deleteMoment`.

**`FirestoreMomentsRepository(firestore, currentUserId, authorName)`**:
- `_uid`: injektovani uid ili `FirebaseAuth.instance.currentUser?.uid`.
- `_resolveAuthorName`: prvi neprazan i različit od "Korisnik" od (kandidat, authorName, displayName), inače "Korisnik".
- `watchMoments`: `moments.orderBy('createdAt', desc).limit(limit)` kroz `FirestoreAuthGuard.guardedStream` (label `moments.watchMoments`).
- `fetchMomentsPage`: ako cursor nije `DocumentSnapshot`, prvo dohvati prvih `limit` (live prozor) i kreće posle poslednjeg; `hasMore = docs.length >= limit`.
- `watchComments`: `moments/{id}/comments.orderBy('createdAt')`.
- `toggleLike` / `toggleCommentLike`: transakcija nad nizom `likes` (read-modify-write, ne `arrayUnion`).
- `addComment`: `add` u `comments`, pa **zasebna** transakcija `commentsCount + 1` (nije atomično sa upisom komentara).
- `createMoment`: zahteva URL slike; `gs://` konvertuje preko `StorageService().resolveDownloadUrl`; mora biti `http(s)`. Podrazumevane vrednosti: dogName "Pas", dogPhotoUrl `kFallbackDogPhotoUrl`, locationName "Novi Sad".
- `deleteMoment`: samo `doc(id).delete()` – **ne briše** podkolekciju `comments`, fajl u Storage-u, niti ID iz istaknutih (`resolveHighlight` samo preskače nepostojeće).

**`MomentsController`** (`NotifierProvider<…, AsyncValue<List<MomentModel>>>`, `momentsControllerProvider`):
- `pageSize = 15`; `hasMore`, `isLoadingMore`.
- `build`: ako `firestoreAuthReadyProvider` nije true → keš ili prazno; inače sluša `watchMoments(limit: 15)` i spaja live listu sa `_older` (dedupe po id). `permission-denied` → prazno + log.
- `reload()`, `loadMore()`, `toggleLike`, `toggleCommentLike`, `addComment`, `delete(momentId)`.
- `create({draft, XFile? photo})`: `ContentValidationService.validateImage` → `StorageService().uploadXFile(file, folderName: 'moments')` → resolve gs → mora biti https → `createMoment`.

Ostali provideri:
- `momentsRepositoryProvider` – Firestore ako `isFirebaseReady` && uid neprazan && auth spreman; inače Local (uid `local-user`, autor "Ti").
- `visibleMomentsProvider` – filtrira autore iz `blockedUserIdsProvider`. (Admin tab koristi nefiltrirani `momentsControllerProvider`.)
- `momentCommentsProvider` – `StreamProvider.family<List<MomentComment>, String>`.
- `momentsMemberIdProvider` – uid ili `''` (Firebase) / `'local-user'`.
- `activeStoryGroupsProvider` – iz `visibleMomentsProvider`, samo `isActiveStory(now)`, grupisano po `dogId` (ili `authorUserId` ako je dogId prazan); unutar grupe najstariji prvi; moje grupe prve, ostale po `latest` opadajuće.
- `seenStoriesProvider`, `hasUnseen(group, seen)`.
- `storyArchiveProvider` – `Provider.family<List<MomentModel>, String dogId>`: sve moje priče za psa (i istekle), ali **samo iz trenutno učitanih** u `momentsControllerProvider`.
- `highlightsRepositoryProvider` – Firestore ako `isFirebaseReady` (ne proverava uid/auth), inače Local.
- `dogHighlightsProvider` – `StreamProvider.family<List<StoryHighlight>, String dogId>`.
- `resolveHighlight(highlight, allMoments)` / `highlightCoverUrl` – takođe zavise od učitanih momenata.
- `HighlightActions` (`highlightActionsProvider`): `create`, `update`, `delete`, `reorder`, `toggleMoment(highlight, momentId)`.

**Istek priča (24h) i istaknuto – objašnjenje:**
- Ne postoji serversko brisanje ni TTL: dokumenti ostaju u `moments` zauvek. "Istek" je isključivo klijentski filter `isActiveStory` (24h).
- `activeStoryGroupsProvider` računa `now = DateTime.now()` u trenutku build-a; nema tajmera, pa priča ne nestaje sa ekrana sama kada istekne – tek pri sledećem rebuild-u.
- Feed učitava najnovijih 15 (live) + paginaciju. Ekran Moments prikazuje samo aktivne grupe, pa paginacija učitava i istekle momente koji se ne vide u gridu, ali služe arhivi i istaknutom.
- Istaknuto (`StoryHighlight`) se čuva u mapi `dogs/{dogId}.storyHighlights` (`FirestoreHighlightsRepository`): ID se generiše preko `dogs/{dogId}/_ids.doc().id` (ništa se ne upisuje tamo); `create/update` = `set(merge)`; `delete` = `update('storyHighlights.<id>': FieldValue.delete())`; `reorder` = `update('storyHighlights.<id>.order': i)`. Greške: "Morate biti prijavljeni.", "Pas nije izabran.". Zavisi od pravila za `/dogs` (update vlasnika).
- Istaknuta priča se prikazuje samo ako je odgovarajući moment trenutno učitan u feed-u; starije priče koje nisu učitane neće se pojaviti u istaknutom ni u arhivi za izbor dok korisnik ne skroluje.

#### Lost dogs

**`LostDogRepository`**: `watchLostDogs()`, `watchComments(dogId)`, `reportLostDog(dog, {photo})`, `addComment(dogId, text, {authorName = ''})`, `toggleCommentLike`, `markFound(id)`, `deleteLostDog(id)`.

**`FirestoreLostDogRepository`**:
- `watchLostDogs`: `lost_dogs.limit(40).snapshots()` **bez orderBy** (komentar u kodu: klijentsko sortiranje da nedostajući `createdAt`/indeks ne isprazni feed) – u praksi dobija proizvoljnih 40 dokumenata, ne najnovijih 40. Greške parsiranja se preskaču uz debugPrint.
- `watchComments`: snapshot dokumenta, čita niz `comments` + mapu `commentLikes`, sortira po `createdAt`.
- `reportLostDog`: zahteva prijavljenog korisnika; validacija slike; `ImageUploadService.uploadFile(photo, folderName: 'lost_dogs')`; `add`. `lostDate` i `foundDate` se pišu istom vrednošću.
- `addComment`: ime = authorName || displayName || **email** || "Korisnik"; `arrayUnion([payload])` + `commentsCount` increment.
- `toggleCommentLike`: transakcija, prepisuje celu mapu `commentLikes`.
- `markFound(id)`: `status = 'resolved'`. `deleteLostDog(id)`: briše dokument (slika u Storage-u ostaje).
- `_statusOf`: `'resolved'` ili legacy `'found'` → resolved; `'missing'` → missing; ostalo → active.

**`LostDogsController`** (`lostDogsControllerProvider`, AsyncValue<List<LostDog>>): `reload()`, `report({...}) → Future<bool>` (greška → `print` + false), `addComment` (ime iz `authState.displayName`), `toggleCommentLike`, `markFound`, `deleteLostDog`.

Provideri: `lostDogRepositoryProvider` (ne zavisi od uid-a), `activeLostDogsProvider` (isMissing), `missingLostDogsProvider` (alias istog), `activeFoundDogsProvider` (found && active), `recentMissingLostDogsProvider` (aktivni nestali sa `createdAt` u poslednja 24h), `lostDogReporterIdProvider`, `lostDogCommentsProvider` (family).

**Prijava nestalog/pronađenog psa:** `+` u AppBar-u → `showReportCaseChooser` (izgubljen/pronađen) → `showReportLostDogSheet` → `LostDogsController.report` → dijalog uspeha (za found prelazi na tab Pronađeni).

**Poklapanje (`LostDogMatcher.matchesFor(found, catalog)`):** samo za aktivan found oglas; kandidati su `isMissing` i drugi id. Skor: 0 ako grad nije isti (lowercase/trim); početno 1; isti kvart +4; rasa se poklapa (jednako ili `contains`, osim "nije sigurno"/"drugo"/"nepoznato") +3; preklapanje tokena (≥4 slova, bez stop-reči, regex `[^a-zčćžšđ0-9]+`) iz opisa+imena+rase +2; ako je skor < 2 i kvart nije isti → 0 (sam grad nije dovoljan). Rezultat sortiran po skoru; UI prikazuje prvi match u `_MatchBanner`. `_isUnknownBreed` poredi samo srpske vrednosti – na engleskom UI "Not sure"/"Other" bi se tretirali kao prava rasa.

**Hitni popup:** `LostDogEmergencyHost` omotava home shell (`home_shell_screen.dart:51`, ispod `PushBootstrap`). Prvi put kada `recentMissingLostDogsProvider` nije prazan → post-frame → ako `LostDogPopupStore.hasDismissed()` vrati false → `showLostDogEmergencyDialog(dogs.first)` → `markDismissed()`. Flag je globalan: posle prvog prikaza popup se **nikad više** ne prikazuje, ni za nove pse. Naslov kaže "U TVOJEM GRADU", ali nema filtriranja po gradu korisnika; prikazuje se i autoru prijave. Dijalog: slika, "ime, mesto", datum; dugmad "Razumem / Zatvori", "Prijavi da sam ga video" (sheet za viđenje), "Pozovi vlasnika".

#### Adoption

**`AdoptionRepository`**: `watchAdoptionDogs()`, `getAdoptionDogs()`, `addAdoptionDog(dog, {photos, city, neighborhood})`, `markAdopted(id)`.

**`FirestoreAdoptionRepository({required this._firestore})`** – privatni imenovani parametar (poziva se kao `firestore:`; zahteva noviju Dart verziju).
- `watch/get`: `orderBy('createdAt', desc).limit(20)`; udomljeni se filtriraju tek u UI (broj vidljivih se smanjuje, nema paginacije).
- `add`: zahteva prijavljenog korisnika; upload svake slike (`folderName: 'adoption'`); `location = 'city, neighborhood'`; `uploaderName` = Firebase displayName ili "Korisnik" (**ignoriše** `dog.uploaderName` koji kontroler postavlja iz `profile.ownerName`).
- `markAdopted`: `status = 'adopted'`.
- **Nema metode za brisanje** (ni admin UI za brisanje oglasa).
- `_fromDoc`: `size` podrazumevano `'srednji'`; `imageUrls` = unija `imageUrls` + `photos`; `status` podrazumevano `'available'`.

**`AdoptionController`** (`adoptionControllerProvider`): `reload()`, `publish({...}) → Future<bool>` (greška → `print` + false), `markAdopted(id)`. Greška streama → `AsyncValue.error` uvek (i kada već ima podataka).

Tok udomljavanja: lista → detalj → "Pošalji poruku" (`chatInboxProvider.notifier.openFromMatch(DiscoverProfile(id: dog.id, ownerId: uploaderUserId, ageYears: 0, …))` → `ChatScreen`) ili "Pozovi vlasnika"; vlasnik oglasa ima "Označi kao udomljen".

#### Moderation (prijave i blokiranje)

**`FirestoreBlockedUsersRepository(firestore, currentUserId)`**: `watchBlocked` = ID-evi dokumenata u `users/{uid}/blocked_users`; `block` = set `{blockedAt: serverTimestamp}`; `unblock` = delete.

**`FirestoreReportRepository`**:
- `submit(report)`: uid = FirebaseAuth uid ili `report.reporterId` (greška "Morate biti prijavljeni da biste poslali prijavu."); targetType `'dog_profile'` za dog, inače ime enuma; entry `{id, reporterId, reportedBy, reportedByUserId (sva tri = uid), reportedUserId, targetType, targetId, reason, details, status, createdAt, timestamp (Timestamp.now())}` → `users/{uid}` set merge `contentReports: arrayUnion([entry])`; zatim `unawaited(_mirrorReport)`.
- `_mirrorReport` (best-effort, greške samo debugPrint): (1) `notifications.add` tip `CONTENT_REPORT`, naslov "Prijava sadržaja", primalac je **sam prijavilac**; (2) `reports/{report.id}.set(entry + serverTimestamp)`; (3) `admin_notifications.add` tip `REPORT_POST_OR_PROFILE`.
- `watchAll()`: sluša **ceo** `reports` (bez filtera/limita) **i celu kolekciju `users`**, iz polja `contentReports` i `placeChangeRequests` pravi `ContentReport`-e; dedupe po id (verzija iz `reports` ima prednost); primenjuje optimističke `_statusOverrides`; sort po vremenu opadajuće. Permission-denied → prazno + log.
- `updateStatus({id, status, reporterId})`: optimistički override u memoriji; `reports/{id}.update({status, reviewedAt})`; ako nema reporterId, `_findReporterId` čita SVE `users` dokumente; `_patchUserArrayStatus` prepisuje ceo niz `contentReports`/`placeChangeRequests`.
- `_fromMap` podržava i zahteve za promenu mesta (`description`, `changeType`, `placeId`, `placeName`; targetType podrazumevano `'poi'`; reason "Prijava promene").

Provideri i kontroleri:
- `blockedUsersRepositoryProvider`, `blockedUsersStreamProvider` (Stream<Set<String>>), `blockedUserIdsProvider` (sinhroni Set).
- `BlockController` (`blockControllerProvider`): `isBlocked`, `block`, `unblock`. **`unblock` se nigde u UI ne poziva** – nema ekrana za odblokiranje.
- Filtriranje blokiranih (grep): `moments_controller.dart:246`, `discover_controller.dart:381`, `chat_inbox.dart:271`. **Ne filtrira se** u lost dogs, adoption, komentarima momenata i lost dogs.
- `HiddenContent` (`hiddenContentProvider`): `hide(id)`, samo u memoriji; koriste ga `discover_controller.dart:380`, `walk_controller.dart:263` i `admin_reports_tab.dart:299`.
- `reportRepositoryProvider`, `contentReportsProvider` (Stream – `watchAll`), `activeReportsProvider` (samo pending; koristi se samo u admin panelu).
- `ReportController` (`reportControllerProvider`): `submit({targetType, targetId, reason, reportedUserId, details})` – id `'report-<millis>'` (klijentski), reporterId = uid ili `'local-user'`; `markReviewed`, `markActionTaken`, `dismiss` (svi sa opcionim `reporterId`).

#### Push notifikacije

**`PushNotificationGateway`** (interfejs): `initialize`, `requestPermission`, `hasPermission`, `syncToken(uid)`, `present(payload)`, `queueForUser(userId, payload)`, `foreground`, `opened` (streamovi), `consumeInitial()`.

**`NoopPushNotificationGateway`** – no-op (web, desktop, bez Firebase-a).

**`FcmPushNotificationGateway(firestore, {notifications})`**:
- `initialize`: `NotificationService.initialize()` + `FirebaseMessaging.setForegroundNotificationPresentationOptions(alert, badge, sound: true)`; greške progutane.
- `requestPermission`: `NotificationService.requestPermissions()` (Android 13 POST_NOTIFICATIONS / iOS) + `FirebaseMessaging.requestPermission`; true ako je bilo koja authorized/provisional.
- **Sinhronizacija FCM tokena** (`syncToken(uid)`): `getToken()` → `users/{uid}` set merge `{fcmToken, fcmTokenUpdatedAt: serverTimestamp}`; `onTokenRefresh` → isto. Jedan token po korisniku (više uređaja = poslednji pobeđuje). U ovom obuhvatu token se ne briše pri odjavi.
- `present(payload)`: debugPrint sa sadržajem + `NotificationService.showPushAlert(title, body, data)`.
- **`queueForUser(userId, payload)`**: dokument `{type, title, body, dogId, fromUserId, senderUserId, conversationId, groupId, eventId, toUserId, isRead: false, createdAt, data: {...payload.data, fromUserId, toUserId}}` → (1) `users/{userId}/fcmInbox.add`, (2) `notifications.add`. Greške progutane.
- `foreground` = `FirebaseMessaging.onMessage`; `opened` = `onMessageOpenedApp`; `consumeInitial` = `getInitialMessage`.

`pushNotificationGatewayProvider` – Noop ako `!isFirebaseReady || !isPushPlatform`, inače FCM. `fcmUidProvider` – uid ili `''`.

**`PushController`** (`NotifierProvider<PushController, bool>`):
- `build`: `initialize`, `syncToken(uid)`, postavlja `notificationServiceProvider.onNotificationTap` (tap na lokalnu notifikaciju → `_handleOpened`), sluša foreground/opened, `consumeInitial`, sinhronizuje stanje dozvole.
- `requestPermission()` (+ syncToken ako je data).
- `notifyMatch` – nigde se ne poziva. `notifyMessage` (`chat_inbox.dart:102`, `:177`), `notifyWalk` (`chat_inbox.dart:129`, `map_screen.dart:912`) – `local: false`. `notifyGroupThread` (`group_unread_alerts.dart:26, 48`) – `local: true`, bez primaoca (samo lokalni prikaz).
- `_isEnabled(kind)`: `AppSettings.notifyNewMatches` / `notifyMessages` (message, group, event) / `notifyWalkRequests`.
- `_dispatch(payload, {local})`: ako je omogućeno i `local` → dodaje u lokalni inbox + `present`; ako `peerUserId` nije prazan → `queueForUser(peer, …)` (bez provere podešavanja primaoca).
- `_handleForeground`: ako je omogućeno → dodaje u inbox + lokalna heads-up notifikacija. `_handleOpened`: dodaje u inbox + `openPushDestination` (moguć duplikat uz Firestore dokument).

**`NotificationController`** (`notificationControllerProvider`):
- `build`: ako Firebase nije spreman / nema uid / auth nije spreman → `[]`; inače `notifications.where('toUserId', isEqualTo: uid).limit(100)` (bez orderBy; klijentski sort).
- `_fromDoc` fallback polja: `createdAt ← timestamp|createdAt`; `kind ← type|kind`; `body ← body|message`; `dogId ← senderDogId|fromDogId|dogId|toDogId`; `fromUserId ← fromUserId|senderUserId|senderId|peerUserId`; `conversationId ← conversationId|chatId|matchId`.
- `_kindFromKey`: `match, walk, message, group, event, SUPER_LIKE|superLike|super_like, like`; **podrazumevano → like** (npr. `CONTENT_REPORT` se prikazuje kao lajk).
- `addWalkRequest` – nigde se ne poziva. `markRead(id)` (update `isRead` + uklanja iz trake), `markChatMessagesRead({conversationId, peerUserId})` – **briše** chat notifikacije (poziva `chat_inbox.dart:71`), `markAllRead()` (batch update).
- `notificationUnreadCountProvider` – bedž (`home_shell_screen.dart:35`, `discover_app_bar.dart:24`).

**Rutiranje** (`notification_routing.dart`): `openAppNotification(context, ref, item)` i `openPushDestination(Ref, payload)` (preko `appNavigatorKey.currentContext`):
- walkRequest → `homeTabIndexProvider.showMap()`.
- groupMessage → `GroupsController.markRead` + push `GroupChatScreen(groupId)`; eventMessage → `EventsController.markRead` + `GroupChatScreen(eventId)`.
- like/superLike → učitava profil psa → `DogDetailSheet`; inače `showDiscover`.
- match/chatMessage → conversationId eksplicitno, ili sortirano `'${uidA}_${uidB}'`, ili `openFromMatch` → `ChatDetailScreen`.
- `_popSheetIfNeeded` pop-uje bilo koju rutu ako `canPop`. `ref` je tipiziran kao `dynamic`.

#### Podrška / feedback

- `SupportRepository.submitFeedback(AdminFeedback)`.
- `FirestoreSupportRepository`: `admin_feedback.add({userId, userName, userEmail, category, subject, message, createdAt: serverTimestamp, status})`; greška → debugPrint + rethrow.
- `LocalSupportRepository` – lista u memoriji.
- `supportRepositoryProvider` – Firestore/Local.
- `SupportController` (`supportControllerProvider`): `sendFeedback({category, subject, message})` – uid iz authState ili FirebaseAuth; ako ga nema, a Firebase je spreman → `StateError('Morate biti prijavljeni.')`; lokalno `'local-user'`. `userName` = displayName ili `profile.ownerName` ili "Korisnik"; `userEmail` = email ili `''`. Naslov i poruka se trim-uju.
- Nema povratnog kanala: korisnik u aplikaciji ne vidi odgovor admina (poruka uspeha kaže "Javićemo vam se ako bude potrebno").

#### Admin – mogućnosti i autorizacija

**Autorizacija:**
- Klijent: `isAdminProvider` (`auth_providers.dart:45`) = `authState.value?.isAdmin`, tj. `AppUser.role == UserRole.admin`, čitano iz `users/{uid}.role`.
- `AdminDashboardScreen` proverava `isAdminProvider`; ako nije admin prikazuje "Samo administratori mogu da otvore ovaj panel.".
- Ulaz: stavka u drawer-u se prikazuje samo `if (isAdmin)` (`home_drawer.dart:76-86`, sa bedžom `newFeedbackCountProvider`), navigacija `DrawerItemKind.admin` (`home_drawer.dart:135`); takođe `profile_system_sheet.dart:72`.
- Server (`firestore.rules`, van obuhvata): `isAdmin()` = `users/{uid}.role == 'admin'` (komentar: dodeljuje se ručno u Firestore-u). Korisnik ne može sam da promeni `role` (create zahteva `role == 'user'`, owner update zahteva nepromenjen `role`); admin može da ažurira bilo koji `users` dokument.
- `adminFeedbackProvider` i `adminUsersProvider` vraćaju prazno ako korisnik nije admin (komentar: da ne izazivaju permission greške).
- `UserPoiSubmissions._assertCanWrite(requireAdmin: true)` baca `StateError('Admin only')` za `updatePoi`/`deletePoi`/`reject` ako nije admin (`user_poi_controller.dart`, van obuhvata).

**`AdminRepository`**: `watchFeedback()`, `watchUsers()`, `resolveFeedback(id)`, `deleteFeedback(id)`, `createPlace(PlaceDraft)`, `updatePlace(PoiModel)`, `deletePlace(id)` (komentar: `places` je izvor istine, upisi se batch-uju sa `pois`).

**`FirestoreAdminRepository({firestore, placesRepository})`**:
- `watchFeedback`: `admin_feedback.orderBy('createdAt', desc)` (bez limita) kroz `guardedStream` (`admin.feedback`), plus klijentski sort. Dokumenti bez `createdAt` ne ulaze u `orderBy` upit.
- `watchUsers`: **cela kolekcija `users`** (bez limita), sort: ako neki nema `createdAt` → po imenu, inače po datumu opadajuće.
- `resolveFeedback`: update `{status: 'resolved', resolvedAt: serverTimestamp}`. `deleteFeedback`: delete.
- `createPlace/updatePlace/deletePlace` delegiraju `FirestorePlacesRepository` (van obuhvata). Pozivaoci: `add_place_screen.dart:354` (createPlace), `user_poi_controller.dart:45, 55, 61, 68`.
- Mapiranje: prazno ime → "Korisnik"; prazan status → `'new'`; `createdAt` → `DateTime.now()` ako ima pending upisa ili nema datuma; `role` podrazumevano `'user'`.

**`LocalAdminRepository`** – seed: feedback "Mapa se sporo učitava" (Milica, new) i "Predlog za nove parkove" (Nikola, resolved); korisnici Milica (user) i Nikola (admin); emailovi `@example.com`.

Provideri: `adminRepositoryProvider` (Firestore ili Local + `ref.onDispose(repo.dispose)`), `adminFeedbackProvider`, `adminUsersProvider`, `newFeedbackCountProvider` (broj nerešenih).

**Šta admin stvarno može (iz koda):**
1. Videti broj korisnika, "aktivnih pasa", aktivnih prijava i POI predloga na čekanju.
2. Čitati, rešavati i brisati poruke iz "Piši Adminu" (`admin_feedback`).
3. Videti listu svih korisnika (samo čitanje – nema promene uloge, banovanja, brisanja ni pretrage).
4. Obrađivati prijave: "Obriši" (za `moment` briše moment; za `poi` postavlja status rejected; za `user`/`message`/`dog`/`chat` **ništa ne briše**, samo lokalno sakrije `targetId` u memoriji i označi prijavu `action_taken`), "Rešeno" (`reviewed`), "Odbaci" (`dismissed`), za POI "Izmeni i reši".
5. Brisati momente (vidi samo prvih 15 učitanih – admin tab nema `loadMore`).
6. Odobravati / menjati / odbijati POI predloge (status `pending` ili `userSubmitted`).
7. Odobravati (`breed_groups/{id}.isApproved = true` merge) ili brisati grupe na čekanju.
8. Van admin panela: brisati oglase izgubljenih pasa i označiti ih rešenim (`lost_dogs_screen.dart`).
- Nema: brisanje oglasa za udomljavanje, brisanje komentara, upravljanje gradovima, banovanje korisnika, slanje obaveštenja korisnicima, odgovaranje na feedback.

---
## 8. AUTENTIFIKACIJA

Kratko:
- **Aktivna metoda:** email + lozinka (Firebase Auth).
- **Google Sign-In:** kompletno implementiran, ali je dugme zakomentarisano u `lib/features/auth/presentation/auth_screen.dart` (linije 19–20, 219–228, 319). Za iOS nedostaje `CFBundleURLTypes` (reversed client id).
- **Apple, telefon, anonimna prijava:** ne postoje.
- **Verifikacija email-a:** ne postoji.
- **Sesija:** podrazumevana Firebase perzistencija; `authStateProvider` = `authStateChanges()` + snapshot `users/{uid}`.
- **Uloge:** `users/{uid}.role` (`'user'` | `'admin'`).
  - Klijent nikad ne postavlja admina; admin se dodeljuje ručno u Firestore konzoli.
  - Pravila (`isAdmin()`) proveravaju isto polje. Custom claims se ne koriste.
- **Registracija sa slikom – bag:**
  - `AuthScreen` uploaduje profilnu sliku pre kreiranja naloga.
  - `StorageService.ownerFolder` baca `StateError` bez prijavljenog korisnika (`lib/services/storage_service.dart:53`).
- **Brisanje naloga:** klijentsko kaskadno brisanje, pa tek onda `user.delete()`. Rizik `requires-recent-login`: podaci su već obrisani, a nalog ostaje.

Detalji (iz pregleda modula core/auth/home):

#### Metode prijave
- **Email + lozinka** – jedina aktivna u UI (`AuthScreen` tab Prijava → `AuthController.signInWithEmail` → `AuthRepositoryImpl.signInWithEmailAndPassword`). Posle uspešne prijave radi se `_upsertUser` transakcija nad `users/{uid}` (piše email/ime/grad/naselje/bio/updatedAt; `role` i `dog` samo za nov dokument).
- **Google** – implementirano kroz ceo lanac (`FirebaseAuthDatasource.signInWithGoogle`, `AuthRepositoryImpl.signInWithGoogle` sa `_createDefaultProfileIfNew`, `AuthController.signInWithGoogle`, `GoogleSignInButton`), ali je u UI **sakriveno** (zakomentarisano u `auth_screen.dart` 19–20, 219–228, 319).
- Nema Apple, telefonske ni anonimne prijave.

#### Registracija
1. Korisnik (opciono) bira profilnu sliku → upload u Storage (`users/…`) pre kreiranja naloga (vidi problem u sekciji Ekrani – zahteva prijavljenog korisnika).
2. Unosi ime, email, grad/naselje, lozinku ×2; prihvatanje pravnih dokumenata je implicitno (tekst „Kreiranjem naloga prihvatate …“, bez checkbox-a).
3. `AuthController.register` → `createUserWithEmailAndPassword` → `updateDisplayName` → `_upsertUser` (sa `includeRole: true` za nov doc → `role: 'user'`, `createdAt`, `dog: emptyDogMap()`) → `updatePhotoURL` ako postoji slika.
4. `AuthScreen` ponovo zove `saveOwnerCustomPhoto` ako postoji slika, pa `popUntil(isFirst)`.
5. `AuthGate` vidi korisnika bez pasa → `DogOnboardingScreen` (van slice-a).
- `bio` se pri registraciji uvek šalje kao `''`.

#### Perzistencija sesije
- Oslanja se na podrazumevanu perzistenciju Firebase Auth-a (nema eksplicitnog `setPersistence`). `authStateProvider` sluša `authStateChanges()` + `users/{uid}` snapshot.
- `sessionSignedOutProvider` je lokalni flag koji pri odjavi odmah forsira `authStateProvider` na `null`; vraća se na `false` pri sledećoj uspešnoj prijavi/registraciji.

#### Uloge / admin
- `isAdmin` = `AppUser.role == UserRole.admin`; `role` se čita iz Firestore polja `users/{uid}.role` i samo string `'admin'` daje admin ulogu (`UserRoleX.fromString`).
- `isAdminProvider` (`auth_providers.dart:45–47`) se koristi u draweru (admin stavka) i van slice-a (map, groups, add_place, profile_system_sheet…).
- Klijent nikad ne postavlja `'admin'`: pri kreiranju dokumenta piše `'user'`; pri izmenama profila `role` se izostavlja (`includeRole: false`, `payload.remove('role')` za postojeći doc). Dodela admin uloge mora se raditi van aplikacije (Firestore konzola / backend) – u slice-u nema koda za to. Nema provere custom claims-a.

#### Odjava
`AuthController.signOut()`: zaustavlja šetnju (`stopForSignOut`), `sessionSignedOut = true`, `FirebaseAuth.signOut()`, async Google signOut (timeout 2 s), invalidira `authStateProvider`, `walkControllerProvider`, `liveWalkingDogsProvider`. UI poziva je van slice-a.

#### Brisanje naloga
- UI je van slice-a (`lib/features/profile/presentation/delete_account_action.dart:70` poziva `auth.deleteAccount()`).
- `AuthController.deleteAccount()` → `stopForSignOut` → `AuthRepositoryImpl.deleteAccount()` → `AccountDeletionService.deleteAllUserData(uid)` (klijentsko kaskadno brisanje, vidi Firestore sekciju) → `FirebaseAuth.currentUser.delete()` → `sessionSignedOut = true`.
- Rizik iz koda: podaci se brišu **pre** brisanja Auth naloga; ako `user.delete()` baci `requires-recent-login` (mapira se na poruku „Ponovo se prijavite, zatim obrišite nalog.“), Firestore/Storage podaci su već obrisani, a nalog ostaje. Nema reautentikacije (`reauthenticateWithCredential`) u kodu.
- Brisanje nije atomično i nije na serveru (Cloud Function se ne koristi u slice-u); delimični neuspeh ostavlja delimično obrisane podatke.
- Kod `LocalAuthRepository` brisanje samo postavlja korisnika na null.

#### Verifikacija email-a
- **Ne postoji** – nema `sendEmailVerification` ni provere `emailVerified` nigde u `lib/`.

#### Reset lozinke
- `ForgotPasswordDialog` → `FirebaseAuth.instance.sendPasswordResetEmail(email)` (email normalizovan na lowercase). Paralelno postoje `AuthController.sendPasswordResetEmail` → `AuthRepositoryImpl` → `FirebaseAuthDatasource.sendPasswordResetEmail`, ali taj lanac UI ne koristi.

#### Mapiranje grešaka
`invalid-email` → „Unesite ispravnu email adresu.“; `wrong-password`/`invalid-credential`/`user-not-found`/`INVALID_LOGIN_CREDENTIALS` → „Pogrešni podaci za prijavu“; `weak-password` → „Slaba lozinka“; `email-already-in-use`/`account-exists-with-different-credential` → „Korisnik već postoji“; `network-request-failed` → mrežna poruka; `requires-recent-login` → „Ponovo se prijavite, zatim obrišite nalog.“; ostalo → „Došlo je do greške. Pokušajte ponovo.“ Neočekivane (ne-Auth) greške u kontroleru → `AuthException(unknown, error.toString())` (sirov tekst greške ide u UI).

---
## 9. NOTIFIKACIJE, UPLOAD, EKSTERNI API

### 9.1 Push i lokalne notifikacije – sažetak
- **FCM (klijent):** `PushController` / `PushNotificationGateway` (`lib/features/notifications/`). Radi sledeće:
  - traži dozvolu;
  - čuva `fcmToken` i `fcmTokenUpdatedAt` u `users/{uid}` (`push_notification_gateway.dart:150`);
  - obrađuje `onMessage`, `onMessageOpenedApp` i `getInitialMessage`.
- **Slanje:** `queueForUser` upisuje dokument u `users/{peer}/fcmInbox` i `notifications`. **Ne postoji server koji šalje FCM** (nema Cloud Functions). Pravi push sa zatvorenom aplikacijom zato **ne radi**.
- **Lokalne notifikacije** (`lib/core/services/notification_service.dart`, `flutter_local_notifications`):
  - kanal `vauvau_alerts` (Importance.high) i kanal `vauvau_health` (podsetnici u 09:00, zakazani preko `timezone`);
  - grupne/event poruke prikazuju lokalnu notifikaciju samo dok aplikacija radi (`group_unread_alerts.dart`).
- **Zvuk dolazne poruke** (nekomitovano):
  - fajlovi `lib/core/services/message_sound_player.dart` i `lib/features/chat/presentation/incoming_message_sound.dart`;
  - asset `assets/sounds/message.wav`;
  - poštuje podešavanje `notifyMessages` i tihi režim.
- **Web:** `NoopPushNotificationGateway`, bez pusha.
- **iOS:** nema `Runner.entitlements` / `aps-environment`, pa push na iOS-u nije podešen.

Detalji (okidači, payload, platforme) su u podsekciji ispod.

### 9.2 Upload fajlova
- **Jedan servis:** `StorageService` (`lib/services/storage_service.dart`), Firebase Storage.
  - Putanja: `{root}/{uid}/[podfolder/]{millis}.{jpg|png|webp|gif}`.
  - Dozvoljeni root-ovi: `pets`, `users`, `moments`, `events`, `groups`, `adoption`, `lost_dogs`, `uploads`, `chats`.
  - Metadata `cacheControl: public,max-age=31536000`.
  - Brisanje po URL-u: `tryDeleteImageByUrl`.
- **Ograničenja u `storage.rules`:** samo `image/*`, manje od 8 MB, upis samo vlasnik putanje, **čitanje javno za sve**.
- **Izvor slika:** `image_picker` (galerija/kamera). Kompresija se radi preko `imageQuality` / `maxWidth` parametara pickera, ako su zadati; poseban paket za kompresiju ne postoji.
- **Neiskorišćeno:** `dog_photo_storage.dart`, `dog_photo_persist*.dart` (lokalno kopiranje slika).

### 9.3 Eksterni servisi i URL-ovi
| Servis | Gde | Ključ |
|---|---|---|
| Firebase (Auth/Firestore/Storage/FCM/Crashlytics) | `lib/firebase_options.dart` (`apiKey`, `appId`, `messagingSenderId`, `projectId`, `storageBucket` za Android i iOS), `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` | Firebase API ključevi su hardkodovani u navedenim fajlovima (vrednosti ovde nisu prikazane). Firebase web/mobilni API ključevi nisu tajna sami po sebi, ali bi trebalo da budu ograničeni u Google Cloud konzoli. |
| Google Sign-In (web) | `web/index.html` – meta `google-signin-client_id` | OAuth client id (nije tajna; vrednost nije prikazana) |
| OpenStreetMap tile-ovi | `lib/features/map/presentation/widgets/osm_tile_layer.dart:20` – `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | Bez ključa. **OSM tile policy zabranjuje teški produkcijski saobraćaj bez sopstvenog/komercijalnog tile servera.** |
| Nominatim (geokodiranje) | `lib/features/map/data/address_geocoder.dart` (samo admin „Dodaj mesto“) | Bez ključa, bez keša i rate-limita u kodu |
| Photon / Nominatim / Overpass | samo skripte u `tool/` (offline priprema seed podataka) | Bez ključa |
| Google Maps / Apple Maps / `geo:` | otvaranje navigacije preko `url_launcher` | – |
| Unsplash slike | `lib/core/images/fallback_image_helper.dart:16–25` (10 fallback ilustracija) | – |
| Pravne stranice | `https://vauvau-3195a.web.app/privacy`, `/terms` (Firebase Hosting, `public/`) | – |
| Kontakt / društvene mreže | `OfficialContacts` (`lib/features/support/domain/official_contacts.dart`) – email `vauvau.app@gmail.com` i linkovi | – |
| Android potpisivanje | `android/key.properties` + keystore (gitignored, **ne sme u git**) | Lozinke keystore-a – samo lokalno |

Nema Google Maps API ključa, platnih servisa, analitike, Sentry-ja i sličnog.

### 9.4 Notifikacije – detaljno (okidači, payload, Android/iOS)
#### Okidači (ko i kada pravi notifikaciju)
| Okidač | Mesto u kodu | Šta se dešava |
|---|---|---|
| Nova chat poruka (tekst) | `chat_inbox.dart:102` → `PushController.notifyMessage` | `local: false`; `queueForUser(peer)` → `users/{peer}/fcmInbox` + `notifications` |
| Chat poruka sa slikom | `chat_inbox.dart:177` (preview "📷 Fotografija") | isto |
| Zahtev za šetnju | `chat_inbox.dart:129`, `map_screen.dart:912` (bez conversationId) → `notifyWalk` | `local: false`; `queueForUser(peer)` |
| Nove grupne / event poruke | `group_unread_alerts.dart:26, 48` → `notifyGroupThread` | `local: true`, bez primaoca → samo lokalna notifikacija na uređaju koji je primetio rast brojača nepročitanih |
| Match | `notifyMatch` | **nigde se ne poziva** |
| Prijava sadržaja | `firestore_report_repository.dart` `_mirrorReport` | `notifications` dokument tipa `CONTENT_REPORT` gde je primalac sam prijavilac; u inbox-u se prikazuje kao "like" (podrazumevani tip) |
| FCM poruka dok je app u prvom planu | `FirebaseMessaging.onMessage` → `_handleForeground` | ako je tip omogućen u podešavanjima → dodaje u inbox + lokalna heads-up notifikacija |
| Tap na FCM notifikaciju (pozadina / ugašena app) | `onMessageOpenedApp` / `getInitialMessage` | dodaje u inbox + `openPushDestination` |
| Tap na lokalnu notifikaciju | `NotificationService.onNotificationTap` → `pushPayloadFromNotificationJson` → `_handleOpened` | rutiranje |
| Like / superLike / match dokumenti | pišu ih drugi moduli u `notifications` (van obuhvata) | čita `NotificationController` |

Nema notifikacija za: nove nestale pse (postoji samo jednokratni in-app popup), nove oglase za udomljavanje, momente, komentare, rešavanje prijava, odgovor admina na feedback.

#### Gde se payload čuva
- `users/{peerUid}/fcmInbox/{auto}` i `notifications/{auto}` (isti dokument, piše pošiljalac sa klijenta).
- Lokalna lista u `NotificationController` (`prepend`) za notifikacije prikazane/otvorene na uređaju.
- Payload lokalne notifikacije = JSON od `PushPayload.data` (prosleđuje se `showPushAlert`).

#### Da li postoji server / Cloud Function
**Ne.** U repou ne postoji folder `functions/`, a `firebase.json` nema sekciju `functions` (samo firestore, storage, hosting). Grep za `fcmInbox`/`fcmToken`/`onDocumentCreated`/`sendToDevice` nalazi samo `push_notification_gateway.dart`, `firestore.rules` i `account_deletion_service.dart`. Klijent upisuje `fcmInbox` i `fcmToken`, ali u repou nema ničega što bi iz `fcmInbox` poslalo FCM poruku na token. Zaključak: pravi push dok je aplikacija u pozadini ili ugašena **ne isporučuje se iz ovog koda**. Radi samo: (a) in-app inbox iz `notifications` dok je aplikacija aktivna, (b) lokalne notifikacije za grupne/event poruke dok aplikacija radi, (c) FCM handleri koji bi radili kada bi spoljni backend slao poruke (takav backend nije vidljiv u repou).

#### Android
- Kanali (u `core/services/notification_service.dart`, van obuhvata): `vauvau_alerts` ("VauVau obaveštenja", Importance.high) i `vauvau_health` ("Zdravlje i podsetnici", podsetnici u 09:00).
- `AndroidManifest.xml`: permisija `POST_NOTIFICATIONS`; meta-data `com.google.firebase.messaging.default_notification_channel_id = vauvau_alerts`; `default_notification_icon = @mipmap/ic_launcher`.
- Ikonica `@mipmap/ic_launcher`; groupKey `vauvau_alerts_group`; tag `vauvau_<type>_<id>`; id = hash od `conversationId|chatId|groupId|eventId|type`.

#### iOS
- `DarwinInitializationSettings(requestAlertPermission/Badge/Sound: false)` – dozvola se traži ručno kroz `PushBootstrap` / `requestPermission`; `DarwinNotificationDetails(presentAlert/Badge/Sound: true)`.
- `FirebaseMessaging.setForegroundNotificationPresentationOptions(alert, badge, sound: true)`.
- `Info.plist`: `UIBackgroundModes` = fetch, location, remote-notification; `FirebaseAppDelegateProxyEnabled = true`.
- U `ios/Runner` ne postoji `.entitlements` fajl → `aps-environment` entitlement nije vidljiv u repou (nejasno da li je podešen u Xcode-u van repoa).
- `main.dart:16-27` `firebaseMessagingBackgroundHandler` samo inicijalizuje Firebase (ništa ne prikazuje); registrovan na `main.dart:41`.
- `getNotificationAppLaunchDetails` se ne koristi → tap na lokalnu notifikaciju koja je pokrenula ugašenu aplikaciju se ne rutira.

#### Polja payload-a
- `PushPayload.data`: `type` (`match|message|walk|group|event`), `title`, `body`, opciono `dogId`, `peerUserId`, `conversationId`, `groupId`, `eventId`.
- `queueForUser` dodaje u `data`: `fromUserId`, `toUserId`; na nivou dokumenta: `type, title, body, dogId, fromUserId, senderUserId, conversationId, groupId, eventId, toUserId, isRead, createdAt`.
- Prihvaćeni alias-i pri čitanju (`fromData`): `senderDogId`, `fromDogId`, `fromUserId`, `senderUserId`, `chatId`, `matchId`, ugnježdena mapa `data`.
- Tekst notifikacije se lokalizuje na jeziku **pošiljaoca** (`NotificationStrings` u `_dispatch`).
- Mogući bug: `payload.data.peerUserId` je primalac, a `PushPayload.fromData` prvo čita `peerUserId` – kada bi FCM data nosila taj ključ, rutiranje na strani primaoca bi kao sagovornika dobilo sopstveni uid. Za in-app `notifications` `_fromDoc` prvo čita `fromUserId` (ispravno).

---
## 10. KONFIGURACIJA

Kratko:
- **Android:**
  - `applicationId`/namespace `com.vauvau.app`; `minSdk`/`targetSdk`/`compileSdk` iz Flutter SDK-a (lokalno 24/36/36).
  - Java 17 + core library desugaring; R8 minify + shrinkResources.
  - Release potpisivanje iz `android/key.properties` (gitignored); `google-services.json` je komitovan.
  - Permisije u `AndroidManifest.xml`: INTERNET, ACCESS_NETWORK_STATE, ACCESS_COARSE/FINE_LOCATION (**bez** background location), FOREGROUND_SERVICE, FOREGROUND_SERVICE_LOCATION, POST_NOTIFICATIONS, WAKE_LOCK, RECEIVE_BOOT_COMPLETED.
  - Pluginovi mogu dodati još permisija u merged manifest; to nije provereno.
- **iOS:**
  - bundle `com.example.vauvau` (šablonski!), deployment target 13.0, pluginovi preko SPM-a;
  - `Info.plist` ima opise za lokaciju, kameru i galeriju, kao i `UIBackgroundModes` (fetch, location, remote-notification);
  - nema entitlements, `DEVELOPMENT_TEAM`, URL scheme za Google.
- **Okruženja:** postoji **samo jedno okruženje** (produkcioni Firebase projekat `vauvau-3195a`). Nema flavor-a, `.env` fajlova, `--dart-define` konfiguracije ni dev/staging projekta.
- **Firebase CLI:** `firebase.json` (firestore/storage/hosting), `.firebaserc` (`default: vauvau-3195a`), lokalni wrapper `firebase.cmd`.
- **Build skripte:**
  - `scripts/build_release.*` grade **APK**, a Play traži AAB (`flutter build appbundle --release`);
  - `docs/play-launch-checklist.md` je zastarela (verzija `1.0.0+4`).
- **Lint:** `analysis_options.yaml` = `package:flutter_lints/flutter.yaml` bez dodatnih pravila. `dart analyze` prijavljuje jednu grešku: `test/profile_test.dart:41` (`const_with_non_constant_argument`).

Detalji po platformama (iz pregleda platforme/konfiguracije):

### 10.1 Android
| Stavka | Vrednost |
|---|---|
| applicationId | `com.vauvau.app` (`android/app/build.gradle.kts:50`) |
| namespace | `com.vauvau.app` (`build.gradle.kts:37`) |
| compileSdk | `flutter.compileSdkVersion` → 36 u lokalnom Flutter SDK 3.44.1 (`FlutterExtension.kt`) |
| minSdk | `flutter.minSdkVersion` → 24 u lokalnom SDK-u |
| targetSdk | `flutter.targetSdkVersion` → 36 u lokalnom SDK-u |
| ndkVersion | `flutter.ndkVersion` → `28.2.13676358` |
| versionCode / versionName | `flutter.versionCode` / `flutter.versionName` → iz `pubspec.yaml` `version: 1.0.0+7` (lokalni `local.properties`: versionName 1.0.0, versionCode 7) |
| Java | source/target `JavaVersion.VERSION_17`, `isCoreLibraryDesugaringEnabled = true`, `desugar_jdk_libs:2.1.4` |
| Kotlin | plugin `org.jetbrains.kotlin.android` 2.3.20 (deklarisan u settings sa `apply false`; u `app/build.gradle.kts` nije eksplicitno primenjen, ali postoji blok `kotlin { compilerOptions { jvmTarget = JVM_17 } }`); `android.builtInKotlin=false` |
| AGP | `com.android.application` 9.0.1 |
| Gradle | 9.1.0 (`-all` distribucija) |
| Ostali Gradle pluginovi | `com.google.gms.google-services` 4.4.2, `com.google.firebase.crashlytics` 3.0.3, `dev.flutter.flutter-gradle-plugin` |

Napomena: vrednosti 36/24/36 su izvedene iz lokalno instaliranog Flutter SDK-a (`C:\src\flutter`), ne iz samog projekta – menjaju se sa verzijom Fluttera.

#### Potpisivanje (release)
- Čita `android/key.properties` (`rootProject.file("key.properties")`) preko `java.util.Properties`.
- Funkcija `requireReleaseSigningProperty(name)` baca `GradleException` ako je vrednost prazna ili sadrži `YOUR_`, `CHANGE_ME`, `path/to` ili `example` (case-insensitive).
- `signingConfigs.release` se popunjava samo ako `key.properties` postoji (da bi debug sync radio); proverava i da `storeFile` fajl postoji.
- `buildTypes.release`: ako `key.properties` ne postoji → `GradleException("Missing android/key.properties…")`; zatim `signingConfig = release`, i dodatna provera da nije `debug` config.
- **Nema fallback-a na debug potpisivanje** – eksplicitno komentarisano „Never fall back to the debug keystore — Play rejects those AABs“.
- `android/key.properties` postoji lokalno i gitignored je (`android/.gitignore:12` i root `.gitignore`); keystore fajl (`storeFile`) nije u repozitorijumu (`*.jks`/`*.keystore` ignorisani). Putanja keystore-a nije prikazana.
- Napomena: zbog `throw` u `buildTypes.release` bloku (konfiguraciona faza), verovatno će i debug build pasti ako `key.properties` ne postoji, jer se release blok evaluira pri svakoj konfiguraciji – ovo nije testirano, samo zaključak iz koda.

#### Minify / shrink
- `isMinifyEnabled = true`, `isShrinkResources = true`, `proguard-android-optimize.txt` + `proguard-rules.pro` (samo za release).

#### Dozvole (`src/main/AndroidManifest.xml`)
- `INTERNET`
- `ACCESS_NETWORK_STATE`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `POST_NOTIFICATIONS`
- `WAKE_LOCK`
- `RECEIVE_BOOT_COMPLETED`
- Nema `ACCESS_BACKGROUND_LOCATION` (komentar: šetnja koristi foreground servis, ne „always“ lokaciju). Nema `CAMERA` ni storage dozvola u glavnom manifestu (eventualno ih dodaju pluginovi kroz manifest merge – nije provereno).
- Debug i profile manifesti: samo `INTERNET`.

#### Application
- `android:label="VauVau"`, `android:name="${applicationName}"`, `android:icon="@mipmap/ic_launcher"`.

#### Aktivnosti
- `.MainActivity` – `exported=true`, `launchMode=singleTop`, `taskAffinity=""`, `theme=@style/LaunchTheme`, `configChanges=…` (šablon), `hardwareAccelerated=true`, `windowSoftInputMode=adjustResize`; meta-data `io.flutter.embedding.android.NormalTheme` → `@style/NormalTheme`.
- Intent filter: samo `MAIN` + `LAUNCHER`. **Nema deep link / App Links intent filtera.**

#### Servisi
- `com.baseflow.geolocator.GeolocatorLocationService` – `enabled=true`, `exported=false`, `foregroundServiceType="location"`, `tools:node="merge"`.
- FCM servis nije eksplicitno deklarisan (dolazi iz `firebase_messaging` plugina putem manifest merge-a – nije provereno u merged manifestu).

#### Receiver-i
- `com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver` – `exported=false`, akcije: `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON`, `com.htc.intent.action.QUICKBOOT_POWERON`.
- `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` – `exported=false`.

#### Meta-data
- `flutterEmbedding` = `2`.
- `com.google.firebase.messaging.default_notification_channel_id` = `vauvau_alerts` – **prisutno**.
- `com.google.firebase.messaging.default_notification_icon` = `@mipmap/ic_launcher` – prisutno (napomena: obojena launcher ikonica kao notifikaciona ikonica se na Androidu obično prikazuje kao bela mrlja; ne postoji namenska monohromatska ikonica).
- Google Maps API ključ (`com.google.android.geo.API_KEY`) – **nije prisutan** (aplikacija koristi `flutter_map`, ne Google Maps).

#### `<queries>` (package visibility)
- `PROCESS_TEXT` (text/plain), `VIEW` za šeme `tel`, `https`, `geo`, `http`, `mailto`, i `SENDTO` `mailto`.

#### Teme / splash
- Splash boja `#0F172A`; launcher pozadina `#FFF8F0`; Android 12+ koristi prazan vektor da sakrije podrazumevanu ikonicu (konfigurisano i u `pubspec.yaml` → `flutter_native_splash.android_12`).

#### google-services.json (struktura)
- `project_info`: `project_id` = `vauvau-3195a`, storage bucket `vauvau-3195a.firebasestorage.app`.
- `client[0]`: package `com.example.vauvau` – 2 oauth_client (tip 1 i 3), 1 api_key, 2 `other_platform_oauth_client`.
- `client[1]`: package `com.vauvau.app` – 3 oauth_client (2× tip 1, 1× tip 3), 1 api_key, 2 `other_platform_oauth_client`.
- `configuration_version` = `1`. API ključevi postoje u fajlu (nisu prikazani).

### 10.2 iOS / macOS
#### iOS
- **Bundle id**: `com.example.vauvau` (`ios/Runner.xcodeproj/project.pbxproj` linije 385, 564, 586); RunnerTests: `com.example.vauvau.RunnerTests`. **Razlikuje se od Android `com.vauvau.app`.**
- **Deployment target**: `IPHONEOS_DEPLOYMENT_TARGET = 13.0` (linije 363, 489, 540).
- **Potpisivanje**: `CODE_SIGN_STYLE = Automatic`, `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"`; **`DEVELOPMENT_TEAM` nije postavljen**; nema provisioning profila.
- Swift 5.0, `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad).
- Verzija: `CFBundleShortVersionString = $(FLUTTER_BUILD_NAME)`, `CFBundleVersion = $(FLUTTER_BUILD_NUMBER)` (iz pubspec-a).
- Display name: `VauVau`.

##### Usage descriptions (Info.plist, doslovno)
- `NSPhotoLibraryUsageDescription`: „VauVau koristi galeriju da dodate fotografije vašeg psa.“
- `NSCameraUsageDescription`: „VauVau koristi kameru da snimite fotografije vašeg psa.“
- `NSLocationWhenInUseUsageDescription`: „VauVau koristi vašu lokaciju da prikaže pse u blizini i da deli status „U šetnji“.“
- `NSLocationAlwaysAndWhenInUseUsageDescription`: „VauVau prikuplja podatke o lokaciji u pozadini kako bi omogućio praćenje rute šetnje vašeg psa i kada je aplikacija zatvorena ili se ne koristi.“
- `NSLocationAlwaysUsageDescription`: isti tekst kao prethodni.
- Nema `NSMicrophoneUsageDescription`, `NSPhotoLibraryAddUsageDescription`, `NSUserTrackingUsageDescription`.

##### Background modes (`UIBackgroundModes`)
- `fetch`, `location`, `remote-notification`.

##### Ostalo u Info.plist
- `LSApplicationQueriesSchemes`: `tel`, `mailto`, `https`, `http`, `instagram`, `fb`, `maps`, `comgooglemaps`.
- `FirebaseAppDelegateProxyEnabled` = `true`.
- `UIApplicationSceneManifest` sa `$(PRODUCT_MODULE_NAME).SceneDelegate`, storyboard `Main`; `UILaunchStoryboardName = LaunchScreen`.
- Orijentacije: iPhone portrait + landscape L/R; iPad sve četiri.
- `CADisableMinimumFrameDurationOnPhone = true`, `UIApplicationSupportsIndirectInputEvents = true`.

##### URL scheme / Google Sign-In
- `GoogleService-Info.plist` **sadrži** `REVERSED_CLIENT_ID`.
- `Info.plist` **nema `CFBundleURLTypes`** → reversed client ID URL scheme nije registrovan, iako `README.md` to navodi kao obavezan korak i projekat koristi `google_sign_in ^6.2.1`. Google Sign-In na iOS-u u ovom stanju ne bi radio (`google_sign_in` zahteva URL scheme).
- `GoogleService-Info.plist` nije dodat u Xcode projekat (nijedna referenca „GoogleService“ u `project.pbxproj`). Aplikacija u Dartu inicijalizuje Firebase preko `DefaultFirebaseOptions` (`lib/firebase_options.dart`, sadrži `ios` opcije sa `iosBundleId: 'com.example.vauvau'`), pa Firebase core verovatno radi i bez plist-a; ali Google Sign-In/FCM na iOS-u često očekuju plist u bundle-u – nije testirano.

##### Push / entitlements
- **Nema `Runner.entitlements`** niti `aps-environment` – Push Notifications capability nije podešena, iako postoji `remote-notification` background mode i `firebase_messaging`. FCM push na iOS-u nije funkcionalan bez toga (+ APNs ključa u Firebase konzoli, što se iz repoa ne vidi).
- Nema Podfile-a; workspace referencira samo `Runner.xcodeproj` → pluginovi se integrišu preko Swift Package Manager-a (postoji generisan `FlutterGeneratedPluginSwiftPackage`).

##### AppDelegate / SceneDelegate
- `AppDelegate`: `@main`, `FlutterAppDelegate` + `FlutterImplicitEngineDelegate`; `didFinishLaunchingWithOptions` samo poziva `super`; `didInitializeImplicitFlutterEngine` registruje pluginove. **Nema prilagođavanja** (nema `FirebaseApp.configure()`, `UNUserNotificationCenter` delegata, APNs registracije).
- `SceneDelegate`: prazna podklasa `FlutterSceneDelegate`.

##### Launch screen
- `LaunchScreen.storyboard`: `LaunchBackground` slika preko celog ekrana + centrirana `LaunchImage`; pozadina view-a bela. `pubspec.yaml` (`flutter_native_splash`, `ios: true`, boja `#0F172A`).

#### macOS
- Bundle id: `com.example.vauvau` (`macos/Runner/Configs/AppInfo.xcconfig`), `PRODUCT_NAME = vauvau`.
- Deployment target: `MACOSX_DEPLOYMENT_TARGET = 10.15`.
- Entitlements: Debug/Profile – app-sandbox, allow-jit, network.server; Release – samo app-sandbox. **Nijedna konfiguracija nema `com.apple.security.network.client`** → odlazne mrežne konekcije (Firebase) bi u sandboxu bile blokirane.
- Info.plist: šablon, bez usage descriptions (lokacija, kamera…), bez URL schemes.
- AppDelegate/MainFlutterWindow: šablon, bez prilagođavanja.
- Nema `GoogleService-Info.plist` za macOS; `firebase_options.dart` za macOS vraća `android` opcije (`default:` grana).
- Zaključak: macOS target je neprilagođen Flutter šablon; nije jasno da li je uopšte ciljna platforma.

### 10.3 Web / Desktop
#### Web
- `web/index.html`:
  - `<base href="$FLUTTER_BASE_HREF">`, `<meta name="description">` na srpskom.
  - `<meta name="google-signin-client_id" …>` – **hardkodovan OAuth web client ID**. Prefiks broja projekta u tom ID-u (`125865322788`) **ne odgovara** broju Firebase projekta `vauvau-3195a` (`461477755452`, iz `GCM_SENDER_ID`/`project_number`) → verovatno pripada drugom/starom Google Cloud projektu.
  - Nema `<script>` tagova za Firebase JS SDK; nema ručne registracije service worker-a – učitava se samo `flutter_bootstrap.js` (Flutter generiše service worker logiku).
  - Splash CSS (klase `.center`, `.contain`, `.cover`…, generisane iz `flutter_native_splash`), ali u `<body>` nema `<picture>`/`<img>` splash elementa; pozadina `#38BDF8` (svetloplava) – ne odgovara brendu (`#0F172A` splash, `#FFF8F0`/`#EA580C` u manifestu). `pubspec.yaml` ima `flutter_native_splash.web: false`.
- `web/manifest.json`: „VauVau“, standalone, `start_url "."`, `background_color #FFF8F0`, `theme_color #EA580C`, `portrait-primary`, 4 ikonice.
- `lib/firebase_options.dart` za web (`kIsWeb`) vraća **Android** `FirebaseOptions` – nema posebne web Firebase aplikacije.
- `build/flutter_assets/packages/flutter_local_notifications_web/web/notifications_service_worker.js` postoji u build izlazu (generisano od plugina), ne u `web/`.

#### Windows
- Šablonski Win32 runner, naslov prozora i ProductName `vauvau`, CompanyName `com.example`. Pluginovi: audioplayers, cloud_firestore, file_selector, firebase_auth/core/storage, flutter_timezone, geolocator, url_launcher, flutter_local_notifications_windows, jni (nema firebase_messaging, crashlytics, google_sign_in).
- Firebase opcije za Windows: `default:` → Android opcije.

#### Linux
- Šablonski GTK runner, `APPLICATION_ID "com.example.vauvau"`, naslov `vauvau`, 1280×720. Pluginovi: audioplayers, file_selector, flutter_timezone, url_launcher, jni – **nema Firebase pluginova** (cloud_firestore/firebase_auth nemaju Linux implementaciju), pa aplikacija na Linuxu verovatno ne može da radi sa backend-om.

#### macOS
- Vidi sekciju iOS/macOS.

Generalno: desktop platforme su neizmenjen `flutter create` šablon sa `com.example` identifikatorima.

### 10.4 Build i pokretanje
#### `scripts/build_release.ps1`
```powershell
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter build apk --release
```

#### `scripts/build_release.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
- Obe skripte: prelaze u koren, rade `pub get` → `analyze` → `test` → **`flutter build apk --release`**.
- Napomena: prave **APK**, ne AAB, iako checklista i Play Store traže `flutter build appbundle --release`. Release build zahteva validan `android/key.properties` (inače Gradle prekida).
- Nema skripti za iOS, web ili deploy.

#### README uputstva
1. Napraviti Firebase projekat, uključiti Email/Password i Google prijavu.
2. `dart pub global activate flutterfire_cli` + `flutterfire configure`.
3. Android: dodati debug SHA-1 i SHA-256 u Firebase konzoli.
4. iOS: dodati reversed client ID URL scheme iz `GoogleService-Info.plist` (**nije urađeno** u `Info.plist`).
- Tvrdnja „`lib/firebase_options.dart` is a stub“ je zastarela. Ostatak je šablon.
- README ne opisuje pokretanje testova, release potpisivanje, deploy pravila ni hosting.

#### `docs/play-launch-checklist.md` – sažetak
**Označeno [x] (urađeno):**
- Potpisan release AAB (`key.properties` + upload keystore).
- Privacy i Terms live na `vauvau-3195a.web.app`.
- Brisanje naloga u aplikaciji + e-mail fallback.
- Crashlytics uključen.
- Firestore/Storage ownership pravila deploy-ovana.
- Chat paginacija; discover `orderBy(createdAt)` + `limit(15)` + infinite scroll; mapa `limit(50)` + subscribe samo na Map tabu.
- R8 minify + shrink.
- Release i debug SHA-1/SHA-256 dodati za `com.vauvau.app`; `google-services.json` osvežen.
- Firestore rules, Storage rules, Firestore indeksi deploy-ovani; hosting i dalje služi `/privacy` i `/terms`.
- `pubspec.yaml` verzija `1.0.0+4`; `flutter build appbundle --release` uspeva; AAB `release/vauvau-1.0.0+4-release.aab`.

**Neoznačeno [ ] (otvoreno):**
- Potvrda da su indeksi „Enabled“ u konzoli.
- (Opciono) Cloud Functions za FCM slanje; (opciono) App Check.
- Ceo Play Console store listing: ime/opisi, ikonica 512, feature graphic, screenshotovi, linkovi na Privacy/Terms, Data safety formular, deklaracija brisanja naloga, content rating, target audience, opravdanje osetljivih dozvola (lokacija + FGS), kontakt e-mail.
- Upload AAB-a na Internal testing (ručno, nema Play API kredencijala u repou).
- Target SDK zahtev (API 36), backup upload keystore-a.
- Ceo smoke test (email/Google prijava, onboarding, discover, chat, mapa/šetnja, momenti, notifikacije, brisanje naloga, test crash).
- Go live: closed testing sa 3–5 korisnika, promocija na produkciju, praćenje 48h.

**Odloženo:** Cloud Functions (pravi push za chat/match u pozadini), App Check, custom domen za legal stranice, iOS App Store.

- Sadrži tabelu sa **release SHA-1 i SHA-256 otiscima** upload keystore-a (javni otisci, nisu tajna, ali su komitovani).
- **Zastarelo**: checklista navodi verziju `1.0.0+4`, a `pubspec.yaml` je sada `1.0.0+7`. U lokalnom folderu `release/` postoji samo `vauvau-1.0.0+4-release.aab` (~83 MB, gitignored).

#### Legal dokumenti
- `docs/privacy-policy.html` / `public/privacy/index.html` – SR/EN, 12. oktobar 2026, kontrolor „VauVau“, kontakt `vauvau.app@gmail.com`. Navodi: GPS „tokom aktivne šetnje i dok je app otvorena“, „na Androidu ne tražimo ‘uvek dozvoli’“.
- `docs/terms-of-service.html` / `public/terms/index.html` – SR/EN, 12. oktobar 2026.
- `Gist` – starija/druga verzija politike privatnosti (7. oktobar 2026, generički tekst, lični kontakt e-mail, pominje „lozinke se čuvaju u enkriptovanom obliku“ i „pronalaženje obližnjih parkova“) – nije usklađena sa zvaničnom verzijom.
- Legal tekstovi ne spominju Crashlytics eksplicitno (samo „tehnički podaci Firebase usluga“), niti zadržavanje/rok čuvanja podataka.

---
## 11. STANJE PROJEKTA

### TODO / FIXME
- U `lib/`, `test/`, `android/`, `ios/`, `web/`, `tool/` i `scripts/` **nema** nijednog `TODO`, `FIXME`, `HACK` ni `XXX` komentara (proveravano ripgrep-om).
- Jedini TODO-ovi su šablonski iz Flutter-a:
  - `windows/flutter/CMakeLists.txt:9`;
  - `linux/flutter/CMakeLists.txt:9` (`# TODO: Move the rest of this into files in ephemeral.`).

### Stanje testova (pokrenuto lokalno, `flutter test`)
- 38 test fajlova, oko 193 testa.
- **18 testova pada** i nisu vezani za skorašnje izmene. Nisu menjani. Po fajlu:
  - po 1: `admin_test`, `events_test` (24h format), `map_test`, `safety_test`;
  - `chat_test` – „walk invite can be sent and accepted“;
  - po 2: `notifications_test`, `settings_test`, `widget_test`;
  - po 3: `discover_test`, `moments_test`.
- `test/profile_test.dart` **ne kompajlira**: `const_with_non_constant_argument` na liniji 41. To je ujedno jedina greška iz `dart analyze`.
- Novi testovi za multiline unos, zvuk, unread, avatar i zakazane šetnje prolaze.

### Najvažniji pronađeni problemi (konsolidovano, po prioritetu)
**Funkcionalni bagovi**
1. **Prvi lajk na grupnoj/event poruci baca `UnsupportedError`.**
   - `_stringList` vraća `const []` kada poruka nema `likes`, pa `ids.add(...)` puca.
   - Mesta: `lib/features/groups/data/firestore_groups_repository.dart:413–431` i analogno u `firestore_events_repository.dart` (oko `:414`).
2. **Push ne radi kada je aplikacija zatvorena.** Nema Cloud Functions koja bi slala FCM iz `fcmInbox`/`notifications` (sekcije 5 i 9).
3. **Registracija sa profilnom slikom:**
   - upload ide pre kreiranja naloga;
   - `StorageService.ownerFolder` baca `StateError` bez prijavljenog korisnika (`lib/services/storage_service.dart:53`).
4. **Brisanje naloga** briše podatke pre `user.delete()`. Kod `requires-recent-login` ostaje nalog bez podataka; reautentikacija ne postoji.
5. **Lista četova** (`chat_list_screen.dart:351`) zove `markRead` pre otvaranja ekrana. `ChatDetailScreen` zato ne zna koliko je bilo nepročitanih, pa se gubi „sidro“ za skrol do prve nepročitane.
6. **Grupni čet** (`group_chat_screen.dart:208`): `_jumpToEndWithRetry` nema `scheduleFrame()`. Kod kratkog razgovora bez skrola `markRead` se možda ne pozove. Isti bag je ispravljen u 1:1 četu (nekomitovano).
7. **`totalUnreadChatCountProvider`** (`chat_inbox.dart:352`) broji i četove sa blokiranim korisnicima (koristi `chatInboxProvider`, ne `visibleConversationsProvider`).
8. **Admin „Obriši“ na prijavi** (`admin_reports_tab.dart`):
   - za mete tipa korisnik, poruka, pas ili čet **ništa ne briše**; samo lokalno sakrije `targetId` i označi prijavu sa `action_taken`;
   - briše se samo moment, a POI se odbija.
9. **`notifyMatch`** (`push_controller.dart:64`) **se nigde ne poziva.** Prijava sadržaja pravi notifikaciju samom prijaviocu, prikazanu kao „like“.
10. **Seed grupe i događaji** sa izmišljenim brojem članova se upisuju sa klijenta u produkcionu bazu (`createdBy == ''`, `isApproved: true`).

**Bezbednost** (detaljno u sekciji 5)
11. Javno čitljivi `users` dokumenti (email, `fcmToken`, lokacija, `contentReports`).
12. Bilo ko menja `events` i `breed_groups` i pravi `notifications` / `matches`.
13. Sve slike u Storage-u, uključujući slike iz privatnih četova, javno su čitljive. CORS je `*`.

**Platforma / izdavanje**
14. iOS:
    - bundle id `com.example.vauvau`;
    - nema push entitlements, Google URL scheme ni `DEVELOPMENT_TEAM`;
    - `GoogleService-Info.plist` nije dodat u Xcode projekat.
15. Web koristi Android Firebase opcije; web Google client id je iz drugog GCP projekta.
16. Build skripte prave APK, a ne AAB; checklista za Play je zastarela.

### Hardkodovane vrednosti (izbor; potpune liste su po modulima ispod)
- Firebase konfiguracija: `lib/firebase_options.dart`, uključujući `projectId vauvau-3195a` i API ključeve (vrednosti nisu prikazane).
- Gradovi, kvartovi, koordinate centara i seed POI/mesta su u Dart kodu (`lib/features/map/...`). Poreklo seed podataka i šta je provereno: sekcija 5, „Podaci o lokacijama“.
- Seed grupe/događaji, `EventVenues`, Unsplash fallback slike, pravni URL-ovi, kontakt email `vauvau.app@gmail.com`.
- Vremena: splash 2 s, svežina zvuka poruke 1 min, razmak između zvukova 1500 ms, trajanje priče 24 h, podsetnici u 09:00, limit uploada 8 MB, `maxLiveWalkers = 50`.

### Tehnički dug (izbor)
- **`print()` u produkciji:** 7 poziva, na primer:
  - `firestore_discover_repository.dart:410`;
  - `lost_dogs_controller.dart:67`;
  - `adoption_controller.dart:75`;
  - `report_lost_dog_sheet.dart:451`;
  - `add_adoption_dog_sheet.dart:464`;
  - `local_discover_repository.dart:85,122`.
  
  `debugPrint` se koristi u 45 fajlova.
- **Neiskorišćen kod:**
  - `AppRoutes`;
  - `dog_photo_storage.dart`, `dog_photo_persist*.dart`;
  - legacy liste u `AppDrawerCatalog`;
  - kolekcija `highlights` (samo brisanje);
  - `support` kolekcija u pravilima.
- **Nekonzistentan format lokacije** (`location` string naspram `cityId`/`neighborhoodId`, GeoPoint naspram `latitude`/`longitude`), sa više alias polja za slike (`photoUrl`, `imageUrl`, `photos`, `photoUrls`, `galleryUrls`).
- **Dupli izvori istine:**
  - prijave u `reports` i u `users/{uid}.contentReports[]`;
  - predlozi izmena u `change_requests` i u `users/{uid}.placeChangeRequests[]`;
  - komentari izgubljenih pasa kao niz, a u pravilima i kao podkolekcija.
- **Lokalizacija:** sopstveni `L10n` bez `.arb` fajlova; deo stringova nije preveden na engleski.
- **Imperativna navigacija bez deep linkova;** neki widgeti direktno zovu `FirebaseFirestore.instance`.
- **Repo higijena:**
  - oko 7,3 MB nekorišćenih splash slika ulazi u APK;
  - `Gist` fajl (stara politika privatnosti sa ličnim email-om);
  - marketinški video i slike u `docs/reels/`;
  - zastareli `README.md`.
- **Nekomitovano:** 25 izmena, uključujući sve nove testove. Push na `master` čeka odobrenje.

### 11.1 Testovi (po fajlu)
Ukupno **38 test fajlova** sa **193 test slučaja** (`test(...)` + `testWidgets(...)`, prebrojano regexom po početku linije). Nema `skip:` testova. Rezultat lokalnog pokretanja (`flutter test`) je u sekciji 11, „Stanje testova“.
Git stanje: `chat_test.dart` i `groups_test.dart` su izmenjeni (nekomitovano); `chat_unread_test.dart`, `incoming_message_sound_test.dart`, `message_bubble_avatar_test.dart`, `scheduled_walks_test.dart` su novi, **nepraćeni** (untracked) fajlovi.

| Fajl | Br. | Šta pokriva |
|---|---|---|
| `test/admin_test.dart` | 3 | Admin ekran: blokira ne-admin korisnike; rešavanje i brisanje feedback-a; brisanje momenta i lista korisnika. |
| `test/adoption_test.dart` | 2 | Oglasi za udomljavanje: prikaz liste i detalja; forma za dodavanje sa obaveznim poljima. |
| `test/chat_test.dart` | 9 | Lista match-eva/konverzacija, prazno stanje na srpskom, slanje poruke, „pronađi prijatelje“ → discover, pretraga po imenu psa, poziv u šetnju (slanje/prihvatanje), tap na avatar otvara profil, picker lokacije (čeka izbor / zatvaranje ne šalje ništa). |
| `test/chat_unread_test.dart` | 3 | `FirestoreChatRepository` unread brojači: odgovor briše moj unread a čuva peer-ov; `markRead` briše samo moj; poruke koje stignu dok je chat otvoren označavaju se pročitanim. |
| `test/compatibility_test.dart` | 1 | Tekst kompatibilnosti energije i šetnje. |
| `test/content_validation_test.dart` | 4 | Validacija sadržaja: odbija srpske/engleske psovke, spam karaktere i prazne linkove, prihvata normalne tekstove, odbija prazne/nevalidne bajtove slike. |
| `test/discover_feed_order_test.dart` | 1 | Redosled discover feed-a: najnoviji prvo, zatim bliži. |
| `test/discover_test.dart` | 5 | Discover: kartice na srpskom, prazno stanje pretrage, otvaranje profile sheet-a, detalji (energija, težina, status, momenti), filter dugme. |
| `test/dog_health_test.dart` | 5 | Zdravlje psa: status prema sledećem datumu, podsetnik u 09:00 na dan dospeća, zakazivanje/otkazivanje podsetnika, izmena postojeće kategorije u sheet-u. |
| `test/dog_photo_gallery_test.dart` | 3 | Galerija: swipe i brojač, full-screen viewer, sakrivene kontrole za jednu fotografiju. |
| `test/dog_reminder_test.dart` | 5 | Podsetnici: hitnost prema datumu, `notifyDate` sa offset-om, zakazivanje notifikacije, sakrivanje praznih kategorija, prikaz samo najbližih podsetnika. |
| `test/events_city_test.dart` | 12 | `EventVenues.forCity` (Novi Sad, Niš, svaki grad ima lokaciju), `cityIdForEvent` (eksplicitan cityId, legacy Novi Sad, nepoznato, seed događaji, kreiranje čuva grad), EventsScreen filter po gradu, prazno stanje, lokacije u formama za događaj i priču. |
| `test/events_test.dart` | 2 | Format vremena HH:mm (24h); prikaz seed događaja i ulazak u chat šetnje. |
| `test/fallback_image_helper_test.dart` | 6 | Fallback slike: stabilan URL/boja za isti seed, varijacija po id-u, odbacivanje Unsplash-a, caption ispod slike, pamćenje odbacivanja popup-a za izgubljenog psa. |
| `test/groups_test.dart` | 6 | Grupe: seed preseti (parkovi, bez grupe malih pasa, sortiranje po članovima), pending grupe skrivene do odobrenja, ulazak u chat, tap na avatar člana i na fotografiju, dijalog „na proveri“ pri kreiranju. |
| `test/group_inbox_test.dart` | 4 | Grupni unread posle `lastRead`, tekst grupne notifikacije, grupa u „Poruke“ sa badge-om, nav badge broji jednu nit. |
| `test/home_city_test.dart` | 4 | Domaći grad i regija mape za Niš, Beograd, Novi Sad; fallback na „moja lokacija“. |
| `test/incoming_message_sound_test.dart` | 12 | `IncomingMessageDetector` (prvi snapshot samo priprema, novi unread, nova konverzacija, stara istorija tiha, čitanje tiho), `incomingMessageSoundProvider` (zvuk za DM, tišina kad su notifikacije isključene, sopstvene poruke, grupni zvuk samo kad OS notifikacija nije čujna), `ChatInputBar` (više linija, newline na telefonu ne šalje, Enter šalje na desktopu a Shift+Enter ne). |
| `test/kragujevac_city_test.dart` | 13 | Kragujevac: izbor grada i kvartovi, koordinate, čuvanje ugrađenog grada kad ga nema u Firestore-u, labele sa/bez dijakritika, discover filter/oblast, seed POI (jedinstveni id, idempotentan merge, cityId i koordinate, kategorije, neverifikovani nisu „verified“), odbijanje nevalidnih koordinata, opciona polja, promena kamere. |
| `test/location_label_test.dart` | 1 | Uklanjanje dupliranog dela (suburb) u labeli lokacije. |
| `test/lost_dogs_test.dart` | 3 | Izgubljeni psi: poklapanje nađenog i izgubljenog psa (kvart + rasa), kartica i CTA za prijavu, „nađeni“ tab sa zelenim kontaktom i banerom poklapanja. |
| `test/lost_dog_neighborhood_test.dart` | 2 | Proširena lista kvartova Beograda; ručno unet kvart u prijavi. |
| `test/map_test.dart` | 4 | Mapa: „Započni/Završi šetnju“, pinovi i bottom sheet, prebacivanje na Beograd, dodavanje korisničkog mesta. |
| `test/message_bubble_avatar_test.dart` | 4 | Message bubble: tap na tekst ne otvara profil, tap na avatar otvara, tap na foto otvara full-screen, sopstvene poruke bez avatara. |
| `test/moments_test.dart` | 4 | Priče ističu posle 24h, prikaz i puštanje priča, istekla priča vidljiva kroz highlight, kreiranje highlight-a iz arhive. |
| `test/nis_city_test.dart` | 7 | Niš: izbor grada, koordinate centra, ugrađeni grad bez Firestore-a, seed POI blizu centra, discover filter ignoriše radius, labele sa/bez dijakritika, discover oblast skriva druge gradove. |
| `test/nis_places_test.dart` | 16 | Niš mesta: Niš/Nis isti id, centar 43.3209/21.8958; seed podaci (cityId i različite koordinate, jedinstveni id, uklonjeni neverifikovani kafići, pet politike, samo ograđeni Čair kao zvanični dog park, nijedan veterinar 24/7 bez dokaza, posebne filijale pet shopova, legacy „Park za pse“ badge); merge sa Firestore-om (admin mesto zamenjuje seed, 0,0 ne postaje marker, opciona polja); mapa (samo Niš markeri, detalji markera, prelazak na Beograd uklanja Niš markere). |
| `test/notifications_test.dart` | 2 | Feed notifikacija na srpskom sa isticanjem nepročitanih; notifikacija šetnje otvara Map tab. |
| `test/profile_test.dart` | 4 | Profil: učitavanje, izmena i čuvanje psa, promena izabranog psa, otvaranje podešavanja i filtera. |
| `test/reminder_schedule_test.dart` | 18 | `ReminderSchedule.nextOccurrence` (dnevno, nedeljno, mesečno, 3/6 meseci, godišnje, clamp 31. jan, prestupna godina) i `advanceToUpcoming`/`rolledForward` (višestruki propušteni ciklusi, `lastCompletedDate`, ne pomera na dan dospeća, `once`, custom 2 nedelje i meseci, dnevni/nedeljni propusti, čuvanje dana u mesecu posle februara, `rollForwardDueReminders` čuva i ponovo zakazuje). |
| `test/safety_test.dart` | 3 | Mapiranje statusa/targeta prijava, repozitorijum blokiranih emituje promene, momenti skrivaju blokirane autore. |
| `test/scheduled_walks_test.dart` | 3 | Zakazane šetnje: prihvaćene šetnje se vide bez otvorenog chata, ostaju posle gubitka poruka, novi prihvaćeni poziv se pojavljuje bez otvaranja chata. |
| `test/schedule_walk_sheet_test.dart` | 4 | Sheet za zakazivanje šetnje: naslov/polja/dugmad vidljivi, dugmad vidljiva sa tastaturom, u kratkom viewport-u i u `showModalBottomSheet`. |
| `test/settings_test.dart` | 4 | Podešavanja: prekidači notifikacija, feedback pri uključivanju, slider radijusa sinhronizovan sa filterima, prekidač lokacije bez akcija naloga. |
| `test/splash_test.dart` | 1 | Splash prikazuje samo brendiranu sliku. |
| `test/storage_owner_folder_test.dart` | 5 | Storage putanje: ugnježđavanje pod uid, zadržavanje ispravnih putanja, ispravka pogrešnog segmenta, eksplicitni `ownerId`, izuzetak bez prijavljenog korisnika. |
| `test/support_test.dart` | 5 | Podrška: mailto i društvene mreže URI, tabovi pravila/saveta, prijava → admin forma, zvanični kontakt linkovi, validacija i slanje feedback-a. |
| `test/widget_test.dart` | 3 | Routing posle splash-a: odjavljen → login, prijavljen bez psa → onboarding, prijavljen sa psom → discover. |

#### Fakes (`test/fakes/`)
- `test/fakes/fake_auth_repository.dart` – `FakeAuthRepository implements AuthRepository`: in-memory `AppUser?`; `watchUser` emituje jednu vrednost; email prijava/registracija pravi korisnika `uid: 'fake'`; Google prijava → `uid: 'google'`, `google@example.com`; `signOut`/`deleteAccount` brišu korisnika; `saveUserProfile`/`saveOwnerCustomPhoto` ažuriraju lokalni objekat; `sendPasswordResetEmail` ne radi ništa.
- `test/fakes/fake_dogs_repository.dart` – `FakeDogsRepository implements DogsRepository`: in-memory lista; `createFirstDog` pravi `dog-1` u Novi Sad/Liman; `updateDog` upsert; `deleteDog` uklanja. Helper `fakeDog()` vraća „Luna“, Golden Retriever, ženka, 3 god., velika, visoka energija, foto `https://example.com/luna.jpg`.

#### Nativni testovi
- `ios/RunnerTests/RunnerTests.swift` i `macos/RunnerTests/RunnerTests.swift` – prazni šablonski XCTest-ovi. Nema Android instrumentation/unit testova. Nema `integration_test/` foldera u opsegu.

### 11.2 Hardkodovano, privremeno, tehnički dug – po modulima
#### 11.2.1 Core, app, servisi, auth, splash, legal, lokacija, home
##### TODO/FIXME/HACK/XXX
- U celom `lib/` nema nijednog `TODO`, `FIXME`, `HACK` ni `XXX` komentara.
- Ekvivalentni „privremeni“ komentari:
  - `lib/features/auth/presentation/auth_screen.dart:19–20` – `// Phase: Google Sign-In hidden — re-enable with google_sign_in_button.dart`.
  - `auth_screen.dart:219–228` – zakomentarisana metoda `_signInWithGoogle`.
  - `auth_screen.dart:319` – `// Phase: Google Sign-In UI hidden — restore divider + GoogleSignInButton here.`
  - `lib/features/home/domain/app_drawer_catalog.dart:120` – „Legacy flat lists kept for callers that still iterate all destinations.“ (nema takvih poziva).
  - `lib/services/storage_service.dart` / `image_upload_service.dart:6–9` – „Prefer [StorageService] directly. This wrapper keeps older call sites working“.
  - `account_deletion_service.dart:138` – „Legacy top-level highlights (if any).“

##### Hardkodovane vrednosti
- `lib/firebase_options.dart:7–9` – web koristi **Android** Firebase opcije (`if (kIsWeb) return android;`); nema web app konfiguracije. `default:` (Windows/macOS/Linux) takođe Android (linija 16).
- `lib/firebase_options.dart:35` – `iosBundleId: 'com.example.vauvau'`, dok komentar na liniji 22 kaže da je Android paket `com.vauvau.app` („not com.example.vauvau“) – iOS bundle id izgleda kao šablonski.
- `lib/firebase_options.dart:21, 30` – API ključ hardkodovan (vrednost namerno izostavljena).
- `lib/features/auth/data/local_auth_repository.dart:7–12, 34–38` – demo korisnik `uid 'local-user'`, email `'aleksandar@vauvau.local'`, ime `'Aleksandar'`, grad `'Novi Sad'`.
- `lib/features/legal/domain/legal_urls.dart:11–14` – `https://vauvau-3195a.web.app/privacy` i `/terms`.
- `lib/features/legal/presentation/legal_document_bodies.dart:16, 18, 97, 102, 205–206` i `legal_strings.dart:42–43` – email `vauvau.app@gmail.com` hardkodovan u tekstu (6+ mesta).
- `legal_document_bodies.dart:119, 122` – tekst pominje `vauvau.app/privacy`, a `LegalUrls` koristi `vauvau-3195a.web.app/privacy` – nekonzistentno.
- `legal_strings.dart:26–29` – datum „12. oktobar 2026.“ hardkodovan.
- `legal_document_bodies.dart:95–97` – politika tvrdi da brisanje naloga briše „momente, vaše chat poruke, mečeve, oglase i događaje“ – u skladu sa `AccountDeletionService`, ali proces je best-effort (vidi rizik iznad).
- `lib/core/geo/geo.dart:19–22` – koordinate gradova; `GeoCoord.forCityName`/`forCityId` padaju na Novi Sad za svaki nepoznat grad.
- `lib/features/location/domain/user_location.dart:18–22` – `noviSadFallback`.
- `lib/core/constants/serbia_locations.dart` – sve lokacije i naselja hardkodovani; `adoptionCities` (163–169) i `noviSadAdoptionNeighborhoods` (171–196) dupliraju podatke iz `cities` sa drugačijim nazivima (npr. „Centar (Stari Grad)“ vs „Centar“, „Detelinara (Stara i Nova)“).
- `serbia_locations.dart:198–216` – `neighborhoodsForAdoptionCity`: Novi Sad i Beograd **nemaju** opciju „Ostalo“ na kraju, a Niš/Kragujevac imaju – nekonzistentno.
- `lib/core/constants/dog_breeds.dart:6–63` – lista rasa (mešavina srpskih i engleskih naziva, npr. „Beagle“, „Greyhound“, „Newfoundland“).
- `lib/core/images/fallback_image_helper.dart:16–25` – 10 Unsplash URL-ova; komentar u `dog_photo_urls.dart:1` kaže „never persist stock Unsplash“ – prikazuju se samo, ali zavise od eksternog CDN-a. Konstante `captionBackground`/`captionForeground` (11–12) se ne koriste u fajlu.
- `lib/core/utils/content_validation_service.dart:11–31` – hardkodovana lista psovki; provera `lower.contains(word)` (linija 49) daje lažne pozitivne rezultate (npr. reči koje sadrže „shit“, „jebi“ kao podstring); poruke samo na srpskom (6–9).
- `lib/core/widgets/ui_bits.dart:221` – `GenderIcon`: muški samo ako je `gender == 'mužjak'` (hardkodovan srpski string; sve ostalo, uključujući prazno, prikazuje se kao ženski).
- `lib/core/widgets/comment_like_button.dart:10` – tooltip `'Lajk'` nije lokalizovan.
- `lib/core/widgets/feed_state.dart:139, 247, 256` – `'Pokušaj ponovo'`, `'VauVau'`, `'Došlo je do greške. Pokušajte ponovo.'` nisu kroz `L10n`.
- `lib/features/auth/domain/auth_exception.dart:14` – default poruka `'Prijava nije uspela.'` nije lokalizovana.
- `lib/services/storage_service.dart:53, 102, 112, 129, 248, 304, 320, 336, 348, 455–467` – sve poruke grešaka na srpskom, nelokalizovane; `:455–456` korisniku prikazuje developersko uputstvo („U Console → Storage → Rules objavi pravila iz storage.rules.“).
- `lib/core/images/image_upload_service.dart:66` – `'Upload na Firebase Storage nije uspeo.'`.
- `lib/core/services/notification_service.dart:24–31` – nazivi kanala samo na srpskom; `reminderHour = 9`.
- `lib/features/location/data/geolocator_location_client.dart:9–17` – tekst foreground notifikacije samo na srpskom.
- `lib/features/splash/presentation/screens/splash_screen.dart:16–17` – `tagline` i `hold = 2 s` (fiksno kašnjenje pri svakom pokretanju).
- `lib/app/firebase_init_error_app.dart:18` – fiksno `ThemeMode.dark`; tekst greške (`app_strings.dart:17–20`) je developerska instrukcija.
- `lib/features/home/presentation/home_drawer.dart:35, 176–178, 289, 320, 326, 340` – hardkodovane boje (drawer ne prati light temu).
- `lib/features/home/domain/app_drawer_catalog.dart:43, 57` – `brandHeader` i `locationPin` nisu lokalizovani (emoji).
- `lib/features/auth/presentation/forgot_password_dialog.dart:33` – regex email-a ograničava TLD na 2–4 znaka (odbija npr. `.agency`, `.photography`).
- `lib/features/auth/presentation/auth_screen.dart:615–621` – validacija email-a samo `contains('@')`.
- `lib/core/constants/app_strings.dart:136–139` vs `202–205` – `stepPhotosHint` kaže „opciono, do 5“, a `dogPhotosRequired` „Dodajte između 1 i 5 fotografija“ – kontradiktorno (koja važi zavisi od onboarding koda van slice-a).

##### debugPrint ostaci (izbor; svi su aktivni i u release build-u jer `debugPrint` nije uslovljen)
- `lib/main.dart:51–52` – `'🔴 MAIN CATCH: $error'`, `'🔴 STACK: $stack'`.
- `lib/core/widgets/feed_state.dart:286–287, 306–307` – `'🔴 FLUTTER ERROR…'`, `'Global Async Error…'`.
- `lib/features/auth/data/firebase_auth_datasource.dart:97` – loguje **email adresu** korisnika pri resetu lozinke (PII u logu).
- `lib/features/auth/presentation/forgot_password_dialog.dart:64, 77, 81, 118–120, 157–158` – uključujući `'Šaljem reset e-mail na: $email'` (PII).
- `lib/features/auth/presentation/auth_screen.dart:171`; `auth_repository_impl.dart:48, 122, 293`.
- `lib/services/storage_service.dart:117–119, 138–140, 258–262, 265–266, 313–317, 327, 334, 361–362` – loguje putanje, bucket i pune download URL-ove (sa tokenima).
- `lib/core/images/dog_image.dart:151, 249–252, 274–277, 308–311, 371–373, 406–408` – loguje URL-ove slika.
- `lib/core/firebase/firestore_auth_guard.dart:32, 92, 155`; `notification_service.dart:54, 73–74, 117, 188–189, 257, 302–303, 315`; `message_sound_player.dart:24`; `account_deletion_service.dart:200, 228, 271–272`.

##### Sumnjiv kod / bagovi (na osnovu čitanja koda)
- **Upload slike na registraciji pre prijave** – `auth_screen.dart:186–217` zove `StorageService().uploadImageFromGallery(folderName: 'users')`; `StorageService.ownerFolder` (`storage_service.dart:48–54`) baca `StateError` ako nema prijavljenog korisnika → za novog korisnika upload ne može uspeti. Ceo „belt-and-suspenders“ blok (158–178) je zato najverovatnije mrtav kod. (Zaključak iz koda, nije testirano.)
- **Redosled brisanja naloga** – `auth_repository_impl.dart:170–171`: prvo brisanje podataka, pa `user.delete()`; `requires-recent-login` ostavlja nalog bez podataka. `AccountDeletionService` ne hvata greške u `_deleteQuery`/`_deleteSubcollection`/`_deleteOwnedDocs` → jedan odbijen upit (npr. rules) prekida brisanje usred procesa.
- **Brisanje kolekcije `matches` dvaput** (`account_deletion_service.dart:84–91`) – dva upita (`userIds`, `participantIds`) jer šema očigledno nije ujednačena; isto za `notifications` (`toUserId` i `recipientId`, 94–101).
- `account_deletion_service.dart:220–222` – `memberCount` se dekrementira samo ako je `arrayField == 'memberIds'`; ne proverava da li je `arrayRemove` zaista nešto uklonio (u ovom upitu jeste, jer filtrira po `arrayContains`), ali nema transakcije – moguće trke.
- `main.dart:42–47` – provera `projectId.isNotEmpty` je uvek tačna (projectId dolazi iz hardkodovanih opcija), pa ne proverava stvarnu dostupnost Auth/Firestore.
- `main.dart:32` – `NotificationService().initialize()` pravi zasebnu instancu; `notificationServiceProvider` (`notification_service.dart:339–341`) pravi drugu. Handler `onNotificationTap` je po instanci – da li je postavljen na pravoj instanci zavisi od koda van slice-a.
- `main.dart:15–27` – background FCM handler ne radi ništa osim inicijalizacije Firebase-a (`catch (_) {}` guta greške).
- `firestore_auth_guard.dart:149–168` – `guardedStream` pretvara **sve** greške streama u `empty` vrednost; UI ne može razlikovati „prazno“ od „greška“.
- `auth_repository_impl.dart:47–52` – greška user-doc streama dok je korisnik prijavljen se samo loguje; korisnik ostaje sa „Auth-only“ podacima (bez role → nije admin, bez grada).
- `auth_repository_impl.dart:403–406` – za postojeći dokument `dog` se čita iz `existing['dog']`, ali se ne upisuje (`includeDog: existing == null`) – redundantno.
- `auth_screen.dart:231–241` + `389–395`/`583–589` – ista greška prikazana i kao SnackBar i kao inline tekst; inline greška iz kontrolera se pojavljuje u oba taba.
- `auth_screen.dart:95, 182` – `popUntil(isFirst)` posle prijave: `AuthScreen` je već sadržaj prve rute (`AuthGate`), pa je ovo uglavnom no-op (osim ako je neki dijalog/ruta otvorena).
- `auth_controller.dart:102–107` – `sendPasswordResetEmail` nekorišćen; dijalog duplira logiku i zaobilazi repozitorijum.
- `auth_providers.dart:20` i `firebase_auth_datasource.dart:16` – `GoogleSignIn(scopes: ['email','profile'])` definisan dvaput.
- `auth_gate.dart:29–31` – ako `ownerDogsProvider` padne sa greškom, korisnik ide pravo na `HomeShellScreen` čak i bez psa (zaobilazi onboarding).
- `home_drawer.dart:112–117, 52–53, 61–62` – grana za `DrawerItemKind.tab` i `selected` logika su mrtav kod (nijedna stavka nema `tabIndex`).
- `home_drawer.dart:137, 362–385` – `DrawerSectionScreen` nedostupan.
- `geolocator_location_client.dart:9–17` vs `location_strings.dart:14–17` i `legal_document_bodies.dart:70–73` – notifikacija kaže „lokacija se prati u pozadini“, a disclosure/politika „Ne tražimo ‘uvek dozvoli’ pristup u pozadini“; na iOS-u walk podešavanja imaju `allowBackgroundLocationUpdates: true` (139–146). Nije nužno kontradikcija (foreground servis), ali formulacije nisu usklađene.
- `content_validation_service.dart:48–51` – `RegExp(...).hasMatch(lower) || lower.contains(word)` – druga provera čini prvu (sa granicama reči) besmislenom.
- `content_validation_service.dart:72–90` – `validateImage` vraća `null` (prolaz) i pri izuzetku i za fajlove bez ekstenzije.
- `dog_image.dart:199–200, 288–317` – `_bytesFallbackStarted` se resetuje u `_prepare`, ali `_loadBytesFallback` se poziva iz `addPostFrameCallback` unutar `errorBuilder`-a; složena logika sa više `debugPrint`-ova.
- `storage_service.dart:41` – statički `_bytesCache` deljen između svih instanci (`StorageService()` se instancira na mnogo mesta); FIFO izbacivanje preko `keys.first`.
- `app_image_provider_io.dart:28–35` – `try/catch` oko `File.existsSync()` pa u oba slučaja vraća `FileImage(File(path))` – `try` blok je suvišan.
- `l10n.dart:5` – jezik je globalno statičko stanje (`L10n._language`) koje postavlja `VauVauApp.build` (`app.dart:30`) kao sporedni efekat u `build` metodi.
- `local_auth_repository.dart:29–40` – lokalna prijava ignoriše lozinku i uvek postavlja ime „Aleksandar“.

##### Neiskorišćen / mrtav kod u slice-u
- `lib/app/routes.dart` (`AppRoutes`) – ceo fajl.
- `lib/features/auth/presentation/register_screen.dart` (`RegisterScreen`) – koristi ga samo `AppRoutes`.
- `lib/features/auth/presentation/widgets/google_sign_in_button.dart` – ceo fajl.
- `lib/features/splash/presentation/widgets/splash_clouds.dart`, `splash_mascot.dart` – ceo fajl.
- `lib/core/widgets/illustration_placeholder.dart` – ceo fajl.
- `lib/core/images/app_image_provider*.dart` – `appImageProvider` nema poziva.
- `GeoHash.coveragePrefixes`/`precisionForRadiusKm` – nema poziva u `lib/`.
- `AppStrings.tagline`, `getStarted`, `homeShellPlaceholder` („Početni ekran. Otkrij, mečevi i profil biće ovde.“ – ostatak placeholder-a), `illustrationPlaceholder` (koristi ga samo nekorišćen widget).
- `LegalStrings.registerConsent` (duplira tekst iz `LegalConsentText`); `AppDrawerCatalog.home/profile/support/locationPin/primaryItems/footerItems/items`.
- `SplashScreen.tagline`, `SplashScreen.background` (komentar kaže da odgovara temi, ali `build` koristi `colorScheme.surface`).
- `AuthController.busy`, `AuthController.sendPasswordResetEmail`, `AuthController.signInWithGoogle` (UI ga ne zove), `AuthErrorCode.userNotFound`.
- `FallbackImageHelper.captionBackground/captionForeground`.

##### Duplirana logika
- Reset lozinke: `ForgotPasswordDialog` (direktno Firebase) vs `AuthController`→repo→datasource.
- Upis owner fotografije: `_upsertUser` (writeOwnerPhoto) + `updatePhotoURL` u `signUp` + ponovo `saveOwnerCustomPhoto` iz `AuthScreen`.
- Magic-byte detekcija slika: `ContentValidationService._looksLikeSupportedImage` i `StorageService._sniffImageContentType`.
- Mrežna detekcija grešaka: `FirestoreAuthGuard.isSoftFailError` i `isNetworkFailure` (preklapajući string-match).
- Lokacije za udomljavanje (`adoptionCities`, `noviSadAdoptionNeighborhoods`) vs `SerbiaLocations.cities`.
- Izračunavanje dimenzija u `_FirebaseStorageImageState.build` i `_memoryImage` (copy-paste `LayoutBuilder` blok).
- Polja fotografija: isti URL se upisuje u 5 polja (`photoUrl`, `imageUrl`, `photos`, `photoUrls`, `galleryUrls`) radi kompatibilnosti sa više šema; `dogs` doc piše i `age` i `ageYears`; `users` doc piše i `city` i `cityName`.

##### Nejasno / nije moguće utvrditi iz slice-a
- Stvarni sadržaj tabova (`DiscoverScreen`, `MapScreen`, `MatchesScreen`, `ProfileScreen`) i ekrana iz drawera – van slice-a.
- Da li `notificationServiceProvider` instanca dobija `onNotificationTap` (postavlja se van slice-a).
- Firestore/Storage security rules (`storage.rules` se pominje u poruci greške, ali nisu deo ovog dela).
- Gde se tačno poziva `AuthController.signOut()` (van slice-a).

#### 11.2.2 Chat, grupe, događaji
##### TODO / FIXME / HACK
- U celom delu (chat, groups, events) **nema** `TODO`, `FIXME`, `HACK` ni `XXX` komentara (grep potvrđen).
- Komentar koji ukazuje na fazni razvoj: `chat/presentation/widgets/chat_ui.dart:7` – „Shared chat / inbox visual tokens (Phase 4 Step 5).“

##### Verovatni bagovi (zaključak iz koda)
1. **Prvi lajk na grupnoj/event poruci baca izuzetak:** `firestore_groups_repository.dart:413` i `firestore_events_repository.dart:418` – `final ids = _stringList(data['likes'])`; `_stringList` (l. 423–431 / 428–436) vraća `const []` kada `likes` ne postoji (a `sendMessage`/`sendWalkInvite` nikad ne pišu `likes`) → `ids.add(currentUserId)` nad nemodifikujućom listom → `UnsupportedError`. Lokalne implementacije nemaju ovaj problem.
2. **Skok na prvu nepročitanu u 1:1 ne radi kad se ulazi iz inbox-a:** `chat_list_screen.dart:351` poziva `markRead` (sinhrono postavlja `unreadCount: 0` u repo inbox-u i stanju kontrolera) PRE `push`-a, a `ChatDetailScreen` (l. 65–66) čita `unreadCount` tek u postFrame-u → `_openUnreadCount` je 0. Slično za grupe/događaje (`chat_list_screen.dart:360, 369` – async markRead pre push-a; ishod zavisi od trke sa `lastRead` stream-om).
3. **`chatNowProvider` (chat_inbox.dart:282)** je `Provider((ref) => DateTime.now())` bez zavisnosti → računa se jednom i kešira; `formatChatTimestamp` u listi i `ChatDetailScreen` koristi zastarelo „sada“ (npr. „Juče“ se ne ažurira posle ponoći dok se provider ne invalidira).
4. **`openFromMatch` može prepisati postojeću sobu:** `firestore_chat_repository.dart:407` proverava samo lokalni `_inbox`; ako inbox još nije učitan (npr. tokom 1000 ms cache hold-a ili pre `start`), `_createRoom` radi `set(merge)` sa `lastMessage: ''`, `unreadByUser: {me:0, peer:0}`, `isNewMatch: true` nad postojećom sobom.
5. **`location` sobe nije po korisniku:** `_createRoom` piše `location` (i `dogId`, `dogName`… kao fallback) iz perspektive kreatora, a `_conversationFromRoom` (l. 987) čita `data['location']` bez mape po uid-u → druga strana vidi lokaciju sopstvenog psa.
6. **`notifyMessage` fallback ime pošiljaoca:** `chat_inbox.dart:99–100` i `174–175` – ako `displayName` nije postavljen, kao `senderName` se koristi `chat.ownerName`, što je ime PEER-a (primaoca), ne pošiljaoca.
7. **1:1 lajk preko `update` celog niza** (`firestore_chat_repository.dart:782–786`) – nije atomičan (nema `arrayUnion`/transakcije) i, ako poruka nije hidratisana, prepisuje tuđe lajkove.
8. **Optimistička poruka i snimak:** `_onMessages` (l. 301–322) zamenjuje celu listu poruka razgovora snimkom bez spajanja po id-ju; optimističke `local-N` poruke se tako gube pri prvom sledećem snimku (što je namerno kad snimak sadrži pravu poruku, ali nema zaštite za slučaj da još ne sadrži).
9. **`totalUnreadChatCountProvider` (chat_inbox.dart:352)** koristi `chatInboxProvider` umesto `visibleConversationsProvider` → nepročitani razgovori sa blokiranim korisnicima i dalje povećavaju badge.
10. **Group/Event chat bez obrade grešaka:** `group_chat_screen.dart:264–291` (`_sendText` – tekst se obriše pre slanja i ne vraća se), `332–352` (`_openScheduleWalk`), `425–442` (`_respondToWalk`); `groups_list_screen.dart:51–61` (`_join`); `events_screen.dart:164–174` (`_join`).
11. **`_jumpToEndWithRetry` u `group_chat_screen.dart:208–236`** nema `WidgetsBinding.instance.scheduleFrame()` koji postoji u `chat_detail_screen.dart:201, 208` uz komentar da bez njega kod kratkog chata `markRead` možda nikad ne bude pozvan.
12. **`deleteGroup` (firestore_groups_repository.dart:250)** briše samo dokument; podkolekcije `messages` i `members` ostaju (Firestore ne briše kaskadno).
13. **`sendMessage` u `FirestoreEventsRepository` (l. 173–217)** prima `senderId` ali ga ignoriše; potpis interfejsa (`events_repository.dart:19`) obećava override.
14. **`isRead` u `chats/.../messages`** se piše kao `false` i nikad ne ažurira – mrtvo polje u Firestore režimu.
15. **`GroupInboxThread.fromMessages` (groups_models.dart:264)** – bez `lastRead` cutoff je `DateTime.now()` → unread 0; za novog člana koji nije dobio `members/{uid}` (npr. greška u best-effort upisu) brojač nikad ne raste do prvog markRead.
16. **Stanje grupe/događaja „pending“ status:** `respondToWalkInvite` uvek piše `'status': 'pending'` (firestore_groups_repository.dart:364, firestore_events_repository.dart:287) – namerno (status je po korisniku u nizovima), ali polje `status` je tada beskorisno za grupe.

##### Seed / mock podaci u produkcionim putanjama
- `firestore_groups_repository.dart:24–62` – `ensureSeeded()` se izvršava pri **svakom** novom `FirestoreGroupsRepository` (provider se rebuild-uje pri svakoj promeni `authStateProvider`): 9× `get` + 9× `set(merge)` iz klijenta, uz upis **lažnih `memberCount`** (45, 42, 41, 38, 34, 31, 29, 28, 22 – `seed_breed_groups.dart:20–100`) dok niko nije član. Zahteva da klijent ima pravo upisa na `breed_groups` (rules nisu u ovom delu). Plus hardkodovano brisanje `vlasnici-malih-pasa-novi-sad` (`seed_breed_groups.dart:11`).
- `firestore_events_repository.dart:30–49` – ako je `events` prazna, klijent upisuje 3 seed događaja sa **lažnim učesnicima** `'seed-1'..'seed-11'` (`seed_events.dart:67–79`) i organizatorom `'vauvau'` → UI prikazuje npr. „11 vlasnika zainteresovano“. Inače `_scrubStockCdnImages()` čita CELU `events` kolekciju pri svakom novom repozitorijumu (l. 52–73).
- `SeedEvents.all` (`seed_events.dart:83`) je `static final` sa datumima relativnim na prvi pristup → seed događaji posle ~7 dana nestaju iz liste (`isListed`).
- `chat_inbox.dart:212–214, 242–243` – `chatSeedProvider` (mock razgovori iz `mock_conversations.dart`, peer id `'owner-<dogId>'`, moj pas `'my-dog'`, korisnik `'local-user'`) koristi se samo kada `isFirebaseReady == false`.
- `incoming_likes.dart:37` – hardkodovan id lokalnog psa `'local-luna'`.
- `mock_conversations.dart` – hardkodovani razgovori na srpskom (nisu lokalizovani).

##### Hardkodovane vrednosti
- Lokacije: `walk_locations.dart:1–5` (`'Kej Žrtava Racije'`, `'Limanski Park'`, `'Dunavski Park'` – samo Novi Sad, koriste se u schedule i location sheet-u za sve gradove); `seed_events.dart:11–29` (`EventVenues.names` + LatLng koordinate).
- `messagePageSize = 30` (`firestore_chat_repository.dart:51`), `limit 30` i u `local_chat_repository.dart:77–80`.
- Tajmeri: cache hold 1000 ms (`firestore_chat_repository.dart:150`), debounce 80 ms (l. 321), zvuk min razmak 1500 ms (`incoming_message_sound.dart:58`), freshness 1 min (l. 26), `scheduledWalksClockProvider` 1 h (`chat_inbox.dart:287`), `listGrace` 6 h (`event_model.dart:40`), batch 400 (`firestore_events_repository.dart:64`).
- Skrol: prag „blizu dna“ 120 px (`chat_detail_screen.dart:121`, `group_chat_screen.dart:142`), `alignment: 0.08`, 3 pokušaja.
- Opsezi datuma: +60 dana (`schedule_walk_sheet.dart:220`), +365 dana (`create_event_screen.dart:261`); default vreme 18:00 (`schedule_walk_sheet.dart:35`).
- Kvalitet slike `imageQuality: 72` (`chat_detail_screen.dart:699`, `group_chat_screen.dart:386`); u `create_event_screen.dart:313` bez `imageQuality`.
- `sortOrder: 999` za korisničke grupe (`firestore_groups_repository.dart:212`, `local_groups_repository.dart:106`).
- Boje van teme: `0xFF16A34A` (`chat_detail_screen.dart:381`), `0xFFE11D48` (`chat_list_screen.dart:435`), `0xFF2E7D32` (`group_card.dart:83`, `events_promo_banner.dart:14`), `0xFF15803D` (`event_card.dart:144`, `events_screen.dart:127`), `Colors.green/red` u dijalozima.
- Fallback profil: `size: 'srednji'`, `location: 'Srbija'` (`chat_detail_screen.dart:556–557`, `group_chat_screen.dart:475–476`).
- Fallback imena: `'Ti'`, `'Korisnik'`, `'Član'`, `'Neko'`, `'VauVau'`, `'vauvau-system'` raštrkano (chat_inbox.dart:103,178,225; firestore_chat_repository.dart:689,692; groups_controller.dart:130,143; events_controller.dart:142,171,184; local_events_repository.dart:78–79; firestore_groups_repository.dart:280; firestore_events_repository.dart:206,305).
- Fallback slova avatara `'Č'` (`message_reply.dart:22`).

##### Nelokalizovani stringovi (zaobilaze `L10n.tr`)
- `'📷 Fotografija'`: `chat_message.dart:71`, `firestore_chat_repository.dart:641`, `chat_inbox.dart:179`, `groups_models.dart:207`, `firestore_groups_repository.dart:267`, `firestore_events_repository.dart:193`.
- `'Poziv na šetnju'` / `'Poziv na šetnju: $x'`: `firestore_chat_repository.dart:551`, `local_chat_repository.dart:191`, `groups_models.dart:201`, `firestore_groups_repository.dart:319`, `local_groups_repository.dart:184`, `firestore_events_repository.dart:244`, `local_events_repository.dart:144`. Ovaj tekst se i čuva u Firestore-u (`text`, `lastMessage`) pa ga engleski korisnik vidi na srpskom.
- `message_reply.dart:85` (`'Poruka'`), `:147` (`'Odgovor za …'`/`'poruku'`), `:169` (`'Otkaži odgovor'`), `:196` (`'Odgovori na poruku'`), `:202` (`'Prijavi poruku'`), `:207` (`'Otkaži'`).
- `chat_time.dart:12` (`'Juče'`).
- `local_events_repository.dart:289` (`EventsJoinCopy.joined` – čuva se u Firestore kao tekst poruke).
- Poruke izuzetaka na srpskom koje se prikazuju u dijalozima: `'Morate biti prijavljeni.'`, `'Naziv grupe je obavezan.'`, `'Naslov je obavezan.'`, `'Lokacija je obavezna.'`, `'Poruka mora imati senderId ulogovanog korisnika.'`.

##### Debug logovi
- `debugPrint`: `incoming_likes.dart:82`, `groups_controller.dart:24`, `events_controller.dart:28, 160–161`, `firestore_events_repository.dart:330` (**loguje ceo payload događaja**, uključujući `organizerUserId`), `:337–338`.
- `developer.log`: `firestore_chat_repository.dart:89, 183, 234, 853, 935`.

##### Nekorišćen / mrtav kod
- `EventsPromoBanner` (`events_promo_banner.dart`) – nigde se ne koristi.
- `ConversationTitle` (`dog_avatar.dart:35–44`) – nigde se ne koristi.
- `chatMessagesProvider` (`chat_inbox.dart:293–296`) i `ChatRepository.watchMessages` – nema korisnika u `lib/`.
- `ChatRepository.watchRooms()` / `ChatRoom` / `ChatConversation.room` – `watchRooms` nema korisnika u `lib/`.
- `sortedGroupsProvider` (`groups_controller.dart:219–224`) – nema korisnika.
- `ChatInboxController.newMatches` / `threads` – ne koriste se nigde u `lib/` ni `test/` (grep); `ChatListScreen` računa iste liste sam.
- `ScheduledWalk`/`chat_time` OK; `lastMessageSenderId` u `breed_groups` – piše se, nikad ne čita.
- Suvišni ternari: `chat_conversation.dart:55–58` (obe grane `last.text`), `local_groups_repository.dart:105` (`currentUserId.isEmpty ? 1 : 1`).
- Omotači `ChatScreen` → `ChatDetailScreen` i `MatchesScreen` → `ChatsScreen` → `ChatListScreen` (tri sloja bez logike).

##### Performanse / trošak Firestore-a
- Walk-invite listener za **svaku** sobu u inbox-u bez limita (`firestore_chat_repository.dart:204–245`) → N paralelnih listenera.
- `joinedGroupThreadsProvider` / `joinedEventThreadsProvider` drže pun (bez limita) stream poruka i `lastRead` listener za svaku grupu/događaj u kom je korisnik – uključujući davno prošle događaje (nema `isListed` filtera u `events_controller.dart:238–250`); ti događaji ostaju i u inbox listi zauvek.
- `breed_groups.snapshots()` i `events.orderBy('dateTime').snapshots()` – cele kolekcije bez `where`/`limit`; filtriranje po odobrenju/gradu/datumu na klijentu.
- `rawIncomingLikesProvider` – za svaki lajk dodatni `loadDiscoverProfile` pri svakom snimku (`asyncMap`).
- `ensureSeeded` / `_scrubStockCdnImages` pri svakom rebuild-u providera (vidi gore).
- Dva odvojena upita nad `chats` ako bi se `watchRooms` koristio zajedno sa `start()`.

##### Veliki fajlovi koje vredi podeliti
- `firestore_chat_repository.dart` (1066) – inbox state machine, walk-invite listeneri, optimistički update-i i mapiranje u jednoj klasi.
- `group_chat_screen.dart` (843) – ekran za dva domena (grupa i događaj) sa `if (widget.isEvent)` granama u ~10 metoda + privatni bubble.
- `chat_detail_screen.dart` (731), `chat_list_screen.dart` (647 – `build` ima ~300 linija duboko ugnježdenog widget stabla, l. 41–347).

##### Duplirana logika između chat / groups / events
- `FirestoreGroupsRepository` ↔ `FirestoreEventsRepository`: `watchMessages`, `watchLastRead`, `markRead`, `sendMessage`, `sendPhoto`, `sendWalkInvite`, `respondToWalkInvite`, `toggleMessageLike`, `_messageFromDoc`, `_stringList`, parsiranje statusa – praktično identično (razlike: `lastMessageSenderId`, `_clipReply`, ignorisani `senderId`).
- `LocalGroupsRepository` ↔ `LocalEventsRepository`: `_append`, `_messageControllerFor`, `_readControllerFor`, `respondToWalkInvite`, `toggleMessageLike`, `dispose`.
- `ChatDetailScreen` ↔ `GroupChatScreen`: `_isNearBottom`, `_scrollToEnd`, `_maybePerformInitialScroll`, `_jumpToEndWithRetry` (sa razlikom – vidi bag 11), `_finishInitialScroll`, `_onMessagesUpdated`, `_pickPhoto` sheet, `_openSenderProfile` fallback `DiscoverProfile`.
- `MessageBubble` ↔ `_GroupMessageBubble` (`group_chat_screen.dart:694–843`) – isti raspored, slika, reply, lajk.
- `ChatMessage` ↔ `GroupMessage` (dva modela poruke; `_groupWalkAsChat` konvertuje jedan u drugi da bi se iskoristio `WalkInviteCard`); `ChatMessage.clipReplyText` ↔ `FirestoreGroupsRepository._clipReply`; `ChatMessage.statusFromKey` ↔ `_statusFromKey` (grupe) ↔ inline switch (događaji).
- `groupsMemberIdProvider` ↔ `eventsMemberIdProvider` (identični); `joinedGroupThreadsProvider` ↔ `joinedEventThreadsProvider` (događaj se veštački pretvara u `BreedGroup` u `_threadFor`).
- `schedule_walk_sheet.dart` ↔ `location_picker_sheet.dart` (isti chip + ručni unos blok); `schedule_walk_sheet.dart` ↔ `create_event_screen.dart` (`_today`, `_pickDate`, `_pickTime`, `_showPastError`, „bump na sledeći sat“).
- `CreateGroupSheet._submit` ↔ `CreateEventScreen._save` (isti obrazac uspeh/greška dijaloga).
- `groupUnreadAlertsProvider` (grupe i događaji – dva skoro identična bloka) i `incomingMessageSoundProvider` (tri skoro identična bloka).
- Stringovi: `GroupsStrings.addPhoto/gallery/camera/cancel/send` = `ChatStrings.*`; `EventsStrings.pastDateError` = `ChatStrings.walkTimeInPast`; `pickDate/pickTime` u obe klase.

##### Ostalo nedovršeno / ograničenja
- Nema paginacije starijih poruka u 1:1 (samo poslednjih 30) ni u grupama (sve poruke).
- Grupe/događaji: nema prijave poruka (`canReport: false`, `group_chat_screen.dart:447`), nema location pin-a, nema optimističkog slanja, nema push-a drugim članovima.
- Lokacije za šetnje su samo tekst; `EventVenues.coordinates` postoji samo za Novi Sad.
- Nema izlaska iz grupe/događaja (nema `leaveGroup`/`leaveEvent` u interfejsima).
- Nema uređivanja/brisanja poruka ni događaja (nema metoda u repozitorijumima).
- `kFallbackDogPhotoUrl` je `''` (`core/images/dog_photo_urls.dart:2`), pa „fallback slika“ za događaje u praksi znači praznu sliku (render preuzima `buildDogImage` sa seed-om).

#### 11.2.3 Discover, psi (zdravlje, podsetnici), profil i podešavanja
##### TODO/FIXME/HACK
U sva 80 fajla **nema nijednog** komentara `TODO`, `FIXME`, `HACK` ili `XXX`. Jedini komentar tipa „rezervisano” je `dog_health_tab.dart:61` („Reserved bucket for future checkup categories; currently unused.”).

##### Debug logovi
- `firestore_discover_repository.dart:409-410` – `// ignore: avoid_print` + `print('DOG LIKE SUCCESS for: $dogId')` u produkcionom putu.
- `local_discover_repository.dart:84-85` i `:121-122` – `print('DOG LIKE SUCCESS…')`, `print('DOG SUPER LIKE SUCCESS…')`.
- `swipe_dog_card.dart:951` – `debugPrint('DOG LIKE ERROR…')`.
- `debugPrint` na greške: `firestore_discover_repository.dart:189, 274, 322, 344, 420, 458`; `discover_controller.dart:300, 362`; `firestore_health_repository.dart:54-55`; `firestore_reminder_repository.dart:66-67`; `health_controller.dart:88`; `reminder_controller.dart:104, 137`.

##### Mock podaci i fallbackovi u produkcionim putevima
- `discover_controller.dart:234-236` – `discoverProfilesProvider` uvek vraća `mockDiscoverProfiles` (seed lokalnog repoa).
- `profile_controller.dart:410-416` – `currentDiscoverDogProvider` vraća **mock Lunu (`my-dog`)** kad korisnik nema pasa; i `user_profile.dart:28-30` (`UserProfile.dog`). U Firebase režimu to znači da like/super like mogu biti poslati sa `myDogId = 'my-dog'`, a `CompatibilityCard`/`MatchDialog` koriste mock psa. (Normalno ga `AuthGate` šalje na onboarding kad nema pasa, ali greška pri čitanju pasa vodi na `HomeShellScreen` – `auth_gate.dart:29-31`.)
- `profile_controller.dart:37-39` – lokalni režim vraća `mockUserProfile` (`user_profile.dart:67-77`: „Aleksandar”, `aleksandar@vauvau.local`).
- `dog_providers.dart:14` – lokalni repo seed-ovan sa `localDemoDog()`; `local_dogs_repository.dart:12-33, 112-117` – hardkodovani Novi Sad / Liman 1.
- `discover_controller.dart:134, 151` – fallback uid `'local-user'`; `:137, 154` – fallback ime `'Neko'`.
- `dog_profile_mapper.dart:26` – default `ownerName: 'Vlasnik'`; `:149` – ako nema imena, kao ime vlasnika se prikazuje `ownerId`; `:172` – id `'user-dog'`.
- `firestore_discover_repository.dart:252, 440` – `'Neko'`; `:255-256, 447-448` – naslovi/tela notifikacija hardkodovani na srpskom (ne prolaze kroz `L10n`); `:202` – `'Morate biti prijavljeni.'`.
- `dogs_repository_impl.dart:302, 306, 314` – `'Izaberite grad i naselje.'` nije lokalizovano.
- `dog_photo_storage.dart:46` – `'Upload fotografije nije uspeo.'`.

##### Hardkodovane vrednosti / nelokalizovani stringovi
- `matching_filters.dart:99` – `'beograd'` literal umesto konstante iz `SerbiaLocations`.
- `discover_filters_bottom_sheet.dart:158-160` – radius 1–20 km; `settings_screen.dart:21-22` i `matching_filters_sheet.dart:161-163` – 1–30 km (nekonzistentno). `:171-173` – starost 0–15; `:188` – `' god.'`.
- `reminder_form_sheet.dart:208, 217` – `'Broj'`, `'Jedinica'`; `:290-291` – opseg datuma 2020 → +5 godina.
- `reminders_screen.dart:79` – `'Svi'`.
- `dog_health_tab.dart:180-184` – labele kategorija samo na srpskom (dupliraju `HealthStrings.categoryLabel`).
- `profile_ui.dart:78` – `'Još nema momenata.'`.
- `profile_strings.dart:195` – `'VauVau v1.0.0'` (verzija nije iz `package_info`).
- `health_strings.dart:60` – „Bravecto / NexGard” kao podrazumevani naziv.
- `discover_controller.dart:182` – `cityReachKm = 30`; `discover_controller.dart:247` – `pageSize = 15`; `firestore_discover_repository.dart:63, 69` – oversample ×3, max 3 pokušaja; `:178` – `limit(25)` za super like; `:287` – `limit(5)`.
- `health_record.dart:34` – `expiringSoonDays = 30`; `dog_reminder.dart:220` – „soon” = 14 dana.
- `dog_onboarding_controller.dart:76` – starost 0–30; `:256`, `profile_controller.dart:248` – timeout 20 s; `dog_photo_persist_io.dart:15, 41, 49` – timeout 4 s / 2 s.
- `swipe_dog_card.dart:1040` – auto-close popup-a 2500 ms; razne hardkodovane boje (`0xFFB45309`, `0xFF15803D`, `0xFFE11D48`…), npr. `:435-442, 643, 980`.

##### Neiskorišćen / mrtav kod
- `swipe_dog_card.dart:23-179` – `SwipeDogCard` + `_SwipeDogCardState` (nigde se ne instancira).
- `steps/area_step.dart` (ceo fajl) – `AreaStep` nije u onboardingu.
- `dog_photo_storage.dart`, `dog_photo_persist.dart`, `dog_photo_persist_io.dart`, `dog_photo_persist_web.dart` – nigde se ne koriste.
- `profile_ui.dart:72-121` – `ProfileMomentsGrid`.
- `discover_image.dart:12-17` – `discoverImageOf` (provider se koristi samo u testovima).
- `reminder_controller.dart:42-47` – `ReminderDogRef`.
- `reminder_schedule.dart:70-96` – `advanceToUpcoming`; `dog_reminder.dart:180` – `defaultCustomIntervalDays`; `dog_preference_tags.dart:21-26` – `sanitize`.
- `local_discover_repository.dart:13, 119` – `_superLikedDogs` se piše, nikad ne čita.
- Stringovi bez upotrebe u `lib/`: `DiscoverStrings.chatPlaceholder` („Poruke uskoro stižu.”, `discover_strings.dart:70-71`), `ProfileStrings.photoPlaceholder`, `momentsGallery`, `joinedLabel`, `personalityOptions` (`profile_strings.dart:103, 120, 226, 229-245`). Ostali stringovi nisu pojedinačno provereni.
- `discover_screen.dart:144-146` – `isMine` praktično uvek false.
- `dog_health_tab.dart:62` – `checkupCount = 0`.

##### Bagovi / rizici uočeni u kodu
1. **Nekonzistentan format lokacije**: `createFirstDog` piše „Grad - Naselje” (`dogs_repository_impl.dart:57-59`), `Dog.location`/`updateDog`/`EditOwnerProfileScreen` koriste `SerbiaLocations.formatPlace` → „Grad, Naselje” (`serbia_locations.dart:339`), a `DiscoverProfile._placeParts` deli samo po `' · '` i `' - '` (`discover_profile.dart:96-101`). Posle izmene psa `cityName` postaje ceo string, a `neighborhoodName` prazan (osim ako `sanitizeLocationLabel` menja format – nije provereno).
2. `dog_profile_mapper.dart:16-18` – bez `location` i bez `area` lokacija postaje `'-'` (trim od `" - "`).
3. `discover_profile.dart:19-20` – default `vaccinated = true`, `chipped = true`; `discoverProfileFromUserDog` (`dog_profile_mapper.dart:169-186`) ih ne postavlja → legacy pas se prikazuje kao vakcinisan i čipovan.
4. `discover_profile.dart:155` – starost 0 god. / 0 mes. prikazuje se kao „1 godina”.
5. `dogs_repository_impl.dart:220-223` – nepoznat temperament se pretvara u `friendly`; `:241` – `sterilized` bez legacy fallbacka.
6. `dogs_repository_impl.dart:160-161` – svaka greška se guta u generički `DogsException()` (gubi se uzrok); `:99-130` – upis u `users` je `unawaited` i prepisuje `createdAt`.
7. Koordinate psa = centar grada (`dogs_repository_impl.dart:60`, `dog_profile_mapper.dart:20`) → udaljenosti u Discover-u su između centara gradova/GPS-a, ne stvarne.
8. Discover upit nije geo/owner filtriran na serveru (`firestore_discover_repository.dart:37-48`) – skaliranje i prazne stranice; `loadMore` duplo čita prvu stranicu (`discover_controller.dart:333-344`).
9. Jedan `matches`/`chats` dokument po paru korisnika (`firestore_discover_repository.dart:296-297`) – drugi par pasa istih vlasnika prepisuje `dogIds`/`dogName` (merge).
10. `swipe(...)` za ne-like akciju prepisuje `swipes` dokument (`:157-165`), ali ne briše `likes/{uid}` → `hasLiked` i dalje true (trenutno nema UI za „pass”).
11. Super Like limit je samo klijentski, upit bez `orderBy` sa `limit(25)` (`:175-179`), na grešku dozvoljava (`:188-190`).
12. `dogId` u notifikaciji ima različito značenje za like (pas pošiljaoca, `:452`) i super like (target pas, `:268`).
13. `reminder_controller.dart:27, 121, 133` – roll-forward zakazuje notifikaciju bez imena psa i piše u Firestore iz `asyncMap` stream-a.
14. `reminder_form_sheet.dart:314-328` – izmena podsetnika: promena psa ostavlja siroče u starom psu; `lastCompletedDate`/`repeatDayOfMonth` se ne prenose.
15. Nema „završi podsetnik” akcije – `isCompleted` je uvek false iz UI-ja.
16. `health_record.dart:87`, `dog_reminder.dart:274` – `notificationId` iz `String.hashCode` (stabilnost između verzija Dart runtime-a nije garantovana specifikacijom; za brisanje se koristi sačuvani id, ali `HealthController.save` uvek računa novi).
17. `health_record_sheet.dart:203-213` – brisanje bez obrade greške.
18. `dog_onboarding_controller.dart:162-191` – `addFromCamera` bez try/catch; `:123-160`/`:193-201` – slike se uploaduju/brišu pre kreiranja psa → siročad u Storage-u ako korisnik odustane.
19. `dog_onboarding_controller.dart:277-286` + `profile_controller.dart:131-171` – `applyCreatedDog` poziva `save`, koji ponovo upisuje profil vlasnika i `updateDog` za sve pse.
20. `profile_controller.dart:162-171` – izmena vlasnika menja `area`/`location` svih pasa.
21. `dogs_repository_impl.dart:277-297` – brisanje psa ne briše podkolekcije niti otkazuje lokalne notifikacije podsetnika/zdravlja.
22. `dog_providers.dart:76-114` – lokalni overlay „pobeđuje” svaku razliku i ostaje do `remove`, pa promene sa drugog uređaja mogu biti maskirane.
23. `swipe_dog_card.dart:784-805` – `_OwnerRow` direktno koristi `FirebaseFirestore.instance` (zaobilazi repo i `isFirebaseReady`).
24. `profile_screen.dart:263` – `PageController` bez `dispose`.
25. `edit_profile_screen.dart:336-355, 399-406` – brojčana polja bez `digitsOnly` i bez validacije opsega.
26. `MatchingFilters` (osim radiusa) se gubi pri restartu; `discover_filters_bottom_sheet` i `matching_filters_sheet` su dva odvojena UI-ja za isti state sa različitim opsezima i skupom polja.
27. `matching_filters.dart:76-78` + `discover_controller.dart:225-229` – radius se primenjuje dva puta (u `GeoQuery` i u `matches`) sa potencijalno različitim vrednostima (`max(radius, 30)` vs `radius`), ali `matches` preskače radius kad je grad izabran, pa je efekat konzistentan samo u tom slučaju.

##### Veliki fajlovi koje bi trebalo podeliti
- `discover/presentation/widgets/swipe_dog_card.dart` – **1154 linije**. Sadrži neiskorišćen `SwipeDogCard` i ceo `DogDetailSheet` sa ~14 privatnih klasa (`_DetailBody`, `_StatusPill`, `_EnergyTile`, `_DogStoriesBlock`, `_DetailSection`, `_BadgeWrap`, `_HealthBadge`, `_ProfileActionBar`, `_OwnerRow`, `_LikeButton`, `_SuperLikeButton`…). Predlog: `dog_detail_sheet.dart`, `dog_detail_sections.dart`, `like_buttons.dart`, `owner_row.dart`; obrisati `SwipeDogCard` (ime fajla više ne odgovara sadržaju).
- `profile/presentation/profile_screen.dart` (661) – `_DogCard` i `_OwnerHeader` (sa logikom upload-a) mogu u zasebne fajlove.
- `profile/presentation/edit_profile_screen.dart` (569) – logika slika i forma.
- `profile/presentation/settings_screen.dart` (504) – sekcije i pomoćni widgeti.
- `discover/data/firestore_discover_repository.dart` (470) – like/match/notification logika bi mogla u poseban servis.
- `dog_photo_gallery.dart` (436), `profile_controller.dart` (416 – tri kontrolera u jednom fajlu), `reminders_screen.dart` (407), `dog_health_tab.dart` (404), `discover_controller.dart` (403 – stanje, oblast, feed paginacija i provideri u jednom fajlu), `dogs_repository_impl.dart` (399).

#### 11.2.4 Mapa, mesta i alati (tool/)
##### TODO/FIXME
- U `lib/features/map/**` i `tool/**` **nema** `TODO`, `FIXME`, `HACK` ni `XXX` komentara (jedini „pogodak“ pretrage je adresa `Todora Milovanovića` u `nis_dog_places_seed.dart:312`).

##### „Mock“ kod
- `widgets/mock_map_canvas.dart` – ime je zaostatak; sadrži pravu `VauInteractiveMap`. Kada nema `initialCenter` (režim „Moja lokacija“), kamera se uvek fituje na **hardkodovane tačke Novog Sada** (`:38-54`).
- `data/mock_map_data.dart`:
  - `:7-14` konstante `noviSadLat/Lng`, `mapCenterLat/Lng`, `limanLat/Lng`, `defaultMapZoom = 14.5`, `limanZoom = 15.6` (koristi se kao zoom za „Moja lokacija“ u `map_screen.dart:773`).
  - `:16-114` 9 hardkodovanih mesta sa izvorom „Google Places“/„VauVau Zajednica“; `nearbyDogs: 1` (`:24, :57, :67, :98, :110`) prikazuje lažno „1 aktivnih pasa u blizini“; `is24_7: true` za dva pet shopa (`:25, :36`) bez izvora.
  - `:116-119` `mockMapPlaces` je **produkcijski izvor** svih seed mesta (koristi ga `mapPlacesProvider`, `walk_controller.dart:293`).
  - `:121-122` `mockWalkingDogs = []` (fallback bez Firebase-a).

##### Logičke greške / rizici (dokazivo iz koda)
- `walk_controller.dart:83-94` – pri startu šetnje lokacija (`lastKnownLocation`, `latitude`, `longitude`, `geohash`) i `isWalking: true` se upisuju u `users` i `dogs` **bez obzira na `showLocationOnMap`**; pošto `watchWalking` lista sve pse sa `isWalking == true`, korisnik se pojavljuje na tuđim mapama na startnoj tački i kada je isključio deljenje lokacije. Komentar tvrdi suprotno („Map pin sharing stays gated by showLocationOnMap“).
- `walk_controller.dart:284-291` – `put` ne uklanja postojeći unos; `rejected`/obrisano admin mesto sa id-em seed mesta ostaje vidljivo kroz seed.
- `places_repository.dart:215-253` – `_fromDoc` čita podskup polja; `isVerified` default `true` (`:231`); `lastVerified = DateTime.now()` (`:250`); `source = 'Admin'` (`:251`) – i za seed mesta koja je admin samo izmenio.
- `firestore_poi_repository.dart:65` – nedostajući `lastVerified` → `DateTime.now()`; `:126` nepoznata kategorija → `park`; `:135` nepoznat grad → `noviSad`.
- `user_poi_controller.dart:29` – `UserPoiSubmissions` drži celu `pois` kolekciju; `:82-93` `approve` radi samo za `pois`, za seed mesta tiho ništa.
- `user_poi_controller.dart:32-39` – `add` nema proveru prijave/admina; da li Firestore pravila dozvoljavaju upis u `pois` običnom korisniku – nije u ovom delu koda (nepoznato).
- `add_poi_sheet.dart:224-226` – koordinate korisničkog predloga = centar grada; `:227` `add` se ne čeka, greška se ne prikazuje, SnackBar uspeha je bezuslovan (`:249-251`).
- `poi_report_controller.dart:111-115` – `notifications` dokument ima primaoca = samog prijavioca.
- `place_sheet.dart:364-367` – svaki korisnik koji izabere „Potvrđujem…“ lokalno vidi mesto kao „✓ Potvrđeno“ sa današnjim datumom; `PoiReports`/`PoiConfirmations` nisu perzistentni (`poi_report_controller.dart:12, 170`).
- `walk_stats_panel.dart:185-208` – SnackBar „Šetnja je sačuvana“ uvek; pragovi čuvanja su u `walk_controller.dart:194-197` (30 s / 0,05 km).
- `walk_history_repository.dart:40-45` – neograničen rast niza `walkHistory` u user dokumentu (Firestore dokument ima limit veličine).
- `walk_controller.dart:228-245` – putanja se kopira pri svakoj tački (`[...state.path]`), lista raste neograničeno tokom šetnje; putanja se ne čuva u istoriji.
- `walk_controller.dart:315` – hardkodovan indeks taba Mape (`== 1`).
- `cities_controller.dart:41` – `ref.read(citiesProvider)` u `build` (ne reaguje na kasnije učitane gradove).
- `cities_controller.dart:25` – „Moja lokacija“/„Grad“ hardkodovano (nije kroz `L10n`); isto `firestore_walk_presence_repository.dart:104` („je u šetnji.“), `walk_history_sheet.dart:158-159` („Danas“, „Juče“), `city_picker_sheet.dart:113` („Radius N km“), `poi_report_controller.dart:36, 108`.
- `places_repository.dart:137` – `cityName` u `updatePlace` = enum ime (`noviSad`), a u `createPlace` ljudsko ime („Novi Sad“) – nekonzistentno.
- `maps_launcher.dart:16-21` – Google URL se pokušava prvi i na iOS-u; `label` se ignoriše u Google/Apple URL-ovima.
- `address_geocoder.dart` – javni Nominatim bez keša i bez ograničenja zahteva; `osm_tile_layer.dart:20` – direktno javni OSM tile server (oba servisa imaju usage policy; da li je saobraćaj u skladu sa njima nije moguće utvrditi iz koda).

##### Hardkodovane vrednosti (izbor)
- Gradovi i radijusi: `city_model.dart:47-82` (Beograd 35 km, ostali 15), `map_city.dart:44-49`.
- `map_screen.dart`: tamne boje overlay-a `0xFF2A2A38` / `0xFFF8FAFC` / `0xFF1D4ED8` (npr. `:203, :222, :955, :1042, :1209, :1358`), pozicija liste `top: 210` (`:402`), „U blizini“ 3 km (`:537`), zoom 10–18 (`:753`), zoom 16 na tap (`:855, :906`), animacija 12×16 ms (`:654-665`), podrazumevani grad „Novi Sad“ u dijalogu (`:806`).
- `cities_controller.dart:29-31` – radijus „Moja lokacija“ 25 km, zoom 14.5/13.
- `firestore_walk_presence_repository.dart:53` – max 50 šetača.
- `walk_history_repository.dart:67` – limit 50; `walk_history_controller.dart:21` – 7 dana (default).
- `osm_tile_layer.dart:29-30` – keš 256 MB / 7 dana.
- `add_place_screen.dart:44-49` – samo 4 kategorije.
- `walk_session.dart:73` – 55 kcal/km (nekorišćeno).
- Datumi verifikacije: `poi_seed_data.dart:9` (2026-08-12), `belgrade_dog_places_seed.dart:8` (2026-10-06), `nis_dog_places_seed.dart:23` i `kragujevac_dog_places_seed.dart:20` (2026-10-14).

##### Mrtav / nekorišćen kod
- `map_city.dart:5` `MapCityFocus`; `map_place.dart:152` `isHotel`; `walk_record.dart:22` `duration`; `walk_session.dart:8, 56-84` (`planned`, `speedKmh`, `paceMinPerKm`, `caloriesEstimate`, `remainingMinutes`); `map_strings.dart:67-70` (`showsPlaces`, `showsWalkers`).
- Nekorišćeni stringovi u `map_strings.dart`: `readyToWalk` (:128), `walkSaveFailed` (:149), `walking` (:161), `directions` (:174), `directionsSoon` (:175 – „Smernice uskoro stižu.“), `navigation` (:177), `reportConfirm` (:187), `submittedBadge` (:215), `nearbyDogs` (:242), `fallbackBanner` (:346), `remaining` (:373).

##### Veliki fajlovi
- `map_screen.dart` – 1441 linija (1374 nepraznih): jedan `ConsumerStatefulWidget` sa filtriranjem, kamerom, dozvolama, dijalozima, navigacijom i 9 privatnih widgeta; kandidat za razbijanje.
- `belgrade_dog_places_seed.dart` – 1683 linije generisanog koda; `place_sheet.dart` – 756; `poi_seed_data.dart` – 598.
- Sva seed mesta (233) se kompajliraju u aplikaciju i ponovo grade pri svakom pristupu getterima (`get all`, `get allVerified`, `get mockMapPlaces` vraćaju nove liste).

##### Alati (`tool/`) – rizici
- `belgrade_places_geocoded.json` trenutno ima **samo 6 stavki** sa koordinatama koje se **razlikuju** od seed-a (npr. Kedrova 44.7452436 u JSON-u vs 44.746 u seed-u). Ponovno pokretanje `generate_belgrade_seed.ps1` bi **prepisalo** Dart seed sa 6 mesta umesto 108. Fajl nije u sinhronizaciji sa seed-om.
- `generate_belgrade_seed.ps1:90-94` – isti fajl se piše dvaput (komentar „Write using absolute path constructed above carefully“).
- `geocode_belgrade_places.ps1:36-49` – blok „Accept first result if none in bbox“ ponovo proverava isti bbox, pa nikad ne prihvata rezultat van bbox-a (mrtva logika).
- `kragujevac_places_geocoded.json` – ćirilica u `geocodeLabel` je pokvarena (mojibake).
- Skripte za `nis_nominatim_parks.txt`, `nis_nominatim_retry.txt` i Overpass upit za `nis_osm_parks.json` nisu u repozitorijumu – postupak nije reproduktivan.
- Skripte nemaju README; kontakt u User-Agent-u je generički („contact: vauvau app“).

#### 11.2.5 Priče, izgubljeni psi, udomljavanje, moderacija, notifikacije, podrška, admin
**TODO/FIXME/HACK:** nema nijednog u obuhvatu.

##### Moments
- `firestore_moments_repository.dart:208` debugPrint URL slike; `:228-229`, `:239-240` debugPrint grešaka.
- `firestore_highlights_repository.dart:66-67, 85-86, 101-102, 120-121`; `highlight_sheets.dart:228-229, 398-399`; `moments_controller.dart:64, 121-122` – debugPrint.
- Podrazumevane vrednosti "Novi Sad" (`firestore_moments_repository.dart:221, 281`), "Pas" (`:216, 274`), "Korisnik" (`:43, 47, 272, 299`; `moments_controller.dart:221`), "Ti" (local).
- `story_viewer.dart:667` – `ageYears: 1` u fallback `DiscoverProfile`.
- `local_moments_repository.dart:13-21` hardkodovan seed komentar; `seed_moments.dart` demo podaci (samo bez Firebase-a/uid-a).
- `deleteMoment` ne čisti komentare, Storage ni istaknuto, a tekst dijaloga (`moments_strings.dart:48-51`) tvrdi da se priča uklanja iz svih istaknutih.
- Istek 24h je samo klijentski (nema TTL-a ni tajmera); `seenStories` nije perzistentno; `commentsCount` se povećava u zasebnoj transakciji; istaknuto/arhiva zavise od učitanih momenata.
- Hardkod boja `0xFFB91C1C` na više mesta.

##### Lost dogs
- `lost_dogs_controller.dart:66-68` i `report_lost_dog_sheet.dart:450-451` – `// ignore: avoid_print` + `print`.
- debugPrint: `firestore_lost_dog_repository.dart:34, 96, 137-138, 179-180`; `lost_dogs_controller.dart:20, 68`; `lost_dog_actions.dart:377, 409`.
- `firestore_lost_dog_repository.dart:28` – `limit(40)` bez `orderBy`.
- `firestore_lost_dog_repository.dart:117` – email kao rezervno javno ime komentatora.
- `lost_dog_popup_store.dart:4` – globalni jednokratni flag popupa.
- `report_lost_dog_sheet.dart:95-96` – podrazumevano "Novi Sad" / "Liman 1".
- `lost_dog_strings.dart:141-153` – hardkodovana lista od 11 rasa; `_isUnknownBreed` radi samo za SR.
- Komentari kao niz u dokumentu (ograničenje 1 MB), `createdAt` komentara je klijentsko vreme; telefon bez validacije formata; slika se ne briše uz oglas; nema filtriranja blokiranih.
- Hardkod boje (`0xFF14532D`, `0xFF7F1D1D`, `0xFF15803D`, `0xFF43A047`, `0xFFB91C1C`…).

##### Adoption
- `mock_adoption_dogs.dart:15, 33, 51` – izmišljeni telefoni i organizacije (samo u Local režimu).
- `adoption_controller.dart:74-76`, `add_adoption_dog_sheet.dart:463-464` – `// ignore: avoid_print` + `print`; debugPrint `firestore_adoption_repository.dart:82`, `adoption_controller.dart:21, 76`.
- `add_adoption_dog_sheet.dart:49-50` "Novi Sad"/"Liman 1"; `:490` "Novi Sad".
- `adoption_detail_screen.dart:246` – `ageYears: 0`; `DiscoverProfile.id` = id oglasa.
- Tamne hardkod boje `0xFF1E2230`, `0xFF2A2D3E` u detalju (moguć sukob sa svetlom temom).
- `uploaderName` iz kontrolera se ignoriše u Firestore repozitorijumu; `limit(20)` bez paginacije uz filtriranje u UI; nema brisanja oglasa ni prijave oglasa.
- Nekorišćeni stringovi (grep): `AdoptionStrings.genderLabel`, `callLabel` (obe grane praktično iste), `details`, `call`, `location`, `locationRequired`.

##### Moderation
- debugPrint: `firestore_report_repository.dart:59, 133, 174, 184, 201, 226, 228, 245, 248, 270`; `report_sheet.dart:212`.
- `firestore_report_repository.dart:155` "Prijava sadržaja" i `:365` "Prijava promene" – hardkod SR.
- Trostruko dupliranje polja (reporterId/reportedBy/reportedByUserId; createdAt/timestamp; recipientId/toUserId; senderId/fromUserId).
- `watchAll` i `_findReporterId` čitaju celu kolekciju `users` (neskalabilno; prijave korisnika su u javno čitljivom `users` dokumentu).
- Optimistički status override-ovi se gube restartom i prikazuju novi status čak i kada svi upisi padnu.
- `typeFromKey`: nepoznat tip → dog; id prijave klijentski `report-<millis>`.
- `report_sheet.dart:59-61` – prazna grana `else if (sent == false)`.
- Nema UI za odblokiranje; `HiddenContent` nije perzistentan; `admin_notifications` se samo piše.

##### Notifications
- `push_notification_gateway.dart:159` – debugPrint sa sadržajem notifikacije; progutane greške `catch (_) {}` na `:90, :109, :144, :199, :203, :213, :226, :242`.
- `notification_controller.dart:117-118` – hardkod SR tekst u nekorišćenom `addWalkRequest`; debugPrint `:149, :217, :250`.
- Mrtav kod: `notifyMatch`, `addWalkRequest`, `seedNotifications`, `NotificationScreen`, stringovi `enableTitle/enableBody/enableConfirm/later`.
- Nema servera za slanje push-a (vidi gore); jedan `fcmToken` po korisniku; token se ne briše pri odjavi (u obuhvatu).
- `notifications` create dozvoljen svakom prijavljenom (moguće lažiranje pošiljaoca); `queueForUser` ne poštuje podešavanja primaoca.
- `limit(100)` bez orderBy; nepoznati tipovi → like; `PushPayload.fromData` mutira ulaz; `ref` tipiziran kao `dynamic` u rutiranju; dve instance `NotificationService` (`main.dart:32` i provider).

##### Support
- `official_contacts.dart:16-25` – email, Instagram nalog, Facebook ime i URL-ovi hardkodovani; `:30` naslov "✉️ Email us" na engleskom i u SR UI.
- `sos_tab.dart:11-61` – 7 hardkodovanih brojeva telefona veterinarskih ambulanti i zoohigijene (Novi Sad, Beograd); javni brojevi ustanova, tačnost/aktuelnost nije proverljiva iz koda.
- `support_strings.dart:93` – "Verzija 1.0.0" hardkod (ne čita se iz `package_info`).
- `rules_and_support_screen.dart:31` – "SOS" nelokalizovano; `initialTab` se nigde ne koristi.
- `admin_feedback.dart:14-19` – kategorije samo na srpskom, sa emoji-jem u vrednosti.
- Mrtav kod: `support_content.dart` (ceo fajl), `support_guide_card.dart`.
- `firestore_support_repository.dart:26-27` – debugPrint.
- `tips_tab.dart:99, 102` – `Navigator.pop()` pre promene taba pretpostavlja da je ekran push-ovan.
- Stanje checklist-e u `TipArticleCard` nije perzistentno.

##### Admin
- `admin_reports_tab.dart:325, 364`, `admin_edit_poi_dialog.dart:438` – debugPrint.
- `admin_reports_tab.dart:240-246` – kada POI nije pronađen, editor dobija izmišljen POI: kategorija `park`, adresa `''`, koordinate `45.2671, 19.8335` (Novi Sad), `source: 'Admin ispravka'`, status `unknown`; šta `updatePlace` radi sa nepostojećim ID-em zavisi od `PlacesRepository` (van obuhvata).
- `admin_reports_tab.dart:298-313` – "Obriši" za `user`, `message`, `dog`, `chat` samo sakrije `targetId` u memoriji i označi prijavu kao `action_taken`; stvarnog brisanja, banovanja ni blokiranja nema.
- `admin_reports_tab.dart:68, 76` i `admin_groups_tab.dart:73` – prikazuju sirove uid-ove umesto imena.
- `admin_reports_tab.dart:374-395` – `_StatusBadge` uvek prikazuje "Na čekanju".
- `admin_dashboard_screen.dart:77-81` – "Aktivni psi" = discover katalog + sopstveni psi, ne ukupan broj u bazi.
- `admin_dashboard_screen.dart:267` – `poi.category.name` (ime enuma, nelokalizovano).
- `admin_moments_tab.dart:16` – koristi `momentsControllerProvider` bez `loadMore` → admin vidi samo poslednjih 15 momenata; blokirani autori nisu filtrirani (namerno ili ne – nije navedeno).
- `admin_groups_tab.dart:118-140` – "Odbij" trajno briše grupu bez dijaloga potvrde.
- `firestore_admin_repository.dart:45` i `firestore_report_repository` – čitanje cele `users` kolekcije bez limita (neskalabilno); `admin_feedback` bez limita.
- `local_admin_repository.dart:73-117` – seed podaci (Milica/Nikola, `@example.com`).
- Nekorišćeni `AdminStrings` (grep po `lib/`): `panel`, `pendingTab`, `reportReason`, `searchTab`, `block`, `dismiss`, `searchHint`, `noSearch`, `users`, `dogs`, `momentsTab`, `drawerItem`, `poiNotFound` – ukazuju na planiranu, a neimplementiranu pretragu korisnika/pasa.
- Admin panel nema: promenu uloge, banovanje, brisanje korisnika, brisanje oglasa za udomljavanje, brisanje komentara, odgovor na feedback.
- Server-side rizik (rules, van obuhvata): `breed_groups` `allow update: if isAuthenticated()` – odobravanje grupe nije zaštićeno samo za admina.

#### 11.2.6 Platforme, konfiguracija, dokumentacija i testovi
##### Identifikatori / konfiguracija
1. **Neusklađen bundle id**: Android `com.vauvau.app`, a iOS (`project.pbxproj:385,564,586`), `GoogleService-Info.plist` `BUNDLE_ID`, `lib/firebase_options.dart` (`iosBundleId`), macOS (`AppInfo.xcconfig`) i Linux (`linux/CMakeLists.txt:10`) koriste šablonski `com.example.vauvau`. App Store ne prihvata `com.example.*`.
2. **`google-services.json` sadrži zaostali klijent `com.example.vauvau`** pored `com.vauvau.app` – ostatak prvobitne konfiguracije.
3. **iOS Google Sign-In nije podešen**: nema `CFBundleURLTypes` sa `REVERSED_CLIENT_ID` u `ios/Runner/Info.plist`, iako README to navodi.
4. **`GoogleService-Info.plist` nije dodat u Xcode projekat** (nema reference u `project.pbxproj`).
5. **iOS push nije podešen**: nema entitlements/`aps-environment`, nema `DEVELOPMENT_TEAM`; `AppDelegate` bez prilagođavanja – a deklarisan je `remote-notification` background mode.
6. **iOS „Always“ lokacija**: `UIBackgroundModes` sadrži `location`, a `NSLocationAlways*` tekstovi kažu da se lokacija prikuplja „i kada je aplikacija zatvorena ili se ne koristi“. To je u suprotnosti sa politikom privatnosti („GPS tokom aktivne šetnje i dok je app otvorena“) i može izazvati odbijanje u App Review-u. Takođe `fetch` background mode – u ovom delu nije pronađena upotreba.
7. **Web Google Sign-In client ID** hardkodovan u `web/index.html:22`, sa brojem projekta (`125865322788`) koji ne odgovara Firebase projektu `vauvau-3195a` (`461477755452`). Moguće iz drugog/starog projekta.
8. **Web/desktop koriste Android Firebase opcije** (`lib/firebase_options.dart`: `kIsWeb` → `android`, `default` → `android`) – nema registrovane web aplikacije.
9. **macOS Release.entitlements bez `network.client`** – Firebase ne bi radio u sandboxu; desktop targeti su generalno neizmenjen šablon (`com.example`, naslov „vauvau“, copyright „com.example“, pogrešno kodiran `©` u `macos/Runner/Configs/AppInfo.xcconfig`).
10. **Linux nema Firebase pluginove** – platforma praktično nepodržana.
11. **Boja web splash-a `#38BDF8`** (`web/index.html:42,93`) ne odgovara brend bojama; nema splash slike u body-ju.
12. **FCM default notification icon** = `@mipmap/ic_launcher` (obojena ikonica) – na Androidu 5+ se obično prikazuje kao bela mrlja; nema monohromatske ikonice.

##### Potpisivanje / build
13. **Debug potpisivanje za release NE postoji** – release eksplicitno zahteva `android/key.properties` i odbija debug config (dobro). `android/key.properties` postoji lokalno i gitignored je; keystore nije u repou.
14. Potencijalni problem: `throw GradleException` u `buildTypes.release` bloku se izvršava u konfiguracionoj fazi, pa bi i `flutter run` (debug) mogao da padne na mašini bez `key.properties` (komentar u `signingConfigs` tvrdi suprotno – „so debug sync still works“). Nije testirano.
15. **Skripte `scripts/build_release.*` grade APK**, ne AAB koji se šalje na Play.
16. **Checklista zastarela**: verzija `1.0.0+4` i `release/vauvau-1.0.0+4-release.aab`, a pubspec je `1.0.0+7`.
17. **Komitovani SHA-1/SHA-256 otisci upload keystore-a** u `docs/play-launch-checklist.md` (javni podaci, nisu tajna, ali nepotrebno u repou).
18. `gradle.properties`: `-Xmx8G` i `MaxMetaspaceSize=4G` – veliki zahtevi za memorijom, mogu pasti na slabijim mašinama/CI.

##### Tajne / fajlovi sa ključevima
19. `android/app/google-services.json` i `ios/Runner/GoogleService-Info.plist` su komitovani i sadrže Firebase API ključeve (uobičajeno i prihvatljivo za Firebase klijentske ključeve; zaštita zavisi od Security Rules i eventualnih API key ograničenja – App Check nije uključen).
20. Nema komitovanih keystore/`key.properties` fajlova (provereno `git ls-files`).

##### Zaostali / privremeni fajlovi
21. `Gist` (koren) – fajl bez ekstenzije, starija verzija politike privatnosti sa ličnim kontakt e-mailom (razlikuje se od `vauvau.app@gmail.com`), komitovan.
22. `firebase.cmd` – lokalni wrapper sa hardkodovanim putanjama ka `%USERPROFILE%\.cache\firebase\…` i Node 20.18.2; specifičan za jednu mašinu. `firebase.exe` i `firebase-tools-instant-win.exe` (~259 MB svaki) leže u korenu (gitignored).
23. U korenu (gitignored, nekomitovano): `moments_fail.txt`, `flutter_01.log`, `flutter_01.png` (0 bajtova), `vauvau.iml`, folder `release/` sa AAB-om, `.firebase/`.
24. `assets/images/` (van opsega, ali traženo): `vauvau_splash.png` je jedina splash slika koja se koristi (`lib/features/splash/presentation/screens/splash_screen.dart:17`), `vauvau_logo.png` se koristi u `pubspec.yaml` za ikonice. **Nekorišćeni**: `vauvau_splash11.png` (~1,9 MB), `vauvau_splash3.png` (~1,8 MB), `vauvau_splash_old.png` (~1,4 MB), `vauvau_splash_old1.png` (~1,8 MB), `vauvau_splash_old2.jpg` (~0,35 MB) – ukupno ~7,3 MB, a ceo folder je deklarisan kao asset (`pubspec.yaml:90` `- assets/images/`), pa ulaze u APK/AAB. Plus prazan `.gitkeep`.
25. `docs/reels/*.jpg` i `vauvau-reels-najava.mp4` – marketinški binarni materijal komitovan u git.
26. `docs/` i `public/` drže duplirane legal stranice (razlikuju se samo u linkovima sa/bez `/`) – rizik od razilaženja.
27. `README.md` – zastarela tvrdnja o „stub“ `firebase_options.dart` i šablonski „Getting Started“ tekst.
28. Generisani fajlovi izmenjeni/nepraćeni u radnoj kopiji: `windows/linux flutter/generated_plugin*`, `macos/Flutter/GeneratedPluginRegistrant.swift` (M); `android/.../GeneratedPluginRegistrant.java`, `ios/Runner/GeneratedPluginRegistrant.m`, `ios|macos/Flutter/ephemeral/.../Package.swift` (nepraćeni, a ios/android su gitignored).
29. 4 nova test fajla nisu dodata u git (`chat_unread_test.dart`, `incoming_message_sound_test.dart`, `message_bubble_avatar_test.dart`, `scheduled_walks_test.dart`).
30. `storage-cors.json` dozvoljava sve origin-e (`*`) i metode za upis (PUT/POST/DELETE) – široko; nema skripte koja ga primenjuje, pa nije poznato da li je primenjen na bucket.

##### TODO komentari (u opsegu)
- `windows/flutter/CMakeLists.txt:9` – `# TODO: Move the rest of this into files in ephemeral.` (Flutter šablon)
- `linux/flutter/CMakeLists.txt:9` – isti šablonski TODO.
- Nema drugih `TODO`/`FIXME`/`HACK` u android/ios/macos/web/public/docs/scripts/test fajlovima.

##### Nejasno / nije provereno
- Merged Android manifest (dozvole koje dodaju pluginovi, npr. kamera, FCM servis) – nije generisan/proveren.
- Da li je `storage-cors.json` primenjen, da li su indeksi „Enabled“, da li postoji APNs ključ u Firebase konzoli – ne vidi se iz repoa.
- Tačne vrednosti minSdk/targetSdk/compileSdk zavise od instalirane Flutter verzije (36/24/36 za lokalni SDK 3.44.1).
- Sadržaj `firestore.rules`, `firestore.indexes.json`, `storage.rules` nije deo ovog dela.

---
## 12. KLJUČNI KOD
Firebase vrednosti `apiKey`/`appId`/`*ClientId` su zamenjene sa `<SKRIVENO>`; prave vrednosti su u `lib/firebase_options.dart`, `android/app/google-services.json` i `ios/Runner/GoogleService-Info.plist`.
### 12.1 Ulazna tačka i aplikacija
#### `lib/main.dart` (56 linija, ceo fajl)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/firebase_init_error_app.dart';
import 'core/crash/crash_reporting.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/feed_state.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep the isolate warm so iOS/Android can deliver data messages while the
  // app is backgrounded or terminated. UI presentation is handled by the OS /
  // local notifications when the user taps the banner.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  await NotificationService().initialize();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final authReady = FirebaseAuth.instance.app.options.projectId.isNotEmpty;
    final firestoreReady =
        FirebaseFirestore.instance.app.options.projectId.isNotEmpty;
    if (!authReady || !firestoreReady) {
      throw StateError('Firebase Auth ili Firestore nisu dostupni.');
    }
    await CrashReporting.init();
    runApp(const ProviderScope(child: VauVauApp()));
  } catch (error, stack) {
    debugPrint('🔴 MAIN CATCH: $error');
    debugPrint('🔴 STACK: $stack');
    await CrashReporting.recordError(error, stack, fatal: true);
    runApp(FirebaseInitErrorApp(message: error.toString()));
  }
}
```

#### `lib/app/app.dart` (79 linija, ceo fajl)
```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../core/crash/crash_reporting.dart';
import '../core/l10n/app_language.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/notifications/presentation/push_navigation.dart';
import '../features/profile/presentation/profile_controller.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

class VauVauApp extends ConsumerWidget {
  const VauVauApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(
      appSettingsProvider.select((settings) => settings.language),
    );
    final themeMode = ref.watch(
      appSettingsProvider.select(
        (settings) => settings.themePreference.themeMode,
      ),
    );
    L10n.setLanguage(language);

    ref.listen(authStateProvider, (previous, next) {
      unawaited(
        CrashReporting.setUserId(next.asData?.value?.uid),
      );
    });

    return MaterialApp(
      title: AppStrings.appName,
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: language.locale,
      supportedLocales: [
        for (final item in AppLanguage.supported) item.locale,
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return _LanguageRebuildScope(
          language: language,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}

/// Marks the tree when language changes so MaterialApp rebuilds route content
/// without remounting the navigator.
class _LanguageRebuildScope extends InheritedWidget {
  const _LanguageRebuildScope({
    required this.language,
    required super.child,
  });

  final AppLanguage language;

  @override
  bool updateShouldNotify(_LanguageRebuildScope oldWidget) {
    return language != oldWidget.language;
  }
}
```

#### `lib/app/routes.dart` (14 linija, ceo fajl)
```dart
import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';

  static Map<String, WidgetBuilder> get map => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
      };
}
```

#### `lib/firebase_options.dart` (37 linija, ceo fajl)
```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return android;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '<SKRIVENO>',
    // Firebase Android app for package com.vauvau.app (not com.example.vauvau).
    appId: '<SKRIVENO>',
    messagingSenderId: '461477755452',
    projectId: 'vauvau-3195a',
    storageBucket: 'vauvau-3195a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '<SKRIVENO>',
    appId: '<SKRIVENO>',
    messagingSenderId: '461477755452',
    projectId: 'vauvau-3195a',
    storageBucket: 'vauvau-3195a.firebasestorage.app',
    iosBundleId: 'com.example.vauvau',
  );
}
```

#### `lib/core/firebase/firebase_status.dart` (3 linija, ceo fajl)
```dart
import 'package:firebase_core/firebase_core.dart';

bool get isFirebaseReady => Firebase.apps.isNotEmpty;
```

### 12.2 Navigacija (`AuthGate` + `HomeShellScreen`; imenovani router ne postoji)
#### `lib/features/auth/presentation/auth_gate.dart` (53 linija, ceo fajl)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dogs/presentation/dog_providers.dart';
import '../../../features/dogs/presentation/onboarding/dog_onboarding_controller.dart';
import '../../../features/dogs/presentation/onboarding/dog_onboarding_screen.dart';
import '../../../features/home/presentation/home_shell_screen.dart';
import '../../../features/profile/presentation/profile_controller.dart';
import 'auth_providers.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    ref.watch(appSettingsProvider.select((s) => s.language));
    ref.watch(dogOnboardingControllerProvider.notifier);

    return authState.when(
      loading: () => const _LoadingScaffold(),
      error: (_, _) => const LoginScreen(),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        final dogs = ref.watch(ownerDogsProvider);
        if (dogs.hasError && !dogs.hasValue) {
          return const HomeShellScreen();
        }
        if (dogs.isLoading || !dogs.hasValue) {
          return const _LoadingScaffold();
        }
        if (dogs.requireValue.isEmpty) {
          return const DogOnboardingScreen();
        }
        return const HomeShellScreen();
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

#### `lib/features/home/presentation/home_shell_screen.dart` (143 linija, ceo fajl)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/presentation/chat_inbox.dart';
import '../../chat/presentation/chat_strings.dart';
import '../../chat/presentation/incoming_message_sound.dart';
import '../../chat/presentation/matches_screen.dart';
import '../../chat/presentation/widgets/scheduled_walks_banner.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../discover/presentation/discover_strings.dart';
import '../../discover/presentation/widgets/discover_app_bar.dart';
import '../../groups/presentation/group_unread_alerts.dart';
import '../../lost_dogs/presentation/lost_dog_emergency_host.dart';
import '../../map/presentation/map_screen.dart';
import '../../map/presentation/map_strings.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../notifications/presentation/notification_strings.dart';
import '../../notifications/presentation/push_bootstrap.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/presentation/profile_strings.dart';
import '../../profile/presentation/profile_system_sheet.dart';
import '../domain/app_drawer_catalog.dart';
import 'home_drawer.dart';
import 'home_tab.dart';

class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(homeTabIndexProvider);
    final scheduledWalks = ref.watch(scheduledWalksProvider);
    final unread = ref.watch(notificationUnreadCountProvider);
    final unreadChats = ref.watch(totalUnreadChatCountProvider);
    // Rebuild tab labels/copy when the user switches language.
    ref.watch(appSettingsProvider.select((s) => s.language));
    final showScheduledWalks = tabIndex == 1 || tabIndex == 2;
    ref.watch(groupUnreadAlertsProvider);
    ref.watch(incomingMessageSoundProvider);

    final titles = [
      '',
      MapStrings.title,
      ChatStrings.title,
      ProfileStrings.title,
    ];

    return PushBootstrap(
      child: LostDogEmergencyHost(
        child: Scaffold(
        drawer: const HomeDrawer(),
        appBar: tabIndex == 0
            ? const DiscoverAppBar()
            : AppBar(
                title: Text(titles[tabIndex]),
                leading: Builder(
                  builder: (context) {
                    return IconButton(
                      tooltip: AppDrawerCatalog.menuTooltip,
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  },
                ),
                actions: [
                  if (tabIndex == 3)
                    IconButton(
                      tooltip: ProfileStrings.moreActions,
                      onPressed: () => showProfileSystemSheet(context, ref),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  IconButton(
                    tooltip: NotificationStrings.tooltip,
                    onPressed: () => showNotificationsSheet(context),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      backgroundColor: const Color(0xFFE11D48),
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                ],
              ),
        body: Column(
          children: [
            if (showScheduledWalks)
              ScheduledWalksBanner(walks: scheduledWalks),
            Expanded(
              child: IndexedStack(
                index: tabIndex,
                children: const [
                  DiscoverScreen(),
                  MapScreen(),
                  MatchesScreen(),
                  ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: (index) {
            ref.read(homeTabIndexProvider.notifier).setIndex(index);
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: DiscoverStrings.title,
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: MapStrings.tabLabel,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadChats > 0,
                label: Text('$unreadChats'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadChats > 0,
                label: Text('$unreadChats'),
                child: const Icon(Icons.chat_bubble),
              ),
              label: ChatStrings.tabLabel,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: ProfileStrings.tabLabel,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
```

### 12.3 Autentifikacija
#### `lib/features/auth/domain/auth_repository.dart` (48 linija, ceo fajl)
```dart
import 'app_user.dart';
import 'user_dog_profile.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String city = '',
    String cityId = '',
    String neighborhoodId = '',
    String neighborhoodName = '',
    String bio = '',
    String customPhotoUrl = '',
  });

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> deleteAccount();

  Future<void> saveUserProfile({
    required AppUser user,
    UserDogProfile? dog,
    String? city,
    String? name,
    String? bio,
    String? cityId,
    String? neighborhoodId,
    String? neighborhoodName,
    bool writeDog = true,
  });

  Future<void> saveOwnerCustomPhoto({
    required String uid,
    required String customPhotoUrl,
  });
}
```

#### `lib/features/auth/presentation/auth_providers.dart` (47 linija, ceo fajl)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/firebase/firebase_status.dart';
import '../data/auth_repository_impl.dart';
import '../data/firebase_auth_datasource.dart';
import '../data/local_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!isFirebaseReady) {
    return LocalAuthRepository(user: localDemoUser);
  }
  return AuthRepositoryImpl(
    FirebaseAuthDatasource(
      FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(scopes: const ['email', 'profile']),
    ),
    firestore: FirebaseFirestore.instance,
  );
});

/// Set to `true` at the start of logout so AuthGate shows login immediately,
/// even while Firebase / route cleanup is still finishing.
class SessionSignedOut extends Notifier<bool> {
  @override
  bool build() => false;

  void setSignedOut(bool value) => state = value;
}

final sessionSignedOutProvider =
    NotifierProvider<SessionSignedOut, bool>(SessionSignedOut.new);

final authStateProvider = StreamProvider<AppUser?>((ref) {
  if (ref.watch(sessionSignedOutProvider)) {
    return Stream<AppUser?>.value(null);
  }
  return ref.watch(authRepositoryProvider).watchUser();
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).asData?.value?.isAdmin ?? false;
});
```

#### `lib/features/auth/data/firebase_auth_datasource.dart` (114 linija, ceo fajl)
```dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_strings.dart';
import '../domain/auth_exception.dart';

class FirebaseAuthDatasource {
  FirebaseAuthDatasource(
    this._auth, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: const ['email', 'profile']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await user.updateDisplayName(name);
    await user.reload();
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw AuthException(AuthErrorCode.cancelled,
          AppStrings.authCancelled,
        );
      }
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return _auth.signInWithCredential(credential);
    } on AuthException {
      rethrow;
    } on PlatformException catch (error) {
      if (_isCancelled(error.code)) {
        throw AuthException(AuthErrorCode.cancelled,
          AppStrings.authCancelled,
        );
      }
      throw AuthException(
        AuthErrorCode.unknown,
        error.message ?? AppStrings.authUnknownError,
      );
    }
  }

  Future<void> signOut() async {
    // Clear Firebase session first so AuthGate flips to login immediately.
    await _auth.signOut();
    // Google cleanup can hang on web — never block logout on it.
    unawaited(_clearGoogleSession());
  }

  Future<void> _clearGoogleSession() async {
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Already signed out, unavailable, or hung on web.
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    final normalized = email.trim().toLowerCase();
    debugPrint('FirebaseAuthDatasource: sendPasswordResetEmail → $normalized');
    return _auth.sendPasswordResetEmail(email: normalized);
  }

  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(AuthErrorCode.unknown);
    }
    await user.delete();
  }

  bool _isCancelled(String code) {
    final normalized = code.toLowerCase();
    return normalized.contains('cancel') ||
        normalized == 'error_aborted_by_user';
  }
}
```

#### `lib/features/auth/data/auth_repository_impl.dart` (444 linija, ceo fajl)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../domain/app_user.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user_dog_profile.dart';
import 'account_deletion_service.dart';
import 'firebase_auth_datasource.dart';
import 'user_document.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource, {this._firestore});

  final FirebaseAuthDatasource _datasource;
  final FirebaseFirestore? _firestore;

  @override
  Stream<AppUser?> watchUser() {
    return _datasource.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream<AppUser?>.value(null);
      }
      final firestore = _firestore;
      if (firestore == null) {
        return Stream<AppUser?>.value(_mapAuthUser(firebaseUser));
      }

      // Emit Auth user immediately, then enrich from Firestore.
      // Swallow permission errors during logout so the auth stream stays healthy.
      return Stream<AppUser?>.multi((controller) {
        controller.add(_mapAuthUser(firebaseUser));
        final sub = firestore
            .collection(userCollection)
            .doc(firebaseUser.uid)
            .snapshots()
            .listen(
          (doc) {
            if (_datasource.currentUser?.uid != firebaseUser.uid) {
              return;
            }
            controller.add(_mapAuthUser(firebaseUser, doc.data()));
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('User profile stream: $error');
            if (_datasource.currentUser == null) {
              controller.add(null);
            }
          },
        );
        controller.onCancel = sub.cancel;
      });
    });
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _datasource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _requireUser(credential.user);
      await _upsertUser(user);
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String city = '',
    String cityId = '',
    String neighborhoodId = '',
    String neighborhoodName = '',
    String bio = '',
    String customPhotoUrl = '',
  }) async {
    try {
      final credential = await _datasource.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _datasource.updateDisplayName(name.trim());
      final ownerPhoto = customPhotoUrl.trim();
      final user = _requireUser(_datasource.currentUser ?? credential.user)
          .copyWith(
            displayName: name.trim(),
            city: city.trim(),
            cityId: cityId.trim(),
            neighborhoodId: neighborhoodId.trim(),
            neighborhoodName: neighborhoodName.trim(),
            bio: bio.trim(),
            customPhotoUrl: ownerPhoto,
          );
      await _upsertUser(
        user,
        name: name.trim(),
        city: city.trim(),
        cityId: cityId.trim(),
        neighborhoodId: neighborhoodId.trim(),
        neighborhoodName: neighborhoodName.trim(),
        bio: bio.trim(),
        writeOwnerPhoto: ownerPhoto.isNotEmpty,
      );
      if (ownerPhoto.isNotEmpty) {
        // Best-effort Auth avatar sync so all surfaces that read photoURL
        // stay aligned with the uploaded owner photo.
        try {
          await _datasource.currentUser?.updatePhotoURL(ownerPhoto);
        } catch (error) {
          debugPrint('Auth photoURL sync skipped: $error');
        }
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final credential = await _datasource.signInWithGoogle();
      final user = _requireUser(credential.user);
      await _createDefaultProfileIfNew(user);
      return user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _datasource.signOut();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _datasource.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final uid = _datasource.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw AuthException(AuthErrorCode.unknown);
    }
    try {
      await _deleteOwnedData(uid);
      await _datasource.deleteCurrentUser();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    }
  }

  Future<void> _deleteOwnedData(String uid) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    await AccountDeletionService(firestore: firestore).deleteAllUserData(uid);
  }

  @override
  Future<void> saveUserProfile({
    required AppUser user,
    UserDogProfile? dog,
    String? city,
    String? name,
    String? bio,
    String? cityId,
    String? neighborhoodId,
    String? neighborhoodName,
    bool writeDog = true,
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final next = user.copyWith(
      displayName: name ?? user.displayName,
      city: city ?? user.city,
      cityId: cityId ?? user.cityId,
      neighborhoodId: neighborhoodId ?? user.neighborhoodId,
      neighborhoodName: neighborhoodName ?? user.neighborhoodName,
      bio: bio ?? user.bio,
      dog: dog ?? user.dog,
    );
    await firestore.collection(userCollection).doc(user.uid).set(
          userDocumentPayload(
            next,
            includeCreatedAt: false,
            // Never clobber Firestore admin role during profile edits.
            includeRole: false,
            includeDog: writeDog,
            includeOwnerPhoto: false,
          ),
          SetOptions(merge: true),
        );
    if (!writeDog) {
      return;
    }
    final dogId = next.dog.id;
    if (dogId.isEmpty) {
      return;
    }
    await firestore.collection('dogs').doc(dogId).set(
      {
        'id': dogId,
        'ownerId': user.uid,
        'name': next.dog.name,
        'breed': next.dog.breed,
        'age': next.dog.age,
        'ageYears': next.dog.age,
        'gender': next.dog.gender,
        'bio': next.dog.bio,
        ...firestorePhotoFields(next.dog.photoUrls),
        'size': next.dog.size,
        'temperament': next.dog.temperament,
        'ownerName': next.displayName ?? '',
        'location': next.locationLabel,
        'cityId': next.cityId,
        'cityName': next.cityName,
        'neighborhoodId': next.neighborhoodId,
        'neighborhoodName': next.neighborhoodName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> saveOwnerCustomPhoto({
    required String uid,
    required String customPhotoUrl,
  }) async {
    final trimmed = customPhotoUrl.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection(userCollection).doc(uid);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        transaction.set(ref, {
          'uid': uid,
          'role': UserRole.user.firestoreValue,
          'photoUrl': trimmed,
          'customPhotoUrl': trimmed,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      // Partial update keeps role and other fields untouched for security rules.
      transaction.update(ref, {
        'photoUrl': trimmed,
        'customPhotoUrl': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    final authUser = _datasource.currentUser;
    if (authUser != null && authUser.uid == uid) {
      try {
        await authUser.updatePhotoURL(trimmed);
        await authUser.reload();
      } catch (error) {
        debugPrint('Auth photoURL sync skipped: $error');
      }
    }
  }

  AppUser _mapAuthUser(User user, [Map<String, dynamic>? data]) {
    return AppUser.fromAuthAndDocument(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      data: data,
    );
  }

  AppUser _requireUser(User? user) {
    if (user == null) {
      throw AuthException(AuthErrorCode.unknown);
    }
    return _mapAuthUser(user);
  }

  AuthException _mapFirebase(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return AuthException(
          AuthErrorCode.invalidEmail,
          AppStrings.authInvalidEmail,
        );
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      case 'INVALID_LOGIN_CREDENTIALS':
        return AuthException(
          AuthErrorCode.wrongPassword,
          AppStrings.authWrongPassword,
        );
      case 'weak-password':
        return AuthException(
          AuthErrorCode.weakPassword,
          AppStrings.authWeakPassword,
        );
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return AuthException(
          AuthErrorCode.emailInUse,
          AppStrings.authEmailInUse,
        );
      case 'network-request-failed':
        return AuthException(
          AuthErrorCode.network,
          AppStrings.authNetwork,
        );
      case 'requires-recent-login':
        return AuthException(
          AuthErrorCode.requiresRecentLogin,
          AppStrings.authRequiresRecentLogin,
        );
      default:
        return AuthException(
          AuthErrorCode.unknown,
          AppStrings.authUnknownError,
        );
    }
  }

  Future<void> _upsertUser(
    AppUser user, {
    String? name,
    String? city,
    String? cityId,
    String? neighborhoodId,
    String? neighborhoodName,
    String? bio,
    bool writeOwnerPhoto = false,
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection(userCollection).doc(user.uid);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final existing = snapshot.data();
      final preservedPhoto = AppUser.ownerPhotoFromDocument(
        existing,
        authPhotoUrl: user.photoUrl,
      );
      final next = user.copyWith(
        displayName: name ?? user.displayName,
        city: (city != null && city.isNotEmpty)
            ? city
            : (existing?['cityName'] as String? ??
                existing?['city'] as String? ??
                user.city),
        cityId: (cityId != null && cityId.isNotEmpty)
            ? cityId
            : (existing?['cityId'] as String? ?? user.cityId),
        neighborhoodId: (neighborhoodId != null && neighborhoodId.isNotEmpty)
            ? neighborhoodId
            : (existing?['neighborhoodId'] as String? ?? user.neighborhoodId),
        neighborhoodName:
            (neighborhoodName != null && neighborhoodName.isNotEmpty)
                ? neighborhoodName
                : (existing?['neighborhoodName'] as String? ??
                    user.neighborhoodName),
        bio: bio ?? (existing?['bio'] as String? ?? user.bio),
        customPhotoUrl: user.customPhotoUrl.trim().isNotEmpty
            ? user.customPhotoUrl.trim()
            : preservedPhoto,
        role: UserRoleX.fromString(existing?['role'] as String?),
        dog: existing == null
            ? user.dog
            : UserDogProfile.fromMap(existing['dog']),
      );
      final shouldWritePhoto =
          writeOwnerPhoto || next.customPhotoUrl.trim().isNotEmpty;
      final payload = userDocumentPayload(
        next,
        includeCreatedAt: existing == null || existing['createdAt'] == null,
        includeRole: existing == null,
        includeDog: existing == null,
        includeOwnerPhoto: shouldWritePhoto,
      );
      if (existing != null) {
        payload.remove('role');
      }
      transaction.set(ref, payload, SetOptions(merge: true));
    });
  }

  Future<void> _createDefaultProfileIfNew(AppUser user) async {
    final firestore = _firestore;
    if (firestore == null) {
      return;
    }
    final ref = firestore.collection(userCollection).doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return;
    }
    await ref.set(
      userDocumentPayload(
        user,
        includeCreatedAt: true,
        includeRole: true,
        includeDog: true,
        includeOwnerPhoto: false,
      ),
    );
  }
}
```

#### `lib/features/auth/data/user_document.dart` (49 linija, ceo fajl)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/user_dog_profile.dart';

const String userCollection = 'users';

Map<String, dynamic> emptyDogMap() => const UserDogProfile().toMap();

Map<String, dynamic> userDocumentPayload(
  AppUser user, {
  required bool includeCreatedAt,
  bool includeRole = true,
  bool includeDog = true,
  bool includeOwnerPhoto = false,
}) {
  final cityName = user.cityName;
  final payload = <String, dynamic>{
    'uid': user.uid,
    'email': user.email ?? '',
    'name': user.displayName ?? '',
    'city': cityName,
    'cityId': user.cityId,
    'cityName': cityName,
    'neighborhoodId': user.neighborhoodId,
    'neighborhoodName': user.neighborhoodName,
    'bio': user.bio,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (includeOwnerPhoto) {
    final ownerPhoto = user.customPhotoUrl.trim().isNotEmpty
        ? user.customPhotoUrl.trim()
        : user.photoUrl.trim();
    payload['photoUrl'] = ownerPhoto;
    payload['customPhotoUrl'] = ownerPhoto;
  }
  if (includeRole) {
    // Preserve the caller's role (admin must not be overwritten to "user"
    // on ordinary profile saves).
    payload['role'] = user.role.firestoreValue;
  }
  if (includeCreatedAt) {
    payload['createdAt'] = FieldValue.serverTimestamp();
  }
  if (includeDog) {
    payload['dog'] = user.dog.hasProfile ? user.dog.toMap() : emptyDogMap();
  }
  return payload;
}
```

#### `lib/features/auth/domain/app_user.dart` (149 linija, ceo fajl)
```dart
import 'user_dog_profile.dart';

import '../../../core/constants/serbia_locations.dart';

enum UserRole { user, admin }

extension UserRoleX on UserRole {
  String get firestoreValue => name;

  static UserRole fromString(String? value) {
    if (value == 'admin') {
      return UserRole.admin;
    }
    return UserRole.user;
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl = '',
    this.customPhotoUrl = '',
    this.city = '',
    this.cityId = '',
    this.neighborhoodId = '',
    this.neighborhoodName = '',
    this.bio = '',
    this.role = UserRole.user,
    this.dog = const UserDogProfile(),
  });

  final String uid;
  final String? email;
  final String? displayName;
  /// Firebase Auth / Google avatar. Never written over a custom owner photo.
  final String photoUrl;
  /// Owner-uploaded profile photo from Firestore (`photoUrl`/`customPhotoUrl`).
  final String customPhotoUrl;
  final String city;
  final String cityId;
  final String neighborhoodId;
  final String neighborhoodName;
  final String bio;
  final UserRole role;
  final UserDogProfile dog;

  bool get isAdmin => role == UserRole.admin;

  String get cityName => city;

  String get locationLabel =>
      SerbiaLocations.formatPlace(cityName, neighborhoodName);

  String get ownerAvatarUrl {
    final custom = customPhotoUrl.trim();
    if (custom.isNotEmpty) {
      return custom;
    }
    return photoUrl.trim();
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? customPhotoUrl,
    String? city,
    String? cityId,
    String? neighborhoodId,
    String? neighborhoodName,
    String? bio,
    UserRole? role,
    UserDogProfile? dog,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      customPhotoUrl: customPhotoUrl ?? this.customPhotoUrl,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      dog: dog ?? this.dog,
    );
  }

  /// Resolves the owner avatar stored on the user document.
  /// Prefers `customPhotoUrl`, then Firestore `photoUrl` when it is not just
  /// mirroring the Firebase Auth / Google avatar.
  static String ownerPhotoFromDocument(
    Map<String, dynamic>? data, {
    String authPhotoUrl = '',
  }) {
    final doc = data ?? const <String, dynamic>{};
    final authPhoto = authPhotoUrl.trim();
    final docCustom = (doc['customPhotoUrl'] as String?)?.trim() ?? '';
    if (docCustom.isNotEmpty) {
      return docCustom;
    }
    final docPhoto = (doc['photoUrl'] as String?)?.trim() ?? '';
    if (docPhoto.isEmpty) {
      return '';
    }
    // Email/password users have no Auth photo — treat Firestore photoUrl as
    // the owner upload. Google users: only use it when it differs from Auth.
    if (authPhoto.isEmpty || docPhoto != authPhoto) {
      return docPhoto;
    }
    return '';
  }

  static AppUser fromAuthAndDocument({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? data,
  }) {
    final doc = data ?? const <String, dynamic>{};
    final authPhoto = photoUrl?.trim() ?? '';
    final storedPhoto = ownerPhotoFromDocument(doc, authPhotoUrl: authPhoto);
    return AppUser(
      uid: uid,
      email: (doc['email'] as String?)?.trim().isNotEmpty == true
          ? doc['email'] as String
          : email,
      displayName: (doc['name'] as String?)?.trim().isNotEmpty == true
          ? doc['name'] as String
          : displayName,
      photoUrl: authPhoto,
      customPhotoUrl: storedPhoto,
      city: (doc['cityName'] as String?)?.trim().isNotEmpty == true
          ? (doc['cityName'] as String).trim()
          : (doc['city'] as String? ?? ''),
      cityId: doc['cityId'] as String? ?? '',
      neighborhoodId: doc['neighborhoodId'] as String? ?? '',
      neighborhoodName: doc['neighborhoodName'] as String? ?? '',
      bio: doc['bio'] as String? ?? '',
      role: UserRoleX.fromString(doc['role'] as String?),
      dog: UserDogProfile.fromMap(doc['dog']),
    );
  }
}
```

### 12.4 Glavni servis baze – chat repozitorijum (najsloženiji Firestore sloj)
#### `lib/features/chat/domain/chat_repository.dart` (76 linija, ceo fajl)
```dart
import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_room.dart';

abstract class ChatRepository {
  List<ChatConversation> get currentInbox;

  /// True after the first usable inbox snapshot is ready for the UI.
  bool get hasLoadedInbox;

  Stream<List<ChatConversation>> watchInbox();

  /// Emits whenever [hasLoadedInbox] flips to true (and the current value).
  Stream<bool> watchInboxLoaded();

  Stream<List<ChatRoom>> watchRooms();

  Stream<List<ChatMessage>> watchMessages(String roomId);

  /// Walk invites per conversation id, kept live for every room — not only
  /// rooms opened in ChatDetail — so scheduled walks stay visible.
  Map<String, List<ChatMessage>> get currentWalkInvites;

  Stream<Map<String, List<ChatMessage>>> watchWalkInvites();

  /// Starts a limited messages listener for an open conversation.
  void attachRoom(String roomId);

  /// Cancels the messages listener when leaving the conversation screen.
  void detachRoom(String roomId);

  String openFromMatch({
    required DiscoverProfile profile,
    required String myUserId,
    required String myDogId,
  });

  void markRead(String conversationId);

  Future<void> sendMessage(
    String conversationId,
    String rawText, {
    ChatMessage? replyTo,
  });

  Future<void> sendWalkInvite({
    required String conversationId,
    required DateTime walkTime,
    required String walkLocationName,
  });

  Future<void> sendLocationPin({
    required String conversationId,
    required String locationName,
  });

  Future<void> sendPhoto({
    required String conversationId,
    required String imageUrl,
    ChatMessage? replyTo,
  });

  Future<void> respondToWalkInvite({
    required String conversationId,
    required String messageId,
    required WalkInviteStatus status,
  });

  Future<void> toggleMessageLike({
    required String conversationId,
    required String messageId,
  });

  void dispose();
}
```

#### `lib/features/chat/data/firestore_chat_repository.dart` (1066 linija, **izvod**: linije 1–200, 479–545, 742–811, 903–945, 1036–1066)
Izostavljeno: walk-invite pretplate (204–253), attach/detach soba (254–300), merge i watch metode (301–398), otvaranje sobe iz meča (399–478), slanje poziva/lokacije/slike (545–741), odgovor na poziv i dispose (812–902), prijava grešaka upisa (946–1035).
```dart
// ── linije 1–200 ──
import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/crash/crash_reporting.dart';
import '../../../core/firebase/firestore_auth_guard.dart';
import '../../../core/images/dog_photo_urls.dart';
import '../../../core/network/network_failure.dart';
import '../../discover/domain/discover_profile.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/chat_room.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({
    required this._firestore,
    required this.currentUserId,
    this.currentUserName = '',
    this.currentUserAvatarUrl = '',
  });

  final FirebaseFirestore _firestore;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;
  List<ChatConversation> _inbox = const [];
  final StreamController<List<ChatConversation>> _inboxController =
      StreamController<List<ChatConversation>>.broadcast();
  final StreamController<bool> _loadedController =
      StreamController<bool>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _messageSubs = {};
  /// Messages that arrived before the parent room was in [_inbox].
  final Map<String, List<ChatMessage>> _pendingMessages = {};
  /// Walk-invite-only listeners for every room (independent of attachRoom).
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _walkInviteSubs = {};
  final Map<String, List<ChatMessage>> _walkInvites = {};
  final StreamController<Map<String, List<ChatMessage>>>
      _walkInvitesController =
      StreamController<Map<String, List<ChatMessage>>>.broadcast();
  var _hasLoadedInbox = false;
  var _localMessageSeq = 0;
  Timer? _cacheHoldTimer;
  Timer? _emitDebounce;

  /// How many recent messages to keep live per open room.
  static const int messagePageSize = 30;

  /// Ref-count of open ChatDetail screens per room.
  final Map<String, int> _roomAttachCounts = {};

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chats');

  void start() {
    if (currentUserId.isEmpty || currentUserId == 'local-user') {
      _publishEmptyInbox();
      return;
    }
    unawaited(_startGuarded());
  }

  Future<void> _startGuarded() async {
    final user = await FirestoreAuthGuard.ensureReady();
    if (user == null || user.uid != currentUserId) {
      _publishEmptyInbox();
      return;
    }
    await _roomsSub?.cancel();
    _roomsSub = _rooms
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .listen(
          _onRooms,
          onError: (Object error, StackTrace stack) {
            if (FirestoreAuthGuard.isPermissionDenied(error)) {
              FirestoreAuthGuard.logPermissionDenied(
                error,
                stack,
                label: 'chat.watchRooms',
              );
              _publishEmptyInbox();
              return;
            }
            developer.log('chat.watchRooms: $error', stackTrace: stack);
            unawaited(
              CrashReporting.recordError(
                error,
                stack,
                reason: 'chat.watchRooms',
              ),
            );
          },
        );
  }

  void _publishEmptyInbox() {
    _inbox = const [];
    _syncWalkInviteSubs(const {});
    if (!_hasLoadedInbox) {
      _hasLoadedInbox = true;
      if (!_loadedController.isClosed) {
        _loadedController.add(true);
      }
    }
    if (!_inboxController.isClosed) {
      _inboxController.add(_inbox);
    }
  }

  void _onRooms(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final rooms = snapshot.docs.map(_conversationFromRoom).toList();

    // Build inbox BEFORE attaching message listeners. Previously listeners
    // started first and the initial messages snapshot often arrived while the
    // new room was still missing from [_inbox], so the first send was dropped
    // until the next cold start.
    _inbox = [
      for (final chat in rooms)
        _merge(
          chat,
          _messageSubs.containsKey(chat.id)
              ? (_pendingMessages.remove(chat.id) ??
                  _byId(chat.id)?.messages ??
                  const [])
              : const [],
        ),
    ];

    final keep = rooms.map((chat) => chat.id).toSet();
    for (final id in _messageSubs.keys.toList()) {
      if (!keep.contains(id)) {
        _messageSubs.remove(id)?.cancel();
        _pendingMessages.remove(id);
        _roomAttachCounts.remove(id);
      }
    }
    _syncWalkInviteSubs(keep);
    // Messages are hydrated only for rooms opened in ChatDetail (attachRoom).

    // Avoid flashing a partial cached inbox (often 1 room) before the
    // server snapshot arrives with the full conversation list.
    if (!_hasLoadedInbox) {
      final fromCache = snapshot.metadata.isFromCache;
      if (fromCache) {
        _cacheHoldTimer ??= Timer(const Duration(milliseconds: 1000), () {
          _publishInitialInbox();
        });
        return;
      }
      _cacheHoldTimer?.cancel();
      _cacheHoldTimer = null;
      _publishInitialInbox();
      return;
    }
    _emitNow();
  }

  void _ensureMessageSub(String roomId) {
    _messageSubs.putIfAbsent(
      roomId,
      () => _rooms
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(messagePageSize)
          .snapshots()
          .listen(
            (messages) => _onMessages(roomId, messages),
            onError: (Object error, StackTrace stack) {
              if (FirestoreAuthGuard.isPermissionDenied(error)) {
                FirestoreAuthGuard.logPermissionDenied(
                  error,
                  stack,
                  label: 'chat.watchMessages',
                );
                return;
              }
              developer.log(
                'chat.watchMessages($roomId): $error',
                stackTrace: stack,
              );
            },
          ),
    );
  }

  @override
  Map<String, List<ChatMessage>> get currentWalkInvites => {
        for (final entry in _walkInvites.entries)
          entry.key: List<ChatMessage>.from(entry.value),
      };

  @override
  Stream<Map<String, List<ChatMessage>>> watchWalkInvites() async* {
    yield currentWalkInvites;

// ... izostavljeno ...

// ── linije 479–545 ──
  void markRead(String conversationId) {
    final chat = _byId(conversationId);
    if (chat != null && chat.unreadCount > 0) {
      _inbox = [
        for (final item in _inbox)
          if (item.id == conversationId) item.copyWith(unreadCount: 0) else item,
      ];
      _emitNow();
    }
    unawaited(
      _rooms.doc(conversationId).set({
        'unreadCount': 0,
        'unreadByUser': {currentUserId: 0},
      }, SetOptions(merge: true)),
    );
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    String rawText, {
    ChatMessage? replyTo,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      return;
    }
    final peerId = _byId(conversationId)?.peerUserId ?? '';
    final replyFields = _replyFields(conversationId, replyTo);
    final localId = _nextLocalId();
    _appendOptimistic(
      conversationId,
      ChatMessage(
        id: localId,
        senderId: currentUserId,
        receiverId: peerId,
        senderName: currentUserName,
        senderAvatarUrl: currentUserAvatarUrl,
        text: text,
        sentAt: DateTime.now(),
        isMine: true,
        isRead: true,
        replyToMessageId: replyFields['replyToMessageId'] ?? '',
        replyToText: replyFields['replyToText'] ?? '',
        replyToSenderName: replyFields['replyToSenderName'] ?? '',
      ),
    );
    await _writeMessage(
      conversationId,
      {
        'senderId': currentUserId,
        'receiverId': peerId,
        'senderName': currentUserName,
        'senderAvatarUrl': currentUserAvatarUrl,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'text',
        ...replyFields,
      },
      text,
      localMessageId: localId,
    );
  }

  @override
  Future<void> sendWalkInvite({

// ... izostavljeno ...

// ── linije 742–811 ──
  Future<void> toggleMessageLike({
    required String conversationId,
    required String messageId,
  }) async {
    if (currentUserId.isEmpty) {
      return;
    }
    List<String>? previous;
    final existing = _byId(conversationId);
    if (existing != null) {
      for (final message in existing.messages) {
        if (message.id == messageId) {
          previous = List<String>.from(message.likes);
          break;
        }
      }
    }
    final nextLikes = <String>[...(previous ?? const <String>[])];
    if (nextLikes.contains(currentUserId)) {
      nextLikes.remove(currentUserId);
    } else {
      nextLikes.add(currentUserId);
    }
    _inbox = [
      for (final chat in _inbox)
        if (chat.id == conversationId)
          chat.copyWith(
            messages: [
              for (final message in chat.messages)
                if (message.id == messageId)
                  message.copyWith(likes: nextLikes)
                else
                  message,
            ],
          )
        else
          chat,
    ];
    _emitNow();
    try {
      await _rooms
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'likes': nextLikes});
    } catch (error, stack) {
      if (previous != null) {
        _inbox = [
          for (final chat in _inbox)
            if (chat.id == conversationId)
              chat.copyWith(
                messages: [
                  for (final message in chat.messages)
                    if (message.id == messageId)
                      message.copyWith(likes: previous)
                    else
                      message,
                ],
              )
            else
              chat,
        ];
        _emitNow();
      }
      await _reportWriteFailure('toggleMessageLike', error, stack);
      rethrow;
    }
  }

  @override

// ... izostavljeno ...

// ── linije 903–945 ──
  Future<void> _writeMessage(
    String conversationId,
    Map<String, dynamic> payload,
    String preview, {
    required String localMessageId,
  }) async {
    final senderId = (payload['senderId'] as String? ?? '').trim();
    if (senderId.isEmpty ||
        senderId != currentUserId ||
        currentUserId.isEmpty ||
        currentUserId == 'local-user') {
      final error = StateError(
        'Poruka mora imati senderId ulogovanog korisnika.',
      );
      _removeOptimistic(conversationId, localMessageId);
      await _reportWriteFailure('sendMessage', error, StackTrace.current);
      throw error;
    }
    try {
      await _rooms.doc(conversationId).collection('messages').add(payload);
      final peerId = _byId(conversationId)?.peerUserId ?? '';
      await _rooms.doc(conversationId).set({
        'lastMessage': preview,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'isNewMatch': false,
        // Replying means everything before it was seen.
        'unreadByUser': {
          currentUserId: 0,
          if (peerId.isNotEmpty) peerId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));
    } catch (error, stack) {
      developer.log(
        'chat write failed: $error',
        name: 'FirestoreChatRepository',
        stackTrace: stack,
      );
      _removeOptimistic(conversationId, localMessageId);
      await _reportWriteFailure('sendMessage', error, stack);
      rethrow;
    }
  }


// ... izostavljeno ...

// ── linije 1036–1066 ──
  int _unreadForMe(Map<String, dynamic> data) {
    final map = data['unreadByUser'];
    if (map is Map && map[currentUserId] is int) {
      return map[currentUserId] as int;
    }
    return data['unreadCount'] as int? ?? 0;
  }

  List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => item.toString()).toList();
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  void _emitNow() {
    if (!_inboxController.isClosed) {
      _inboxController.add(currentInbox);
    }
  }
}
```

#### `lib/services/storage_service.dart` (470 linija, **izvod**: linije 1–76, 220–330, 352–377)
Izostavljeno: download/keš (77–155), pickeri (156–219), MIME detekcija i poruke grešaka (378–470).
```dart
// ── linije 1–76 ──
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads and deletes images on Firebase Storage.
///
/// Objects live under `{root}/{userId}/...` so Storage rules can enforce
/// `isOwner(userId)` on create/update/delete.
class StorageService {
  StorageService({
    FirebaseStorage? storage,
    ImagePicker? picker,
    String? Function()? currentUserId,
  })  : _storageOverride = storage,
        _picker = picker ?? ImagePicker(),
        _currentUserId = currentUserId ??
            (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseStorage? _storageOverride;
  final ImagePicker _picker;
  final String? Function() _currentUserId;

  FirebaseStorage get _storage =>
      _storageOverride ?? FirebaseStorage.instance;

  /// Roots that must be owner-scoped: `{root}/{uid}/file`.
  static const Set<String> ownerScopedRoots = {
    'pets',
    'users',
    'moments',
    'events',
    'groups',
    'adoption',
    'lost_dogs',
    'uploads',
    'chats',
  };

  /// In-memory cache so story grids don't re-download the same object.
  static final Map<String, Uint8List> _bytesCache = {};
  static const int _maxCachedImages = 48;
  static const int _maxDownloadBytes = 8 * 1024 * 1024;

  /// Builds `{root}/{userId}` (or nests [folderName] under the signed-in uid).
  ///
  /// Pass [ownerId] when uploading on behalf of a known owner (must match auth).
  String ownerFolder(String folderName, {String ownerId = ''}) {
    final uid = ownerId.trim().isNotEmpty
        ? ownerId.trim()
        : (_currentUserId()?.trim() ?? '');
    if (uid.isEmpty) {
      throw StateError('Moraš biti prijavljen da bi poslao sliku.');
    }
    final folder = folderName.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (folder.isEmpty) {
      return 'uploads/$uid';
    }
    final parts = folder.split('/').where((part) => part.isNotEmpty).toList();
    final root = parts.first;
    if (!ownerScopedRoots.contains(root)) {
      // Unknown root → park under uploads/{uid}/...
      return 'uploads/$uid/$folder';
    }
    if (parts.length >= 2 && parts[1] == uid) {
      return parts.join('/');
    }
    if (parts.length == 1) {
      return '$root/$uid';
    }
    // pets/extra → pets/{uid}/extra (never pets/wrongId/...)
    final rest = parts.skip(1).join('/');
    return '$root/$uid/$rest';
  }

  /// True for HTTPS download URLs and `gs://` object URIs.

// ... izostavljeno ...

// ── linije 220–330 ──
  Future<String?> uploadXFile({
    required XFile file,
    required String folderName,
    String ownerId = '',
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    return uploadBytes(
      bytes: Uint8List.fromList(bytes),
      folderName: folderName,
      fileName: file.name,
      mimeType: file.mimeType,
      ownerId: ownerId,
    );
  }

  /// Uploads raw [bytes] under [folderName] (auto-scoped to `{root}/{uid}/`).
  /// Always returns an HTTPS download URL (never `gs://` / fullPath).
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String folderName,
    String fileName = 'upload.jpg',
    String? mimeType,
    String ownerId = '',
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Prazna fotografija.');
    }
    try {
      return await _putBytes(
        bytes: bytes,
        folderName: ownerFolder(folderName, ownerId: ownerId),
        fileName: fileName,
        mimeType: mimeType,
      );
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'StorageService FirebaseException '
        'code=${error.code} message=${error.message} plugin=${error.plugin}',
      );
      debugPrint('$stack');
      throw StateError(_userMessageForFirebase(error));
    } catch (error, stack) {
      debugPrint('StorageService.uploadBytes failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  Future<String?> _pickAndUpload({
    required String folderName,
    required ImageSource source,
    String ownerId = '',
  }) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (file == null) {
      return null;
    }
    return uploadXFile(
      file: file,
      folderName: folderName,
      ownerId: ownerId,
    );
  }

  Future<String> _putBytes({
    required Uint8List bytes,
    required String folderName,
    required String fileName,
    String? mimeType,
  }) async {
    // [folderName] is already owner-scoped by [ownerFolder] / [uploadBytes].
    final folder = folderName.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    // Prefer real bytes / mime over a forced .jpg name (screenshots are often PNG).
    final contentType = _contentTypeFor(fileName, mimeType, bytes);
    final ext = _extensionForContentType(contentType);
    if (folder.isEmpty) {
      throw StateError('Storage putanja mora uključivati vlasnika (userId).');
    }
    final path = '$folder/$stamp$ext';

    final ref = _storage.ref(path);
    final metadata = SettableMetadata(
      contentType: contentType,
      cacheControl: 'public,max-age=31536000',
    );
    debugPrint(
      'StorageService uploading path=$path '
      'bytes=${bytes.length} contentType=$contentType '
      'bucket=${_storage.bucket}',
    );
    final snapshot = await ref.putData(bytes, metadata);
    if (snapshot.state != TaskState.success) {
      throw StateError('Storage upload nije uspeo (${snapshot.state}).');
    }

    // Always resolve the public HTTPS URL — never return fullPath / gs:// /
    // Reference.toString(), which Image.network cannot load.
    final downloadUrl = await snapshot.ref.getDownloadURL();
    final httpsUrl = _requireHttpsDownloadUrl(downloadUrl);
    debugPrint('StorageService uploaded path=$path url=$httpsUrl');
    return httpsUrl;
  }


// ... izostavljeno ...

// ── linije 352–377 ──
  Future<void> deleteImageByUrl(String imageUrl) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return;
    }
    try {
      final ref = _refFromAny(url);
      await ref.delete();
    } catch (error, stack) {
      debugPrint('StorageService.deleteImageByUrl failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Best-effort delete — ignores non-Storage URLs and delete failures.
  Future<void> tryDeleteImageByUrl(String? imageUrl) async {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty || !isFirebaseStorageUrl(url)) {
      return;
    }
    try {
      await deleteImageByUrl(url);
    } catch (_) {}
  }

```

### 12.5 Modeli
#### `lib/features/dogs/domain/dog.dart` (95 linija, ceo fajl)
```dart
import '../../../core/constants/serbia_locations.dart';
import 'dog_area.dart';
import 'dog_enums.dart';

class Dog {
  const Dog({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.gender,
    required this.ageYears,
    required this.size,
    required this.energyLevel,
    required this.temperament,
    required this.area,
    required this.photoUrls,
    this.weightKg,
    this.ageMonths = 0,
    this.bio = '',
    this.vaccinated = false,
    this.chipped = false,
    this.sterilized = false,
    this.likesTags = const [],
    this.dislikesTags = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final DogGender gender;
  final int ageYears;
  final int ageMonths;
  final DogSize size;
  final double? weightKg;
  final DogEnergyLevel energyLevel;
  final List<DogTemperament> temperament;
  final DogArea area;
  final List<String> photoUrls;
  final String bio;
  final bool vaccinated;
  final bool chipped;
  final bool sterilized;
  final List<String> likesTags;
  final List<String> dislikesTags;

  String get location =>
      SerbiaLocations.formatPlace(area.cityName, area.neighborhoodName);

  String get photoUrl => photoUrls.isEmpty ? '' : photoUrls.first;

  Dog copyWith({
    String? name,
    String? breed,
    DogGender? gender,
    int? ageYears,
    int? ageMonths,
    DogSize? size,
    double? weightKg,
    bool clearWeight = false,
    DogEnergyLevel? energyLevel,
    List<DogTemperament>? temperament,
    DogArea? area,
    List<String>? photoUrls,
    String? bio,
    bool? vaccinated,
    bool? chipped,
    bool? sterilized,
    List<String>? likesTags,
    List<String>? dislikesTags,
  }) {
    return Dog(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      ageYears: ageYears ?? this.ageYears,
      ageMonths: ageMonths ?? this.ageMonths,
      size: size ?? this.size,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      energyLevel: energyLevel ?? this.energyLevel,
      temperament: temperament ?? this.temperament,
      area: area ?? this.area,
      photoUrls: photoUrls ?? this.photoUrls,
      bio: bio ?? this.bio,
      vaccinated: vaccinated ?? this.vaccinated,
      chipped: chipped ?? this.chipped,
      sterilized: sterilized ?? this.sterilized,
      likesTags: likesTags ?? this.likesTags,
      dislikesTags: dislikesTags ?? this.dislikesTags,
    );
  }
}
```

#### `lib/features/chat/domain/chat_conversation.dart` (93 linija, ceo fajl)
```dart
import 'chat_message.dart';
import 'chat_room.dart';

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.dogId,
    required this.dogName,
    required this.ownerName,
    required this.breed,
    required this.location,
    required this.photoUrl,
    required this.messages,
    required this.lastActivityAt,
    this.participantIds = const [],
    this.dogIds = const [],
    this.peerUserId = '',
    this.isNewMatch = false,
    this.unreadCount = 0,
    this.lastMessagePreview = '',
  });

  final String id;
  final String dogId;
  final String dogName;
  final String ownerName;
  final String breed;
  final String location;
  final String photoUrl;
  final List<String> participantIds;
  final List<String> dogIds;
  final String peerUserId;
  final List<ChatMessage> messages;
  final DateTime lastActivityAt;
  final bool isNewMatch;
  final int unreadCount;

  /// From the room document (`lastMessage`) — used when messages are not hydrated.
  final String lastMessagePreview;

  String get title => '$dogName ($ownerName)';

  ChatRoom get room => ChatRoom(
        id: id,
        participantIds: participantIds,
        dogIds: dogIds.isEmpty ? [dogId] : dogIds,
        lastMessage: lastSnippet,
        lastMessageTimestamp: lastActivityAt,
        unreadCount: unreadCount,
      );

  String get lastSnippet {
    if (messages.isNotEmpty) {
      final last = messages.last;
      if (last.isWalkInvite) {
        return last.walkLocationName == null || last.walkLocationName!.isEmpty
            ? last.text
            : last.text;
      }
      return last.previewText;
    }
    return lastMessagePreview;
  }

  ChatConversation copyWith({
    List<String>? participantIds,
    List<String>? dogIds,
    String? peerUserId,
    List<ChatMessage>? messages,
    DateTime? lastActivityAt,
    bool? isNewMatch,
    int? unreadCount,
    String? lastMessagePreview,
  }) {
    return ChatConversation(
      id: id,
      dogId: dogId,
      dogName: dogName,
      ownerName: ownerName,
      breed: breed,
      location: location,
      photoUrl: photoUrl,
      participantIds: participantIds ?? this.participantIds,
      dogIds: dogIds ?? this.dogIds,
      peerUserId: peerUserId ?? this.peerUserId,
      messages: messages ?? this.messages,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isNewMatch: isNewMatch ?? this.isNewMatch,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
```

#### `lib/features/chat/domain/chat_message.dart` (156 linija, ceo fajl)
```dart
enum ChatMessageType {
  text,
  walkInvite,
  locationPin,
}

enum WalkInviteStatus { pending, accepted, declined }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.senderId = '',
    this.receiverId = '',
    this.senderName = '',
    this.senderAvatarUrl = '',
    this.imageUrl = '',
    this.isRead = false,
    this.type = ChatMessageType.text,
    this.status,
    this.walkTime,
    this.walkLocationName,
    this.replyToMessageId = '',
    this.replyToText = '',
    this.replyToSenderName = '',
    this.likes = const [],
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final String imageUrl;
  final DateTime sentAt;
  final bool isRead;
  final bool isMine;
  final ChatMessageType type;
  final WalkInviteStatus? status;
  final DateTime? walkTime;
  final String? walkLocationName;
  final String replyToMessageId;
  final String replyToText;
  final String replyToSenderName;

  /// User ids that liked this message.
  final List<String> likes;

  DateTime get timestamp => sentAt;

  bool get hasImage => imageUrl.trim().isNotEmpty;

  bool get hasReply =>
      replyToMessageId.isNotEmpty || replyToText.trim().isNotEmpty;

  int get likeCount => likes.length;

  bool isLikedBy(String uid) =>
      uid.isNotEmpty && likes.contains(uid);

  /// Inbox / reply preview when the body is a photo with no caption.
  String get previewText {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    if (hasImage) {
      return '📷 Fotografija';
    }
    return '';
  }

  String get typeKey => switch (type) {
        ChatMessageType.text => 'text',
        ChatMessageType.walkInvite => 'walk_invite',
        ChatMessageType.locationPin => 'location_pin',
      };

  String? get statusKey => switch (status) {
        WalkInviteStatus.pending => 'pending',
        WalkInviteStatus.accepted => 'accepted',
        WalkInviteStatus.declined => 'declined',
        null => null,
      };

  bool get isWalkInvite => type == ChatMessageType.walkInvite;

  bool get isLocationPin => type == ChatMessageType.locationPin;

  ChatMessage copyWith({
    bool? isRead,
    WalkInviteStatus? status,
    String? senderAvatarUrl,
    String? imageUrl,
    List<String>? likes,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      text: text,
      imageUrl: imageUrl ?? this.imageUrl,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      isMine: isMine,
      type: type,
      status: status ?? this.status,
      walkTime: walkTime,
      walkLocationName: walkLocationName,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      likes: likes ?? this.likes,
    );
  }

  static ChatMessageType typeFromKey(String? value) {
    return switch (value) {
      'walk_invite' => ChatMessageType.walkInvite,
      'location_pin' => ChatMessageType.locationPin,
      _ => ChatMessageType.text,
    };
  }

  static WalkInviteStatus? statusFromKey(String? value) {
    return switch (value) {
      'pending' => WalkInviteStatus.pending,
      'accepted' => WalkInviteStatus.accepted,
      'declined' => WalkInviteStatus.declined,
      _ => null,
    };
  }

  static String clipReplyText(String raw, [int max = 120]) {
    final text = raw.trim();
    if (text.length <= max) {
      return text;
    }
    return '${text.substring(0, max).trimRight()}…';
  }

  static List<String> likesFrom(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item != null && '$item'.trim().isNotEmpty) '$item',
    ];
  }
}
```

#### `lib/features/groups/domain/groups_models.dart` (334 linija, ceo fajl)
```dart
class BreedGroup {
  const BreedGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.memberIds,
    required this.memberCount,
    this.sortOrder = 0,
    this.lastMessage = '',
    this.lastMessageAt,
    this.isApproved = true,
    this.createdBy = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> memberIds;
  final int memberCount;
  final int sortOrder;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final bool isApproved;
  final String createdBy;
  final DateTime? createdAt;

  int get displayMemberCount =>
      memberCount >= memberIds.length ? memberCount : memberIds.length;

  bool isMember(String uid) => uid.isNotEmpty && memberIds.contains(uid);

  /// Safe Firestore/document map parser — returns null on malformed data.
  static BreedGroup? tryFromMap(String id, Map<String, dynamic>? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final memberIds = <String>[
        for (final value in _asList(raw['memberIds']))
          if (value is String && value.isNotEmpty) value,
      ];
      final memberCount = _asInt(raw['memberCount']) ??
          _asInt(raw['membersCount']) ??
          memberIds.length;
      final isApproved = raw['isApproved'];
      return BreedGroup(
        id: id,
        title: raw['title'] as String? ?? '',
        description: raw['description'] as String? ?? '',
        imageUrl: raw['imageUrl'] as String? ?? '',
        memberIds: memberIds,
        memberCount: memberCount,
        sortOrder: _asInt(raw['sortOrder']) ?? 0,
        lastMessage: raw['lastMessage'] as String? ?? '',
        lastMessageAt: _asDateTime(raw['lastMessageAt']),
        isApproved: isApproved is bool ? isApproved : true,
        createdBy: raw['createdBy'] as String? ?? '',
        createdAt: _asDateTime(raw['createdAt']),
      );
    } catch (_) {
      return null;
    }
  }

  static List<Object?> _asList(Object? value) {
    if (value is List) {
      return List<Object?>.from(value);
    }
    return const [];
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    // Timestamp is handled by callers that convert first; duck-type via toDate.
    try {
      final dynamic dynamicValue = value;
      if (dynamicValue != null && dynamicValue.toDate is Function) {
        final date = dynamicValue.toDate();
        if (date is DateTime) {
          return date;
        }
      }
    } catch (_) {}
    return null;
  }

  BreedGroup copyWith({
    List<String>? memberIds,
    int? memberCount,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? isApproved,
    String? createdBy,
    String? title,
    String? description,
    String? imageUrl,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return BreedGroup(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      sortOrder: sortOrder ?? this.sortOrder,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isApproved: isApproved ?? this.isApproved,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.isMine,
    this.replyToMessageId = '',
    this.replyToText = '',
    this.replyToSenderName = '',
    this.type = GroupMessageType.text,
    this.status,
    this.walkTime,
    this.walkLocationName,
    this.acceptedByUserIds = const [],
    this.declinedByUserIds = const [],
    this.likes = const [],
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final String imageUrl;
  final DateTime createdAt;
  final bool isMine;
  final String replyToMessageId;
  final String replyToText;
  final String replyToSenderName;
  final GroupMessageType type;
  final GroupWalkInviteStatus? status;
  final DateTime? walkTime;
  final String? walkLocationName;
  /// User ids that accepted this group walk invite (updates live on the message).
  final List<String> acceptedByUserIds;
  final List<String> declinedByUserIds;

  /// User ids that liked this message.
  final List<String> likes;

  int get likeCount => likes.length;

  bool isLikedBy(String uid) =>
      uid.isNotEmpty && likes.contains(uid);

  bool get hasImage => imageUrl.trim().isNotEmpty;

  bool get isWalkInvite => type == GroupMessageType.walkInvite;

  int get acceptedCount => acceptedByUserIds.length;

  bool get hasReply =>
      replyToMessageId.isNotEmpty || replyToText.trim().isNotEmpty;

  bool hasUserResponded(String userId) {
    if (userId.isEmpty) {
      return false;
    }
    return acceptedByUserIds.contains(userId) ||
        declinedByUserIds.contains(userId);
  }

  String get preview {
    if (isWalkInvite) {
      final place = (walkLocationName ?? '').trim();
      return place.isEmpty ? 'Poziv na šetnju' : 'Poziv na šetnju: $place';
    }
    if (text.trim().isNotEmpty) {
      return text.trim();
    }
    if (hasImage) {
      return '📷 Fotografija';
    }
    return '';
  }

  GroupMessage copyWith({
    GroupWalkInviteStatus? status,
    List<String>? acceptedByUserIds,
    List<String>? declinedByUserIds,
    List<String>? likes,
  }) {
    return GroupMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: text,
      imageUrl: imageUrl,
      createdAt: createdAt,
      isMine: isMine,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      type: type,
      status: status ?? this.status,
      walkTime: walkTime,
      walkLocationName: walkLocationName,
      acceptedByUserIds: acceptedByUserIds ?? this.acceptedByUserIds,
      declinedByUserIds: declinedByUserIds ?? this.declinedByUserIds,
      likes: likes ?? this.likes,
    );
  }
}

enum GroupMessageType { text, walkInvite }

enum GroupWalkInviteStatus { pending, accepted, declined }

class GroupInboxThread {
  const GroupInboxThread({
    required this.group,
    required this.lastMessage,
    required this.lastActivityAt,
    required this.unreadCount,
  });

  final BreedGroup group;
  final String lastMessage;
  final DateTime lastActivityAt;
  final int unreadCount;

  static GroupInboxThread fromMessages({
    required BreedGroup group,
    required List<GroupMessage> messages,
    DateTime? lastRead,
  }) {
    final last = messages.isEmpty ? null : messages.last;
    final cutoff = lastRead ?? DateTime.now();
    var unread = 0;
    for (final message in messages) {
      if (!message.isMine && message.createdAt.isAfter(cutoff)) {
        unread++;
      }
    }
    return GroupInboxThread(
      group: group,
      lastMessage: last?.preview ?? group.lastMessage,
      lastActivityAt: last?.createdAt ??
          group.lastMessageAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      unreadCount: unread,
    );
  }
}

abstract class GroupsRepository {
  Stream<List<BreedGroup>> watchGroups();

  Stream<List<BreedGroup>> watchPendingGroups();

  Stream<List<GroupMessage>> watchMessages(String groupId);

  Stream<DateTime?> watchLastRead(String groupId);

  Future<void> joinGroup(String groupId);

  Future<void> markRead(String groupId);

  Future<BreedGroup> createGroup({
    required String title,
    required String description,
    bool approveImmediately = false,
  });

  Future<void> approveGroup(String groupId);

  Future<void> deleteGroup(String groupId);

  Future<void> sendMessage({
    required String groupId,
    required String text,
    String imageUrl = '',
    GroupMessage? replyTo,
  });

  Future<void> sendPhoto({
    required String groupId,
    required String imageUrl,
    GroupMessage? replyTo,
  });

  Future<void> sendWalkInvite({
    required String groupId,
    required DateTime walkTime,
    required String walkLocationName,
  });

  Future<void> respondToWalkInvite({
    required String groupId,
    required String messageId,
    required GroupWalkInviteStatus status,
  });

  Future<void> toggleMessageLike({
    required String groupId,
    required String messageId,
  });
}
```

#### `lib/features/events/domain/event_model.dart` (89 linija, ceo fajl)
```dart
class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.locationName,
    required this.dateTime,
    required this.description,
    required this.imageUrl,
    required this.organizerUserId,
    required this.organizerName,
    required this.participantUserIds,
    required this.createdAt,
    this.lastMessage = '',
    this.lastMessageAt,
    this.cityId = '',
  });

  final String id;
  /// [SerbiaLocations] id (`novi_sad`, `beograd`, `nis`, `kragujevac`).
  /// Empty on events created before city support.
  final String cityId;
  final String title;
  final String locationName;
  final DateTime dateTime;
  final String description;
  final String imageUrl;
  final String organizerUserId;
  final String organizerName;
  final List<String> participantUserIds;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime? lastMessageAt;

  int get participantCount => participantUserIds.length;

  bool isJoined(String uid) =>
      uid.isNotEmpty && participantUserIds.contains(uid);

  /// Keep listing for a few hours after start so late joiners still see it.
  static const Duration listGrace = Duration(hours: 6);

  /// Whether this event should appear in the Events & walks list.
  bool isListed([DateTime? now]) {
    final reference = now ?? DateTime.now();
    return dateTime.add(listGrace).isAfter(reference);
  }

  EventModel copyWith({
    String? title,
    String? locationName,
    DateTime? dateTime,
    String? description,
    String? imageUrl,
    List<String>? participantUserIds,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? cityId,
  }) {
    return EventModel(
      id: id,
      cityId: cityId ?? this.cityId,
      title: title ?? this.title,
      locationName: locationName ?? this.locationName,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerUserId: organizerUserId,
      organizerName: organizerName,
      participantUserIds: participantUserIds ?? this.participantUserIds,
      createdAt: createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

class EventInboxThread {
  const EventInboxThread({
    required this.event,
    required this.lastMessage,
    required this.lastActivityAt,
    required this.unreadCount,
  });

  final EventModel event;
  final String lastMessage;
  final DateTime lastActivityAt;
  final int unreadCount;
}
```

#### `lib/features/map/domain/models/poi_model.dart` (228 linija, ceo fajl)
```dart
import '../map_city.dart';
import '../map_place_type.dart';

enum PoiCategory {
  cafe,
  restaurant,
  park,
  petShop,
  groomer,
  vet,
  lodging,
  training,
  dogHotel,
  selfWash,
  dogTreats,
  shelter,
  water,
  petSitter,
  other,
}

enum PoiVerificationStatus {
  verified,
  userSubmitted,
  pending,
  reported,
  unknown,
  rejected,
}

extension PoiVerificationStatusX on PoiVerificationStatus {
  bool get isAwaitingReview =>
      this == PoiVerificationStatus.pending ||
      this == PoiVerificationStatus.userSubmitted;

  String get firestoreValue => name;

  static PoiVerificationStatus fromString(String? value) {
    return switch (value) {
      'verified' => PoiVerificationStatus.verified,
      'userSubmitted' => PoiVerificationStatus.userSubmitted,
      'pending' => PoiVerificationStatus.pending,
      'reported' => PoiVerificationStatus.reported,
      'rejected' => PoiVerificationStatus.rejected,
      _ => PoiVerificationStatus.unknown,
    };
  }
}

class PoiModel {
  const PoiModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone = '',
    this.website,
    this.is24_7 = false,
    this.isEmergencyService = false,
    this.overnightStay = false,
    this.dayCare = false,
    this.hasYard = false,
    this.pricePerNight,
    this.openingHours = '',
    this.petFriendly = true,
    this.dogFriendlyIndoor,
    this.dogFriendlyOutdoor,
    this.waterAvailable,
    this.isDogPark,
    this.municipality = '',
    this.description = '',
    this.imageUrl,
    this.sourceUrl = '',
    this.city = MapCity.noviSad,
    this.cityId = '',
    this.verificationStatus = PoiVerificationStatus.unknown,
    required this.lastVerified,
    required this.source,
    this.rating,
    this.isSponsored = false,
    this.sponsorName = '',
    this.sponsoredUntil,
    this.sponsorBadge = '',
    this.sponsorPriority = 0,
  });

  final String id;
  final String name;
  final PoiCategory category;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String? website;
  final bool is24_7;
  final bool isEmergencyService;
  final bool overnightStay;
  final bool dayCare;
  final bool hasYard;
  final double? pricePerNight;
  /// Free-text hours, e.g. "Pon–Pet 09–20, Sub 10–14".
  final String openingHours;
  final bool petFriendly;
  final bool? dogFriendlyIndoor;
  final bool? dogFriendlyOutdoor;
  final bool? waterAvailable;
  /// Officially designated (fenced) dog area. Null = not set; legacy docs
  /// fall back to the "Park za pse" naming convention.
  final bool? isDogPark;
  final String municipality;
  final String description;
  final String? imageUrl;
  final String sourceUrl;
  final MapCity city;
  final String cityId;
  final PoiVerificationStatus verificationStatus;
  final DateTime lastVerified;
  final String source;
  final double? rating;
  final bool isSponsored;
  final String sponsorName;
  final DateTime? sponsoredUntil;
  final String sponsorBadge;
  final int sponsorPriority;

  MapPlaceType get mapPlaceType => switch (category) {
        PoiCategory.cafe => MapPlaceType.cafe,
        PoiCategory.restaurant => MapPlaceType.restaurant,
        PoiCategory.park => MapPlaceType.park,
        PoiCategory.petShop => MapPlaceType.petShop,
        PoiCategory.groomer => MapPlaceType.groomer,
        PoiCategory.vet => MapPlaceType.vet,
        PoiCategory.lodging => MapPlaceType.lodging,
        PoiCategory.training => MapPlaceType.training,
        PoiCategory.dogHotel => MapPlaceType.dogHotel,
        PoiCategory.selfWash => MapPlaceType.selfWash,
        PoiCategory.dogTreats => MapPlaceType.dogTreats,
        PoiCategory.shelter => MapPlaceType.shelter,
        PoiCategory.water => MapPlaceType.water,
        PoiCategory.petSitter => MapPlaceType.petSitter,
        PoiCategory.other => MapPlaceType.other,
      };

  String get resolvedCityId {
    if (cityId.isNotEmpty) return cityId;
    return city.cityId;
  }

  PoiModel copyWith({
    String? name,
    String? address,
    PoiCategory? category,
    double? latitude,
    double? longitude,
    PoiVerificationStatus? verificationStatus,
    bool? petFriendly,
    DateTime? lastVerified,
    String? source,
    double? rating,
    String? phone,
    String? website,
    bool clearWebsite = false,
    bool? is24_7,
    bool? isEmergencyService,
    bool? overnightStay,
    bool? dayCare,
    bool? hasYard,
    double? pricePerNight,
    bool clearPricePerNight = false,
    String? openingHours,
    MapCity? city,
    String? cityId,
    String? municipality,
    String? description,
    String? imageUrl,
    String? sourceUrl,
    bool? dogFriendlyIndoor,
    bool? dogFriendlyOutdoor,
    bool? waterAvailable,
    bool? isDogPark,
    bool? isSponsored,
    String? sponsorName,
    DateTime? sponsoredUntil,
    String? sponsorBadge,
    int? sponsorPriority,
  }) {
    return PoiModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      website: clearWebsite ? null : (website ?? this.website),
      is24_7: is24_7 ?? this.is24_7,
      isEmergencyService: isEmergencyService ?? this.isEmergencyService,
      overnightStay: overnightStay ?? this.overnightStay,
      dayCare: dayCare ?? this.dayCare,
      hasYard: hasYard ?? this.hasYard,
      pricePerNight:
          clearPricePerNight ? null : (pricePerNight ?? this.pricePerNight),
      openingHours: openingHours ?? this.openingHours,
      petFriendly: petFriendly ?? this.petFriendly,
      dogFriendlyIndoor: dogFriendlyIndoor ?? this.dogFriendlyIndoor,
      dogFriendlyOutdoor: dogFriendlyOutdoor ?? this.dogFriendlyOutdoor,
      waterAvailable: waterAvailable ?? this.waterAvailable,
      isDogPark: isDogPark ?? this.isDogPark,
      municipality: municipality ?? this.municipality,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      lastVerified: lastVerified ?? this.lastVerified,
      source: source ?? this.source,
      rating: rating ?? this.rating,
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorName: sponsorName ?? this.sponsorName,
      sponsoredUntil: sponsoredUntil ?? this.sponsoredUntil,
      sponsorBadge: sponsorBadge ?? this.sponsorBadge,
      sponsorPriority: sponsorPriority ?? this.sponsorPriority,
    );
  }
}
```

#### `lib/features/moments/domain/moment_model.dart` (90 linija, ceo fajl)
```dart
class MomentModel {
  const MomentModel({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.dogId,
    required this.dogName,
    required this.dogBreed,
    required this.dogPhotoUrl,
    required this.momentPhotoUrl,
    required this.caption,
    required this.locationName,
    required this.likes,
    required this.commentsCount,
    required this.createdAt,
  });

  final String id;
  final String authorUserId;
  final String authorName;
  final String dogId;
  final String dogName;
  final String dogBreed;
  final String dogPhotoUrl;
  final String momentPhotoUrl;
  final String caption;
  final String locationName;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;

  static const Duration storyLifetime = Duration(hours: 24);

  int get likeCount => likes.length;

  bool isActiveStory(DateTime now) => now.difference(createdAt) < storyLifetime;

  bool isLikedBy(String uid) => uid.isNotEmpty && likes.contains(uid);

  MomentModel copyWith({List<String>? likes, int? commentsCount}) {
    return MomentModel(
      id: id,
      authorUserId: authorUserId,
      authorName: authorName,
      dogId: dogId,
      dogName: dogName,
      dogBreed: dogBreed,
      dogPhotoUrl: dogPhotoUrl,
      momentPhotoUrl: momentPhotoUrl,
      caption: caption,
      locationName: locationName,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
    );
  }
}

class MomentComment {
  const MomentComment({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.likes = const [],
  });

  final String id;
  final String authorUserId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final List<String> likes;

  int get likeCount => likes.length;

  bool isLikedBy(String uid) => uid.isNotEmpty && likes.contains(uid);

  MomentComment copyWith({List<String>? likes}) {
    return MomentComment(
      id: id,
      authorUserId: authorUserId,
      authorName: authorName,
      text: text,
      createdAt: createdAt,
      likes: likes ?? this.likes,
    );
  }
}
```

#### `lib/features/moments/domain/story_highlight.dart` (43 linija, ceo fajl)
```dart
/// A named collection of stories pinned to a dog's profile. Highlights only
/// reference moment ids, so a story stays visible here after its 24h expire.
class StoryHighlight {
  const StoryHighlight({
    required this.id,
    required this.ownerId,
    required this.dogId,
    required this.title,
    required this.momentIds,
    this.coverMomentId = '',
    this.order = 0,
    required this.createdAt,
  });

  static const int maxTitleLength = 20;

  final String id;
  final String ownerId;
  final String dogId;
  final String title;
  final List<String> momentIds;
  final String coverMomentId;
  final int order;
  final DateTime createdAt;

  StoryHighlight copyWith({
    String? title,
    List<String>? momentIds,
    String? coverMomentId,
    int? order,
  }) {
    return StoryHighlight(
      id: id,
      ownerId: ownerId,
      dogId: dogId,
      title: title ?? this.title,
      momentIds: momentIds ?? this.momentIds,
      coverMomentId: coverMomentId ?? this.coverMomentId,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
```

#### `lib/features/lost_dogs/domain/lost_dog.dart` (134 linija, ceo fajl)
```dart
class LostDog {
  const LostDog({
    required this.id,
    required this.dogName,
    required this.city,
    required this.neighborhood,
    required this.lostDate,
    required this.description,
    required this.imageUrl,
    required this.contactPhone,
    required this.uploaderUserId,
    required this.status,
    required this.createdAt,
    this.type = LostDogType.lost,
    this.breed = '',
    this.foundDate,
  });

  final String id;
  final String dogName;
  final String city;
  final String neighborhood;
  final DateTime lostDate;
  final DateTime? foundDate;
  final String description;
  final String imageUrl;
  final String contactPhone;
  final String uploaderUserId;
  final String status;
  final String type;
  final String breed;
  final DateTime createdAt;

  bool get isLostListing => type != LostDogType.found;

  bool get isFoundListing => type == LostDogType.found;

  bool get isActive =>
      status == LostDogStatus.active || status == LostDogStatus.legacyMissing;

  bool get isMissing => isLostListing && isActive;

  DateTime get eventDate =>
      isFoundListing ? (foundDate ?? lostDate) : lostDate;

  String get placeLabel {
    if (city.isEmpty) {
      return neighborhood;
    }
    if (neighborhood.isEmpty) {
      return city;
    }
    return '$city – $neighborhood';
  }

  LostDog copyWith({
    String? id,
    String? dogName,
    String? city,
    String? neighborhood,
    DateTime? lostDate,
    DateTime? foundDate,
    String? description,
    String? imageUrl,
    String? contactPhone,
    String? uploaderUserId,
    String? status,
    String? type,
    String? breed,
    DateTime? createdAt,
  }) {
    return LostDog(
      id: id ?? this.id,
      dogName: dogName ?? this.dogName,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      lostDate: lostDate ?? this.lostDate,
      foundDate: foundDate ?? this.foundDate,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      contactPhone: contactPhone ?? this.contactPhone,
      uploaderUserId: uploaderUserId ?? this.uploaderUserId,
      status: status ?? this.status,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

abstract final class LostDogType {
  static const String lost = 'lost';
  static const String found = 'found';
}

abstract final class LostDogStatus {
  static const String active = 'active';
  static const String resolved = 'resolved';
  static const String legacyMissing = 'missing';
  static const String legacyFound = 'found';
}

class LostDogComment {
  const LostDogComment({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.likes = const [],
  });

  final String id;
  final String authorUserId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final List<String> likes;

  int get likeCount => likes.length;

  bool isLikedBy(String uid) => uid.isNotEmpty && likes.contains(uid);

  LostDogComment copyWith({List<String>? likes}) {
    return LostDogComment(
      id: id,
      authorUserId: authorUserId,
      authorName: authorName,
      text: text,
      createdAt: createdAt,
      likes: likes ?? this.likes,
    );
  }
}
```

#### `lib/features/adoption/domain/adoption_dog.dart` (79 linija, ceo fajl)
```dart
class AdoptionDog {
  const AdoptionDog({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.size,
    required this.location,
    required this.description,
    required this.imageUrls,
    required this.contactPhone,
    required this.uploaderUserId,
    required this.uploaderName,
    required this.isVaccinated,
    required this.isSterilized,
    required this.createdAt,
    this.status = 'available',
  });

  final String id;
  final String name;
  final String breed;
  final String age;
  final String gender;
  final String size;
  final String location;
  final String description;
  final List<String> imageUrls;
  final String contactPhone;
  final String uploaderUserId;
  final String uploaderName;
  final bool isVaccinated;
  final bool isSterilized;
  final DateTime createdAt;
  final String status;

  bool get isAdopted => status == 'adopted';

  String get photoUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  AdoptionDog copyWith({
    String? id,
    String? name,
    String? breed,
    String? age,
    String? gender,
    String? size,
    String? location,
    String? description,
    List<String>? imageUrls,
    String? contactPhone,
    String? uploaderUserId,
    String? uploaderName,
    bool? isVaccinated,
    bool? isSterilized,
    DateTime? createdAt,
    String? status,
  }) {
    return AdoptionDog(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      size: size ?? this.size,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      contactPhone: contactPhone ?? this.contactPhone,
      uploaderUserId: uploaderUserId ?? this.uploaderUserId,
      uploaderName: uploaderName ?? this.uploaderName,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      isSterilized: isSterilized ?? this.isSterilized,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
```

#### `lib/features/notifications/domain/app_notification.dart` (53 linija, ceo fajl)
```dart
enum NotificationKind {
  match,
  walkRequest,
  chatMessage,
  like,
  superLike,
  groupMessage,
  eventMessage,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.dogId,
    this.fromUserId,
    this.conversationId,
    this.groupId,
    this.eventId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? dogId;
  final String? fromUserId;
  final String? conversationId;
  final String? groupId;
  final String? eventId;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      dogId: dogId,
      fromUserId: fromUserId,
      conversationId: conversationId,
      groupId: groupId,
      eventId: eventId,
    );
  }
}
```

#### `lib/features/notifications/domain/push_payload.dart` (85 linija, ceo fajl)
```dart
enum PushKind { match, message, walk, group, event }

class PushPayload {
  const PushPayload({
    required this.kind,
    required this.title,
    required this.body,
    this.dogId,
    this.peerUserId,
    this.conversationId,
    this.groupId,
    this.eventId,
  });

  final PushKind kind;
  final String title;
  final String body;
  final String? dogId;
  final String? peerUserId;
  final String? conversationId;
  final String? groupId;
  final String? eventId;

  String get typeName => switch (kind) {
        PushKind.match => 'match',
        PushKind.message => 'message',
        PushKind.walk => 'walk',
        PushKind.group => 'group',
        PushKind.event => 'event',
      };

  Map<String, String> get data => {
        'type': typeName,
        'title': title,
        'body': body,
        'dogId': ?dogId,
        'peerUserId': ?peerUserId,
        'conversationId': ?conversationId,
        'groupId': ?groupId,
        'eventId': ?eventId,
      };

  factory PushPayload.fromData(Map<String, dynamic> data) {
    String? read(String key) {
      final value = data[key]?.toString().trim();
      if (value == null || value.isEmpty) {
        return null;
      }
      return value;
    }

    final nested = data['data'];
    if (nested is Map) {
      for (final entry in nested.entries) {
        data.putIfAbsent(entry.key.toString(), () => entry.value);
      }
    }

    return PushPayload(
      kind: kindFrom(read('type')),
      title: read('title') ?? '',
      body: read('body') ?? '',
      dogId: read('dogId') ?? read('senderDogId') ?? read('fromDogId'),
      peerUserId: read('peerUserId') ?? read('fromUserId') ?? read('senderUserId'),
      conversationId: read('conversationId') ?? read('chatId') ?? read('matchId'),
      groupId: read('groupId'),
      eventId: read('eventId'),
    );
  }

  static PushKind kindFrom(String? raw) {
    switch (raw) {
      case 'message':
        return PushKind.message;
      case 'walk':
        return PushKind.walk;
      case 'group':
        return PushKind.group;
      case 'event':
        return PushKind.event;
      default:
        return PushKind.match;
    }
  }
}
```

#### `lib/features/profile/domain/app_settings.dart` (46 linija, ceo fajl)
```dart
import '../../../core/l10n/app_language.dart';
import '../../../core/theme/app_theme_preference.dart';

class AppSettings {
  const AppSettings({
    this.notifyWalkRequests = true,
    this.notifyMessages = true,
    this.notifyNewMatches = true,
    this.radiusKm = 20,
    this.showLocationOnMap = true,
    this.pushPrompted = false,
    this.language = AppLanguage.serbian,
    this.themePreference = AppThemePreference.dark,
  });

  final bool notifyWalkRequests;
  final bool notifyMessages;
  final bool notifyNewMatches;
  final double radiusKm;
  final bool showLocationOnMap;
  final bool pushPrompted;
  final AppLanguage language;
  final AppThemePreference themePreference;

  AppSettings copyWith({
    bool? notifyWalkRequests,
    bool? notifyMessages,
    bool? notifyNewMatches,
    double? radiusKm,
    bool? showLocationOnMap,
    bool? pushPrompted,
    AppLanguage? language,
    AppThemePreference? themePreference,
  }) {
    return AppSettings(
      notifyWalkRequests: notifyWalkRequests ?? this.notifyWalkRequests,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyNewMatches: notifyNewMatches ?? this.notifyNewMatches,
      radiusKm: radiusKm ?? this.radiusKm,
      showLocationOnMap: showLocationOnMap ?? this.showLocationOnMap,
      pushPrompted: pushPrompted ?? this.pushPrompted,
      language: language ?? this.language,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}
```

Ostali modeli (npr. `DiscoverProfile`, zdravstveni zapisi, podsetnici, gradovi/kvartovi, prijave) opisani su u sekciji 6 bez punog koda.
---
## 13. PREDLOG SLEDEĆIH KORAKA

Redosled je predlog po uticaju i riziku; ništa od ovoga nije urađeno u okviru pregleda.

### Odmah (mali, sigurni koraci)
1. **Komitovati trenutni rad** (25 izmena i novi testovi). Push na `master` čeka odobrenje. Ne komitovati `android/key.properties`, `*.jks` ni `*.keystore`.
2. **Ispraviti lajk na grupnim/event porukama:** `_stringList` treba da vraća promenljivu listu, na primer `<String>[]`. Dodati test za prvi lajk.
3. **Grupni čet:** dodati `WidgetsBinding.instance.scheduleFrame()` u `_jumpToEndWithRetry`, kao u 1:1 četu.
4. **Lista četova:** ne zvati `markRead` u `chat_list_screen.dart:351` pre otvaranja; detaljni ekran to već radi posle skrola.
5. **`totalUnreadChatCountProvider`:** brojati iz `visibleConversationsProvider`, bez blokiranih.
6. **Testovi:**
   - popraviti `test/profile_test.dart:41` (ne kompajlira);
   - zasebno pregledati 18 testova koji padaju (vidi sekciju 11) i ne „popravljati“ ih menjanjem očekivanja bez razloga.
7. **Zameniti `print()`** sa `debugPrint` ili Crashlytics logovanjem.

### Kratkoročno (bezbednost i backend)
8. **Firestore pravila** – pooštriti; deploy samo uz eksplicitno odobrenje i posle testiranja u emulatoru:
   - `users`: javni profil odvojiti od privatnih polja (email, `fcmToken`, prijave, lokacija), na primer u podkolekciju `private`;
   - `events` i `breed_groups` update: samo organizator/admin; članstvo samo kroz `members/{uid}` i ograničena polja (`memberIds`, `memberCount`);
   - zabraniti klijentu da pravi `isApproved: true` grupe;
   - `notifications`/`fcmInbox` create: `fromUserId == auth.uid` i ograničena polja;
   - `matches`/`swipes`: proveravati učesnike;
   - `lost_dogs`: komentari kao podkolekcija umesto niza.
9. **Storage:** `chats/` čitanje samo za učesnike (na primer putanja `chats/{chatId}/...` sa proverom preko `firestore.get`) i suziti CORS.
10. **Cloud Functions (TypeScript, Firebase Functions v2):**
    - `onDocumentCreated('users/{uid}/fcmInbox/{id}')` → FCM na `fcmToken`;
    - serversko kreiranje mečeva i notifikacija;
    - kaskadno brisanje naloga (`onDelete` korisnika ili callable);
    - admin dodela uloge preko custom claims-a.
    
    Potreban je Blaze plan.
11. **Brisanje naloga:** prvo reautentikacija, pa `user.delete()`, pa čišćenje podataka (idealno na serveru).
12. **Registracija:** upload profilne slike tek posle `createUserWithEmailAndPassword`.
13. **Seed grupe i događaji:** prestati sa upisom sa klijenta (lažni `memberCount`); seed raditi jednokratno admin skriptom.

### Srednjoročno (izdavanje)
14. **iOS:**
    - pravi bundle id (npr. `com.vauvau.app`) i registracija iOS aplikacije u Firebase-u;
    - `GoogleService-Info.plist` u Xcode projekat;
    - Push capability + APNs ključ;
    - `DEVELOPMENT_TEAM`;
    - URL scheme za Google;
    - uskladiti tekstove lokacije sa politikom privatnosti.
15. **Android:** build skripte za AAB, ažurirati `docs/play-launch-checklist.md`, monohromatska ikona za notifikacije.
16. **Web:** registrovati web aplikaciju u Firebase-u (`flutterfire configure`) i ispraviti Google client id; ili zvanično odustati od web-a.
17. **Mapa:** sopstveni ili komercijalni tile provajder umesto `tile.openstreetmap.org`; keš i rate-limit za Nominatim.

### Dugoročno (kvalitet koda)
18. Ujednačiti šemu lokacije i slika (jedno polje za grad/kvart i jedan GeoPoint; jedno polje za listu slika) uz migraciju. Migracije rade samo uz odobrenje, bez brisanja admin i korisničkih podataka.
19. Ukloniti duple izvore istine (`contentReports[]`, `placeChangeRequests[]`) i neiskorišćen kod (`AppRoutes`, `dog_photo_persist*`, legacy `highlights`).
20. Lokalizacija preko `flutter gen-l10n` (`.arb`) i prevesti preostale stringove.
21. Uvesti deklarativnu navigaciju (npr. `go_router`) sa deep linkovima za push.
22. Očistiti repo: nekorišćene splash slike (~7,3 MB), `Gist`, `docs/reels/` binarne fajlove, zastareli README.
23. Dodati CI (GitHub Actions: `flutter analyze` + `flutter test`) i Firestore rules unit testove u emulatoru.

---
## KRATAK REZIME (za brzi kontekst)

1. **VauVau:** Flutter 3.44.1 / Dart 3.12.1 aplikacija za vlasnike pasa u Srbiji (Novi Sad, Beograd, Niš, Kragujevac). UI je na srpskom, delimično na engleskom.
2. **Stack:** Riverpod 3.4.3 (bez code-gen-a), feature-first struktura `lib/features/<x>/{domain,data,presentation}`, repository pattern (Firestore + Local/seed implementacija).
3. **Firebase projekat `vauvau-3195a`:** Auth (email aktivan; Google implementiran, ali sakriven), Firestore (offline keš), Storage, FCM (samo klijent), Crashlytics, Hosting (samo pravne stranice).
4. **Nema Cloud Functions ni servera.** Mečevi, brojači, notifikacije i brisanje naloga rade se sa klijenta; push sa zatvorenom aplikacijom ne stiže.
5. **Tok:** `main` → `SplashScreen` → `AuthGate` → Login / DogOnboarding / `HomeShellScreen`.
   - Tabovi: Otkrij, Mapa, Poruke, Profil.
   - Drawer: Grupe, Događaji, Priče, Izgubljeni psi, Udomi, Pravila, Podešavanja, Admin.
6. **Funkcije:**
   - swipe/lajk/super lajk/meč, 1:1 čet (tekst, slika, lokacija, poziv na šetnju, lajkovi, unread);
   - grupe i događaji sa četom;
   - OSM mapa sa mestima i praćenjem šetnje;
   - priče 24h + istaknute;
   - izgubljeni psi, udomljavanje, zdravstveni karton/podsetnici;
   - prijave/blokiranje, admin panel.
7. **Admin:** `users/{uid}.role == 'admin'`, postavlja se ručno u konzoli. Navigacija je samo `Navigator.push`, bez imenovanih ruta i deep linkova.
8. **Platforme:** Android je primaran (`com.vauvau.app`, release potpisivanje). iOS nije spreman (`com.example.vauvau`, nema push/entitlements). Web koristi Android Firebase opcije.
9. **Glavni bagovi:**
   - prvi lajk na grupnoj/event poruci baca `UnsupportedError`;
   - upload slike pri registraciji pre logina;
   - brisanje naloga pre reautentikacije;
   - `markRead` iz liste četova;
   - grupni čet bez `scheduleFrame`.
10. **Bezbednost:** `users` je čitljiv svima prijavljenima (email, token, lokacija). `events`/`breed_groups` može da menja svako. `notifications`/`matches` može da pravi svako. Sve Storage slike (i četovi) su javne.
11. **Testovi:** 38 fajlova, oko 193 testa; 18 nevezanih padova i `profile_test.dart` koji ne kompajlira. Nema TODO/FIXME u kodu.
12. **Nekomitovano:** 25 izmena (multiline unos, zvuk poruke, unread popravke, avatar → profil, zakazane šetnje, full-screen slike, novi testovi).
13. **Prioriteti:**
    - komit, pa popravke bagova iz tačke 9;
    - pooštriti Firestore i Storage pravila (deploy samo uz odobrenje);
    - Cloud Functions za push i serversku logiku;
    - iOS podešavanje i AAB build;
    - čišćenje šeme lokacije/slika i repoa.
14. **Ograničenja:** ne menjati produkcione podatke radi testiranja; ne izmišljati podatke o mestima (adrese, telefoni, radna vremena, pet politike); čuvati admin i korisničke lokacije; ne komitovati `key.properties` i keystore.
