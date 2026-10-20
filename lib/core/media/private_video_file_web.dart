import 'package:firebase_storage/firebase_storage.dart';

/// Web has no file system: the player streams a URL instead.
Future<String> downloadPrivateVideoToFile(Reference ref) =>
    throw UnsupportedError('Web koristi URL za video.');

Future<void> forgetPrivateVideoFile(String fullPath) async {}
