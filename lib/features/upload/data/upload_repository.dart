import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/logging/log.dart';

/// Uploads session files to the configured server.
class UploadRepository {
  final Dio _dio;

  UploadRepository(this._dio);

  /// Upload session directory to the server.
  /// Returns true on success.
  Future<bool> uploadSession({
    required String sessionId,
    required String dirPath,
    required String baseUrl,
  }) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        log.e('Upload: directory not found: $dirPath');
        return false;
      }

      final files = await dir.list().toList();
      final formData = FormData();

      formData.fields.add(MapEntry('session_id', sessionId));

      for (final entity in files) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(entity.path, filename: fileName),
          ));
        }
      }

      final response = await _dio.post(
        '$baseUrl/api/sessions/upload',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log.i('Upload success: $sessionId');
        return true;
      } else {
        log.e('Upload failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log.e('Upload error', error: e);
      rethrow;
    }
  }
}
