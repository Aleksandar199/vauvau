import 'package:image_picker/image_picker.dart';

Future<List<String>> persistDogPhotos({
  required String dogId,
  required List<XFile> files,
}) async {
  return [for (final file in files) file.path];
}
