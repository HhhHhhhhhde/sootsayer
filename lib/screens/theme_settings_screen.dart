import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '选择主题',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context,
                themeProvider,
                AppTheme.light,
                '浅色主题',
                '清爽明亮的界面风格',
                Icons.light_mode,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                context,
                themeProvider,
                AppTheme.dark,
                '暗色主题',
                '护眼舒适的深色风格',
                Icons.dark_mode,
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                context,
                themeProvider,
                AppTheme.highSaturation,
                '高饱和主题',
                '鲜艳生动的彩色风格',
                Icons.palette,
              ),
              const SizedBox(height: 32),
              const Text(
                '亮度模式',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildBrightnessOption(
                context,
                themeProvider,
                ThemeMode.light,
                '浅色',
                Icons.wb_sunny,
              ),
              const SizedBox(height: 12),
              _buildBrightnessOption(
                context,
                themeProvider,
                ThemeMode.dark,
                '深色',
                Icons.nights_stay,
              ),
              const SizedBox(height: 12),
              _buildBrightnessOption(
                context,
                themeProvider,
                ThemeMode.system,
                '跟随系统',
                Icons.settings_brightness,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    AppTheme theme,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = themeProvider.appTheme == theme;
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? Theme.of(context).primaryColor
        : colorScheme.outline.withOpacity(0.65);
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color ??
        colorScheme.onSurfaceVariant;
    
    return GestureDetector(
      onTap: () {
        themeProvider.setAppTheme(theme);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getThemePreviewColor(theme),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeMode mode,
    String title,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? Theme.of(context).primaryColor
        : colorScheme.outline.withOpacity(0.65);
    
    return GestureDetector(
      onTap: () {
        themeProvider.setThemeMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Color _getThemePreviewColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const Color(0xFF2D5BFF);
      case AppTheme.dark:
        return const Color(0xFF1F2937);
      case AppTheme.highSaturation:
        return const Color(0xFFFF6B6B);
    }
  }
}
