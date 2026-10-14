import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_status.dart';

/// Thin Crashlytics wrapper — no-ops on web / when Firebase is not ready.
abstract final class CrashReporting {
  static bool get _enabled =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) &&
      isFirebaseReady;

  static Future<void> init() async {
    if (!_enabled) {
      return;
    }
    // Collect in debug too so Play QA / internal testing sees crashes early.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  static Future<void> setUserId(String? uid) async {
    if (!_enabled) {
      return;
    }
    final value = (uid ?? '').trim();
    await FirebaseCrashlytics.instance.setUserIdentifier(value);
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    if (!_enabled) {
      return;
    }
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!_enabled) {
      return;
    }
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: fatal,
      reason: reason,
    );
  }

  static Future<void> log(String message) async {
    if (!_enabled) {
      return;
    }
    await FirebaseCrashlytics.instance.log(message);
  }
}
