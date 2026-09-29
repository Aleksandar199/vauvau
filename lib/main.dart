import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/firebase_init_error_app.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final authReady = FirebaseAuth.instance.app.options.projectId.isNotEmpty;
    final firestoreReady =
        FirebaseFirestore.instance.app.options.projectId.isNotEmpty;
    if (!authReady || !firestoreReady) {
      throw StateError('Firebase Auth ili Firestore nisu dostupni.');
    }
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('🔴 FLUTTER ERROR: ${details.exceptionAsString()}');
      debugPrint('🔴 STACK: ${details.stack}');
    };
    runApp(const ProviderScope(child: VauVauApp()));
  } catch (error, stack) {
    debugPrint('🔴 MAIN CATCH: $error');
    debugPrint('🔴 STACK: $stack');
    runApp(FirebaseInitErrorApp(message: error.toString()));
  }
}
