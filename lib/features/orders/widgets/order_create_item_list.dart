import 'package:flutter/material.dart';
import 'order_create_item_row.dart';
import 'order_create_models.dart';

/// 商品明细列表 + 添加商品按钮
class OrderCreateItemList extends StatelessWidget {
  final List<OrderItemData> items;
  final void Function(int index) onEditItem;
  final void Function(int index) onRemoveItem;
  final VoidCallback onAddProduct;

  const OrderCreateItemList({
    super.key,
    required this.items,
    required this.onEditItem,
    required this.onRemoveItem,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('商品明细', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        ...List.generate(items.length, (i) => OrderCreateItemRow(
          key: ValueKey('${items[i].productId}_${items[i].skuId}_$i'),
          item: items[i],
          onTap: () => onEditItem(i),
          onLongPress: () => onRemoveItem(i),
        )),
        OutlinedButton.icon(
          onPressed: onAddProduct,
          icon: const Icon(Icons.add),
          label: const Text('添加商品'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        ),
      ],
    );
  }
}
