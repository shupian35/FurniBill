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
        return SafeArea(
          child: Column(
            children: [
              _buildFilterChips(context, provider),
              Expanded(child: _buildList(context, provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, OrderProvider provider) {
    final filters = [
      {'key': '', 'label': '全部'},
      {'key': 'paid', 'label': '已结清'},
      {'key': 'partial', 'label': '部分付款'},
      {'key': 'unpaid', 'label': '未付'},
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final selected = provider.statusFilter == f['key'];
          return FilterChip(
            label: Text(f['label']!),
            selected: selected,
            onSelected: (_) => provider.setStatusFilter(f['key']!),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, OrderProvider provider) {
    final orders = provider.filteredOrders;
    if (provider.loading) return const LoadingIndicator();
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: '暂无订单',
        actionLabel: '新建销售单',
        onAction: () => _navigateToCreate(context),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _OrderCard(order: orders[index]);
      },
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
    return '未付';
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              context.read<OrderProvider>().cancelOrder(order.id!);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.cancel_outlined,
            label: '作废',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Row(
            children: [
              Expanded(child: Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              StatusChip(status: _paymentStatus),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${order.customerName ?? "客户"}  |  ${order.items.length}种 ${order.itemCount}件'),
              Row(children: [
                AmountText(amount: order.receivable, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(width: 8),
                Text(
                  order.createTime.toString().substring(0, 16),
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                ),
              ]),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id!)));
          },
        ),
      ),
    );
  }
}
