import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/app/app.dart';
import 'package:vauvau/core/constants/app_strings.dart';
import 'package:vauvau/features/auth/domain/app_user.dart';
import 'package:vauvau/features/auth/presentation/auth_providers.dart';
import 'package:vauvau/features/discover/presentation/discover_image.dart';
import 'package:vauvau/features/discover/presentation/discover_strings.dart';
import 'package:vauvau/features/dogs/presentation/dog_providers.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_dogs_repository.dart';

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  const signedInUser = AppUser(
    uid: '1',
    email: 'alex@example.com',
    displayName: 'Alex',
  );

  testWidgets('logged out shows welcome and Get Started opens login', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(),
          ),
        ],
        child: const VauVauApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appName), findsWidgets);
    expect(find.text(AppStrings.getStarted), findsOneWidget);

    await tester.tap(find.text(AppStrings.getStarted));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.logInTitle), findsWidgets);
    expect(find.text(AppStrings.continueWithGoogle), findsOneWidget);
  });

  testWidgets('logged in without a dog shows onboarding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(user: signedInUser),
          ),
          dogsRepositoryProvider.overrideWith(
            (ref) => FakeDogsRepository(),
          ),
        ],
        child: const VauVauApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(AppStrings.onboardingTitle), findsOneWidget);
    expect(find.text(AppStrings.stepBasicsTitle), findsOneWidget);
    expect(find.text(AppStrings.next), findsOneWidget);
  });

  testWidgets('logged in with a dog shows discover', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(user: signedInUser),
          ),
          dogsRepositoryProvider.overrideWith(
            (ref) => FakeDogsRepository(dogs: [fakeDog()]),
          ),
          discoverImageFactoryProvider.overrideWith((ref) {
            return (_) => MemoryImage(_transparentPng);
          }),
        ],
        child: const VauVauApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(DiscoverStrings.title), findsWidgets);
    expect(find.text(DiscoverStrings.signOut), findsOneWidget);
    expect(find.text('Bobi, 2 god.'), findsOneWidget);
  });
}
