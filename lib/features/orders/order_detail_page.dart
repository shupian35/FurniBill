import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/order.dart';
import '../../core/models/payment.dart';
import '../../core/providers/order_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/widgets.dart';
import '../../features/printing/print_preview_page.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  List<Payment> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final orderProvider = context.read<OrderProvider>();
    await orderProvider.refresh();
    final orders = orderProvider.orders;
    _order = orders.firstWhere((o) => o.id == widget.orderId, orElse: () => orders.first);
    _payments = await orderProvider.getPayments(widget.orderId);
    setState(() => _loading = false);
  }

  // _paymentStatus removed as unused

  Future<void> _addPayment() async {
    if (_order == null) return;
    final amountCtrl = TextEditingController();
    final methodCtrl = TextEditingController(text: _order!.paymentMethod ?? '现金');
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('追加收款'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: '金额', border: OutlineInputBorder(), prefixText: '¥'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: methodCtrl.text,
            decoration: const InputDecoration(labelText: '方式', border: OutlineInputBorder()),
            items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => methodCtrl.text = v ?? '现金',
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () {
            Navigator.pop(ctx, {'amount': amountCtrl.text, 'method': methodCtrl.text});
          }, child: const Text('确认收款')),
        ],
      ),
    );
    if (result != null) {
      final amount = double.tryParse(result['amount']!) ?? 0;
      if (amount <= 0) return;
      final orderProvider = context.read<OrderProvider>();
      await orderProvider.addPayment(Payment(
        orderId: _order!.id!,
        customerId: _order!.customerId,
        amount: amount,
        method: result['method']!,
      ));
      final newReceived = _order!.received + amount;
      final newOwing = _order!.receivable - newReceived;
      await orderProvider.updateOrder(Order(
        id: _order!.id,
        orderNo: _order!.orderNo,
        customerId: _order!.customerId,
        customerName: _order!.customerName,
        items: _order!.items,
        totalAmount: _order!.totalAmount,
        orderDiscount: _order!.orderDiscount,
        discountAmount: _order!.discountAmount,
        roundOff: _order!.roundOff,
        receivable: _order!.receivable,
        received: newReceived,
        owing: newOwing,
        status: _order!.status,
        isDraft: false,
      ));
      await _loadOrder();
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: '作废订单',
      message: '订单作废后状态变为"已作废"，不可撤销。',
      confirmLabel: '作废',
    );
    if (confirmed == true && mounted) {
      await context.read<OrderProvider>().cancelOrder(_order!.id!);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('订单已作废')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingIndicator());
    if (_order == null) return const Scaffold(body: EmptyState(message: '订单不存在'));

    final order = _order!;
    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNo),
        actions: [
          IconButton(icon: const Icon(Icons.print), tooltip: '补打三联单', onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PrintPreviewPage(order: order)));
          }),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 客户信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('客户信息', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(order.customerName ?? '未知', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // 商品明细
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('商品明细', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (item.specSummary != null && item.specSummary!.isNotEmpty)
                        Text(item.specSummary!, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
                    ])),
                    Text('x${item.quantity}'),
                    const SizedBox(width: 16),
                    AmountText(amount: item.amount),
                  ]),
                )),
                const Divider(),
                _buildAmountRow('商品总额', order.totalAmount),
                if (order.orderDiscount < 1.0)
                  _buildAmountRow('整单折扣 -${((1 - order.orderDiscount) * 100).toStringAsFixed(0)}%', -order.discountAmount),
                if (order.roundOff > 0)
                  _buildAmountRow('抹零', -order.roundOff),
                const Divider(),
                _buildAmountRow('应收合计', order.receivable, bold: true),
                _buildAmountRow('已收', order.received),
                if (order.owing > 0)
                  _buildAmountRow('欠款', order.owing, color: Colors.red),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // 操作
          if (order.owing > 0 && order.status != 'cancelled')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                onPressed: _addPayment,
                icon: const Icon(Icons.payment),
                label: const Text('追加收款'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ),
          if (order.status != 'cancelled')
            OutlinedButton.icon(
              onPressed: _cancelOrder,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('作废订单'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Colors.red,
              ),
            ),
          const SizedBox(height: 16),
          // 收款记录
          if (_payments.isNotEmpty) ...[
            Text('收款记录', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._payments.map((p) => Card(
              child: ListTile(
                title: Text(p.method),
                subtitle: Text(p.createTime.toString().substring(0, 16)),
                trailing: AmountText(amount: p.amount, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text('¥${amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
      ]),
    );
  }
}
