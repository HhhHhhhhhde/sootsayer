import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../models/analysis_result.dart';
import '../services/apk_service.dart';

class AppSubmitScreen extends StatefulWidget {
  final bool isBatch;

  const AppSubmitScreen({super.key, this.isBatch = false});

  @override
  State<AppSubmitScreen> createState() => _AppSubmitScreenState();
}

class _AppSubmitScreenState extends State<AppSubmitScreen> {
  List<Map<String, String>> _selectedFiles = [];
  bool _isUploading = false;

  Future<void> _pickApkFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
      allowMultiple: widget.isBatch,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _selectedFiles = result.files
          .where((f) => f.path != null)
          .map((f) {
            final raw = f.name;
            final name =
                raw.endsWith('.apk') ? raw.substring(0, raw.length - 4) : raw;
            return {'name': name, 'path': f.path!};
          })
          .toList();
    });
  }

  void _removeFile(int index) =>
      setState(() => _selectedFiles.removeAt(index));

  Future<String?> _showRenameDialog(String defaultName) async {
    final controller = TextEditingController(text: defaultName);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('修改 APK 名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'APK 名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              Navigator.pop(ctx, name.isNotEmpty ? name : defaultName);
            },
            child: const Text('确认上传'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadSelected() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择 APK 文件')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.sessionToken ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('未登录，请重新登录'), backgroundColor: Colors.red),
      );
      return;
    }

    // Single-file mode: show rename dialog before uploading.
    List<Map<String, String>> filesToUpload = List.from(_selectedFiles);
    if (!widget.isBatch && filesToUpload.length == 1) {
      final chosen = await _showRenameDialog(filesToUpload[0]['name']!);
      if (chosen == null) return;
      filesToUpload[0] = {'name': chosen, 'path': filesToUpload[0]['path']!};
    }

    setState(() => _isUploading = true);

    final analysisProvider =
        Provider.of<AnalysisProvider>(context, listen: false);
    int successCount = 0;
    int failCount = 0;

    for (final fileInfo in filesToUpload) {
      final apkPath = fileInfo['path']!;
      final appName = fileInfo['name']!;
      try {
        final uploadResult = await ApkService.uploadApkToBackend(
          apkPath,
          appName,
          '',
          '',
          token,
        );
        if (uploadResult != null && uploadResult['success'] == true) {
          final fileSize = File(apkPath).lengthSync();
          analysisProvider.addResult(AnalysisResult(
            id: uploadResult['taskId'].toString(),
            taskId: uploadResult['taskId'] as int,
            appName: appName,
            apkPath: apkPath,
            fileSize: fileSize,
            submitTime: DateTime.now(),
            status: 'WAITING',
          ));
          successCount++;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }
    }

    setState(() => _isUploading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上传完成：成功 $successCount 个，失败 $failCount 个'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBatch ? '批量提交 APK' : '提交 APK'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickApkFiles,
              icon: const Icon(Icons.folder_open),
              label: Text(widget.isBatch
                  ? '从存储中选择 APK 文件（可多选）'
                  : '从存储中选择 APK 文件'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFiles.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.android, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        '暂未选择任何 APK 文件',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已选 ${_selectedFiles.length} 个文件',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _selectedFiles.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          final sizeBytes =
                              File(file['path']!).lengthSync();
                          final sizeMb =
                              (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.android,
                                  color: Colors.green),
                              title: Text(file['name']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text('$sizeMb MB',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: _isUploading
                                    ? null
                                    : () => _removeFile(index),
                                tooltip: '移除',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isUploading ? null : _uploadSelected,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _selectedFiles.isEmpty
                        ? '上传'
                        : '上传 ${_selectedFiles.length} 个文件',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}
