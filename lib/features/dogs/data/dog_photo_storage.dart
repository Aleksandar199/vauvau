import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class DogPhotoStorage {
  DogPhotoStorage(this._storage);

  final FirebaseStorage _storage;

  Future<String> upload({
    required String dogId,
    required int index,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final ref = _storage.ref('dogs/$dogId/photos/$index.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
