import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/customer.dart';
import '../../core/providers/customer_provider.dart';

class CustomerEditPage extends StatefulWidget {
  final Customer? customer;
  const CustomerEditPage({super.key, this.customer});

  @override
  State<CustomerEditPage> createState() => _CustomerEditPageState();
}

class _CustomerEditPageState extends State<CustomerEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      final c = widget.customer!;
      _nameCtrl.text = c.name;
      _phoneCtrl.text = c.phone;
      _addressCtrl.text = c.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<CustomerProvider>();
    final customer = Customer(
      id: widget.customer?.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
    );
    try {
      int? savedId = customer.id;
      if (isEdit) {
        await provider.updateCustomer(customer);
      } else {
        savedId = await provider.addCustomer(customer);
      }
      if (mounted) {
        final saved = isEdit ? customer : provider.getById(savedId!);
        Navigator.pop(context, saved ?? customer);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑客户' : '添加客户')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '客户名称 *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty == true ? '请输入客户名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: '电话 *', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.trim().isEmpty == true ? '请输入电话' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: '地址', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? '保存中...' : '保存')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
