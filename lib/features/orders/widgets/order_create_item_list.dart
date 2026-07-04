import 'package:flutter/material.dart';
import 'order_create_item_row.dart';
import 'order_create_models.dart';

/// 商品明细列表 + 添加商品按钮
class OrderCreateItemList extends StatelessWidget {
  final List<OrderItemData> items;
  final void Function(int index) onEditItem;
  final void Function(int index) onRemoveItem;
  final void Function(int index, double newQty) onQuantityChanged;
  final VoidCallback onAddProduct;

  const OrderCreateItemList({
    super.key,
    required this.items,
    required this.onEditItem,
    required this.onRemoveItem,
    required this.onQuantityChanged,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('商品明细', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(width: 6),
          Text('(${items.length})', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ...List.generate(items.length, (i) => OrderCreateItemRow(
          index: i,
          item: items[i],
          onTap: () => onEditItem(i),
          onDelete: onRemoveItem,
          onQuantityChanged: (v) => onQuantityChanged(i, v),
        )),
        OutlinedButton.icon(
          onPressed: onAddProduct,
          icon: const Icon(Icons.add),
          label: const Text('添加商品'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
