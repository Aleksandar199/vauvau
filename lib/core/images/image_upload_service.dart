import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/storage_service.dart';

/// Uploads images to Firebase Storage.
///
/// Prefer [StorageService] directly. This wrapper keeps older call sites
/// working with an explicit [folderName].
class ImageUploadService {
  const ImageUploadService();

  static Future<String> upload(
    Uint8List bytes, {
    required String folderName,
    String fileName = 'upload.jpg',
    String ownerId = '',
  }) {
    return const ImageUploadService().uploadImage(
      bytes,
      folderName: folderName,
      fileName: fileName,
      ownerId: ownerId,
    );
  }

  static Future<String> uploadFile(
    XFile file, {
    required String folderName,
    String ownerId = '',
  }) {
    return const ImageUploadService().uploadXFile(
      file,
      folderName: folderName,
      ownerId: ownerId,
    );
  }

  Future<String> uploadImage(
    Uint8List bytes, {
    required String folderName,
    String fileName = 'upload.jpg',
    String ownerId = '',
  }) {
    return StorageService().uploadBytes(
      bytes: bytes,
      folderName: folderName,
      fileName: fileName,
      ownerId: ownerId,
    );
  }

  Future<String> uploadXFile(
    XFile file, {
    required String folderName,
    String ownerId = '',
  }) async {
    final url = await StorageService().uploadXFile(
      file: file,
      folderName: folderName,
      ownerId: ownerId,
    );
    if (url == null ||
        url.startsWith('gs://') ||
        !(url.startsWith('https://') || url.startsWith('http://'))) {
      throw StateError('Upload na Firebase Storage nije uspeo.');
    }
    return url;
  }

  Future<List<String>> uploadAll(
    List<XFile> files, {
    required String folderName,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadXFile(file, folderName: folderName));
    }
    return urls;
  }
}
