import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../core/models/customer.dart';
import '../../core/providers/customer_provider.dart';
import '../../widgets/common/widgets.dart';
import 'customer_edit_page.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppSearchBar(
                  hintText: '搜索客户名称/电话/区域',
                  onChanged: provider.setSearch,
                  onClear: () => provider.setSearch(''),
                ),
                if (provider.regions.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.regions.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return FilterChip(
                            label: const Text('全部区域'),
                            selected: provider.regionFilter.isEmpty,
                            onSelected: (_) => provider.setRegionFilter(''),
                          );
                        }
                        final r = provider.regions[index - 1];
                        return FilterChip(
                          label: Text(r),
                          selected: provider.regionFilter == r,
                          onSelected: (_) => provider.setRegionFilter(r),
                        );
                      },
                    ),
                  ),
                Expanded(child: _buildList(context, provider)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToEdit(context),
            tooltip: '添加客户',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, CustomerProvider provider) {
    final customers = provider.filteredCustomers;
    if (provider.loading) return const LoadingIndicator();
    if (customers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outlined,
        message: '暂无客户',
        actionLabel: '添加客户',
        onAction: () => _navigateToEdit(context),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final c = customers[index];
        return _CustomerCard(customer: c);
      },
    );
  }

  void _navigateToEdit(BuildContext context, [Customer? customer]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerEditPage(customer: customer)),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除客户「${customer.name}」吗？\n\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CustomerProvider>().deleteCustomer(customer.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除「${customer.name}」')),
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
    final hasOwing = customer.owing > 0;
    return Slidable(
      key: ValueKey(customer.id),
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
            child: Text(
              customer.name.isNotEmpty ? customer.name[0] : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              StatusChip(status: customer.grade),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(customer.phone),
              if (customer.region != null && customer.region!.isNotEmpty)
                Text(
                  customer.region!,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                ),
              if (hasOwing)
                Text(
                  '欠款 ¥${customer.owing.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomerEditPage(customer: customer)),
            );
          },
        ),
      ),
    );
  }
}
