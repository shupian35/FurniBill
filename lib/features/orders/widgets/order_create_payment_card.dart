import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';

/// 收款信息卡片：收款方式 + 快捷金额按钮 + 实收金额 + 找零提示
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
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _receivedCtrl = TextEditingController(
        text: widget.received > 0
            ? _fmt(widget.received)
            : _fmt(widget.receivable));
  }

  @override
  void didUpdateWidget(covariant OrderCreatePaymentCard old) {
    super.didUpdateWidget(old);
    // 实收金额由外部按钮同步时，把 controller 也更新（避免光标跳动）
    if (!_focusNode.hasFocus) {
      final expected = widget.received > 0
          ? _fmt(widget.received)
          : _fmt(widget.receivable);
      if (_receivedCtrl.text != expected) {
        _receivedCtrl.text = expected;
      }
    }
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static String _fmt(double v) => v.toStringAsFixed(2);

  /// 一键金额：根据应收自动算
  void _quickFill(String mode) {
    final r = widget.receivable;
    if (r <= 0) return;
    double v;
    switch (mode) {
      case 'full':
        v = r;
        break;
      case 'round':
        // 抹零到 10 元：100.3 -> 100
        v = (r / 10).floor() * 10.0;
        if (v < r) v += 10;
        break;
      case 'hundred':
        // 取整到 100：123 -> 200
        v = ((r / 100).ceil() * 100).toDouble();
        break;
      case 'clear':
        v = 0;
        break;
      default:
        return;
    }
    _receivedCtrl.text = _fmt(v);
    widget.onReceivedChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final change = widget.received - widget.receivable;
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
          const SizedBox(height: 12),
          TextField(
            controller: _receivedCtrl,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: '实收金额',
              border: const OutlineInputBorder(),
              prefixText: '¥ ',
              suffixIcon: widget.receivable > 0 && widget.received != widget.receivable
                  ? IconButton(
                      icon: const Icon(Icons.flash_on, color: Colors.amber, size: 20),
                      tooltip: '一键应收',
                      onPressed: () => _quickFill('full'),
                    )
                  : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (v) => widget.onReceivedChanged(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 8),
          // 快捷金额按钮
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _QuickButton(
                label: '应收',
                onTap: () => _quickFill('full'),
                emphasized: true,
              ),
              const SizedBox(width: 8),
              _QuickButton(label: '抹零', onTap: () => _quickFill('round')),
              const SizedBox(width: 8),
              _QuickButton(label: '凑整100', onTap: () => _quickFill('hundred')),
              const SizedBox(width: 8),
              _QuickButton(label: '清零', onTap: () => _quickFill('clear')),
            ]),
          ),
          if (change.abs() > 0.01)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                Icon(
                  change > 0 ? Icons.savings_outlined : Icons.warning_amber_rounded,
                  size: 18,
                  color: change > 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  change > 0
                      ? '找零 ¥${_fmt(change)}'
                      : '尚欠 ¥${_fmt(-change)}',
                  style: TextStyle(
                    color: change > 0 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          if (widget.receivable <= 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('请先添加商品', style: TextStyle(color: cs.outline, fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
  const _QuickButton({required this.label, required this.onTap, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (emphasized) {
      return FilledButton.tonalIcon(
        onPressed: onTap,
        icon: const Icon(Icons.flash_on, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
