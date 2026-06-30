import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/warehouse.dart';
import '../../core/providers/warehouse_provider.dart';

class WarehouseEditPage extends StatefulWidget {
  final Warehouse? warehouse;
  const WarehouseEditPage({super.key, this.warehouse});

  @override
  State<WarehouseEditPage> createState() => _WarehouseEditPageState();
}

class _WarehouseEditPageState extends State<WarehouseEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isDefault = false;
  bool _saving = false;

  bool get isEdit => widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      final w = widget.warehouse!;
      _nameCtrl.text = w.name;
      _addressCtrl.text = w.address ?? '';
      _phoneCtrl.text = w.phone ?? '';
      _isDefault = w.isDefault;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<WarehouseProvider>();
    final warehouse = Warehouse(
      id: widget.warehouse?.id,
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      isDefault: _isDefault,
    );
    if (isEdit) {
      await provider.updateWarehouse(warehouse);
    } else {
      await provider.addWarehouse(warehouse);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑仓库' : '新建仓库')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '仓库名称 *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty == true ? '请输入名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: '地址',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: '联系电话',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('设为默认仓库'),
              subtitle: const Text('开单时默认选择此仓库'),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中...' : '保存'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
