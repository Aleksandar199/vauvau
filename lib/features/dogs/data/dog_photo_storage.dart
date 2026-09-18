import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class DogPhotoStorage {
  DogPhotoStorage(this._storage);

  final FirebaseStorage _storage;

  Future<String> upload({
    required String dogId,
    required int index,
    required XFile file,
  }) {
    final path = index == 0
        ? 'dogs/$dogId/profile.jpg'
        : 'dogs/$dogId/gallery/$index.jpg';
    return _put(path, file);
  }

  Future<String> _put(String path, XFile file) async {
    final bytes = await file.readAsBytes();
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
