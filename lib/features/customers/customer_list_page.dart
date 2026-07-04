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
    final cs = Theme.of(context).colorScheme;
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: provider.setSearch,
                    decoration: InputDecoration(
                      hintText: '搜索名称 / 电话 / 地址',
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
                Expanded(child: _buildList(context, provider)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToEdit(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('客户'),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, CustomerProvider provider) {
    final customers = provider.filteredCustomers;
    if (provider.loading) return const LoadingIndicator();
    if (customers.isEmpty) {
      final hasFilter = provider.searchQuery.isNotEmpty;
      return EmptyState(
        icon: hasFilter ? Icons.search_off : Icons.people_outline,
        message: hasFilter ? '没有匹配的客户' : '暂无客户',
        actionLabel: hasFilter ? null : '添加客户',
        onAction: hasFilter ? null : () => _navigateToEdit(context),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await provider.init();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          return _CustomerCard(customer: customers[index]);
        },
      ),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await ConfirmDialog.show(
      context,
      title: '删除客户',
      message: '确定删除「${customer.name}」？\n此操作不可撤销。',
      confirmLabel: '删除',
    );
    if (ok == true && context.mounted) {
      await context.read<CustomerProvider>().deleteCustomer(customer.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除「${customer.name}」')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = customer.name.isNotEmpty ? customer.name[0] : '?';
    return Slidable(
      key: ValueKey('customer_${customer.id}'),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => _navigateToEdit(context, customer),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            icon: Icons.edit_outlined,
            label: '编辑',
            borderRadius: BorderRadius.circular(12),
          ),
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
            backgroundColor: cs.primaryContainer,
            child: Text(
              initial,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(Icons.phone, size: 12, color: cs.outline),
                const SizedBox(width: 4),
                Text(customer.phone, style: TextStyle(color: cs.outline, fontSize: 12)),
              ]),
              if (customer.address != null && customer.address!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(children: [
                    Icon(Icons.location_on_outlined, size: 12, color: cs.outline),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.address!,
                        style: TextStyle(color: cs.outline, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: cs.outline),
          onTap: () => _navigateToEdit(context, customer),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Customer? customer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerEditPage(customer: customer)),
    );
  }
}
