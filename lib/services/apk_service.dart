import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ApkService {
  static const platform = MethodChannel('com.example.myapp/apk');
  static const String backendUrl = 'http://10.0.2.2:8080/api';

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getInstalledApps');
      return result.map((app) => Map<String, dynamic>.from(app)).toList();
    } on PlatformException catch (e) {
      print("Failed to get installed apps: '${e.message}'.");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> extractApk(String packageName) async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'extractApk',
        {'packageName': packageName},
      );
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print("Failed to extract APK: '${e.message}'.");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadApkToBackend(
    String apkPathOrDir,
    String appName,
    String packageName,
    String versionName,
    String token,
  ) async {
    try {
      // Validate input
      if (apkPathOrDir.isEmpty) {
        print("APK path is empty");
        return null;
      }

      // Check if it's a directory or file
      final pathEntity = FileSystemEntity.typeSync(apkPathOrDir);
      File fileToUpload;

      if (pathEntity == FileSystemEntityType.directory) {
        // If it's a directory with split APKs, compress it to zip
        print("APK path is a directory, compressing to zip");
        final dir = Directory(apkPathOrDir);
        
        // Verify directory has files
        final files = dir.listSync();
        if (files.isEmpty) {
          print("Directory is empty: $apkPathOrDir");
          return null;
        }

        print("Files in directory: ${files.map((f) => f.path).toList()}");

        // Create zip file
        final zipPath = '${dir.path}.zip';
        fileToUpload = await _compressDirectoryToZip(apkPathOrDir, zipPath);
        
        if (!fileToUpload.existsSync()) {
          print("Failed to create zip file: $zipPath");
          return null;
        }
      } else {
        // It's a file
        fileToUpload = File(apkPathOrDir);
        if (!fileToUpload.existsSync()) {
          print("APK file not found: $apkPathOrDir");
          return null;
        }
      }

      final fileSize = fileToUpload.lengthSync();
      if (fileSize == 0) {
        print("File is empty: ${fileToUpload.path}");
        return null;
      }

      // Persist file to cache directory before uploading
      final persistedFilePath = await _persistFileToCache(fileToUpload.path);
      print("Uploading file: $persistedFilePath (${fileSize} bytes)");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/tasks'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', persistedFilePath),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("Upload response status: ${response.statusCode}");
      print("Upload response body: $responseBody");

      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> jsonResponse = _parseJson(responseBody);
        if (jsonResponse['code'] == 200 && jsonResponse['data'] != null) {
          return {
            'success': true,
            'taskId': jsonResponse['data']['taskId'],
            'appName': appName,
            'packageName': packageName,
            'versionName': versionName,
            'fileName': jsonResponse['data']['fileName'],
            'status': jsonResponse['data']['status'],
            'createTime': jsonResponse['data']['createTime'],
          };
        }
      }
      print("Upload failed with status: ${response.statusCode}");
      return null;
    } catch (e) {
      print("Failed to upload APK: $e");
      return null;
    }
  }

  static Future<String> _persistFileToCache(String sourceFilePath) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!sourceFile.existsSync()) {
        print("Source file not found: $sourceFilePath");
        return sourceFilePath;
      }

      final cacheDir = await getApplicationCacheDirectory();
      final persistDir = Directory('${cacheDir.path}/apk_cache');
      
      if (!persistDir.existsSync()) {
        persistDir.createSync(recursive: true);
      }

      final fileName = path.basename(sourceFilePath);
      final persistedFilePath = '${persistDir.path}/$fileName';
      
      print("Persisting file from $sourceFilePath to $persistedFilePath");
      await sourceFile.copy(persistedFilePath);
      
      return persistedFilePath;
    } catch (e) {
      print("Error persisting file: $e");
      return sourceFilePath;
    }
  }

  static Future<File> _compressDirectoryToZip(String dirPath, String zipPath) async {
    final dir = Directory(dirPath);
    final encoder = ZipFileEncoder();
    
    encoder.create(zipPath);
    
    // Add all files from directory to zip
    final files = dir.listSync(recursive: true);
    for (var file in files) {
      if (file is File) {
        final relativePath = path.relative(file.path, from: dir.path);
        encoder.addFile(file, relativePath);
      }
    }
    
    encoder.close();
    print("Zip file created: $zipPath");
    
    return File(zipPath);
  }

  static Map<String, dynamic> _parseJson(String jsonString) {
    try {
      // Simple JSON parsing without external dependency
      if (jsonString.contains('"code":200')) {
        final taskIdMatch = RegExp(r'"taskId":(\d+)').firstMatch(jsonString);
        final fileNameMatch = RegExp(r'"fileName":"([^"]+)"').firstMatch(jsonString);
        final statusMatch = RegExp(r'"status":"([^"]+)"').firstMatch(jsonString);
        
        return {
          'code': 200,
          'data': {
            'taskId': taskIdMatch != null ? int.parse(taskIdMatch.group(1)!) : 0,
            'fileName': fileNameMatch?.group(1) ?? '',
            'status': statusMatch?.group(1) ?? 'PENDING',
            'createTime': DateTime.now().toIso8601String(),
          }
        };
      }
      return {'code': 500};
    } catch (e) {
      print("JSON parsing error: $e");
      return {'code': 500};
    }
  }
}
