import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../widgets/common/widgets.dart';
import 'order_create_models.dart';

/// 单条商品明细行：内联数量步进器 + 滑块删除 + 点击编辑折扣/备注
///
/// 点击 [onTap] 触发"编辑折扣/备注"（数量已内联）
/// 左滑/右滑 [onDelete] 触发删除
class OrderCreateItemRow extends StatelessWidget {
  final OrderItemData item;
  final int index;
  final ValueChanged<int> onDelete;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onTap;

  const OrderCreateItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amount = item.price * item.quantity * item.discount;
    final outline = cs.outline;
    return Slidable(
      key: ValueKey('${item.productId}_${item.skuId}_$index'),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(index),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '删除',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AmountText(
                    amount: amount,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ]),
                if (item.specSummary != null && item.specSummary!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.specSummary!, style: TextStyle(color: outline, fontSize: 12)),
                  ),
                const SizedBox(height: 6),
                Row(children: [
                  // 数量步进器
                  _QtyStepper(
                    value: item.quantity,
                    unit: item.unit,
                    onChanged: (v) => onQuantityChanged(v),
                  ),
                  const SizedBox(width: 12),
                  // 单价
                  Text('¥${item.price.toStringAsFixed(2)}', style: TextStyle(color: outline, fontSize: 12)),
                  if (item.discount < 1.0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(item.discount * 100).toStringAsFixed(0)}折',
                        style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.edit_outlined, size: 14, color: outline),
                  const SizedBox(width: 2),
                  Text('编辑', style: TextStyle(color: outline, fontSize: 11)),
                ]),
                if (item.remark != null && item.remark!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '备注：${item.remark}',
                      style: TextStyle(color: outline, fontSize: 11, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final double value;
  final String? unit;
  final ValueChanged<double> onChanged;

  const _QtyStepper({required this.value, required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          onTap: value > 1 ? () => onChanged(value - 1) : null,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Icon(Icons.remove, size: 16, color: value > 1 ? cs.onSurface : cs.outline),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 32),
          alignment: Alignment.center,
          child: Text(
            '${value.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        InkWell(
          onTap: () => onChanged(value + 1),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Icon(Icons.add, size: 16, color: cs.onSurface),
          ),
        ),
        if (unit != null && unit!.isNotEmpty) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text('/$unit', style: TextStyle(color: cs.outline, fontSize: 12)),
          ),
        ],
      ]),
    );
  }
}
