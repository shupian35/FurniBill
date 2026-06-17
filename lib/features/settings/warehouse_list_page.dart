import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../core/providers/warehouse_provider.dart';
import '../../core/models/warehouse.dart';
import '../../widgets/common/widgets.dart';
import 'warehouse_edit_page.dart';

class WarehouseListPage extends StatelessWidget {
  const WarehouseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('仓库管理')),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, _) {
          if (provider.loading) return const LoadingIndicator();
          final warehouses = provider.warehouses;
          if (warehouses.isEmpty) {
            return EmptyState(
              icon: Icons.warehouse_outlined,
              message: '暂无仓库',
              actionLabel: '添加仓库',
              onAction: () => _navigateToEdit(context),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: warehouses.length,
            itemBuilder: (context, index) {
              return _WarehouseCard(warehouse: warehouses[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(context),
        tooltip: '添加仓库',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, [Warehouse? warehouse]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WarehouseEditPage(warehouse: warehouse),
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  const _WarehouseCard({required this.warehouse});

  void _confirmDelete(BuildContext context) {
    if (warehouse.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('默认仓库不能删除')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除仓库「${warehouse.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<WarehouseProvider>().deleteWarehouse(warehouse.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除「${warehouse.name}」')),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(warehouse.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(Icons.warehouse, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          title: Row(children: [
            Text(warehouse.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (warehouse.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('默认', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
              ),
            ],
          ]),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warehouse.address != null && warehouse.address!.isNotEmpty)
                Text(warehouse.address!, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
              if (warehouse.phone != null && warehouse.phone!.isNotEmpty)
                Text(warehouse.phone!, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WarehouseEditPage(warehouse: warehouse),
              ),
            );
          },
        ),
      ),
    );
  }
}
