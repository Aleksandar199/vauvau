import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Which App Check provider a build uses.
enum AppCheckPlan {
  /// Play Integrity (Android) / App Attest with DeviceCheck fallback (iOS):
  /// only the genuine, store-installed app on an uncompromised device gets
  /// a token. This is what stops scripts, repackaged APKs and emulators.
  production,

  /// Debug builds (`flutter run`): the debug provider. The token it prints
  /// in the log must be registered once in Firebase Console → App Check →
  /// Apps → Manage debug tokens, otherwise enforced requests are refused.
  debug,

  /// Not activated (release web, desktop): nothing to attest.
  none,
}

/// Pure decision, so it can be tested.
AppCheckPlan appCheckPlanFor({
  required bool isWeb,
  required TargetPlatform platform,
  required bool isDebug,
}) {
  final mobile =
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  if (isWeb) return isDebug ? AppCheckPlan.debug : AppCheckPlan.none;
  if (!mobile) return AppCheckPlan.none;
  return isDebug ? AppCheckPlan.debug : AppCheckPlan.production;
}

/// Turns App Check on right after Firebase is initialised. Never throws and
/// never delays start-up for long: while App Check is only *monitored* in
/// the console a failure here changes nothing, and once it is enforced the
/// requests are refused by the server anyway.
Future<void> activateAppCheck() async {
  final plan = appCheckPlanFor(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    isDebug: kDebugMode,
  );
  if (plan == AppCheckPlan.none) return;
  try {
    final debug = plan == AppCheckPlan.debug;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: debug
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: debug
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      providerWeb: debug ? WebDebugProvider() : null,
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (error) {
    debugPrint('App Check activation failed: $error');
  }
}
