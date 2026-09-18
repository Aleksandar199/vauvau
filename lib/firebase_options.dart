// Replace this file by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Enable Email/Password and Google in Firebase Authentication.
// Android: add debug SHA-1/SHA-256. iOS: URL scheme from REVERSED_CLIENT_ID.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured. Run `dart pub global activate flutterfire_cli` '
      'then `flutterfire configure` in this project.',
    );
  }
}
