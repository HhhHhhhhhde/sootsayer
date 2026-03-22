class AnalysisResult {
  final String id;
  final String appName;
  final String packageName;
  final String versionName;
  final String apkPath;
  final int fileSize;
  final DateTime submitTime;
  final String status; // 'pending', 'analyzing', 'completed', 'failed'
  final int? vulnerabilities;
  final String? riskLevel; // 'low', 'medium', 'high', 'critical'
  final int? taskId; // Backend task ID

  AnalysisResult({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.apkPath,
    required this.fileSize,
    required this.submitTime,
    this.status = 'pending',
    this.vulnerabilities,
    this.riskLevel,
    this.taskId,
  });

  AnalysisResult copyWith({
    String? status,
    int? vulnerabilities,
    String? riskLevel,
    int? taskId,
  }) {
    return AnalysisResult(
      id: id,
      appName: appName,
      packageName: packageName,
      versionName: versionName,
      apkPath: apkPath,
      fileSize: fileSize,
      submitTime: submitTime,
      status: status ?? this.status,
      vulnerabilities: vulnerabilities ?? this.vulnerabilities,
      riskLevel: riskLevel ?? this.riskLevel,
      taskId: taskId ?? this.taskId,
    );
  }
}
