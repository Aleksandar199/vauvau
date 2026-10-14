import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads and deletes images on Firebase Storage.
///
/// Objects live under `{root}/{userId}/...` so Storage rules can enforce
/// `isOwner(userId)` on create/update/delete.
class StorageService {
  StorageService({
    FirebaseStorage? storage,
    ImagePicker? picker,
    String? Function()? currentUserId,
  })  : _storageOverride = storage,
        _picker = picker ?? ImagePicker(),
        _currentUserId = currentUserId ??
            (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseStorage? _storageOverride;
  final ImagePicker _picker;
  final String? Function() _currentUserId;

  FirebaseStorage get _storage =>
      _storageOverride ?? FirebaseStorage.instance;

  /// Roots that must be owner-scoped: `{root}/{uid}/file`.
  static const Set<String> ownerScopedRoots = {
    'pets',
    'users',
    'moments',
    'events',
    'groups',
    'adoption',
    'lost_dogs',
    'uploads',
    'chats',
  };

  /// In-memory cache so story grids don't re-download the same object.
  static final Map<String, Uint8List> _bytesCache = {};
  static const int _maxCachedImages = 48;
  static const int _maxDownloadBytes = 8 * 1024 * 1024;

  /// Builds `{root}/{userId}` (or nests [folderName] under the signed-in uid).
  ///
  /// Pass [ownerId] when uploading on behalf of a known owner (must match auth).
  String ownerFolder(String folderName, {String ownerId = ''}) {
    final uid = ownerId.trim().isNotEmpty
        ? ownerId.trim()
        : (_currentUserId()?.trim() ?? '');
    if (uid.isEmpty) {
      throw StateError('Moraš biti prijavljen da bi poslao sliku.');
    }
    final folder = folderName.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (folder.isEmpty) {
      return 'uploads/$uid';
    }
    final parts = folder.split('/').where((part) => part.isNotEmpty).toList();
    final root = parts.first;
    if (!ownerScopedRoots.contains(root)) {
      // Unknown root → park under uploads/{uid}/...
      return 'uploads/$uid/$folder';
    }
    if (parts.length >= 2 && parts[1] == uid) {
      return parts.join('/');
    }
    if (parts.length == 1) {
      return '$root/$uid';
    }
    // pets/extra → pets/{uid}/extra (never pets/wrongId/...)
    final rest = parts.skip(1).join('/');
    return '$root/$uid/$rest';
  }

  /// True for HTTPS download URLs and `gs://` object URIs.
  static bool isFirebaseStorageUrl(String url) {
    final value = url.trim().toLowerCase();
    if (value.isEmpty) {
      return false;
    }
    if (value.startsWith('gs://')) {
      return true;
    }
    return value.contains('firebasestorage.googleapis.com') ||
        value.contains('firebasestorage.app') ||
        value.contains('.appspot.com');
  }

  static bool isHttpsDownloadUrl(String url) {
    final value = url.trim();
    return value.startsWith('https://') || value.startsWith('http://');
  }

  static bool isGsUri(String url) => url.trim().toLowerCase().startsWith('gs://');

  /// Downloads image bytes via the Storage SDK (auth + correct decode).
  /// Accepts HTTPS download URLs and `gs://bucket/path` URIs.
  Future<Uint8List> downloadBytes(String imageUrl) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      throw StateError('Prazan Storage URL.');
    }
    final cached = _bytesCache[url];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final ref = _refFromAny(url);
      final bytes = await ref.getData(_maxDownloadBytes);
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Storage fajl je prazan.');
      }
      _rememberBytes(url, bytes);
      return bytes;
    } on FirebaseException catch (error) {
      debugPrint(
        'StorageService.downloadBytes failed code=${error.code} url=$url',
      );
      throw StateError(_userMessageForFirebase(error));
    }
  }

  /// Converts a `gs://` URI (or any Storage ref URL) into a public HTTPS
  /// download URL. HTTPS inputs are returned unchanged.
  Future<String> resolveDownloadUrl(String imageUrl) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      throw StateError('Prazan Storage URL.');
    }
    if (isHttpsDownloadUrl(url) && !isGsUri(url)) {
      return url;
    }
    try {
      final downloadUrl = await _refFromAny(url).getDownloadURL();
      return _requireHttpsDownloadUrl(downloadUrl);
    } on FirebaseException catch (error) {
      debugPrint(
        'StorageService.resolveDownloadUrl failed code=${error.code} url=$url',
      );
      throw StateError(_userMessageForFirebase(error));
    }
  }

  static void _rememberBytes(String url, Uint8List bytes) {
    if (_bytesCache.length >= _maxCachedImages) {
      _bytesCache.remove(_bytesCache.keys.first);
    }
    _bytesCache[url] = bytes;
  }

  /// Picks an image from the gallery and uploads it under [folderName].
  ///
  /// Returns the public HTTPS download URL, or `null` if the user cancels.
  /// Throws on upload failure.
  Future<String?> uploadImageFromGallery({
    required String folderName,
    String ownerId = '',
  }) {
    return _pickAndUpload(
      folderName: folderName,
      source: ImageSource.gallery,
      ownerId: ownerId,
    );
  }

  /// Picks up to [limit] gallery images and uploads each under [folderName].
  ///
  /// Returns successfully uploaded HTTPS URLs (may be fewer than selected).
  /// Empty list if the user cancels. Throws on a hard upload failure.
  Future<List<String>> uploadImagesFromGallery({
    required String folderName,
    required int limit,
    String ownerId = '',
  }) async {
    if (limit <= 0) {
      return const [];
    }
    final files = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1080,
      limit: limit,
    );
    if (files.isEmpty) {
      return const [];
    }
    final selected = files.take(limit).toList();
    final urls = <String>[];
    for (final file in selected) {
      final url = await uploadXFile(
        file: file,
        folderName: folderName,
        ownerId: ownerId,
      );
      if (url != null &&
          (url.startsWith('https://') || url.startsWith('http://'))) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// Picks an image from the camera and uploads it under [folderName].
  ///
  /// Returns the public HTTPS download URL, or `null` if the user cancels.
  Future<String?> uploadImageFromCamera({
    required String folderName,
    String ownerId = '',
  }) {
    return _pickAndUpload(
      folderName: folderName,
      source: ImageSource.camera,
      ownerId: ownerId,
    );
  }

  /// Uploads an already-picked [file] under [folderName].
  /// Returns `null` only for empty files; throws on Storage errors.
  /// Always returns an HTTPS download URL (never `gs://` / fullPath).
  Future<String?> uploadXFile({
    required XFile file,
    required String folderName,
    String ownerId = '',
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    return uploadBytes(
      bytes: Uint8List.fromList(bytes),
      folderName: folderName,
      fileName: file.name,
      mimeType: file.mimeType,
      ownerId: ownerId,
    );
  }

  /// Uploads raw [bytes] under [folderName] (auto-scoped to `{root}/{uid}/`).
  /// Always returns an HTTPS download URL (never `gs://` / fullPath).
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String folderName,
    String fileName = 'upload.jpg',
    String? mimeType,
    String ownerId = '',
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Prazna fotografija.');
    }
    try {
      return await _putBytes(
        bytes: bytes,
        folderName: ownerFolder(folderName, ownerId: ownerId),
        fileName: fileName,
        mimeType: mimeType,
      );
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'StorageService FirebaseException '
        'code=${error.code} message=${error.message} plugin=${error.plugin}',
      );
      debugPrint('$stack');
      throw StateError(_userMessageForFirebase(error));
    } catch (error, stack) {
      debugPrint('StorageService.uploadBytes failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  Future<String?> _pickAndUpload({
    required String folderName,
    required ImageSource source,
    String ownerId = '',
  }) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (file == null) {
      return null;
    }
    return uploadXFile(
      file: file,
      folderName: folderName,
      ownerId: ownerId,
    );
  }

  Future<String> _putBytes({
    required Uint8List bytes,
    required String folderName,
    required String fileName,
    String? mimeType,
  }) async {
    // [folderName] is already owner-scoped by [ownerFolder] / [uploadBytes].
    final folder = folderName.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    // Prefer real bytes / mime over a forced .jpg name (screenshots are often PNG).
    final contentType = _contentTypeFor(fileName, mimeType, bytes);
    final ext = _extensionForContentType(contentType);
    if (folder.isEmpty) {
      throw StateError('Storage putanja mora uključivati vlasnika (userId).');
    }
    final path = '$folder/$stamp$ext';

    final ref = _storage.ref(path);
    final metadata = SettableMetadata(
      contentType: contentType,
      cacheControl: 'public,max-age=31536000',
    );
    debugPrint(
      'StorageService uploading path=$path '
      'bytes=${bytes.length} contentType=$contentType '
      'bucket=${_storage.bucket}',
    );
    final snapshot = await ref.putData(bytes, metadata);
    if (snapshot.state != TaskState.success) {
      throw StateError('Storage upload nije uspeo (${snapshot.state}).');
    }

    // Always resolve the public HTTPS URL — never return fullPath / gs:// /
    // Reference.toString(), which Image.network cannot load.
    final downloadUrl = await snapshot.ref.getDownloadURL();
    final httpsUrl = _requireHttpsDownloadUrl(downloadUrl);
    debugPrint('StorageService uploaded path=$path url=$httpsUrl');
    return httpsUrl;
  }

  String _requireHttpsDownloadUrl(String raw) {
    final url = raw.trim();
    if (isGsUri(url) || url.contains('fullPath') || !isHttpsDownloadUrl(url)) {
      debugPrint('StorageService rejected non-HTTPS download URL: $url');
      throw StateError(
        'Storage nije vratio HTTPS download URL (dobijeno: $url).',
      );
    }
    return url;
  }

  Reference _refFromAny(String imageUrl) {
    final url = imageUrl.trim();
    // refFromURL accepts both https://firebasestorage... and gs://bucket/path.
    if (isGsUri(url) || isFirebaseStorageUrl(url)) {
      return _storage.refFromURL(url);
    }
    throw StateError('Nije Firebase Storage URL: $url');
  }

  /// Deletes a Storage object identified by HTTPS download URL or `gs://` URI.
  Future<void> deleteImageByUrl(String imageUrl) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return;
    }
    try {
      final ref = _refFromAny(url);
      await ref.delete();
    } catch (error, stack) {
      debugPrint('StorageService.deleteImageByUrl failed: $error');
      debugPrint('$stack');
      rethrow;
    }
  }

  /// Best-effort delete — ignores non-Storage URLs and delete failures.
  Future<void> tryDeleteImageByUrl(String? imageUrl) async {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty || !isFirebaseStorageUrl(url)) {
      return;
    }
    try {
      await deleteImageByUrl(url);
    } catch (_) {}
  }

  String _contentTypeFor(
    String fileName,
    String? mimeType,
    Uint8List bytes,
  ) {
    final sniffed = _sniffImageContentType(bytes);
    if (sniffed != null) {
      return sniffed;
    }
    final mime = mimeType?.trim().toLowerCase() ?? '';
    if (mime.startsWith('image/') && mime != 'image/*') {
      return mime;
    }
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  String? _sniffImageContentType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
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
      return 'image/webp';
    }
    return null;
  }

  String _extensionForContentType(String contentType) {
    switch (contentType) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      default:
        return '.jpg';
    }
  }

  String _userMessageForFirebase(FirebaseException error) {
    switch (error.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Firebase Storage odbio upload (rules). '
            'U Console → Storage → Rules objavi pravila iz storage.rules.';
      case 'object-not-found':
        return 'Storage bucket nije pronađen. Proveri da je Storage uključen u Firebase projektu.';
      case 'unauthenticated':
        return 'Moraš biti prijavljen da bi poslao sliku.';
      case 'canceled':
        return 'Upload je otkazan.';
      case 'retry-limit-exceeded':
      case 'unknown':
        return 'Upload nije uspeo (${error.code}). Proveri internet i Storage u Firebase Console.';
      default:
        return 'Upload nije uspeo (${error.code}): ${error.message ?? error.code}';
    }
  }
}
