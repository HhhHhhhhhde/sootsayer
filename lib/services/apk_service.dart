import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ApkService {
  static const String backendUrl = 'http://10.0.2.2:8080/api';

  /// Uploads an APK file at [apkPath] to the backend task endpoint.
  /// Returns a map with `success` and `taskId` on success, or `null` on failure.
  ///
  /// API: POST /api/tasks (multipart/form-data)
  /// Response: { "code": 200, "data": <taskId as int> }
  static Future<Map<String, dynamic>?> uploadApkToBackend(
    String apkPath,
    String appName,
    String packageName,
    String versionName,
    String token,
  ) async {
    try {
      if (apkPath.isEmpty) {
        debugPrint('APK path is empty');
        return null;
      }

      final fileToUpload = File(apkPath);
      if (!fileToUpload.existsSync()) {
        debugPrint('APK file not found: $apkPath');
        return null;
      }

      final fileSize = fileToUpload.lengthSync();
      if (fileSize == 0) {
        debugPrint('APK file is empty: $apkPath');
        return null;
      }

      // Streaming SHA-256 — safe for large APKs (avoids OOM).
      final apkHash = await _computeSha256Stream(fileToUpload);

      // Copy to cache so the file remains accessible during the upload.
      final persistedPath = await _persistFileToCache(apkPath);
      debugPrint('Uploading APK: $persistedPath ($fileSize bytes)');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/tasks'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['apkName'] =
          appName.isNotEmpty ? appName : path.basename(apkPath);
      request.fields['apkSize'] = fileSize.toString();
      request.fields['apkHash'] = apkHash;
      request.files.add(
        await http.MultipartFile.fromPath('file', persistedPath),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResp = _parseJson(responseBody);
        final code = jsonResp['code'];
        final isSuccess = code == 200 || code == 0;
        if (isSuccess && jsonResp['data'] != null) {
          final taskId = jsonResp['data'];
          return {
            'success': true,
            'taskId': taskId,
            'appName': appName,
            'packageName': packageName,
            'versionName': versionName,
          };
        }
      }

      debugPrint('Upload failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Failed to upload APK: $e');
      return null;
    }
  }

  /// Uploads multiple APK files in one multipart request.
  /// Response data is expected to be a taskId list in the same order.
  static Future<List<Map<String, dynamic>>?> uploadApksToBackend(
    List<Map<String, String>> files,
    String token,
  ) async {
    try {
      if (files.isEmpty) {
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/tasks/batch'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      for (final fileInfo in files) {
        final apkPath = fileInfo['path'] ?? '';
        final appName = fileInfo['name'] ?? '';
        if (apkPath.isEmpty) {
          return null;
        }

        final file = File(apkPath);
        if (!file.existsSync()) {
          debugPrint('APK file not found: $apkPath');
          return null;
        }

        final fileSize = file.lengthSync();
        if (fileSize == 0) {
          debugPrint('APK file is empty: $apkPath');
          return null;
        }

        final apkHash = await _computeSha256Stream(file);
        final persistedPath = await _persistFileToCache(apkPath);

        request.fields['apkName'] =
            appName.isNotEmpty ? appName : path.basename(apkPath);
        request.fields['apkSize'] = fileSize.toString();
        request.fields['apkHash'] = apkHash;
        request.files.add(
          await http.MultipartFile.fromPath('files', persistedPath),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Batch upload response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> jsonResp = _parseJson(responseBody);
      final code = jsonResp['code'];
      final isSuccess = code == 200 || code == 0;
      final data = jsonResp['data'];
      if (!isSuccess || data is! List) {
        return null;
      }

      final taskIds = data;
      if (taskIds.length != files.length) {
        debugPrint('Batch upload task count mismatch');
        return null;
      }

      final results = <Map<String, dynamic>>[];
      for (var i = 0; i < files.length; i++) {
        results.add({
          'success': true,
          'taskId': taskIds[i],
          'appName': files[i]['name'] ?? '',
          'apkPath': files[i]['path'] ?? '',
        });
      }
      return results;
    } catch (e) {
      debugPrint('Failed to batch upload APKs: $e');
      return null;
    }
  }

  /// Computes SHA-256 of [file] using BytesBuilder streaming.
  /// BytesBuilder(copy:false) holds chunk references without copying until
  /// toBytes() is called, keeping per-chunk memory usage low.
  static Future<String> _computeSha256Stream(File file) async {
    final digest = await file.openRead().transform(sha256).first;
    return digest.toString();
  }

  static Future<String> _persistFileToCache(String sourceFilePath) async {
    try {
      final sourceFile = File(sourceFilePath);
      final cacheDir = await getApplicationCacheDirectory();
      final persistDir = Directory('${cacheDir.path}/apk_cache');
      if (!persistDir.existsSync()) {
        persistDir.createSync(recursive: true);
      }
      final fileName = path.basename(sourceFilePath);
      final dest = '${persistDir.path}/$fileName';
      await sourceFile.copy(dest);
      return dest;
    } catch (e) {
      debugPrint('Error persisting file to cache: $e');
      return sourceFilePath;
    }
  }

  static Map<String, dynamic> _parseJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      final codeMatch =
          RegExp(r'"code"\s*:\s*(\d+)').firstMatch(jsonString);
      final dataMatch =
          RegExp(r'"data"\s*:\s*(\d+)').firstMatch(jsonString);
      if (codeMatch != null) {
        return {
          'code': int.parse(codeMatch.group(1)!),
          'data': dataMatch != null ? int.parse(dataMatch.group(1)!) : null,
        };
      }
      return {'code': 500};
    }
  }
}
