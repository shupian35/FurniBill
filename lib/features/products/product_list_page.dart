import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/models/product.dart';
import '../../widgets/common/widgets.dart';
import 'product_edit_page.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppSearchBar(
                  hintText: '搜索商品名称/规格',
                  onChanged: provider.setSearch,
                  onClear: () => provider.setSearch(''),
                ),
                Expanded(child: _buildList(context, provider)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToEdit(context),
            tooltip: '添加商品',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, ProductProvider provider) {
    final products = provider.filteredProducts;
    if (provider.loading) return const LoadingIndicator();
    if (products.isEmpty) {
      return EmptyState(
        icon: Icons.chair_outlined,
        message: '暂无商品',
        actionLabel: '添加商品',
        onAction: () => _navigateToEdit(context),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return _ProductCard(product: p);
      },
    );
  }

  void _navigateToEdit(BuildContext context, [Product? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductEditPage(product: product),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除商品「${product.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除「${product.name}」')),
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
      key: ValueKey(product.id),
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
            child: Icon(Icons.chair, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(children: [
            if (product.spec != null && product.spec!.isNotEmpty) ...[
              Text(product.spec!, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
              const SizedBox(width: 8),
            ],
            AmountText(
              amount: product.price,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            ),
            if (product.unit != null && product.unit!.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text('/${product.unit}', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
            ],
          ]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductEditPage(product: product),
              ),
            );
          },
        ),
      ),
    );
  }
}
