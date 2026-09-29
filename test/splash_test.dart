import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('shows branded splash copy in Serbian', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();

    expect(find.image(const AssetImage('assets/images/vauvau_logo.jpg')), findsOneWidget);
    expect(find.text(SplashScreen.tagline), findsOneWidget);
  });
}
