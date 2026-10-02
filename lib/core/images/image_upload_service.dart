import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../network/network_failure.dart';

class ImageUploadService {
  const ImageUploadService();

  static const String _imgbbEndpoint =
      'https://api.imgbb.com/1/upload?key=b33032470eb6bd51cea176b8a10309dd';

  static Future<String> upload(Uint8List bytes) {
    return const ImageUploadService().uploadImage(bytes);
  }

  Future<String> uploadImage(Uint8List bytes) async {
    debugPrint('[IMAGE UPLOAD] Starting upload');
    debugPrint('[IMAGE UPLOAD] Bytes: ${bytes.length}');
    if (bytes.isEmpty) {
      throw StateError('Prazna fotografija.');
    }
    try {
      return await _uploadImgbb(bytes);
    } on NetworkFailure {
      rethrow;
    } catch (error) {
      debugPrint('[IMAGE UPLOAD] ImgBB FAILED');
      debugPrint('[IMAGE UPLOAD] Error type: ${error.runtimeType}');
      debugPrint('[IMAGE UPLOAD] Error message: ${_redact('$error')}');
      if (isNetworkFailure(error)) {
        throw const NetworkFailure();
      }
      throw StateError('Upload nije uspeo: ${_redact('$error')}');
    }
  }

  Future<String> uploadXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    return uploadImage(bytes);
  }

  Future<List<String>> uploadAll(List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadXFile(file));
    }
    return urls;
  }

  Future<String> _uploadImgbb(Uint8List bytes) async {
    final uri = Uri.parse(_imgbbEndpoint);
    debugPrint('[IMAGE UPLOAD] Trying ImgBB');
    debugPrint('[IMAGE UPLOAD] ImgBB method: POST');
    debugPrint('[IMAGE UPLOAD] ImgBB endpoint: ${_safeUri(uri)}');
    debugPrint(
      '[IMAGE UPLOAD] ImgBB body: application/x-www-form-urlencoded image=<base64>',
    );
    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            body: {'image': base64Encode(bytes)},
          )
          .timeout(const Duration(seconds: 45));
    } catch (error) {
      if (isNetworkFailure(error)) {
        throw const NetworkFailure();
      }
      rethrow;
    }
    debugPrint('[IMAGE UPLOAD] ImgBB HTTP status: ${response.statusCode}');
    debugPrint('[IMAGE UPLOAD] ImgBB response: ${_summarizeBody(response.body)}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'ImgBB HTTP ${response.statusCode}: ${_summarizeBody(response.body)}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw StateError('ImgBB nije vratio JSON objekat.');
    }
    final data = decoded['data'];
    if (data is! Map) {
      debugPrint('[IMAGE UPLOAD] ImgBB parsed URL: null');
      throw StateError('ImgBB nije vratio podatke.');
    }
    final url = _httpsUrl(data['url']) ??
        _httpsUrl(data['display_url']) ??
        _httpsUrl(data['image'] is Map ? data['image']['url'] : null);
    debugPrint('[IMAGE UPLOAD] ImgBB parsed URL: ${url ?? 'null'}');
    if (url == null) {
      throw StateError('ImgBB nije vratio javni URL.');
    }
    return url;
  }

  String? _httpsUrl(Object? value) {
    final url = value?.toString().trim() ?? '';
    if (url.startsWith('https://') || url.startsWith('http://')) {
      return url;
    }
    return null;
  }

  String _safeUri(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters);
    if (params.containsKey('key')) {
      params['key'] = 'REDACTED';
    }
    return uri.replace(queryParameters: params).toString();
  }

  String _redact(String value) {
    return value.replaceAll(RegExp(r'key=[^&\s"]+'), 'key=REDACTED');
  }

  String _summarizeBody(String body) {
    final redacted = _redact(body);
    if (redacted.length <= 500) {
      return redacted;
    }
    return '${redacted.substring(0, 500)}…';
  }
}
