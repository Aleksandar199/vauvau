import '../../support/domain/official_contacts.dart';

/// Public HTTPS URLs for Play Console Data safety and external browsers.
///
/// Host the HTML under `docs/` (or Firebase Hosting) at these paths before
/// submitting the store listing. In-app screens remain the primary UX.
abstract final class LegalUrls {
  /// Default Firebase Hosting URLs for project `vauvau-3195a`.
  /// After `firebase deploy --only hosting`, confirm these open in a browser.
  /// If you later attach a custom domain (e.g. vauvau.app), update both URIs.
  static final Uri privacyPolicy =
      Uri.parse('https://vauvau-3195a.web.app/privacy');
  static final Uri termsOfService =
      Uri.parse('https://vauvau-3195a.web.app/terms');

  static final Uri privacyContact = OfficialContacts.emailUri;
}
