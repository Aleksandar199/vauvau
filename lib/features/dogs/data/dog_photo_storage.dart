import 'package:image_picker/image_picker.dart';

import '../../../services/storage_service.dart';

class DogPhotoStorage {
  DogPhotoStorage({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;

  Future<List<String>> uploadAll({
    required String dogId,
    required List<XFile> files,
    String ownerId = '',
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await _storage.uploadXFile(
        file: file,
        folderName: 'pets',
        ownerId: ownerId,
      );
      if (url != null &&
          url.startsWith('http') &&
          !StorageService.isGsUri(url)) {
        urls.add(url);
      }
    }
    return urls;
  }

  Future<String> upload({
    required String dogId,
    required int index,
    required XFile file,
    String ownerId = '',
  }) async {
    final url = await _storage.uploadXFile(
      file: file,
      folderName: 'pets',
      ownerId: ownerId,
    );
    if (url == null ||
        !url.startsWith('http') ||
        StorageService.isGsUri(url)) {
      throw StateError('Upload fotografije nije uspeo.');
    }
    return url;
  }
}
