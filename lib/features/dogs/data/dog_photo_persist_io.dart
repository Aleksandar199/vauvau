import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<List<String>> persistDogPhotos({
  required String dogId,
  required List<XFile> files,
}) async {
  if (files.isEmpty) {
    return const [];
  }
  try {
    return await _copyToDocuments(dogId, files).timeout(
      const Duration(seconds: 4),
      onTimeout: () => _fallbackPaths(files),
    );
  } catch (_) {
    return _fallbackPaths(files);
  }
}

List<String> _fallbackPaths(List<XFile> files) {
  return [
    for (final file in files)
      if (file.path.isNotEmpty) file.path,
  ];
}

Future<List<String>> _copyToDocuments(String dogId, List<XFile> files) async {
  final docs = await getApplicationDocumentsDirectory();
  final folder = Directory('${docs.path}/dog_photos/$dogId');
  await folder.create(recursive: true);
  final urls = <String>[];
  for (var i = 0; i < files.length; i++) {
    final sourcePath = files[i].path;
    final saved = File('${folder.path}/$i.jpg');
    if (sourcePath.isNotEmpty) {
      try {
        await File(sourcePath).copy(saved.path).timeout(
          const Duration(seconds: 2),
        );
        urls.add(saved.path);
        continue;
      } catch (_) {}
    }
    try {
      final bytes = await files[i].readAsBytes().timeout(
        const Duration(seconds: 2),
      );
      await saved.writeAsBytes(bytes, flush: true);
      urls.add(saved.path);
    } catch (_) {
      if (sourcePath.isNotEmpty) {
        urls.add(sourcePath);
      }
    }
  }
  return urls;
}
