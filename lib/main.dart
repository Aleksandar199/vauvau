import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _tryInitializeFirebase();
  runApp(const ProviderScope(child: VauVauApp()));
}

Future<void> _tryInitializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Unconfigured stub or plugin failure: run Phase 1–4 UI with local mocks.
  }
}
