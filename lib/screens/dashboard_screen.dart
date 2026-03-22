import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/security_metrics_card.dart';
import '../widgets/app_submit_card.dart';
import '../widgets/recent_analysis_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}，这是您的应用安全健康简报',
              style: const TextStyle(fontSize: 16),
            ),
            const Text(
              'AppShield Security Dashboard',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusPill(
                    label: '引擎状态',
                    value: '在线',
                    color: const Color(0xFF34C759),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: '今日扫描',
                    value: '0 个',
                    color: const Color(0xFF2D5BFF),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: '待处理风险',
                    value: '0 项',
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: '云端积分',
                    value: '0',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Security Metrics
            const SecurityMetricsCard(),
            const SizedBox(height: 16),

            // App Submit Card
            const AppSubmitCard(),
            const SizedBox(height: 16),

            // Recent Analysis
            const RecentAnalysisCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
