import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vauvau/core/images/fallback_image_helper.dart';
import 'package:vauvau/features/lost_dogs/data/lost_dog_popup_store.dart';

void main() {
  test('picks a stable real dog photo for the same seed', () {
    final first = FallbackImageHelper.getRandomFallbackImage('dog-42');
    final second = FallbackImageHelper.getRandomFallbackImage('dog-42');
    expect(first, second);
    expect(FallbackImageHelper.illustrationUrls, hasLength(10));
    expect(FallbackImageHelper.illustrationUrls.contains(first), isTrue);
    expect(first.contains('unsplash.com'), isTrue);
  });

  test('varies photos across different listing ids', () {
    final urls = {
      for (var i = 0; i < 24; i++)
        FallbackImageHelper.getRandomFallbackImage('listing-$i'),
    };
    expect(urls.length, greaterThan(1));
  });

  testWidgets('caption sits below the image, not over it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 120,
                width: 200,
                child: ColoredBox(color: Colors.blue),
              ),
              FallbackIllustrationCaption(url: ''),
            ],
          ),
        ),
      ),
    );
    expect(find.text(FallbackImageHelper.badgeLabel), findsOneWidget);
    expect(find.byType(FallbackIllustrationCaption), findsOneWidget);
  });

  test('lost dog popup dismissal is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await LostDogPopupStore.hasDismissed(), isFalse);
    await LostDogPopupStore.markDismissed();
    expect(await LostDogPopupStore.hasDismissed(), isTrue);
  });
}
