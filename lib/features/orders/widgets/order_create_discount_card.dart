import 'package:flutter/material.dart';

/// 整单调整卡片：整单折扣 + 抹零 + 整单备注
class OrderCreateDiscountCard extends StatefulWidget {
  final double orderDiscount;
  final double roundOff;
  final double afterDiscount;
  final String remark;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<double> onRoundOffChanged;
  final ValueChanged<String> onRemarkChanged;

  const OrderCreateDiscountCard({
    super.key,
    required this.orderDiscount,
    required this.roundOff,
    required this.afterDiscount,
    required this.remark,
    required this.onDiscountChanged,
    required this.onRoundOffChanged,
    required this.onRemarkChanged,
  });

  @override
  State<OrderCreateDiscountCard> createState() => _OrderCreateDiscountCardState();
}

class _OrderCreateDiscountCardState extends State<OrderCreateDiscountCard> {
  late final TextEditingController _discountCtrl;
  late final TextEditingController _roundOffCtrl;
  late final TextEditingController _remarkCtrl;

  @override
  void initState() {
    super.initState();
    _discountCtrl = TextEditingController(
        text: '${(widget.orderDiscount * 100).toStringAsFixed(0)}');
    _roundOffCtrl = TextEditingController(text: widget.roundOff.toStringAsFixed(2));
    _remarkCtrl = TextEditingController(text: widget.remark);
  }

  @override
  void didUpdateWidget(covariant OrderCreateDiscountCard old) {
    super.didUpdateWidget(old);
    final externalDiscountText = '${(widget.orderDiscount * 100).toStringAsFixed(0)}';
    if (_discountCtrl.text != externalDiscountText) {
      _discountCtrl.text = externalDiscountText;
    }
    final externalRoundOffText = widget.roundOff.toStringAsFixed(2);
    if (_roundOffCtrl.text != externalRoundOffText) {
      _roundOffCtrl.text = externalRoundOffText;
    }
    if (_remarkCtrl.text != widget.remark) {
      _remarkCtrl.text = widget.remark;
    }
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _roundOffCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('整单调整', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            const Text('整单折扣'),
            const Spacer(),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _discountCtrl,
                decoration: const InputDecoration(
                    suffixText: '%', border: OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final d = (double.tryParse(v) ?? 100) / 100;
                  widget.onDiscountChanged(d.clamp(0.1, 1.0));
                },
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Text('抹零'),
            const Spacer(),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _roundOffCtrl,
                decoration: const InputDecoration(
                    prefixText: '¥', border: OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) => widget.onRoundOffChanged(double.tryParse(v) ?? 0),
              ),
            ),
          ]),
          if (widget.roundOff <= 0) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                final frac = widget.afterDiscount - widget.afterDiscount.floorToDouble();
                widget.onRoundOffChanged(frac);
              },
              child: const Text('抹去元以下'),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _remarkCtrl,
            decoration: const InputDecoration(
                labelText: '整单备注',
                border: OutlineInputBorder(),
                hintText: '发货仓库、物流单号等'),
            onChanged: widget.onRemarkChanged,
          ),
        ]),
      ),
    );
  }
}
