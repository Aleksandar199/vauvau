import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/firebase/app_check_setup.dart';

void main() {
  group('App Check: koji provajder koristi build', () {
    AppCheckPlan plan({
      bool web = false,
      TargetPlatform platform = TargetPlatform.android,
      bool debug = false,
    }) => appCheckPlanFor(isWeb: web, platform: platform, isDebug: debug);

    test('release na telefonu: Play Integrity / App Attest', () {
      expect(plan(), AppCheckPlan.production);
      expect(plan(platform: TargetPlatform.iOS), AppCheckPlan.production);
    });

    test('debug na telefonu i webu: debug provajder (token se registruje)', () {
      expect(plan(debug: true), AppCheckPlan.debug);
      expect(
        plan(platform: TargetPlatform.iOS, debug: true),
        AppCheckPlan.debug,
      );
      expect(plan(web: true, debug: true), AppCheckPlan.debug);
    });

    test('release web i desktop: ne aktivira se', () {
      expect(plan(web: true), AppCheckPlan.none);
      expect(plan(platform: TargetPlatform.windows), AppCheckPlan.none);
      expect(
        plan(platform: TargetPlatform.macOS, debug: true),
        AppCheckPlan.none,
      );
    });
  });
}
