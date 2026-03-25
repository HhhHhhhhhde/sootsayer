import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

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
 late final List<Package> packages;
 Package? selectedPackage;
 String selectedPaymentMethod = 'balance';
 double accountBalance =0.0;

 bool _isLoading = false;
 bool _isSubscribing = false;
 Map<String, dynamic>? _currentSubscription;

 @override
 void initState() {
 super.initState();
 packages = [
 Package(
 id: 'free',
 name: 'Free 套餐',
 price:0,
 durationDays:0,
 durationLabel: '免费版',
 benefits: const [
 '检测次数：5次/天',
 '并发任务数：1个',
 '适合轻量体验用户',
 ],
 ),
 Package(
 id: 'lite',
 name: 'Lite 套餐',
 price:49.99,
 durationDays:30,
 durationLabel: '按月订阅',
 benefits: const [
 '检测次数：30次/月',
 '并发任务数：1个',
 '适合个人基础使用',
 ],
 ),
 Package(
 id: 'pro',
 name: 'Pro 套餐',
 price:199.99,
 durationDays:30,
 durationLabel: '按月订阅',
 benefits: const [
 '检测次数：100次/月',
 '并发任务数：3个',
 '适合高频专业用户',
 ],
 ),
 Package(
 id: 'ultra',
 name: 'Ultra 套餐',
 price:499.99,
 durationDays:30,
 durationLabel: '按月订阅',
 benefits: const [
 '检测次数：不限',
 '并发任务数：10个',
 '适合团队与重度使用场景',
 ],
 ),
 ];
 _loadInitialData();
 }

 Future<void> _loadInitialData() async {
 setState(() => _isLoading = true);
 await Future.wait([
 _loadBalance(),
 _loadCurrentSubscription(),
 ]);
 if (mounted) {
 setState(() => _isLoading = false);
 }
 }

 Future<void> _loadBalance() async {
 final authProvider = Provider.of<AuthProvider>(context, listen: false);
 final balance = await authProvider.getBalance();
 if (mounted) {
 setState(() {
 accountBalance = balance ??0.0;
 });
 }
 }

 Future<void> _loadCurrentSubscription() async {
 final authProvider = Provider.of<AuthProvider>(context, listen: false);
 final subscription = await authProvider.getCurrentSubscription();
 if (mounted) {
 setState(() {
 _currentSubscription = subscription;
 });
 }
 }

 String _formatDateTime(String? raw) {
 if (raw == null || raw.isEmpty) return '--';
 final dt = DateTime.tryParse(raw);
 if (dt == null) return raw;
 final local = dt.toLocal();
 return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
 '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
 }

 String _planLabel(String? planType) {
 switch (planType?.toLowerCase()) {
 case 'free':
 return '免费版';
 case 'lite':
 return 'Lite 套餐';
 case 'pro':
 return 'Pro 套餐';
 case 'ultra':
 return 'Ultra 套餐';
 default:
 return planType ?? '免费用户';
 }
 }

 String _statusLabel() {
 final status = _currentSubscription?['status'];
 if (_currentSubscription == null) return '免费用户';
 return status ==1 ? '订阅中' : '已过期';
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
 const SizedBox(height:12),
 _buildOrderItem('价格', '¥${selectedPackage!.price.toStringAsFixed(2)}'),
 const SizedBox(height:12),
 _buildOrderItem('有效期', selectedPackage!.durationLabel),
 const SizedBox(height:16),
 const Divider(),
 const SizedBox(height:16),
 const Text(
 '选择支付方式',
 style: TextStyle(fontWeight: FontWeight.bold),
 ),
 const SizedBox(height:12),
 _buildPaymentMethodOption('balance', '账户余额'),
 ],
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(dialogContext),
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
 Text(label, style: const TextStyle(color: Colors.grey)),
 Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
 color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
 width: isSelected ?2 :1,
 ),
 borderRadius: BorderRadius.circular(8),
 color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
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
 Expanded(
 child: Align(
 alignment: Alignment.centerRight,
 child: Text(
 '余额: ¥${accountBalance.toStringAsFixed(2)}',
 style: TextStyle(
 fontSize:12,
 color: accountBalance >= (selectedPackage?.price ??0) ? Colors.green : Colors.red,
 ),
 ),
 ),
 ),
 ],
 ),
 ),
 );
 }

 Future<void> _handlePayment() async {
 if (selectedPackage == null || _isSubscribing) return;

 if (selectedPaymentMethod == 'balance' && accountBalance < selectedPackage!.price) {
 _showInsufficientBalanceDialog();
 return;
 }

 await _subscribeSelectedPlan();
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
 Text('当前余额: ¥${accountBalance.toStringAsFixed(2)}'),
 const SizedBox(height:8),
 Text('需要: ¥${selectedPackage!.price.toStringAsFixed(2)}'),
 const SizedBox(height:8),
 Text(
 '差额: ¥${(selectedPackage!.price - accountBalance).toStringAsFixed(2)}',
 style: const TextStyle(color: Colors.red),
 ),
 ],
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(dialogContext),
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

 Future<void> _subscribeSelectedPlan() async {
 final authProvider = Provider.of<AuthProvider>(context, listen: false);

 setState(() => _isSubscribing = true);

 final success = await authProvider.subscribePlan(selectedPackage!.id);

 if (!mounted) return;

 if (success) {
 await _loadCurrentSubscription();
 await _loadBalance();
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(content: Text('订阅成功，已刷新当前订阅状态')),
 );
 } else {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(authProvider.errorMessage ?? '订阅失败')),
 );
 }

 if (mounted) {
 setState(() => _isSubscribing = false);
 }
 }

 Widget _buildInfoRow(String label, String value) {
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(label, style: const TextStyle(fontSize:12, color: Colors.grey)),
 Expanded(
 child: Text(
 value,
 textAlign: TextAlign.right,
 style: const TextStyle(fontSize:12),
 ),
 ),
 ],
 );
 }

 @override
 Widget build(BuildContext context) {
 final planType = _currentSubscription?['planType']?.toString();
 final startTime = _currentSubscription?['startTime']?.toString();
 final endTime = _currentSubscription?['endTime']?.toString();

 return Scaffold(
 appBar: AppBar(
 title: const Text('套餐订阅'),
 leading: IconButton(
 icon: const Icon(Icons.arrow_back),
 onPressed: () => Navigator.pop(context),
 ),
 ),
 body: _isLoading
 ? const Center(child: CircularProgressIndicator())
 : SingleChildScrollView(
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
 style: TextStyle(fontSize:12, color: Colors.grey),
 ),
 const SizedBox(height:8),
 Text(
 _statusLabel(),
 style: const TextStyle(
 fontSize:18,
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height:12),
 _buildInfoRow('订阅方案', _planLabel(planType)),
 const SizedBox(height:8),
 _buildInfoRow('开始时间', _formatDateTime(startTime)),
 const SizedBox(height:8),
 _buildInfoRow('结束时间', _formatDateTime(endTime)),
 ],
 ),
 ),
 const SizedBox(height:32),

 const Text(
 '选择套餐',
 style: TextStyle(fontSize:16, fontWeight: FontWeight.bold),
 ),
 const SizedBox(height:16),
 ...packages.map((package) {
 final isSelected = selectedPackage?.id == package.id;
 return GestureDetector(
 onTap: () => setState(() => selectedPackage = package),
 child: Container(
 margin: const EdgeInsets.only(bottom:16),
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 border: Border.all(
 color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
 width: isSelected ?2 :1,
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
 fontSize:16,
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height:4),
 Text(
 package.durationLabel,
 style: TextStyle(
 fontSize:12,
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
 fontSize:20,
 fontWeight: FontWeight.bold,
 color: Theme.of(context).primaryColor,
 ),
 ),
 const SizedBox(height:4),
 if (isSelected)
 Icon(
 Icons.check_circle,
 color: Theme.of(context).primaryColor,
 ),
 ],
 ),
 ],
 ),
 const SizedBox(height:16),
 const Text(
 '权益说明',
 style: TextStyle(fontSize:12, fontWeight: FontWeight.bold),
 ),
 const SizedBox(height:8),
 ...package.benefits.map(
 (benefit) => Padding(
 padding: const EdgeInsets.only(bottom:4),
 child: Row(
 children: [
 Icon(
 Icons.check,
 size:14,
 color: Theme.of(context).primaryColor,
 ),
 const SizedBox(width:8),
 Expanded(
 child: Text(
 benefit,
 style: const TextStyle(fontSize:12),
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
 }),
 const SizedBox(height:32),

 SizedBox(
 width: double.infinity,
 child: ElevatedButton(
 onPressed: _isSubscribing ? null : _showOrderConfirmDialog,
 style: ElevatedButton.styleFrom(
 padding: const EdgeInsets.symmetric(vertical:16),
 backgroundColor: Theme.of(context).primaryColor,
 foregroundColor: Colors.white,
 ),
 child: _isSubscribing
 ? const SizedBox(
 height:20,
 width:20,
 child: CircularProgressIndicator(
 strokeWidth:2,
 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
 ),
 )
 : const Text('立即订阅'),
 ),
 ),
 ],
 ),
 ),
 ),
 );
 }
}
