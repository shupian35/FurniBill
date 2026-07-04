import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/models/order.dart';
import '../../core/providers/order_provider.dart';
import '../../widgets/common/widgets.dart';
import 'order_create_page.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatelessWidget {
  const OrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildSearchAndFilter(context, provider),
                Expanded(child: _buildList(context, provider)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToCreate(context),
            icon: const Icon(Icons.add),
            label: const Text('开单'),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, OrderProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: provider.setSearch,
            decoration: InputDecoration(
              hintText: '搜索单号 / 客户',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: provider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => provider.setSearch(''),
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              _filterChip(context, provider, '', '全部', Icons.list_alt),
              const SizedBox(width: 8),
              _filterChip(context, provider, 'paid', '已结清', Icons.check_circle_outline),
              const SizedBox(width: 8),
              _filterChip(context, provider, 'partial', '部分付款', Icons.payments_outlined),
              const SizedBox(width: 8),
              _filterChip(context, provider, 'unpaid', '未付款', Icons.error_outline),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(BuildContext context, OrderProvider provider, String key, String label, IconData icon) {
    final selected = provider.statusFilter == key;
    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: selected,
      onSelected: (_) => provider.setStatusFilter(key),
    );
  }

  Widget _buildList(BuildContext context, OrderProvider provider) {
    final orders = provider.filteredOrders;
    if (provider.loading) return const LoadingIndicator();
    if (orders.isEmpty) {
      final hasFilter = provider.searchQuery.isNotEmpty || provider.statusFilter.isNotEmpty;
      return EmptyState(
        icon: hasFilter ? Icons.search_off : Icons.receipt_long_outlined,
        message: hasFilter ? '没有匹配的订单' : '暂无订单',
        actionLabel: hasFilter ? null : '新建销售单',
        onAction: hasFilter ? null : () => _navigateToCreate(context),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await provider.refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _OrderCard(order: orders[index]);
        },
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderCreatePage()),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  String get _paymentStatus {
    if (order.owing <= 0) return '已结清';
    if (order.received > 0) return '部分付款';
    return '未付款';
  }

  Color _statusColor(BuildContext context) {
    if (order.owing <= 0) return Colors.green;
    if (order.received > 0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(context);
    return Slidable(
      key: ValueKey('order_${order.id}'),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id!)),
              );
            },
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            icon: Icons.visibility_outlined,
            label: '查看',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) async {
              final confirm = await ConfirmDialog.show(
                context,
                title: '作废订单',
                message: '确定作废订单 ${order.orderNo}？此操作不可撤销。',
                confirmLabel: '作废',
              );
              if (confirm == true && context.mounted) {
                await context.read<OrderProvider>().cancelOrder(order.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('订单已作废')),
                  );
                }
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.cancel_outlined,
            label: '作废',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id!)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      order.orderNo,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _paymentStatus,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  order.customerName ?? '散客',
                  style: TextStyle(color: cs.onSurface, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Text(
                    '${order.items.length}单 / ${order.itemCount}件',
                    style: TextStyle(color: cs.outline, fontSize: 12),
                  ),
                  const Spacer(),
                  AmountText(
                    amount: order.receivable,
                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary, fontSize: 16),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  if (order.owing > 0) ...[
                    Icon(Icons.error_outline, size: 12, color: Colors.red.shade400),
                    const SizedBox(width: 2),
                    Text(
                      '欠 ¥${order.owing.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.red.shade400, fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    order.createTime.toString().substring(0, 16),
                    style: TextStyle(color: cs.outline, fontSize: 11),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
