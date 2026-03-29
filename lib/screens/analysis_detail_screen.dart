import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';

class _RiskItem {
  final int leakId;
  final bool isTrueLeak;
  final String riskLevel;
  final int riskScore;
  final String analysis;
  final String dataFlowExplanation;
  final String legalImplications;
  final String remediation;
  final List<String> complianceReferences;
  bool isExpanded;

  _RiskItem({
    required this.leakId,
    required this.isTrueLeak,
    required this.riskLevel,
    required this.riskScore,
    required this.analysis,
    required this.dataFlowExplanation,
    required this.legalImplications,
    required this.remediation,
    required this.complianceReferences,
    this.isExpanded = false,
  });

  factory _RiskItem.fromJson(Map<String, dynamic> j) => _RiskItem(
        leakId: (j['leakId'] as num?)?.toInt() ?? 0,
        isTrueLeak: j['isTrueLeak'] as bool? ?? false,
        riskLevel: j['riskLevel']?.toString() ?? 'LOW',
        riskScore: (j['riskScore'] as num?)?.toInt() ?? 0,
        analysis: j['analysis']?.toString() ?? '',
        dataFlowExplanation: j['dataFlowExplanation']?.toString() ?? '',
        legalImplications: j['legalImplications']?.toString() ?? '',
        remediation: j['remediation']?.toString() ?? '',
        complianceReferences:
            (j['complianceReferences'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
      );
}

class AnalysisDetailScreen extends StatefulWidget {
  final String resultId;
  const AnalysisDetailScreen({super.key, required this.resultId});

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  bool _reportLoading = false;
  bool _actionLoading = false;
  String? _riskLevel;
  int? _overallScore;
  String? _summary;
  List<_RiskItem> _riskItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  AnalysisResult? _getResult() =>
      Provider.of<AnalysisProvider>(context, listen: false)
          .getResultById(widget.resultId);

  Future<void> _loadReport() async {
    final result = _getResult();
    if (result == null || result.status != 'COMPLETED') return;
    final token =
        Provider.of<AuthProvider>(context, listen: false).sessionToken ?? '';
    if (token.isEmpty) return;
    setState(() => _reportLoading = true);
    try {
      final resp = await ApiService.getSemanticReport(token, result.taskId);
      final code = resp['code'];
      if ((code == 200 || code == 0) && resp['data'] != null) {
        final data = resp['data'] as Map<String, dynamic>;
        final items = (data['riskItems'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(_RiskItem.fromJson)
            .toList();
        if (mounted) {
          setState(() {
            _riskLevel = data['riskLevel']?.toString();
            _overallScore = (data['overallScore'] as num?)?.toInt();
            _summary = data['summary']?.toString();
            _riskItems = items;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load report: $e');
    } finally {
      if (mounted) setState(() => _reportLoading = false);
    }
  }

  Future<void> _cancelTask(AnalysisResult result) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).sessionToken ?? '';
    setState(() => _actionLoading = true);
    try {
      final resp = await ApiService.cancelTask(token, result.taskId);
      final code = resp['code'];
      if (code == 200 || code == 0) {
        Provider.of<AnalysisProvider>(context, listen: false)
            .cancelTask(result.id);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('任务已取消')));
          Navigator.pop(context);
        }
      } else {
        _showError(
            resp['message']?.toString() ?? resp['msg']?.toString() ?? '取消失败');
      }
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _retryTask(AnalysisResult result) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).sessionToken ?? '';
    setState(() => _actionLoading = true);
    try {
      final resp = await ApiService.retryTask(token, result.taskId);
      final code = resp['code'];
      if (code == 200 || code == 0) {
        setState(() {
          _riskLevel = null;
          _overallScore = null;
          _summary = null;
          _riskItems = [];
        });
        Provider.of<AnalysisProvider>(context, listen: false)
            .updateResultStatus(result.id, 'WAITING');
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('任务已重新提交')));
        }
      } else {
        _showError(
            resp['message']?.toString() ?? resp['msg']?.toString() ?? '重试失败');
      }
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  Color _riskColor(String l) {
    switch (l.toUpperCase()) {
      case 'HIGH': return Colors.red;
      case 'MEDIUM': return Colors.orange;
      default: return Colors.green;
    }
  }

  String _riskText(String l) {
    switch (l.toUpperCase()) {
      case 'HIGH': return '高危';
      case 'MEDIUM': return '中危';
      default: return '低危';
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'COMPLETED': return Colors.green;
      case 'SCANNING':
      case 'AI_AUDITING': return Colors.blue;
      case 'FAILED': return Colors.red;
      case 'CANCELLED': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _statusText(String s) {
    switch (s.toUpperCase()) {
      case 'WAITING': return '等待中';
      case 'SCANNING': return '扫描中';
      case 'AI_AUDITING': return 'AI 审核中';
      case 'COMPLETED': return '已完成';
      case 'FAILED': return '失败';
      case 'CANCELLED': return '已取消';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        final result = provider.getResultById(widget.resultId);
        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('分析详情')),
            body: const Center(child: Text('未找到分析结果')),
          );
        }
        final isCompleted = result.status == 'COMPLETED';
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI 语义分析报告'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
                onPressed: _reportLoading ? null : _loadReport,
              ),
            ],
          ),
          body: _reportLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _buildInfoCard(result),
                    const SizedBox(height: 16),
                    if (isCompleted && _overallScore != null) ...[
                      _buildScoreCard(),
                      const SizedBox(height: 16),
                    ],
                    if (isCompleted && _summary != null) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                    ],
                    if (isCompleted && _riskItems.isNotEmpty)
                      _buildRiskItemsSection()
                    else if (!isCompleted)
                      _buildStatusPlaceholder(result),
                  ],
                ),
          bottomNavigationBar: _buildBottomBar(result, isCompleted),
        );
      },
    );
  }
  Widget _buildInfoCard(AnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    result.appName.isNotEmpty
                        ? result.appName[0].toUpperCase()
                        : "?",
                    style: TextStyle(
                        fontSize: 22,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.appName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(result.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_statusText(result.status),
                            style: TextStyle(
                                fontSize: 11,
                                color: _statusColor(result.status),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _infoRow("APK 名称", result.appName),
            const SizedBox(height: 10),
            _infoRow("文件大小", _formatSize(result.fileSize)),
            const SizedBox(height: 10),
            _infoRow("提交时间", _formatDate(result.submitTime)),
            if (result.updateTime != null) ...[
              const SizedBox(height: 10),
              _infoRow("更新时间", _formatDate(result.updateTime!)),
            ],
            if (result.progress != null && !result.isTerminal) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: result.progress! / 100,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 6),
              Text("${result.currentStep ?? "处理中"} · ${result.progress}%",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    final level = _riskLevel ?? "LOW";
    final score = _overallScore ?? 0;
    final color = _riskColor(level);
    final high = _riskItems.where((i) => i.riskLevel.toUpperCase() == "HIGH").length;
    final med = _riskItems.where((i) => i.riskLevel.toUpperCase() == "MEDIUM").length;
    final low = _riskItems.where((i) => i.riskLevel.toUpperCase() == "LOW").length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("总体风险评分",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.1),
                        border: Border.all(color: color, width: 3),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("$score",
                                style: TextStyle(fontSize: 32,
                                    fontWeight: FontWeight.bold, color: color)),
                            Text("分",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_riskText(level),
                          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statRow("高危", high, Colors.red),
                    const SizedBox(height: 14),
                    _statRow("中危", med, Colors.orange),
                    const SizedBox(height: 14),
                    _statRow("低危", low, Colors.green),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Text("$count",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("分析摘要",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_summary ?? "",
                style: const TextStyle(fontSize: 13, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPlaceholder(AnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.hourglass_top, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text("任务${_statusText(result.status)}，报告生成后将自动显示",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("风险分析详情",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._riskItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRiskItemCard(item),
            )),
      ],
    );
  }

  Widget _buildRiskItemCard(_RiskItem item) {
    final color = _riskColor(item.riskLevel);
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => item.isExpanded = !item.isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(_riskText(item.riskLevel),
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.bold, color: color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text("泄露点 #${item.leakId}",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  Text("${item.riskScore}分",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 8),
                  Icon(item.isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
          if (item.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailSection("分析说明", item.analysis),
                  const SizedBox(height: 12),
                  _detailSection("数据流", item.dataFlowExplanation),
                  const SizedBox(height: 12),
                  _detailSection("法律影响", item.legalImplications),
                  const SizedBox(height: 12),
                  _detailSection("修复建议", item.remediation),
                  if (item.complianceReferences.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("合规依据",
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: item.complianceReferences
                          .map((r) => Chip(
                                label: Text(r,
                                    style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
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

  Widget _detailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(content,
              style: const TextStyle(fontSize: 12, height: 1.6)),
        ),
      ],
    );
  }

  Widget _buildBottomBar(AnalysisResult result, bool isCompleted) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _actionLoading
            ? const Center(child: CircularProgressIndicator())
            : isCompleted
                ? ElevatedButton.icon(
                    onPressed: () => _retryTask(result),
                    icon: const Icon(Icons.refresh),
                    label: const Text("重试任务"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  )
                : result.isTerminal
                    ? const SizedBox.shrink()
                    : ElevatedButton.icon(
                        onPressed: () => _cancelTask(result),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text("取消任务"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
      ),
    );
  }
}