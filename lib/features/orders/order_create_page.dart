import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/order.dart';
import '../../core/models/customer.dart';
import '../../core/models/product.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/customer_provider.dart';
import '../../widgets/common/widgets.dart';
import '../customers/customer_edit_page.dart';
import '../printing/print_preview_page.dart';
import 'widgets/order_create_discount_card.dart';
import 'widgets/order_create_footer.dart';
import 'widgets/order_create_header.dart';
import 'widgets/order_create_item_list.dart';
import 'widgets/order_create_models.dart';
import 'widgets/order_create_payment_card.dart';
import '../../core/services/order_calculator.dart';

class OrderCreatePage extends StatefulWidget {
  final Order? draft;
  const OrderCreatePage({super.key, this.draft});

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  Customer? _selectedCustomer;
  final List<OrderItemData> _items = [];
  double _orderDiscount = 1.0;
  double _roundOff = 0;
  String _remark = '';
  String _paymentMethod = '现金';
  double _received = 0;
  String? _clerk;
  bool _saving = false;
  final OrderCalculator _calc = const OrderCalculator();

  bool get isDraftEdit => widget.draft != null;

  double get _totalAmount => _calc.totalAmount(_items);
  double get _discountAmount => _calc.discountAmount(_totalAmount, _orderDiscount);
  double get _afterDiscount => _calc.afterDiscount(_totalAmount, _orderDiscount);
  double get _receivable => _calc.receivable(_afterDiscount, _roundOff);
  double get _owing => _calc.owing(_receivable, _received);

  double get _totalQuantity =>
      _items.fold(0.0, (s, i) => s + i.quantity);

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
        _items.add(OrderItemData(
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
                        Navigator.pop(ctx);
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
                        AmountText(amount: p.price),
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
        _items.add(OrderItemData(
          productId: result.id,
          name: result.name,
          specSummary: result.spec,
          unit: result.unit,
          price: result.price,
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
              _items.add(OrderItemData(
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

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
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
      final orderNo = isDraftEdit ? widget.draft!.orderNo : orderProvider.generateOrderNo();
      final items = _items.map((i) => OrderItem(
        productId: i.productId,
        skuId: i.skuId,
        name: i.name,
        specSummary: i.specSummary,
        unit: i.unit,
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
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('开单成功')));
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
        unit: i.unit,
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
          IconButton(icon: const Icon(Icons.bookmark_outline), tooltip: '存草稿', onPressed: _saveDraft),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OrderCreateHeader(customer: _selectedCustomer, onTap: _selectCustomer),
                const SizedBox(height: 12),
                OrderCreateItemList(
                  items: _items,
                  onEditItem: _editItem,
                  onRemoveItem: _removeItem,
                  onAddProduct: _selectProduct,
                ),
                const SizedBox(height: 16),
                OrderCreateDiscountCard(
                  orderDiscount: _orderDiscount,
                  roundOff: _roundOff,
                  afterDiscount: _afterDiscount,
                  remark: _remark,
                  onDiscountChanged: (v) => setState(() => _orderDiscount = v),
                  onRoundOffChanged: (v) => setState(() => _roundOff = v),
                  onRemarkChanged: (v) => _remark = v,
                ),
                const SizedBox(height: 16),
                OrderCreatePaymentCard(
                  paymentMethod: _paymentMethod,
                  received: _received,
                  receivable: _receivable,
                  onPaymentMethodChanged: (v) => setState(() => _paymentMethod = v),
                  onReceivedChanged: (v) => setState(() => _received = v),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          OrderCreateFooter(
            itemCount: _items.length,
            totalQuantity: _totalQuantity,
            receivable: _receivable,
            saving: _saving,
            onSubmit: _completeOrder,
          ),
        ],
      ),
    );
  }
}
