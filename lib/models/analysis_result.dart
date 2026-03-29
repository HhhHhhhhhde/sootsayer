class AnalysisResult {
  final String id;        // == taskId.toString()
  final int taskId;
  final String appName;   // apkName from backend
  final String packageName;
  final String versionName;
  final String apkPath;
  final int fileSize;     // apkSize from backend (bytes)
  final DateTime submitTime; // createTime from backend
  final String status;   // backend: WAITING/SCANNING/AI_AUDITING/COMPLETED/FAILED/CANCELLED
  final int? progress;
  final String? currentStep;
  final DateTime? updateTime;
  final int? vulnerabilities;
  final String? riskLevel;

  AnalysisResult({
    required this.id,
    required this.taskId,
    required this.appName,
    this.packageName = '',
    this.versionName = '',
    this.apkPath = '',
    required this.fileSize,
    required this.submitTime,
    this.status = 'WAITING',
    this.progress,
    this.currentStep,
    this.updateTime,
    this.vulnerabilities,
    this.riskLevel,
  });

  /// Construct from backend GET /api/tasks list item.
  factory AnalysisResult.fromTaskJson(Map<String, dynamic> json) {
    final taskId = json['id'] as int? ?? 0;
    return AnalysisResult(
      id: taskId.toString(),
      taskId: taskId,
      appName: json['apkName']?.toString() ?? 'Unknown',
      fileSize: (json['apkSize'] as num?)?.toInt() ?? 0,
      submitTime: json['createTime'] != null
          ? DateTime.tryParse(json['createTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'WAITING',
      updateTime: json['updateTime'] != null
          ? DateTime.tryParse(json['updateTime'].toString())
          : null,
    );
  }

  /// Construct from backend GET /api/tasks/{id}/status response.
  AnalysisResult withStatusJson(Map<String, dynamic> json) {
    return copyWith(
      status: json['status']?.toString(),
      progress: (json['progress'] as num?)?.toInt(),
      currentStep: json['currentStep']?.toString(),
      updateTime: json['updateTime'] != null
          ? DateTime.tryParse(json['updateTime'].toString())
          : null,
    );
  }

  bool get isTerminal =>
      status == 'COMPLETED' ||
      status == 'FAILED' ||
      status == 'CANCELLED';

  AnalysisResult copyWith({
    String? status,
    int? progress,
    String? currentStep,
    DateTime? updateTime,
    int? vulnerabilities,
    String? riskLevel,
    int? taskId,
  }) {
    return AnalysisResult(
      id: id,
      taskId: taskId ?? this.taskId,
      appName: appName,
      packageName: packageName,
      versionName: versionName,
      apkPath: apkPath,
      fileSize: fileSize,
      submitTime: submitTime,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      updateTime: updateTime ?? this.updateTime,
      vulnerabilities: vulnerabilities ?? this.vulnerabilities,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }
}
