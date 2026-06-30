import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/purchase_order.dart';
import '../../core/models/product.dart';
import '../../core/providers/purchase_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../widgets/common/widgets.dart';

class PurchaseCreatePage extends StatefulWidget {
  const PurchaseCreatePage({super.key});

  @override
  State<PurchaseCreatePage> createState() => _PurchaseCreatePageState();
}

class _PurchaseCreatePageState extends State<PurchaseCreatePage> {
  final _supplierNameCtrl = TextEditingController();
  final _supplierPhoneCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final List<_PurchaseItemData> _items = [];
  double _paidAmount = 0;
  String _paymentMethod = '现金';
  bool _saving = false;

  double get _totalAmount =>
      _items.fold(0, (sum, i) => sum + (i.price * i.quantity));
  double get _owingAmount => _totalAmount - _paidAmount;

  Future<void> _selectProduct() async {
    final provider = context.read<ProductProvider>();
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text(
                      '选择商品',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          _addCustomItem,
                        );
                      },
                      child: const Text('+ 临时商品'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: provider.products.length,
                  itemBuilder: (_, i) {
                    final p = provider.products[i];
                    return ListTile(
                      leading: Icon(
                        Icons.chair,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(p.name),
                      subtitle: Row(
                        children: [
                          if (p.spec != null && p.spec!.isNotEmpty) ...[
                            Text(
                              p.spec!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          AmountText(amount: p.price),
                          if (p.unit != null && p.unit!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '/${p.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => Navigator.pop(ctx, p),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _items.add(
          _PurchaseItemData(
            productId: result.id,
            name: result.name,
            spec: result.spec,
            unit: result.unit,
            price: result.price,
          ),
        );
      });
    }
  }

  void _addCustomItem() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('临时商品'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '品名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: specCtrl,
              decoration: const InputDecoration(
                labelText: '规格（选填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                labelText: '采购单价',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                _items.add(
                  _PurchaseItemData(
                    name: nameCtrl.text.trim(),
                    spec: specCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text) ?? 0,
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _editItem(int index) {
    final item = _items[index];
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final priceCtrl = TextEditingController(text: item.price.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(
                labelText: '数量',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                labelText: '采购单价',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                item.quantity = double.tryParse(qtyCtrl.text) ?? 1;
                item.price = double.tryParse(priceCtrl.text) ?? 0;
              });
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请添加商品')));
      return;
    }
    setState(() => _saving = true);
    try {
      final provider = context.read<PurchaseProvider>();
      final orderNo = provider.generateOrderNo();
      final items = _items
          .map(
            (i) => PurchaseOrderItem(
              productId: i.productId,
              name: i.name,
              spec: i.spec,
              unit: i.unit,
              quantity: i.quantity,
              price: i.price,
            ),
          )
          .toList();

      final order = PurchaseOrder(
        orderNo: orderNo,
        supplierName: _supplierNameCtrl.text.trim().isNotEmpty
            ? _supplierNameCtrl.text.trim()
            : null,
        supplierPhone: _supplierPhoneCtrl.text.trim().isNotEmpty
            ? _supplierPhoneCtrl.text.trim()
            : null,
        items: items,
        totalAmount: _totalAmount,
        paidAmount: _paidAmount,
        owingAmount: _owingAmount,
        status: 'completed',
        remark: _remarkCtrl.text.trim().isNotEmpty
            ? _remarkCtrl.text.trim()
            : null,
        completeTime: DateTime.now(),
      );

      final stockChanges = <int, int>{};
      for (final item in items) {
        if (item.productId != null) {
          stockChanges[item.productId!] = item.quantity.toInt();
        }
      }

      await provider.completeOrder(order, stockChanges);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('采购单已提交')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('提交失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建采购单')),
      body: Column(
        children: [
          Expanded(child: _buildBody(context)),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '供应商信息',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _supplierNameCtrl,
                  decoration: const InputDecoration(
                    labelText: '供应商名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _supplierPhoneCtrl,
                  decoration: const InputDecoration(
                    labelText: '联系电话（选填）',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '商品明细',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((e) {
          final i = e.value;
          final amount = i.price * i.quantity;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                i.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i.spec != null && i.spec!.isNotEmpty)
                    Text(
                      i.spec!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        'x${i.quantity}${i.unit != null && i.unit!.isNotEmpty ? i.unit! : ""}',
                      ),
                      const SizedBox(width: 8),
                      AmountText(
                        amount: i.price,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: AmountText(
                amount: amount,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => _editItem(e.key),
              onLongPress: () {
                setState(() => _items.removeAt(e.key));
              },
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: _selectProduct,
          icon: const Icon(Icons.add),
          label: const Text('添加商品'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '付款信息',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: '付款方式',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '现金', child: Text('现金')),
                    DropdownMenuItem(value: '微信', child: Text('微信')),
                    DropdownMenuItem(value: '支付宝', child: Text('支付宝')),
                    DropdownMenuItem(value: '转账', child: Text('转账')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v ?? '现金'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(
                    text: _paidAmount > 0
                        ? _paidAmount.toString()
                        : _totalAmount.toStringAsFixed(2),
                  ),
                  decoration: const InputDecoration(
                    labelText: '已付金额',
                    border: OutlineInputBorder(),
                    prefixText: '¥',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      setState(() => _paidAmount = double.tryParse(v) ?? 0),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _remarkCtrl,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
                hintText: '采购备注',
              ),
              maxLines: 2,
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '合计',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_items.length} 种 ${_items.fold(0.0, (s, i) => s + i.quantity)} 件',
                      ),
                    ],
                  ),
                  AmountText(
                    amount: _totalAmount,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (_owingAmount > 0)
                    Text(
                      '欠款：¥${_owingAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _saving ? null : _completeOrder,
              style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
              child: Text(
                _saving ? '处理中...' : '确认入库',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseItemData {
  int? productId;
  String name;
  String? spec;
  String? unit;
  double quantity = 1;
  double price;

  _PurchaseItemData({
    this.productId,
    required this.name,
    this.spec,
    this.unit,
    required this.price,
  });
}
