import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/firebase_init_error_app.dart';
import 'core/crash/crash_reporting.dart';
import 'core/firebase/app_check_setup.dart';
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
      await _initializeFirebase();
    }
  } catch (_) {}
}

/// iOS (and Android with google-services) configure the native "[DEFAULT]"
/// app from GoogleService-Info.plist / google-services.json before Dart runs.
/// When the Dart options differ from that file (e.g. API key),
/// initializeApp(options:) throws `duplicate-app` and the app never starts –
/// then the native app is used as is (it is the source of truth on device).
Future<FirebaseApp> _initializeFirebase() async {
  try {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
    debugPrint('Firebase: using the natively configured default app.');
    return Firebase.app();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  await NotificationService().initialize();
  try {
    await _initializeFirebase();
    // App Check before any Firestore / Storage / Functions request.
    await activateAppCheck();
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
