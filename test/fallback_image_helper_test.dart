import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vauvau/core/images/dog_photo_urls.dart';
import 'package:vauvau/core/images/fallback_image_helper.dart';
import 'package:vauvau/features/lost_dogs/data/lost_dog_popup_store.dart';

void main() {
  test('picks a stable illustration URL for the same seed', () {
    final first = FallbackImageHelper.getRandomFallbackImage('dog-42');
    final second = FallbackImageHelper.getRandomFallbackImage('dog-42');
    expect(first, second);
    expect(first, isNotEmpty);
    expect(FallbackImageHelper.illustrationUrls.contains(first), isTrue);
    expect(FallbackImageHelper.illustrationUrls, hasLength(10));
  });

  test('varies illustration URLs across different listing ids', () {
    final urls = {
      for (var i = 0; i < 24; i++)
        FallbackImageHelper.getRandomFallbackImage('listing-$i'),
    };
    expect(urls.length, greaterThan(1));
  });

  test('picks a stable local color for the same seed', () {
    final first = FallbackImageHelper.colorForSeed('dog-42');
    final second = FallbackImageHelper.colorForSeed('dog-42');
    expect(first, second);
    expect(FallbackImageHelper.illustrationColors.contains(first), isTrue);
  });

  test('rejects Unsplash as unusable / non-persistable', () {
    const unsplash =
        'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=800&q=80';
    expect(isUnusableDogPhotoUrl(unsplash), isTrue);
    expect(isStockCdnPhotoUrl(unsplash), isTrue);
    expect(uniquePhotoUrls([unsplash]), isEmpty);
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
