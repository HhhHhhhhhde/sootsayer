import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int _currentStep = 0;
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  bool _agreedToDelete = false;
  bool _isVerifying = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _sendVerificationCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.userEmail;
    
    setState(() => _isVerifying = true);
    
    final result = await authProvider.sendVerifyCode(userEmail ?? '', 'RESET');
    
    if (!mounted) return;
    setState(() => _isVerifying = false);
    
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已发送到您的邮箱')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? '发送验证码失败')),
      );
    }
  }

  void _verifyIdentity() {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入密码')),
      );
      return;
    }

    setState(() => _currentStep = 2);
  }

  void _submitDeleteRequest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() => _isDeleting = true);

    final result = await authProvider.eraseAccount(_passwordController.text);
    
    if (!mounted) return;
    setState(() => _isDeleting = false);
    
    if (result) {
      _showDeletionProcessingDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? '注销账户失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeletionProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('删除请求已提交'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text(
                '您的账户删除请求已提交，正在处理中...',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '处理进度：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• 删除任务记录'),
                    Text('• 删除上传文件'),
                    Text('• 删除分析报告'),
                    Text('• 清除个人数据'),
                    SizedBox(height: 8),
                    Text(
                      '预计在24小时内完成',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '我们将在删除完成后发送确认邮件到您的邮箱。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
              },
              child: const Text('返回'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注销账户'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (!_agreedToDelete) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请勾选确认框')),
              );
              return;
            }
            setState(() => _currentStep = 1);
          } else if (_currentStep == 1) {
            _verifyIdentity();
          } else if (_currentStep == 2) {
            _submitDeleteRequest();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          Step(
            title: const Text('确认删除'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '重要提示',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '删除的数据范围：',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• 所有任务记录和分析历史'),
                      const Text('• 上传的APK文件'),
                      const Text('• 生成的分析报告'),
                      const Text('• 个人账户信息'),
                      const Text('• 订阅和充值记录'),
                      const SizedBox(height: 12),
                      const Text(
                        '删除的后果：',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• 所有数据将被永久删除，无法恢复'),
                      const Text('• 账户将被标记为已注销'),
                      const Text('• 无法使用该账户登录'),
                      const Text('• 相关权益将被清除'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToDelete,
                      onChanged: (value) {
                        setState(() => _agreedToDelete = value ?? false);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        '我已了解删除的后果，确认继续',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('身份验证'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '为了保护您的账户安全，请验证您的身份',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '请输入当前密码',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _verificationCodeController,
                        decoration: InputDecoration(
                          labelText: '验证码',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : _sendVerificationCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('发送'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '验证码已发送到您的邮箱 user@example.com',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('确认删除'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '删除摘要',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryItem('账户', 'user@example.com'),
                      _buildSummaryItem('任务记录', '5 条'),
                      _buildSummaryItem('上传文件', '3 个'),
                      _buildSummaryItem('分析报告', '5 份'),
                      const SizedBox(height: 12),
                      const Text(
                        '点击下方"确认删除"按钮后，系统将立即开始处理您的删除请求。',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
        ],
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isDeleting ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _currentStep == 2 ? '确认删除' : '下一步',
                        ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isDeleting ? null : details.onStepCancel,
                  child: const Text('上一步'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
