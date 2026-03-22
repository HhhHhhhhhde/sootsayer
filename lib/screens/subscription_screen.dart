import 'package:flutter/material.dart';

class Package {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final List<String> benefits;
  final String durationLabel;

  Package({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.benefits,
    required this.durationLabel,
  });
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late List<Package> packages;
  Package? selectedPackage;
  String selectedPaymentMethod = 'balance';
  double accountBalance = 0.0;

  @override
  void initState() {
    super.initState();
    packages = [
      Package(
        id: 'FREE',
        name: '免费版',
        price: 0.0,
        durationDays: 0,
        durationLabel: '永久免费',
        benefits: [
          '每月检测次数：10次',
          '并发任务数：1个',
          '基础分析报告',
          '社区支持',
          '标准数据保留：30天',
        ],
      ),
      Package(
        id: 'BASIC',
        name: '基础版',
        price: 49.99,
        durationDays: 30,
        durationLabel: '1个月',
        benefits: [
          '每月检测次数：100次',
          '并发任务数：5个',
          '详细分析报告',
          '邮件支持',
          '数据导出功能',
          '数据保留：90天',
          '优先级队列',
        ],
      ),
      Package(
        id: 'PREMIUM',
        name: '高级版',
        price: 149.99,
        durationDays: 30,
        durationLabel: '1个月',
        benefits: [
          '每月检测次数：500次',
          '并发任务数：10个',
          '高级分析报告',
          '优先级支持（工作时间）',
          '数据导出功能',
          '数据保留：180天',
          '自定义分析规则',
          'API 接口访问',
          '团队协作功能',
        ],
      ),
      Package(
        id: 'ENTERPRISE',
        name: '企业版',
        price: 499.99,
        durationDays: 30,
        durationLabel: '1个月',
        benefits: [
          '每月检测次数：无限',
          '并发任务数：50个',
          '企业级分析报告',
          '24小时专属支持',
          '数据导出功能',
          '数据保留：1年',
          '自定义分析规则',
          '完整 API 接口',
          '团队协作功能',
          '单点登录（SSO）',
          '审计日志',
          '专属账户经理',
          '定制化解决方案',
        ],
      ),
    ];
  }

  void _showOrderConfirmDialog() {
    if (selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择套餐')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('订单确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderItem('套餐名称', selectedPackage!.name),
              const SizedBox(height: 12),
              _buildOrderItem('价格', '¥${selectedPackage!.price.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _buildOrderItem('有效期', selectedPackage!.durationLabel),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                '选择支付方式',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodOption('balance', '账户余额'),
              const SizedBox(height: 8),
              _buildPaymentMethodOption('wechat', '微信支付'),
              const SizedBox(height: 8),
              _buildPaymentMethodOption('alipay', '支付宝'),
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
                _handlePayment();
              },
              child: const Text('确认支付'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(String value, String label) {
    final isSelected = selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() => selectedPaymentMethod = value);
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
            Radio<String>(
              value: value,
              groupValue: selectedPaymentMethod,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => selectedPaymentMethod = newValue);
                }
              },
            ),
            Text(label),
            if (value == 'balance')
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '余额: ¥${accountBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: accountBalance >= (selectedPackage?.price ?? 0)
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePayment() {
    if (selectedPackage == null) return;

    if (selectedPaymentMethod == 'balance') {
      if (accountBalance < selectedPackage!.price) {
        _showInsufficientBalanceDialog();
        return;
      }
    }

    _showPaymentProcessingDialog();
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('余额不足'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前余额: ¥${accountBalance.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              Text(
                '需要: ¥${selectedPackage!.price.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              Text(
                '差额: ¥${(selectedPackage!.price - accountBalance).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.red),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请先充值账户余额')),
                );
              },
              child: const Text('去充值'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('处理中'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                '正在处理 ${selectedPackage!.name} 订阅...',
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context);
      _showSubscriptionSuccessDialog();
    });
  }

  void _showSubscriptionSuccessDialog() {
    final expiryDate = DateTime.now().add(
      Duration(days: selectedPackage!.durationDays),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('订阅成功'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                '${selectedPackage!.name}订阅已激活',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '会员信息',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                '有效期',
                '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} 至 ${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow('套餐类型', selectedPackage!.name),
              const SizedBox(height: 16),
              const Text(
                '权益说明',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...selectedPackage!.benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('套餐订阅'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前会员状态
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
                      '当前会员状态',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '免费用户',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '升级会员享受更多权益',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 套餐列表
              const Text(
                '选择套餐',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...packages.map((package) {
                final isSelected = selectedPackage?.id == package.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedPackage = package);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  package.durationLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '¥${package.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '权益说明',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...package.benefits.map(
                          (benefit) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 32),

              // 立即订阅按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showOrderConfirmDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('立即订阅'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
