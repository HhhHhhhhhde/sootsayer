import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class BalanceRecord {
  final DateTime dateTime;
  final String type; // 'recharge', 'consume', 'refund'
  final double amount;
  final String remark;

  BalanceRecord({
    required this.dateTime,
    required this.type,
    required this.amount,
    required this.remark,
  });
}

class BalanceRecordsScreen extends StatefulWidget {
  const BalanceRecordsScreen({super.key});

  @override
  State<BalanceRecordsScreen> createState() => _BalanceRecordsScreenState();
}

class _BalanceRecordsScreenState extends State<BalanceRecordsScreen> {
 late DateTime _startDate;
 late DateTime _endDate;
 int _currentPage =1;
 final int _pageSize =10;
 double _currentBalance =0.0;
 bool _isLoadingBalance = false;

 @override
 void initState() {
 super.initState();
 _endDate = DateTime.now();
 _startDate = _endDate.subtract(const Duration(days:30));
 _refreshBalanceByGet();
 }

 Future<void> _refreshBalanceByGet() async {
 setState(() => _isLoadingBalance = true);
 final authProvider = Provider.of<AuthProvider>(context, listen: false);
 final balance = await authProvider.getBalance();
 if (!mounted) return;
 setState(() {
 _currentBalance = balance ??0.0;
 _isLoadingBalance = false;
 });
 }

  List<BalanceRecord> _getMockRecords() {
    final records = <BalanceRecord>[
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'recharge',
        amount: 100.0,
        remark: '微信支付充值',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(hours: 5)),
        type: 'consume',
        amount: 50.0,
        remark: '任务ID: 12345',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        type: 'recharge',
        amount: 200.0,
        remark: '支付宝充值',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        type: 'consume',
        amount: 30.0,
        remark: '套餐: 基础版',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 3)),
        type: 'refund',
        amount: 20.0,
        remark: '订单退款',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 5)),
        type: 'consume',
        amount: 15.0,
        remark: '任务ID: 12346',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 7)),
        type: 'recharge',
        amount: 150.0,
        remark: '微信支付充值',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 10)),
        type: 'consume',
        amount: 25.0,
        remark: '套餐: 高级版',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 15)),
        type: 'consume',
        amount: 40.0,
        remark: '任务ID: 12347',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 20)),
        type: 'recharge',
        amount: 300.0,
        remark: '支付宝充值',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 25)),
        type: 'consume',
        amount: 60.0,
        remark: '套餐: 企业版',
      ),
      BalanceRecord(
        dateTime: DateTime.now().subtract(const Duration(days: 28)),
        type: 'refund',
        amount: 50.0,
        remark: '订单退款',
      ),
    ];

    // 按日期范围筛选
    final filtered = records
        .where((r) =>
            r.dateTime.isAfter(_startDate) && r.dateTime.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    // 按日期倒序排列
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return filtered;
  }

  List<BalanceRecord> _getPaginatedRecords() {
    final allRecords = _getMockRecords();
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, allRecords.length);

    if (startIndex >= allRecords.length) {
      return [];
    }

    return allRecords.sublist(startIndex, endIndex);
  }

  int _getTotalPages() {
    final allRecords = _getMockRecords();
    return (allRecords.length / _pageSize).ceil();
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'recharge':
        return '充值';
      case 'consume':
        return '消费';
      case 'refund':
        return '退款';
      default:
        return '其他';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'recharge':
        return Colors.green;
      case 'consume':
        return Colors.red;
      case 'refund':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'recharge':
        return Icons.add_circle;
      case 'consume':
        return Icons.remove_circle;
      case 'refund':
        return Icons.undo;
      default:
        return Icons.help;
    }
  }

  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        DateTime tempStartDate = _startDate;
        DateTime tempEndDate = _endDate;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择时间范围'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('开始日期'),
                    subtitle: Text(
                      '${tempStartDate.year}-${tempStartDate.month.toString().padLeft(2, '0')}-${tempStartDate.day.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStartDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => tempStartDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('结束日期'),
                    subtitle: Text(
                      '${tempEndDate.year}-${tempEndDate.month.toString().padLeft(2, '0')}-${tempEndDate.day.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEndDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => tempEndDate = picked);
                      }
                    },
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
                    this.setState(() {
                      _startDate = tempStartDate;
                      _endDate = tempEndDate;
                      _currentPage = 1;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _getPaginatedRecords();
    final totalPages = _getTotalPages();

    return Scaffold(
      appBar: AppBar(
        title: const Text('账户流水'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 当前余额
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前余额',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
 _isLoadingBalance
 ? const SizedBox(
 width:24,
 height:24,
 child: CircularProgressIndicator(strokeWidth:2),
 )
 : Text(
 '¥${_currentBalance.toStringAsFixed(2)}',
 style: TextStyle(
 fontSize:24,
 fontWeight: FontWeight.bold,
 color: Theme.of(context).primaryColor,
 ),
 ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showDateRangeDialog,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('筛选'),
                ),
              ],
            ),
          ),

          // 时间范围显示
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                const Text(
                  '至',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 流水记录列表
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无流水记录',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            _getTypeIcon(record.type),
                            color: _getTypeColor(record.type),
                          ),
                          title: Text(record.remark),
                          subtitle: Text(
                            '${record.dateTime.year}-${record.dateTime.month.toString().padLeft(2, '0')}-${record.dateTime.day.toString().padLeft(2, '0')} ${record.dateTime.hour.toString().padLeft(2, '0')}:${record.dateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${record.type == 'consume' ? '-' : '+'}¥${record.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getTypeColor(record.type),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTypeLabel(record.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getTypeColor(record.type),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 分页控件
          if (records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '$_currentPage / $totalPages',
                    style: const TextStyle(fontSize: 14),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() => _currentPage++);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
