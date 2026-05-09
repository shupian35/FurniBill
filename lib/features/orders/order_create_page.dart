import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/order.dart';
import '../../core/models/product.dart';
import '../../core/models/customer.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/widgets.dart';
import '../customers/customer_edit_page.dart';
import '../../features/printing/print_preview_page.dart';

class OrderCreatePage extends StatefulWidget {
  final Order? draft;
  const OrderCreatePage({super.key, this.draft});

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  Customer? _selectedCustomer;
  final List<_OrderItemData> _items = [];
  double _orderDiscount = 1.0;
  double _roundOff = 0;
  String _remark = '';
  String _paymentMethod = '现金';
  double _received = 0;
  String? _clerk;
  bool _saving = false;

  bool get isDraftEdit => widget.draft != null;

  @override
  void initState() {
    super.initState();
    if (widget.draft != null) {
      final d = widget.draft!;
      _orderDiscount = d.orderDiscount;
      _remark = d.remark ?? '';
      _paymentMethod = d.paymentMethod ?? '现金';
      _clerk = d.clerk;
      final customerProvider = context.read<CustomerProvider>();
      _selectedCustomer = customerProvider.getById(d.customerId);
      for (final item in d.items) {
        _items.add(_OrderItemData(
          productId: item.productId,
          skuId: item.skuId,
          name: item.name,
          specSummary: item.specSummary,
          quantity: item.quantity,
          price: item.price,
          discount: item.discount,
          remark: item.remark,
        ));
      }
    }
  }

  double get _totalAmount =>
      _items.fold(0, (sum, i) => sum + (i.price * i.quantity * i.discount));
  double get _discountAmount => _totalAmount * (1 - _orderDiscount);
  double get _afterDiscount => _totalAmount * _orderDiscount;
  double get _receivable => _afterDiscount - _roundOff;
  double get _owing => _receivable - _received;

  Future<void> _selectCustomer() async {
    final provider = context.read<CustomerProvider>();
    final result = await showModalBottomSheet<Customer>(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('选择客户', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // 先关闭
                        final c = await Navigator.push<Customer>(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomerEditPage()),
                        );
                        if (c != null && mounted) {
                          setState(() => _selectedCustomer = c);
                        }
                      },
                      child: const Text('+ 新增'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: provider.customers.length,
                  itemBuilder: (_, i) {
                    final c = provider.customers[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(c.name[0])),
                      title: Text(c.name),
                      subtitle: Text(c.phone),
                      onTap: () => Navigator.pop(ctx, c),
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
      setState(() => _selectedCustomer = result);
    }
  }

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  const Text('添加商品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // 等 BottomSheet 关闭动画完成后再弹窗
                      Future.delayed(const Duration(milliseconds: 300), _addCustomItem);
                    },
                    child: const Text('+ 临时商品'),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: provider.products.length,
                  itemBuilder: (_, i) {
                    final p = provider.products[i];
                    return ListTile(
                      leading: Icon(Icons.chair, color: Theme.of(context).colorScheme.primary),
                      title: Text(p.name),
                      subtitle: Row(children: [
                        if (p.spec != null && p.spec!.isNotEmpty) ...[
                          Text(p.spec!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                          const SizedBox(width: 8),
                        ],
                        AmountText(amount: p.wholesalePrice),
                        if (p.unit != null && p.unit!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text('/${p.unit}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                        ],
                      ]),
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
        _items.add(_OrderItemData(
          productId: result.id,
          name: result.name,
          specSummary: result.spec,
          unit: result.unit,
          price: result.wholesalePrice,
        ));
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
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '品名', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: specCtrl, decoration: const InputDecoration(labelText: '规格（选填）', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: '单价', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            setState(() {
              _items.add(_OrderItemData(
                name: nameCtrl.text.trim(),
                specSummary: specCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text) ?? 0,
              ));
            });
            Navigator.pop(ctx);
          }, child: const Text('添加')),
        ],
      ),
    );
  }

  void _editItem(int index) {
    final item = _items[index];
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final priceCtrl = TextEditingController(text: item.price.toString());
    final discCtrl = TextEditingController(text: item.discount.toString());
    final remarkCtrl = TextEditingController(text: item.remark ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: '数量', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: '单价', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: discCtrl, decoration: const InputDecoration(labelText: '折扣 (1=原价)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: remarkCtrl, decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () {
            setState(() {
              item.quantity = double.tryParse(qtyCtrl.text) ?? 1;
              item.price = double.tryParse(priceCtrl.text) ?? 0;
              item.discount = double.tryParse(discCtrl.text) ?? 1;
              item.remark = remarkCtrl.text.trim();
            });
            Navigator.pop(ctx);
          }, child: const Text('确定')),
        ],
      ),
    );
  }

  Future<void> _completeOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择客户')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请添加商品')));
      return;
    }
    setState(() => _saving = true);
    try {
      final orderProvider = context.read<OrderProvider>();
      final productProvider = context.read<ProductProvider>();

      final orderNo = isDraftEdit ? widget.draft!.orderNo : orderProvider.generateOrderNo();
      final items = _items.map((i) => OrderItem(
        productId: i.productId,
        skuId: i.skuId,
        name: i.name,
        specSummary: i.specSummary,
        quantity: i.quantity,
        price: i.price,
        discount: i.discount,
        remark: i.remark,
      )).toList();

      final order = Order(
        id: widget.draft?.id,
        orderNo: orderNo,
        customerId: _selectedCustomer!.id!,
        customerName: _selectedCustomer!.name,
        items: items,
        totalAmount: _totalAmount,
        orderDiscount: _orderDiscount,
        discountAmount: _discountAmount,
        roundOff: _roundOff,
        receivable: _receivable,
        received: _received,
        owing: _owing,
        status: 'completed',
        clerk: _clerk,
        remark: _remark,
        paymentMethod: _paymentMethod,
        isDraft: false,
        completeTime: DateTime.now(),
      );

      if (isDraftEdit) {
        await orderProvider.updateOrder(order);
      } else {
        await orderProvider.saveOrder(order);
      }

      // 扣库存
      for (final item in items) {
        if (item.productId != null) {
          await productProvider.updateStock(item.productId!, item.skuId, -item.quantity.toInt());
        }
      }

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('开单成功')));
        // 弹出到订单列表并打开打印预览
        Navigator.pop(context, true);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PrintPreviewPage(order: order),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开单失败：$e')),
        );
      }
    }
  }

  Future<void> _saveDraft() async {
    if (_items.isEmpty) return;
    setState(() => _saving = true);
    try {
      final orderProvider = context.read<OrderProvider>();
      final orderNo = isDraftEdit ? widget.draft!.orderNo : orderProvider.generateOrderNo();
      final items = _items.map((i) => OrderItem(
        productId: i.productId, skuId: i.skuId,
        name: i.name, specSummary: i.specSummary,
        quantity: i.quantity, price: i.price,
        discount: i.discount, remark: i.remark,
      )).toList();

      final order = Order(
        id: widget.draft?.id,
        orderNo: orderNo,
        customerId: _selectedCustomer?.id ?? 0,
        customerName: _selectedCustomer?.name,
        items: items,
        totalAmount: _totalAmount,
        orderDiscount: _orderDiscount,
        discountAmount: _discountAmount,
        roundOff: _roundOff,
        receivable: _receivable,
        remark: _remark,
        isDraft: true,
        clerk: _clerk,
      );

      if (isDraftEdit) {
        await orderProvider.updateOrder(order);
      } else {
        await orderProvider.saveOrder(order);
      }

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存草稿')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存草稿失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isDraftEdit ? '编辑草稿' : '新建销售单'),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_outline), tooltip: '挂单', onPressed: _saveDraft),
        ],
      ),
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
        // 客户选择
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(_selectedCustomer?.name ?? '选择客户'),
            subtitle: _selectedCustomer != null
                ? Text('${_selectedCustomer!.phone}')
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectCustomer,
          ),
        ),
        const SizedBox(height: 12),
        // 商品列表
        const Text('商品明细', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((e) {
          final i = e.value;
          final amount = i.price * i.quantity * i.discount;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i.specSummary != null && i.specSummary!.isNotEmpty)
                    Text(i.specSummary!, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  Row(children: [
                    Text('x${i.quantity}${i.unit != null && i.unit!.isNotEmpty ? i.unit! : ""}'),
                    const SizedBox(width: 8),
                    AmountText(amount: i.price, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
                    if (i.discount < 1.0) ...[
                      const SizedBox(width: 8),
                      Text('${(i.discount * 100).toStringAsFixed(0)}折', style: const TextStyle(color: Colors.orange, fontSize: 13)),
                    ],
                    if (i.remark != null && i.remark!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(child: Text(i.remark!, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ],
                  ]),
                ],
              ),
              trailing: AmountText(amount: amount, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _editItem(e.key),
              onLongPress: () {
                setState(() => _items.removeAt(e.key));
              },
            ),
          );
        }),
        // 添加商品按钮
        OutlinedButton.icon(
          onPressed: _selectProduct,
          icon: const Icon(Icons.add),
          label: const Text('添加商品'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        ),
        const SizedBox(height: 16),
        // 整单调整
        Card(
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
                    controller: TextEditingController(text: '${(_orderDiscount * 100).toStringAsFixed(0)}'),
                    decoration: const InputDecoration(suffixText: '%', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final d = (double.tryParse(v) ?? 100) / 100;
                      setState(() => _orderDiscount = d.clamp(0.1, 1.0));
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
                    controller: TextEditingController(text: _roundOff.toStringAsFixed(2)),
                    decoration: const InputDecoration(prefixText: '¥', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _roundOff = double.tryParse(v) ?? 0),
                  ),
                ),
              ]),
              if (_roundOff <= 0) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    // 抹去元以下
                    final frac = _afterDiscount - _afterDiscount.floorToDouble();
                    setState(() => _roundOff = frac);
                  },
                  child: const Text('抹去元以下'),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: '整单备注', border: OutlineInputBorder(), hintText: '发货仓库、物流单号等'),
                onChanged: (v) => _remark = v,
                controller: TextEditingController(text: _remark),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        // 收款信息
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('收款信息', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: '收款方式', border: OutlineInputBorder()),
                items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? '现金'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _received > 0 ? _received.toString() : _receivable.toStringAsFixed(2)),
                decoration: const InputDecoration(labelText: '实收金额', border: OutlineInputBorder(), prefixText: '¥'),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _received = double.tryParse(v) ?? 0),
              ),
              if (_received > _receivable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('找零：¥${(_received - _receivable).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green)),
                ),
            ]),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('合计', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
                const SizedBox(width: 8),
                Text('${_items.length} 种 ${_items.fold(0.0, (s, i) => s + i.quantity)} 件'),
              ]),
              AmountText(amount: _receivable, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ]),
          ),
          FilledButton(
            onPressed: _saving ? null : _completeOrder,
            style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
            child: Text(_saving ? '处理中...' : '完成开单', style: const TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}

class _OrderItemData {
  int? productId;
  int? skuId;
  String name;
  String? specSummary;
  String? unit;
  double quantity;
  double price;
  double discount;
  String? remark;

  _OrderItemData({
    this.productId,
    this.skuId,
    required this.name,
    this.specSummary,
    this.unit,
    this.quantity = 1,
    required this.price,
    this.discount = 1.0,
    this.remark,
  });
}
