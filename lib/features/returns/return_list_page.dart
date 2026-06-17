import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/models/return_order.dart';
import '../../core/providers/return_provider.dart';
import '../../widgets/common/widgets.dart';
import 'return_create_page.dart';

class ReturnListPage extends StatelessWidget {
  const ReturnListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReturnProvider>(
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

  Widget _buildFilterChips(BuildContext context, ReturnProvider provider) {
    final filters = [
      {'key': '', 'label': '全部'},
      {'key': 'sales_return', 'label': '销售退货'},
      {'key': 'purchase_return', 'label': '采购退货'},
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

  Widget _buildList(BuildContext context, ReturnProvider provider) {
    var returns = provider.returns;
    if (provider.loading) return const LoadingIndicator();
    if (returns.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_return_outlined,
        message: '暂无退货单',
        actionLabel: '新建退货单',
        onAction: () => _navigateToCreate(context),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: returns.length,
      itemBuilder: (context, index) {
        return _ReturnOrderCard(returnOrder: returns[index]);
      },
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReturnCreatePage()),
    );
  }
}

class _ReturnOrderCard extends StatelessWidget {
  final ReturnOrder returnOrder;
  const _ReturnOrderCard({required this.returnOrder});

  String get _typeLabel {
    switch (returnOrder.type) {
      case 'sales_return':
        return '销售退货';
      case 'purchase_return':
        return '采购退货';
      default:
        return returnOrder.type;
    }
  }

  String get _statusLabel {
    switch (returnOrder.status) {
      case 'completed':
        return '已完成';
      case 'pending':
        return '待处理';
      case 'cancelled':
        return '已作废';
      default:
        return returnOrder.status;
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
              context.read<ReturnProvider>().deleteReturn(returnOrder.id!);
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
              Expanded(child: Text(returnOrder.orderNo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              StatusChip(status: _statusLabel),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: returnOrder.type == 'sales_return'
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_typeLabel, style: TextStyle(
                    fontSize: 11,
                    color: returnOrder.type == 'sales_return' ? Colors.blue : Colors.orange,
                  )),
                ),
                const SizedBox(width: 8),
                Text(returnOrder.supplierName ?? (returnOrder.customerId != null ? '客户' : '未关联')),
              ]),
              Row(children: [
                AmountText(amount: returnOrder.totalAmount, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(width: 8),
                Text(
                  returnOrder.createTime.toString().substring(0, 16),
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                ),
              ]),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ),
    );
  }
}
