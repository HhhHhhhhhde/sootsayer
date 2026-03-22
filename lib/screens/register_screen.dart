import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0; // 0: 填写信息, 1: 验证码, 2: 完成
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _codeSent = false;
  int _countdownSeconds = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _codeSent = true;
      _countdownSeconds = 10;
    });
    
    _decrementCountdown();
  }

  void _decrementCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
        if (_countdownSeconds > 0) {
          _decrementCountdown();
        }
      }
    });
  }

  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    return hasLetter && hasDigit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建账户'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentStep == 0) _buildFillInfoStep(),
              if (_currentStep == 1) _buildVerificationStep(),
              if (_currentStep == 2) _buildCompleteStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFillInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '填写账户信息',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '请填写您的邮箱和密码',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),
        
        // 用户名输入框（可选）
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: '用户名（可选）',
            hintText: '请输入用户名（2-50字符）',
            prefixIcon: const Icon(Icons.person_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 邮箱输入框
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: '邮箱地址',
            hintText: '请输入您的邮箱',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        
        // 手机号输入框（可选）
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: '手机号（可选）',
            hintText: '请输入手机号（11位）',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.phone,
          maxLength: 11,
        ),
        const SizedBox(height: 16),
        
        // 密码输入框
        TextField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: '密码',
            hintText: '请设置密码（至少8位，需包含字母和数字）',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _passwordVisible = !_passwordVisible);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_passwordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _passwordController.text.length >= 8
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: _passwordController.text.length >= 8
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '至少8位',
                      style: TextStyle(
                        fontSize: 12,
                        color: _passwordController.text.length >= 8
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _passwordController.text.contains(RegExp(r'[a-zA-Z]'))
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: _passwordController.text.contains(RegExp(r'[a-zA-Z]'))
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '包含字母',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _passwordController.text.contains(RegExp(r'[0-9]'))
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: _passwordController.text.contains(RegExp(r'[0-9]'))
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '包含数字',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
        // 确认密码输入框
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          decoration: InputDecoration(
            labelText: '确认密码',
            hintText: '请再次输入密码',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // 下一步按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final email = _emailController.text.trim();
              final password = _passwordController.text;
              final confirmPassword = _confirmPasswordController.text;

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入邮箱')),
                );
                return;
              }

              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入密码')),
                );
                return;
              }

              if (!_isPasswordValid(password)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密码必须至少8位，且包含字母和数字')),
                );
                return;
              }

              if (password != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的密码不一致')),
                );
                return;
              }

              setState(() => _currentStep = 1);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('下一步'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '验证身份',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '我们已向您的邮箱发送验证码',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),
        
        // 显示接收地址
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.email_outlined,
                color: Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _emailController.text,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _currentStep = 0);
                },
                child: const Text('修改'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // 验证码输入框
        TextField(
          controller: _verificationCodeController,
          decoration: InputDecoration(
            labelText: '验证码',
            hintText: '请输入6位验证码',
            prefixIcon: const Icon(Icons.security_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 16),
        
        // 获取验证码按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _codeSent && _countdownSeconds > 0
                ? null
                : () async {
                    final email = _emailController.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请先输入邮箱')),
                      );
                      return;
                    }

                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final success = await authProvider.sendVerifyCode(email, 'REGISTER');

                    if (!mounted) return;

                    if (success) {
                      _startCountdown();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('验证码已发送至邮箱')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authProvider.errorMessage ?? '发送验证码失败')),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (_codeSent && _countdownSeconds > 0) {
                  return Text('重新发送($_countdownSeconds秒)');
                }
                return authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('获取验证码');
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // 验证并创建账户按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              final password = _passwordController.text;
              final confirmPassword = _confirmPasswordController.text;
              final verifyCode = _verificationCodeController.text.trim();

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入邮箱')),
                );
                return;
              }

              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入密码')),
                );
                return;
              }

              if (password != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的密码不一致')),
                );
                return;
              }

              if (verifyCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入验证码')),
                );
                return;
              }

              final username = _usernameController.text.trim();
              final phone = _phoneController.text.trim();

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.register(
                email,
                password,
                verifyCode,
                username: username.isEmpty ? null : username,
                phone: phone.isEmpty ? null : phone,
              );

              if (!mounted) return;

              if (success) {
                setState(() => _currentStep = 2);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authProvider.errorMessage ?? '注册失败')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('创建账户');
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 返回按钮
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              setState(() => _currentStep = 0);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('返回'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    // 自动跳转到主页
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '账户创建成功！',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '欢迎加入 AppShield Security',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '将在 2 秒后自动返回主页...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        // 立即返回按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('立即返回主页'),
          ),
        ),
      ],
    );
  }
}
