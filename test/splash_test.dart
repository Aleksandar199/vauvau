import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('shows only the branded splash image', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();

    expect(
      find.image(const AssetImage(SplashScreen.logoAsset)),
      findsOneWidget,
    );
    // Title/tagline live inside the PNG — no duplicate Flutter text.
    expect(find.text(SplashScreen.tagline), findsNothing);
  });
}
