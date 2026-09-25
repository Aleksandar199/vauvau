import 'package:image_picker/image_picker.dart';

import 'dog_photo_persist_io.dart'
    if (dart.library.html) 'dog_photo_persist_web.dart' as impl;

Future<List<String>> persistDogPhotos({
  required String dogId,
  required List<XFile> files,
}) {
  return impl.persistDogPhotos(dogId: dogId, files: files);
}
