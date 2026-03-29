import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../models/analysis_result.dart';
import '../providers/analysis_provider.dart';

/// 依据 GET /api/tasks 同步到 [AnalysisProvider.results] 的任务状态，用「天气」隐喻展示安全态势。
enum _PrivacySky { sunny, cloudy, rainy }

class PrivacyWeatherCard extends StatelessWidget {
  const PrivacyWeatherCard({super.key});

  static _PrivacySky _skyFor(List<AnalysisResult> results) {
    final hasPending = results.any((r) => !r.isTerminal);
    if (hasPending) return _PrivacySky.cloudy;
    final hasLeak = results.any(
      (r) => r.status == 'COMPLETED' && (r.vulnerabilities ?? 0) > 0,
    );
    if (hasLeak) return _PrivacySky.rainy;
    return _PrivacySky.sunny;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<AnalysisProvider>(
      builder: (context, analysis, _) {
        final sky = _skyFor(analysis.results);
        final isLoading = analysis.isLoading && analysis.results.isEmpty;

        final (title, subtitle, scoreLine, gradient) = switch (sky) {
          _PrivacySky.sunny => (
              '晴天',
              '最近完成的分析未发现隐私泄露项',
              '安全评分：优',
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFF8E1).withValues(alpha: 0.95),
                  const Color(0xFFFFE082).withValues(alpha: 0.65),
                  cs.primaryContainer.withValues(alpha: 0.4),
                ],
              ),
            ),
          _PrivacySky.cloudy => (
              '多云',
              '有任务正在排队或分析中',
              '安全评分：观察中',
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surfaceContainerHighest.withValues(alpha: 0.85),
                  const Color(0xFFB0BEC5).withValues(alpha: 0.45),
                  cs.secondaryContainer.withValues(alpha: 0.35),
                ],
              ),
            ),
          _PrivacySky.rainy => (
              '雨天',
              '近期完成的分析中检测到隐私风险',
              '安全评分：需关注',
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF546E7A).withValues(alpha: 0.35),
                  const Color(0xFF78909C).withValues(alpha: 0.4),
                  cs.errorContainer.withValues(alpha: 0.45),
                ],
              ),
            ),
        };

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient,
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.wb_cloudy_outlined, size: 18, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            '隐私风险「天气」',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: cs.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scoreLine,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _WeatherLottie(sky: sky),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeatherLottie extends StatelessWidget {
  const _WeatherLottie({required this.sky});

  final _PrivacySky sky;

  @override
  Widget build(BuildContext context) {
    const size = 112.0;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: switch (sky) {
          _PrivacySky.sunny => Stack(
              alignment: Alignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/sunny.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
                Icon(
                  Icons.shield_rounded,
                  size: 40,
                  color: Colors.amber.shade800.withValues(alpha: 0.9),
                  shadows: [
                    Shadow(
                      color: Colors.amber.shade200.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ],
            ),
          _PrivacySky.cloudy => Lottie.asset(
              'assets/lottie/cloudy.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          _PrivacySky.rainy => Stack(
              fit: StackFit.expand,
              children: [
                Lottie.asset(
                  'assets/lottie/cloudy.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
                const Positioned.fill(child: _RainFall()),
              ],
            ),
        },
      ),
    );
  }
}

class _RainFall extends StatefulWidget {
  const _RainFall();

  @override
  State<_RainFall> createState() => _RainFallState();
}

class _RainFallState extends State<_RainFall> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RainPainter(_controller.value),
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.65)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final h = size.height;
    final w = size.width;
    for (var i = 0; i < 48; i++) {
      final x = (i * 13.17) % w;
      final phase = (i * 0.31) % 1.0;
      final y = ((phase + t) % 1.0) * h;
      canvas.drawLine(Offset(x, y), Offset(x - 1.5, y + 7), paint);
    }
    // 第二层稍快，增加层次
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 32; i++) {
      final x = (i * 19.0 + 5) % w;
      final phase = (i * 0.47 + 0.2) % 1.0;
      final y = ((phase + t * 1.15) % 1.0) * h;
      canvas.drawLine(Offset(x, y), Offset(x - 1.2, y + 6), paint2);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.t != t;
}
