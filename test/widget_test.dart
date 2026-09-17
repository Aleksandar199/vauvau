import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/app/app.dart';
import 'package:vauvau/core/constants/app_strings.dart';

void main() {
  testWidgets('welcome screen navigates to discover', (tester) async {
    await tester.pumpWidget(const VauVauApp());

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.getStarted), findsOneWidget);

    await tester.tap(find.text(AppStrings.getStarted));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.discoverTitle), findsOneWidget);
    expect(find.text(AppStrings.discoverPlaceholder), findsOneWidget);
  });
}
