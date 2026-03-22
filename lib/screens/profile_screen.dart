import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'change_password_screen.dart';
import 'recharge_screen.dart';
import 'subscription_screen.dart';
import 'theme_settings_screen.dart';
import 'delete_account_screen.dart';
import 'user_info_screen.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息卡片
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final userInfo = authProvider.userInfo;
              final username = userInfo?['username'] ?? '默认用户';
              final email = userInfo?['email'] ?? '未设置';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserInfoScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // 设置选项
          _buildSection(context, '账户设置', [
            _buildListTile(context, Icons.person, '个人信息', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserInfoScreen(),
                ),
              );
            }),
            _buildListTile(context, Icons.lock, '修改密码', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            }),
            _buildListTile(context, Icons.account_balance_wallet, '充值', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RechargeScreen(),
                ),
              );
            }),
            _buildListTile(context, Icons.card_membership, '套餐订阅', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            }),
            _buildListTile(context, Icons.delete_forever, '注销账户', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeleteAccountScreen(),
                ),
              );
            }, isDestructive: true),
          ]),
          
          _buildSection(context, '其他', [
            _buildListTile(context, Icons.palette, '主题', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            }),
            _buildListTile(context, Icons.help, '帮助中心', () {}),
            _buildListTile(context, Icons.info, '关于', () {}),
            _buildListTile(context, Icons.logout, '退出登录', () {
              _showLogoutDialog(context);
            }, isDestructive: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
