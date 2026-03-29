import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import 'analysis_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh list every time this tab is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AnalysisProvider>(context, listen: false);
      provider.fetchTasks();
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED': return Colors.green;
      case 'SCANNING':
      case 'AI_AUDITING': return Colors.blue;
      case 'FAILED': return Colors.red;
      case 'CANCELLED': return Colors.grey;
      default: return Colors.orange; // WAITING
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING': return '等待中';
      case 'SCANNING': return '扫描中';
      case 'AI_AUDITING': return 'AI 审核中';
      case 'COMPLETED': return '已完成';
      case 'FAILED': return '失败';
      case 'CANCELLED': return '已取消';
      default: return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED': return Icons.check_circle_outline;
      case 'FAILED': return Icons.error_outline;
      case 'CANCELLED': return Icons.cancel_outlined;
      case 'SCANNING':
      case 'AI_AUDITING': return Icons.sync;
      default: return Icons.hourglass_empty;
    }
  }

  void _showCancelConfirmDialog(
    BuildContext context,
    AnalysisProvider provider,
    String resultId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认取消'),
        content: const Text('确定要取消该任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () {
              provider.cancelTask(resultId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('任务已取消')),
              );
            },
            child: const Text('取消任务',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析历史'),
        actions: [
          Consumer<AnalysisProvider>(
            builder: (_, provider, __) => IconButton(
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : provider.fetchTasks,
              tooltip: '刷新',
            ),
          ),
        ],
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.results.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = provider.results;

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('暂无分析历史',
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('提交 APK 开始分析',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Stats bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        '总任务', '${provider.totalAnalyses}', Icons.analytics),
                    _buildStatItem('已完成',
                        '${provider.completedAnalyses}', Icons.check_circle),
                    _buildStatItem('发现漏洞',
                        '${provider.totalVulnerabilities}', Icons.bug_report),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.fetchTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final isActive = !result.isTerminal;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getStatusColor(result.status).withOpacity(0.15),
                            child: Icon(
                              _getStatusIcon(result.status),
                              color: _getStatusColor(result.status),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            result.appName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(result.status)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getStatusText(result.status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            _getStatusColor(result.status),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (result.progress != null &&
                                      isActive) ...
                                    [
                                      const SizedBox(width: 6),
                                      Text(
                                        '${result.progress}%',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(result.submitTime)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          trailing: isActive
                              ? PopupMenuButton(
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.stop_circle,
                                              color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('取消任务'),
                                        ],
                                      ),
                                      onTap: () => _showCancelConfirmDialog(
                                          context, provider, result.id),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalysisDetailScreen(
                                  resultId: result.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
