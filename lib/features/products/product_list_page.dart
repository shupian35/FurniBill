import 'package:flutter/material.dart';
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
        return Column(
          children: [
            AppSearchBar(
              hintText: '搜索商品名称/货号',
              onChanged: provider.setSearch,
              onClear: () => provider.setSearch(''),
            ),
            _buildCategoryChips(context, provider),
            Expanded(child: _buildList(context, provider)),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips(BuildContext context, ProductProvider provider) {
    final cats = provider.categories;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = provider.categoryFilter == 0;
            return FilterChip(
              label: const Text('全部'),
              selected: selected,
              onSelected: (_) => provider.setCategoryFilter(0),
            );
          }
          final cat = cats[index - 1];
          final selected = provider.categoryFilter == cat['id'];
          return FilterChip(
            label: Text(cat['name'] as String),
            selected: selected,
            onSelected: (_) => provider.setCategoryFilter(cat['id'] as int),
          );
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stockAlert > 0 && product.stock <= product.stockAlert;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: product.imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(product.imagePath!, fit: BoxFit.cover),
                )
              : Icon(Icons.chair, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('货号: ${product.code}'),
            Row(
              children: [
                AmountText(amount: product.wholesalePrice,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                if (lowStock)
                  const StatusChip(status: '库存不足'),
              ],
            ),
          ],
        ),
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
    );
  }
}
