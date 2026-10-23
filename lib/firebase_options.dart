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
    apiKey: 'AIzaSyB_HVvq7j8Yf_VyO7I7FrSKWT1_yviagUs',
    // Firebase iOS app for bundle com.vauvau.app (not com.example.vauvau).
    appId: '1:461477755452:ios:c24497b80ebc6f38912139',
    messagingSenderId: '461477755452',
    projectId: 'vauvau-3195a',
    storageBucket: 'vauvau-3195a.firebasestorage.app',
    iosClientId: '461477755452-jv0dsh80ic6700mr657ulttlr0iba5an.apps.googleusercontent.com',
    iosBundleId: 'com.vauvau.app',
  );
}
