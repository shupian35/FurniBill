import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/product.dart';
import '../../core/providers/product_provider.dart';

class ProductEditPage extends StatefulWidget {
  final Product? product;
  const ProductEditPage({super.key, this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  bool _saving = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _specCtrl.text = p.spec ?? '';
      _unitCtrl.text = p.unit ?? '';
      _priceCtrl.text = p.price.toString();
      _stockCtrl.text = p.stock.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<ProductProvider>();
    final product = Product(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      spec: _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
      unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
    );
    if (isEdit) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑商品' : '新建商品')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '商品名称 *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty == true ? '请输入名称' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(flex: 3, child: TextFormField(controller: _specCtrl, decoration: const InputDecoration(labelText: '规格', border: OutlineInputBorder(), hintText: '如 1.8m×2.0m'))),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: TextFormField(controller: _unitCtrl, decoration: const InputDecoration(labelText: '单位', border: OutlineInputBorder(), hintText: '件'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _priceCtrl, decoration: const InputDecoration(labelText: '单价 *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v?.trim().isEmpty == true ? '必填' : null)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _stockCtrl, decoration: const InputDecoration(labelText: '库存数量', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? '保存中...' : '保存')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
