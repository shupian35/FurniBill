import 'package:flutter/material.dart';
import '../../../../widgets/common/widgets.dart';
import 'order_create_models.dart';

/// 单条商品明细行
///
/// 点击触发 [onTap]（一般是弹窗编辑），长按触发 [onLongPress]（一般是删除）。
class OrderCreateItemRow extends StatelessWidget {
  final OrderItemData item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const OrderCreateItemRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final amount = item.price * item.quantity * item.discount;
    final outline = Theme.of(context).colorScheme.outline;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.specSummary != null && item.specSummary!.isNotEmpty)
              Text(item.specSummary!, style: TextStyle(color: outline)),
            Row(children: [
              Text('x${item.quantity}${item.unit != null && item.unit!.isNotEmpty ? item.unit! : ""}'),
              const SizedBox(width: 8),
              AmountText(amount: item.price, style: TextStyle(color: outline, fontSize: 13)),
              if (item.discount < 1.0) ...[
                const SizedBox(width: 8),
                Text('${(item.discount * 100).toStringAsFixed(0)}折',
                    style: const TextStyle(color: Colors.orange, fontSize: 13)),
              ],
              if (item.remark != null && item.remark!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(child: Text(item.remark!, style: TextStyle(color: outline, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ]),
          ],
        ),
        trailing: AmountText(amount: amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
