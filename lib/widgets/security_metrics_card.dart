import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';

class SecurityMetricsCard extends StatelessWidget {
  const SecurityMetricsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, analysisProvider, child) {
        // 统计已完成分析的APK的危险等级
        final completedResults = analysisProvider.results
            .where((r) => r.status == 'completed')
            .toList();

        int highCount = 0;
        int mediumCount = 0;
        int lowCount = 0;
        int infoCount = 0;

        for (final result in completedResults) {
          switch (result.riskLevel) {
            case 'high':
              highCount++;
              break;
            case 'medium':
              mediumCount++;
              break;
            case 'low':
              lowCount++;
              break;
            default:
              infoCount++;
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '安全指标概览',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricItem(
                        label: '高危',
                        value: highCount,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    Expanded(
                      child: _MetricItem(
                        label: '中危',
                        value: mediumCount,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    Expanded(
                      child: _MetricItem(
                        label: '低危',
                        value: lowCount,
                        color: const Color(0xFF34C759),
                      ),
                    ),
                    Expanded(
                      child: _MetricItem(
                        label: '信息',
                        value: infoCount,
                        color: const Color(0xFF2D5BFF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
