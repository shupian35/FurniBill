import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/customer.dart';
import '../../core/models/order.dart';
import '../../core/providers/customer_provider.dart';
import '../../widgets/common/widgets.dart';

class ReconciliationPage extends StatefulWidget {
  const ReconciliationPage({super.key});

  @override
  State<ReconciliationPage> createState() => _ReconciliationPageState();
}

class _ReconciliationPageState extends State<ReconciliationPage> {
  final _db = DatabaseHelper.instance;
  List<_CustomerAccount> _accounts = [];
  bool _loading = true;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _loading = true);
    final customers = context.read<CustomerProvider>().customers;
    final accounts = <_CustomerAccount>[];

    for (final c in customers) {
      List<Map<String, dynamic>> orderRows;
      if (_dateRange != null) {
        orderRows = await _db.query(
          'orders',
          where: 'customer_id = ? AND is_draft = 0 AND status != \'cancelled\' AND create_time >= ? AND create_time <= ?',
          whereArgs: [
            c.id,
            _dateRange!.start.toIso8601String(),
            _dateRange!.end.toIso8601String(),
          ],
          orderBy: 'create_time DESC',
        );
      } else {
        orderRows = await _db.query(
          'orders',
          where: 'customer_id = ? AND is_draft = 0 AND status != \'cancelled\'',
          whereArgs: [c.id],
          orderBy: 'create_time DESC',
        );
      }

      final orders = orderRows.map((r) => Order.fromMap(r)).toList();
      final totalReceivable = orders.fold(0.0, (sum, o) => sum + o.receivable);
      final totalReceived = orders.fold(0.0, (sum, o) => sum + o.received);
      final totalOwing = totalReceivable - totalReceived;

      if (orders.isNotEmpty || c.totalOwing > 0) {
        accounts.add(_CustomerAccount(
          customer: c,
          orders: orders,
          totalReceivable: totalReceivable,
          totalReceived: totalReceived,
          totalOwing: totalOwing,
        ));
      }
    }

    accounts.sort((a, b) => b.totalOwing.compareTo(a.totalOwing));
    setState(() {
      _accounts = accounts;
      _loading = false;
    });
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadAccounts();
    }
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
    _loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final totalOwing = _accounts.fold(0.0, (sum, a) => sum + a.totalOwing);
    return Scaffold(
      appBar: AppBar(
        title: const Text('客户对账'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccounts,
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : Column(
              children: [
                _buildDateFilter(),
                _buildSummaryBar(totalOwing),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildDateFilter() {
    final hasRange = _dateRange != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilledButton.tonalIcon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(hasRange
                ? '${_dateRange!.start.toString().substring(0, 10)} ~ ${_dateRange!.end.toString().substring(0, 10)}'
                : '选择日期范围'),
          ),
          if (hasRange) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: _clearDateRange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBar(double totalOwing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          const Text('合计欠款', style: TextStyle(fontSize: 14)),
          const Spacer(),
          AmountText(
            amount: totalOwing,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: totalOwing > 0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_accounts.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        message: '暂无对账数据',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _accounts.length,
      itemBuilder: (context, index) => _CustomerAccountCard(
        account: _accounts[index],
        onTap: () => _showDetail(_accounts[index]),
      ),
    );
  }

  void _showDetail(_CustomerAccount account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _AccountDetailSheet(
          account: account,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _CustomerAccountCard extends StatelessWidget {
  final _CustomerAccount account;
  final VoidCallback onTap;

  const _CustomerAccountCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                account.customer.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            AmountText(
              amount: account.totalOwing,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: account.totalOwing > 0 ? Colors.red : Colors.green,
                fontSize: 14,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text('订单 ${account.orders.length} 笔', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            Text('已付 ¥${account.totalReceived.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            Text('应收 ¥${account.totalReceivable.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AccountDetailSheet extends StatelessWidget {
  final _CustomerAccount account;
  final ScrollController scrollController;

  const _AccountDetailSheet({required this.account, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('电话：${account.customer.phone}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('欠款', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  AmountText(
                    amount: account.totalOwing,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: account.totalOwing > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: account.orders.length,
            itemBuilder: (context, index) {
              final order = account.orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  title: Text(order.orderNo, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    order.createTime.toString().substring(0, 16),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AmountText(amount: order.receivable, style: const TextStyle(fontSize: 14)),
                      if (order.owing > 0)
                        Text('欠 ¥${order.owing.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerAccount {
  final Customer customer;
  final List<Order> orders;
  final double totalReceivable;
  final double totalReceived;
  final double totalOwing;

  const _CustomerAccount({
    required this.customer,
    required this.orders,
    required this.totalReceivable,
    required this.totalReceived,
    required this.totalOwing,
  });
}
