import 'package:image_picker/image_picker.dart';

import '../../../core/images/image_upload_service.dart';

class DogPhotoStorage {
  const DogPhotoStorage({this.uploader = const ImageUploadService()});

  final ImageUploadService uploader;

  Future<List<String>> uploadAll({
    required String dogId,
    required List<XFile> files,
    String ownerId = '',
  }) {
    return uploader.uploadAll(files);
  }

  Future<String> upload({
    required String dogId,
    required int index,
    required XFile file,
    String ownerId = '',
  }) async {
    return ImageUploadService.upload(await file.readAsBytes());
  }
}
