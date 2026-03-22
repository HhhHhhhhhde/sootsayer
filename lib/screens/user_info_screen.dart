import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
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
        title: const Text('个人信息'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userInfo = authProvider.userInfo;
          if (userInfo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('无法加载用户信息'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserInfo,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    icon: Icons.person,
                    label: '用户ID',
                    value: userInfo['id']?.toString() ?? '未设置',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.account_circle,
                    label: '用户名',
                    value: userInfo['username'] ?? '未设置',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.email,
                    label: '邮箱',
                    value: userInfo['email'] ?? '未设置',
                  ),
                  const SizedBox(height: 12),
                  if (userInfo['phone'] != null && userInfo['phone'].toString().isNotEmpty)
                    Column(
                      children: [
                        _buildInfoCard(
                          icon: Icons.phone,
                          label: '手机号',
                          value: userInfo['phone'] ?? '未设置',
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  if (userInfo['createTime'] != null)
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      label: '创建时间',
                      value: userInfo['createTime'] ?? '未设置',
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
