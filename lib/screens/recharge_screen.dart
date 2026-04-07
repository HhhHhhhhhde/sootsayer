import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'balance_records_screen.dart';
import 'payment_page_screen.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final List<int> _presetAmounts = [50, 100, 200];
  int? _selectedAmount;
  final _customAmountController = TextEditingController();
  String _selectedPaymentMethod = 'wechat';
  bool _isProcessing = false;
  double _currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is fully mounted before calling Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalance();
    });
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    // 1. 记录函数开始进入
    debugPrint('[_loadBalance] 开始加载余额...');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 2. 记录请求发起前的状态（可选，如当前用户ID）
      debugPrint('[_loadBalance] 正在调用 authProvider.getBalance()...');

      final balance = await authProvider.getBalance();

      // 3. 记录接口返回的原始数据
      debugPrint('[_loadBalance] 接口返回余额: $balance');

      if (!mounted) {
        // 4. 重点调试：检查组件是否在异步返回前已被销毁
        debugPrint('[_loadBalance] 警告：组件已卸载 (mounted == false)，跳过 setState');
        return;
      }

      setState(() {
        _currentBalance = balance ?? 0.0;
        // 5. 记录状态更新完成
        debugPrint('[_loadBalance] 状态已更新，当前内存余额: $_currentBalance');
      });

    } catch (e, stackTrace) {
      // 6. 异常捕获：这是调试中最关键的部分
      debugPrint('[_loadBalance] 错误：获取余额失败');
      debugPrint('错误详情: $e');
      debugPrint('堆栈信息: $stackTrace');
    }
  }

  int? _getSelectedAmount() {
    if (_selectedAmount != null) {
      return _selectedAmount;
    }
    if (_customAmountController.text.isNotEmpty) {
      return int.tryParse(_customAmountController.text);
    }
    return null;
  }

  void _handleRecharge() {
    final amount = _getSelectedAmount();
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择或输入充值金额')),
      );
      return;
    }

    _showPaymentDialog(amount.toDouble());
  }

  void _showPaymentDialog(double amount) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('确认充值'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('充值金额：¥${amount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text(
                '支付方式：${_selectedPaymentMethod == 'wechat' ? '微信支付' : '支付宝'}',
              ),
              const SizedBox(height: 16),
              const Text(
                '点击确认后，将跳转至支付页面',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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
                _processRecharge(amount);
              },
              child: const Text('确认支付'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRecharge(double amount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isProcessing = true);

    final payMethod = _selectedPaymentMethod == 'wechat' ? 'WECHAT' : 'ALIPAY';
    debugPrint('[Recharge] calling getPaymentPage: amount=$amount method=$payMethod');
    final paymentPage = await authProvider.getPaymentPage(amount, payMethod);
    debugPrint('[Recharge] getPaymentPage result: $paymentPage');

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (paymentPage == null || paymentPage['code'] != 200) {
      debugPrint('[Recharge] ERROR: payment page failed, code=${paymentPage?["code"]} msg=${paymentPage?["message"]}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? paymentPage?['message']?.toString() ?? '创建支付失败'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final htmlContent = paymentPage['htmlContent']?.toString() ?? '';
    final outTradeNo = paymentPage['outTradeNo']?.toString() ?? '';
    debugPrint('[Recharge] navigating to PaymentPageScreen: outTradeNo=$outTradeNo htmlLen=${htmlContent.length}');

    if (htmlContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('支付页面为空，请稍后重试'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentCompleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPageScreen(
          htmlContent: htmlContent,
          paymentMethod: payMethod,
          amount: amount,
          outTradeNo: outTradeNo,
        ),
      ),
    );

    if (paymentCompleted == true) {
      await _loadBalance();
      if (!mounted) return;
      _showSuccessDialog(amount);
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('充值成功'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                '成功充值 ¥${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '账户余额已更新',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('完成'),
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
        title: const Text('充值'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BalanceRecordsScreen(),
                ),
              );
            },
            child: Text(
              '流水记录',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前余额
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前余额',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${_currentBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 预设金额
              const Text(
                '选择充值金额',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _presetAmounts.length,
                itemBuilder: (context, index) {
                  final amount = _presetAmounts[index];
                  final isSelected = _selectedAmount == amount;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                        _customAmountController.clear();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¥$amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 自定义金额
              const Text(
                '自定义金额',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customAmountController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() => _selectedAmount = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: '请输入充值金额',
                  prefixText: '¥ ',
                  prefixStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 支付方式
              const Text(
                '选择支付方式',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodOption(
                'wechat',
                Icons.payment,
                '微信支付',
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodOption(
                'alipay',
                Icons.payment,
                '支付宝',
              ),
              const SizedBox(height: 32),

              // 充值按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleRecharge,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('立即充值'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String value,
    IconData icon,
    String label,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
