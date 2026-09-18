# vauvau

A Flutter app for dog owners (Serbia first).

## Firebase setup (required for Auth)

1. Create a Firebase project and enable **Email/Password** and **Google** sign-in.
2. From the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

3. Android: add your debug SHA-1 and SHA-256 in the Firebase console (needed for Google Sign-In).
4. iOS: add the reversed client ID URL scheme from `GoogleService-Info.plist`.

`lib/firebase_options.dart` is a stub until `flutterfire configure` generates the real options.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
