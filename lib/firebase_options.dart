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
    apiKey: 'AIzaSyD2WpCWpsaj0lM15ort_OpVd1-l-0g0vCI',
    // Firebase Android app for package com.vauvau.app (not com.example.vauvau).
    appId: '1:461477755452:android:13d12fdcbb5f9d68912139',
    messagingSenderId: '461477755452',
    projectId: 'vauvau-3195a',
    storageBucket: 'vauvau-3195a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2WpCWpsaj0lM15ort_OpVd1-l-0g0vCI',
    appId: '1:461477755452:ios:44694b8fcf6cfa67912139',
    messagingSenderId: '461477755452',
    projectId: 'vauvau-3195a',
    storageBucket: 'vauvau-3195a.firebasestorage.app',
    iosBundleId: 'com.example.vauvau',
  );
}
