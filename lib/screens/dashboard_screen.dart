import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/privacy_weather_card.dart';
import '../widgets/privacy_tip_card.dart';
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
          final token =
              Provider.of<AuthProvider>(context, listen: false).sessionToken;
          if (token != null) {
            await Provider.of<AnalysisProvider>(context, listen: false)
                .fetchTasks();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // const PrivacyWeatherCard(),
            // const SizedBox(height: 16),

            // App Submit Card
            const AppSubmitCard(),
            const SizedBox(height: 16),

            // Recent Analysis
            const RecentAnalysisCard(),
            const SizedBox(height: 16),
            const PrivacyTipCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
