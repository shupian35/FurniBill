import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/product.dart';
import '../../core/models/sku.dart';
import '../../core/providers/product_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/widgets.dart';

class ProductEditPage extends StatefulWidget {
  final Product? product;
  const ProductEditPage({super.key, this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _wholesalePriceCtrl = TextEditingController();
  final _retailPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _stockAlertCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  int _categoryId = 0;
  String? _imagePath;
  bool _skuEnabled = false;
  List<ProductAttribute> _attributes = [];
  List<Sku> _skus = [];
  bool _saving = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _codeCtrl.text = p.code;
      _specCtrl.text = p.spec ?? '';
      _unitCtrl.text = p.unit ?? '';
      _wholesalePriceCtrl.text = p.wholesalePrice.toString();
      _retailPriceCtrl.text = p.retailPrice?.toString() ?? '';
      _costPriceCtrl.text = p.costPrice?.toString() ?? '';
      _stockCtrl.text = p.stock.toString();
      _stockAlertCtrl.text = p.stockAlert.toString();
      _remarkCtrl.text = p.remark ?? '';
      _categoryId = p.categoryId;
      _imagePath = p.imagePath;
      _skuEnabled = p.skuEnabled;
      _attributes = List.from(p.attributesSchema);
      _loadSkus();
    }
  }

  Future<void> _loadSkus() async {
    if (widget.product?.id != null) {
      final provider = context.read<ProductProvider>();
      _skus = await provider.getSkus(widget.product!.id!);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _specCtrl.dispose();
    _unitCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _retailPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _stockCtrl.dispose();
    _stockAlertCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<ProductProvider>();
    final product = Product(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
      spec: _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
      unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
      categoryId: _categoryId,
      imagePath: _imagePath,
      wholesalePrice: double.tryParse(_wholesalePriceCtrl.text) ?? 0,
      retailPrice: double.tryParse(_retailPriceCtrl.text),
      costPrice: double.tryParse(_costPriceCtrl.text),
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      stockAlert: int.tryParse(_stockAlertCtrl.text) ?? 0,
      skuEnabled: _skuEnabled,
      attributesSchema: _attributes,
      remark: _remarkCtrl.text.trim(),
    );
    if (isEdit) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  void _addAttribute() {
    showDialog(
      context: context,
      builder: (ctx) => _AttributeDialog(
        onAdd: (attr) {
          setState(() => _attributes.add(attr));
        },
      ),
    );
  }

  void _generateSkus() {
    if (_attributes.isEmpty) return;
    final singleSelectAttrs = _attributes.where((a) => a.type == 'single_select' && a.options != null && a.options!.isNotEmpty).toList();
    if (singleSelectAttrs.isEmpty) return;

    List<Map<String, String>> combinations = [{}];
    for (final attr in singleSelectAttrs) {
      final newCombos = <Map<String, String>>[];
      for (final combo in combinations) {
        for (final opt in attr.options!) {
          newCombos.add({...combo, attr.label: opt});
        }
      }
      combinations = newCombos;
    }

    setState(() {
      _skus = combinations.map((combo) {
        final summary = combo.values.join(' / ');
        return Sku(
          productId: widget.product?.id ?? 0,
          attrs: combo,
          attrsSummary: summary,
          price: double.tryParse(_wholesalePriceCtrl.text) ?? 0,
        );
      }).toList();
    });
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
            // 图片
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(_imagePath!, fit: BoxFit.cover))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo, size: 32, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 4),
                          Text('添加图片', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                        ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 基础信息
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '商品名称 *', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty == true ? '请输入名称' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _codeCtrl, decoration: const InputDecoration(labelText: '货号', border: OutlineInputBorder(), hintText: '留空自动生成')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(flex: 3, child: TextFormField(controller: _specCtrl, decoration: const InputDecoration(labelText: '规格', border: OutlineInputBorder(), hintText: '如 1.8m×2.0m'))),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: TextFormField(controller: _unitCtrl, decoration: const InputDecoration(labelText: '单位', border: OutlineInputBorder(), hintText: '件'))),
            ]),
            const SizedBox(height: 12),
            // 分类选择
            _buildCategorySelector(),
            const SizedBox(height: 12),
            // 价格
            Row(children: [
              Expanded(child: TextFormField(controller: _wholesalePriceCtrl, decoration: const InputDecoration(labelText: '批发价 *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v?.trim().isEmpty == true ? '必填' : null)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _retailPriceCtrl, decoration: const InputDecoration(labelText: '零售价', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _costPriceCtrl, decoration: const InputDecoration(labelText: '成本价', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _stockCtrl, decoration: const InputDecoration(labelText: '库存', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _stockAlertCtrl, decoration: const InputDecoration(labelText: '预警值', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            // SKU 开关
            SwitchListTile(title: const Text('启用 SKU 管理'), value: _skuEnabled, onChanged: (v) => setState(() => _skuEnabled = v)),
            // 属性区域
            if (_attributes.isNotEmpty) ...[
              const Text('家具属性', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              ..._attributes.asMap().entries.map((e) => ListTile(
                title: Text(e.value.label),
                subtitle: Text('类型: ${AppConstants.attrTypeLabels[e.value.type] ?? e.value.type}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _attributes.removeAt(e.key)),
                ),
              )),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _addAttribute, icon: const Icon(Icons.add), label: const Text('添加属性')),
            if (_skuEnabled) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _generateSkus,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('自动生成 SKU'),
              ),
              if (_skus.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('SKU 列表', style: TextStyle(fontWeight: FontWeight.w600)),
                ..._skus.map((sku) => ListTile(
                  title: Text(sku.attrsSummary),
                  trailing: AmountText(amount: sku.price),
                )),
              ],
            ],
            const SizedBox(height: 12),
            TextFormField(controller: _remarkCtrl, decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? '保存中...' : '保存')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<int>(
          value: _categoryId,
          decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: 0, child: Text('未分类')),
            ...provider.categories.map((c) => DropdownMenuItem(
              value: c['id'] as int,
              child: Text(c['name'] as String),
            )),
          ],
          onChanged: (v) => setState(() => _categoryId = v ?? 0),
        );
      },
    );
  }
}

class _AttributeDialog extends StatefulWidget {
  final Function(ProductAttribute) onAdd;
  const _AttributeDialog({required this.onAdd});

  @override
  State<_AttributeDialog> createState() => _AttributeDialogState();
}

class _AttributeDialogState extends State<_AttributeDialog> {
  final _labelCtrl = TextEditingController();
  String _type = 'single_select';
  final _optionsCtrl = TextEditingController();
  bool _affectsPrice = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加属性'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _labelCtrl, decoration: const InputDecoration(labelText: '属性名称', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: '类型', border: OutlineInputBorder()),
            items: AppConstants.attrTypeLabels.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _type = v ?? 'single_select'),
          ),
          if (_type == 'single_select' || _type == 'multi_select') ...[
            const SizedBox(height: 12),
            TextField(controller: _optionsCtrl, decoration: const InputDecoration(labelText: '选项（逗号分隔）', border: OutlineInputBorder(), hintText: '红色,蓝色,白色')),
          ],
          SwitchListTile(title: const Text('影响价格'), value: _affectsPrice, onChanged: (v) => setState(() => _affectsPrice = v)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () {
          if (_labelCtrl.text.trim().isEmpty) return;
          final options = _type == 'single_select' || _type == 'multi_select'
              ? _optionsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
              : <String>[];
          widget.onAdd(ProductAttribute(
            key: DateTime.now().millisecondsSinceEpoch.toString(),
            label: _labelCtrl.text.trim(),
            type: _type,
            options: options.isNotEmpty ? options : null,
            affectsPrice: _affectsPrice,
          ));
          Navigator.pop(context);
        }, child: const Text('添加')),
      ],
    );
  }
}
