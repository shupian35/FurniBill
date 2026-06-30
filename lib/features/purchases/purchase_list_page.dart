import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/models/purchase_order.dart';
import '../../core/providers/purchase_provider.dart';
import '../../widgets/common/widgets.dart';
import 'purchase_create_page.dart';

class PurchaseListPage extends StatelessWidget {
  const PurchaseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
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

  Widget _buildFilterChips(BuildContext context, PurchaseProvider provider) {
    final filters = [
      {'key': '', 'label': '全部'},
      {'key': 'completed', 'label': '已完成'},
      {'key': 'draft', 'label': '待处理'},
    ];
    String currentFilter = '';
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final selected = currentFilter == f['key'];
          return FilterChip(
            label: Text(f['label']!),
            selected: selected,
            onSelected: (_) {
              currentFilter = f['key']!;
            },
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, PurchaseProvider provider) {
    var orders = provider.orders;
    if (provider.loading) return const LoadingIndicator();
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_cart_outlined,
        message: '暂无采购单',
        actionLabel: '新建采购单',
        onAction: () => _navigateToCreate(context),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _PurchaseOrderCard(order: orders[index]);
      },
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PurchaseCreatePage()),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  const _PurchaseOrderCard({required this.order});

  String get _statusLabel {
    switch (order.status) {
      case 'completed':
        return '已完成';
      case 'draft':
        return '待处理';
      case 'cancelled':
        return '已作废';
      default:
        return order.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              context.read<PurchaseProvider>().deleteOrder(order.id!);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              StatusChip(status: _statusLabel),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${order.supplierName ?? "供应商"}  |  ${order.items.length}种 ${order.items.fold(0, (s, i) => s + i.quantity.toInt())}件',
              ),
              Row(
                children: [
                  AmountText(
                    amount: order.totalAmount,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.createTime.toString().substring(0, 16),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ),
    );
  }
}
