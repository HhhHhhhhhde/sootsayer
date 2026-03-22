import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';

class SemanticIssue {
  final String id;
  final String title;
  final String description;
  final String reason;
  final String riskLevel;
  final String? businessLogic;
  final String? codeLocation;
  bool isExpanded;

  SemanticIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.reason,
    required this.riskLevel,
    this.businessLogic,
    this.codeLocation,
    this.isExpanded = false,
  });
}

class AnalysisDetailScreen extends StatefulWidget {
  final String resultId;

  const AnalysisDetailScreen({super.key, required this.resultId});

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  late List<SemanticIssue> semanticIssues;

  @override
  void initState() {
    super.initState();
    _initializeSemanticIssues();
  }

  void _initializeSemanticIssues() {
    semanticIssues = [
      SemanticIssue(
        id: '1',
        title: '数据泄露风险',
        description: '应用可能会将用户敏感信息（如位置、联系方式）上传到不安全的服务器。',
        reason: '检测到应用使用了不加密的HTTP连接传输用户数据，且目标服务器证书验证不完整。',
        riskLevel: 'high',
        businessLogic: '应用声称不收集用户位置信息，但代码中存在位置权限申请和数据上传逻辑。',
        codeLocation: 'com.example.app.LocationService.java:45-67',
      ),
      SemanticIssue(
        id: '2',
        title: '权限滥用',
        description: '应用申请了过多权限，可能用于追踪用户行为或窃取隐私信息。',
        reason: '应用申请了CAMERA、RECORD_AUDIO、READ_CONTACTS等权限，但在功能中并未明确使用。',
        riskLevel: 'medium',
        businessLogic: '应用是一个天气应用，不应该需要摄像头和麦克风权限。',
        codeLocation: 'AndroidManifest.xml:12-28',
      ),
      SemanticIssue(
        id: '3',
        title: '代码混淆不足',
        description: '应用的关键代码未进行充分混淆，容易被逆向工程分析。',
        reason: '检测到应用中存在明文的API密钥、加密算法实现和业务逻辑代码。',
        riskLevel: 'medium',
        codeLocation: 'com.example.app.ApiClient.java:23',
      ),
      SemanticIssue(
        id: '4',
        title: '不安全的存储',
        description: '应用将敏感数据（如密码、令牌）以明文形式存储在本地。',
        reason: '检测到SharedPreferences中存储了未加密的用户认证令牌和密码。',
        riskLevel: 'high',
        businessLogic: '应用应该使用Android Keystore或加密存储敏感信息。',
        codeLocation: 'com.example.app.PreferenceManager.java:34-56',
      ),
      SemanticIssue(
        id: '5',
        title: '动态代码执行',
        description: '应用可能在运行时动态加载和执行代码，增加安全风险。',
        reason: '检测到使用了反射、ClassLoader.loadClass()和DexClassLoader等动态加载机制。',
        riskLevel: 'high',
        codeLocation: 'com.example.app.PluginManager.java:78-92',
      ),
    ];
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getRiskLevelColor(String level) {
    switch (level) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _getRiskLevelText(String level) {
    switch (level) {
      case 'high':
        return '高危';
      case 'medium':
        return '中危';
      default:
        return '低危';
    }
  }

  double _calculateOverallRiskScore() {
    int highCount = semanticIssues.where((i) => i.riskLevel == 'high').length;
    int mediumCount = semanticIssues.where((i) => i.riskLevel == 'medium').length;
    return (highCount * 30 + mediumCount * 15) / semanticIssues.length;
  }

  String _getOverallRiskLevel() {
    double score = _calculateOverallRiskScore();
    if (score >= 25) return 'high';
    if (score >= 15) return 'medium';
    return 'low';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final result = provider.getResultById(widget.resultId);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('分析详情')),
        body: const Center(child: Text('未找到分析结果')),
      );
    }

    final overallScore = _calculateOverallRiskScore();
    final overallLevel = _getOverallRiskLevel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI语义分析报告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享功能开发中')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 任务基本信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          result.appName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.appName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              result.packageName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow('APK名称', result.appName),
                  const SizedBox(height: 12),
                  _buildInfoRow('包名', result.packageName),
                  const SizedBox(height: 12),
                  _buildInfoRow('版本', result.versionName),
                  const SizedBox(height: 12),
                  _buildInfoRow('文件大小', _formatFileSize(result.fileSize)),
                  const SizedBox(height: 12),
                  _buildInfoRow('检测时间', _formatDate(result.submitTime)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 总体风险评分
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '总体风险评分',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getRiskLevelColor(overallLevel).withOpacity(0.1),
                              border: Border.all(
                                color: _getRiskLevelColor(overallLevel),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    overallScore.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: _getRiskLevelColor(overallLevel),
                                    ),
                                  ),
                                  Text(
                                    '分',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRiskLevelColor(overallLevel).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _getRiskLevelText(overallLevel),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getRiskLevelColor(overallLevel),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRiskStatItem(
                            '高危问题',
                            semanticIssues.where((i) => i.riskLevel == 'high').length.toString(),
                            Colors.red,
                          ),
                          const SizedBox(height: 16),
                          _buildRiskStatItem(
                            '中危问题',
                            semanticIssues.where((i) => i.riskLevel == 'medium').length.toString(),
                            Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          _buildRiskStatItem(
                            '低危问题',
                            semanticIssues.where((i) => i.riskLevel == 'low').length.toString(),
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 语义分析条目
          const Text(
            '风险分析详情',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...semanticIssues.map((issue) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSemanticIssueCard(issue),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskStatItem(String label, String count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSemanticIssueCard(SemanticIssue issue) {
    return Card(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                issue.isExpanded = !issue.isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRiskLevelColor(issue.riskLevel).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getRiskLevelText(issue.riskLevel),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getRiskLevelColor(issue.riskLevel),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          issue.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        issue.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    issue.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (issue.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('违规原因', issue.reason),
                  const SizedBox(height: 16),
                  if (issue.businessLogic != null) ...[
                    _buildDetailSection('业务逻辑矛盾', issue.businessLogic!),
                    const SizedBox(height: 16),
                  ],
                  if (issue.codeLocation != null) ...[
                    _buildDetailSection('代码位置', issue.codeLocation!),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('查看代码: ${issue.codeLocation}'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.code,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '查看技术证据',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
