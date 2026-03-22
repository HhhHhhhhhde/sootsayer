import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SettingsSection(
            title: '账户设置',
            children: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('账户信息'),
                    subtitle: Text(authProvider.userEmail ?? '未登录'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to account info
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('修改密码'),
                subtitle: const Text('更改您的账户密码'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('退出登录'),
                subtitle: const Text('登出当前账户'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: '外观',
            children: [
              SwitchListTile(
                title: const Text('深色模式'),
                subtitle: const Text('切换应用主题'),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
                secondary: Icon(
                  themeProvider.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: '扫描设置',
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('自动扫描'),
                subtitle: const Text('设置自动扫描计划'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to auto scan settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('扫描通知'),
                subtitle: const Text('管理扫描完成通知'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Toggle notifications
                  },
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: '数据管理',
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('导出报告'),
                subtitle: const Text('导出审计报告'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Export reports
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('清除缓存'),
                subtitle: const Text('清除应用缓存数据'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showClearCacheDialog(context);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: '关于',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本信息'),
                subtitle: const Text('v1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show version info
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('隐私政策'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show privacy policy
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('使用条款'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show terms of service
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有缓存数据吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清除')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已退出登录')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }
}
