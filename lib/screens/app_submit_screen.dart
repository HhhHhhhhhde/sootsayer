import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/apk_service.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../models/analysis_result.dart';

class AppSubmitScreen extends StatefulWidget {
  final bool isBatch;

  const AppSubmitScreen({super.key, this.isBatch = false});

  @override
  State<AppSubmitScreen> createState() => _AppSubmitScreenState();
}

class _AppSubmitScreenState extends State<AppSubmitScreen> {
  List<Map<String, dynamic>> _installedApps = [];
  Set<String> _selectedPackages = {};
  bool _isLoading = true;
  bool _isExtracting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    setState(() => _isLoading = true);
    final apps = await ApkService.getInstalledApps();
    setState(() {
      _installedApps = apps;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;
    return _installedApps.where((app) {
      final appName = app['appName']?.toString().toLowerCase() ?? '';
      final packageName = app['packageName']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return appName.contains(query) || packageName.contains(query);
    }).toList();
  }

  Future<void> _extractSelectedApps() async {
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个应用')),
      );
      return;
    }

    setState(() => _isExtracting = true);

    final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
    int successCount = 0;
    int failCount = 0;

    for (final packageName in _selectedPackages) {
      try {
        // Step 1: Extract APK locally
        print('Extracting APK for package: $packageName');
        final extractResult = await ApkService.extractApk(packageName);
        
        if (extractResult != null && extractResult['success'] == true) {
          final apkPath = extractResult['outputPath'] ?? '';
          final appName = extractResult['appName'] ?? '';
          final versionName = extractResult['versionName'] ?? '';
          
          print('APK extracted successfully: $apkPath');
          
          // Step 2: Upload APK to backend
          print('Uploading APK to backend...');
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final token = authProvider.sessionToken ?? '';
          
          if (token.isEmpty) {
            print('Error: No authentication token available');
            failCount++;
            continue;
          }
          
          final uploadResult = await ApkService.uploadApkToBackend(
            apkPath,
            appName,
            packageName,
            versionName,
            token,
          );
          
          if (uploadResult != null && uploadResult['success'] == true) {
            final analysisResult = AnalysisResult(
              id: uploadResult['taskId'].toString(),
              appName: appName,
              packageName: packageName,
              versionName: versionName,
              apkPath: apkPath,
              fileSize: extractResult['size'] ?? 0,
              submitTime: DateTime.now(),
              status: 'pending',
              taskId: uploadResult['taskId'],
            );
            analysisProvider.addResult(analysisResult);
            print('APK uploaded successfully with taskId: ${uploadResult['taskId']}');
            successCount++;
          } else {
            print('Failed to upload APK for package: $packageName');
            failCount++;
          }
        } else {
          print('Failed to extract APK for package: $packageName');
          failCount++;
        }
      } catch (e) {
        print('Error processing package $packageName: $e');
        failCount++;
      }
    }

    setState(() => _isExtracting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上传完成: 成功 $successCount 个, 失败 $failCount 个'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBatch ? '批量提交应用' : '提交应用'),
        actions: [
          if (_selectedPackages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  label: Text('已选 ${_selectedPackages.length}'),
                  backgroundColor: Theme.of(context).primaryColor,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索应用名称或包名',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApps.isEmpty
                    ? const Center(child: Text('未找到应用'))
                    : ListView.builder(
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final packageName = app['packageName'] ?? '';
                          final isSelected = _selectedPackages.contains(packageName);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  (app['appName'] ?? 'A')[0].toUpperCase(),
                                ),
                              ),
                              title: Text(app['appName'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(packageName),
                                  if (app['versionName']?.isNotEmpty ?? false)
                                    Text(
                                      'v${app['versionName']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: widget.isBatch
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedPackages.add(packageName);
                                          } else {
                                            _selectedPackages.remove(packageName);
                                          }
                                        });
                                      },
                                    )
                                  : Radio<String>(
                                      value: packageName,
                                      groupValue: _selectedPackages.isEmpty
                                          ? null
                                          : _selectedPackages.first,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPackages.clear();
                                          if (value != null) {
                                            _selectedPackages.add(value);
                                          }
                                        });
                                      },
                                    ),
                              onTap: () {
                                setState(() {
                                  if (widget.isBatch) {
                                    if (isSelected) {
                                      _selectedPackages.remove(packageName);
                                    } else {
                                      _selectedPackages.add(packageName);
                                    }
                                  } else {
                                    _selectedPackages.clear();
                                    _selectedPackages.add(packageName);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isExtracting ? null : _extractSelectedApps,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isExtracting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    '提取应用 (${_selectedPackages.length})',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}
