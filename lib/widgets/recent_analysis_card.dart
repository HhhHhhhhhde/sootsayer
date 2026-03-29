import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../models/analysis_result.dart';
import '../screens/analysis_detail_screen.dart';

class RecentAnalysisCard extends StatelessWidget {
  const RecentAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        final recentResults = provider.recentResults;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '近期分析',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (recentResults.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('暂无分析记录',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentResults.map((r) => _AnalysisItem(result: r)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnalysisItem extends StatelessWidget {
  final AnalysisResult result;
  const _AnalysisItem({required this.result});

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

  String _formatSize(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(result.status);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisDetailScreen(resultId: result.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                result.appName.isNotEmpty
                    ? result.appName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.appName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatDate(result.submitTime)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusText(result.status),
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                if (result.progress != null && !result.isTerminal)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${result.progress}%',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
