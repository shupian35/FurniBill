import 'package:flutter/material.dart';
import '../../../../widgets/common/widgets.dart';

/// 开单页底部：合计行数/件数 + 应收金额 + 完成按钮
class OrderCreateFooter extends StatelessWidget {
  final int itemCount;
  final double totalQuantity;
  final double receivable;
  final bool saving;
  final VoidCallback onSubmit;

  const OrderCreateFooter({
    super.key,
    required this.itemCount,
    required this.totalQuantity,
    required this.receivable,
    required this.saving,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text('合计', style: TextStyle(color: colorScheme.outline, fontSize: 13)),
                const SizedBox(width: 8),
                Text('$itemCount 单 ${totalQuantity.toStringAsFixed(0)} 件'),
              ]),
              AmountText(
                  amount: receivable,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary)),
            ]),
          ),
          FilledButton(
            onPressed: saving ? null : onSubmit,
            style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
            child: Text(saving ? '处理中...' : '完成开单',
                style: const TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}
