import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/product.dart';
import '../../core/providers/product_provider.dart';
import '../../widgets/common/widgets.dart';

class InventoryAlertPage extends StatelessWidget {
  const InventoryAlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('库存预警')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.loading) return const LoadingIndicator();

          final alerts = provider.products
              .where((p) => p.minStock > 0 && p.stock <= p.minStock)
              .toList();

          if (alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              message: '暂无库存预警商品',
            );
          }

          return Column(
            children: [
              _buildSummaryBar(alerts),
              Expanded(child: _buildList(context, alerts)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(List<Product> alerts) {
    final outOfStock = alerts.where((p) => p.stock == 0).length;
    final lowStock = alerts.length - outOfStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '共 ${alerts.length} 个商品库存不足',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (outOfStock > 0)
            Text(
              '缺货 $outOfStock',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          if (outOfStock > 0 && lowStock > 0) const SizedBox(width: 8),
          if (lowStock > 0)
            Text(
              '低库存 $lowStock',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Product> alerts) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: alerts.length,
      itemBuilder: (context, index) => _AlertCard(product: alerts[index]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Product product;
  const _AlertCard({required this.product});

  bool get _isOutOfStock => product.stock == 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _isOutOfStock
              ? Colors.red.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          child: Icon(
            _isOutOfStock
                ? Icons.remove_shopping_cart
                : Icons.warning_amber_rounded,
            color: _isOutOfStock ? Colors.red : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.spec != null)
              Text(product.spec!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '库存 ${product.stock}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isOutOfStock ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '最低 ${product.minStock}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '缺 ${product.minStock - product.stock}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
