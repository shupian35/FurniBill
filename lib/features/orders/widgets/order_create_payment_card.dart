import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// 收款信息卡片：收款方式 + 实收金额 + 找零提示
class OrderCreatePaymentCard extends StatefulWidget {
  final String paymentMethod;
  final double received;
  final double receivable;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<double> onReceivedChanged;

  const OrderCreatePaymentCard({
    super.key,
    required this.paymentMethod,
    required this.received,
    required this.receivable,
    required this.onPaymentMethodChanged,
    required this.onReceivedChanged,
  });

  @override
  State<OrderCreatePaymentCard> createState() => _OrderCreatePaymentCardState();
}

class _OrderCreatePaymentCardState extends State<OrderCreatePaymentCard> {
  late final TextEditingController _receivedCtrl;

  @override
  void initState() {
    super.initState();
    _receivedCtrl = TextEditingController(
        text: widget.received > 0
            ? widget.received.toString()
            : widget.receivable.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant OrderCreatePaymentCard old) {
    super.didUpdateWidget(old);
    final expected = widget.received > 0
        ? widget.received.toString()
        : widget.receivable.toStringAsFixed(2);
    if (_receivedCtrl.text != expected) {
      _receivedCtrl.text = expected;
    }
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('收款信息', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: widget.paymentMethod,
            decoration: const InputDecoration(
                labelText: '收款方式', border: OutlineInputBorder()),
            items: AppConstants.paymentMethods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => widget.onPaymentMethodChanged(v ?? '现金'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _receivedCtrl,
            decoration: const InputDecoration(
                labelText: '实收金额', border: OutlineInputBorder(), prefixText: '¥'),
            keyboardType: TextInputType.number,
            onChanged: (v) => widget.onReceivedChanged(double.tryParse(v) ?? 0),
          ),
          if (widget.received > widget.receivable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('找零：¥${(widget.received - widget.receivable).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green)),
            ),
        ]),
      ),
    );
  }
}
