import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads a private Storage object (rules are checked) into the app's
/// temp folder and returns the local path. Reused while the file exists, so
/// replaying a story does not download it again; the OS may clear the temp
/// folder at any time.
Future<String> downloadPrivateVideoToFile(Reference ref) async {
  final dir = await getTemporaryDirectory();
  final name = ref.fullPath.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final file = File('${dir.path}/vv_video_$name');
  if (await file.exists() && await file.length() > 0) {
    return file.path;
  }
  final partial = File('${file.path}.part');
  final task = await ref.writeToFile(partial);
  if (task.state != TaskState.success) {
    throw StateError('Video nije preuzet (${task.state}).');
  }
  await partial.rename(file.path);
  return file.path;
}

/// Removes the local copy (story deleted / access lost).
Future<void> forgetPrivateVideoFile(String fullPath) async {
  try {
    final dir = await getTemporaryDirectory();
    final name = fullPath.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${dir.path}/vv_video_$name');
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}
