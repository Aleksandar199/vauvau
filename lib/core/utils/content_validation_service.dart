import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

abstract final class ContentValidationService {
  static const String invalidTextMessage =
      'Uneseni tekst sadrži neprikladne reči ili nevažeći format.';
  static const String invalidImageMessage =
      'Fotografija nije prepoznata. Pokušajte JPEG, PNG ili WebP.';

  static const List<String> _blocked = [
    'jebem',
    'jebi',
    'jebiga',
    'kurac',
    'pička',
    'picka',
    'sranje',
    'govno',
    'krmak',
    'pederski',
    'ušmrk',
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'cunt',
    'nigger',
    'whore',
    'retard',
  ];

  static final RegExp _spamChars = RegExp(r'(.)\1{7,}');
  static final RegExp _url = RegExp(r'(https?:\/\/|www\.)\S+', caseSensitive: false);
  static final RegExp _letters = RegExp(r'[a-zA-ZčćžšđČĆŽŠĐ]');

  static String? validateText(
    String raw, {
    bool allowEmpty = false,
    int minLetters = 2,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return allowEmpty ? null : invalidTextMessage;
    }
    final lower = text.toLowerCase();
    for (final word in _blocked) {
      if (RegExp('\\b${RegExp.escape(word)}\\b', unicode: true).hasMatch(lower) ||
          lower.contains(word)) {
        return invalidTextMessage;
      }
    }
    if (_spamChars.hasMatch(text)) {
      return invalidTextMessage;
    }
    if (_url.allMatches(text).length > 2) {
      return invalidTextMessage;
    }
    if (text.length >= 8 && !_letters.hasMatch(text)) {
      return invalidTextMessage;
    }
    final letterCount = _letters.allMatches(text).length;
    if (letterCount < minLetters && text.length > 3) {
      return invalidTextMessage;
    }
    return null;
  }

  static String? validateTitle(String raw) =>
      validateText(raw, minLetters: 3);

  static Future<String?> validateImage(XFile file) async {
    try {
      final name = file.name.toLowerCase();
      final mime = (file.mimeType ?? '').toLowerCase();
      final allowedName = name.endsWith('.jpg') ||
          name.endsWith('.jpeg') ||
          name.endsWith('.png') ||
          name.endsWith('.webp') ||
          name.endsWith('.heic') ||
          name.endsWith('.heif') ||
          !name.contains('.');
      final allowedMime = mime.isEmpty || mime.startsWith('image/');
      if (!allowedName && !allowedMime) {
        return invalidImageMessage;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? validateImageBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return invalidImageMessage;
    }
    if (!_looksLikeSupportedImage(bytes)) {
      return invalidImageMessage;
    }
    return null;
  }

  static bool _looksLikeSupportedImage(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return true;
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    return false;
  }
}
