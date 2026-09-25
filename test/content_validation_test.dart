import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vauvau/core/utils/content_validation_service.dart';

void main() {
  test('rejects Serbian and English profanity', () {
    expect(
      ContentValidationService.validateText('Ovo je sranje'),
      ContentValidationService.invalidTextMessage,
    );
    expect(
      ContentValidationService.validateText('What the fuck'),
      ContentValidationService.invalidTextMessage,
    );
  });

  test('rejects spam characters and empty links', () {
    expect(
      ContentValidationService.validateTitle('aaaaaaaaaaaa'),
      ContentValidationService.invalidTextMessage,
    );
    expect(
      ContentValidationService.validateText(
        'www.spam.com www.spam2.com www.spam3.com',
      ),
      ContentValidationService.invalidTextMessage,
    );
  });

  test('accepts normal bios and titles', () {
    expect(
      ContentValidationService.validateText('Luna voli šetnje uz Dunav.'),
      isNull,
    );
    expect(
      ContentValidationService.validateTitle('Park kod Keja'),
      isNull,
    );
  });

  test('rejects empty or invalid image bytes', () {
    expect(
      ContentValidationService.validateImageBytes(Uint8List(0)),
      ContentValidationService.invalidImageMessage,
    );
    expect(
      ContentValidationService.validateImageBytes(
        Uint8List.fromList(const [1, 2, 3, 4]),
      ),
      ContentValidationService.invalidImageMessage,
    );
    final png = Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    expect(ContentValidationService.validateImageBytes(png), isNull);
  });
}
