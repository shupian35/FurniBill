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
  final _creditLimitCtrl = TextEditingController();
  final _dueDaysCtrl = TextEditingController();
  String _tier = '普通';
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
      _tier = c.tier;
      _creditLimitCtrl.text = c.creditLimit.toString();
      _dueDaysCtrl.text = c.dueDays.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _creditLimitCtrl.dispose();
    _dueDaysCtrl.dispose();
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
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      tier: _tier,
      creditLimit: double.tryParse(_creditLimitCtrl.text) ?? 0,
      dueDays: int.tryParse(_dueDaysCtrl.text) ?? 0,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
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
              decoration: const InputDecoration(
                labelText: '客户名称 *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty == true ? '请输入客户名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: '电话 *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.trim().isEmpty == true ? '请输入电话' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: '地址',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tier,
              decoration: const InputDecoration(
                labelText: '客户等级',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '普通', child: Text('普通')),
                DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                DropdownMenuItem(value: '代理', child: Text('代理')),
                DropdownMenuItem(value: '批发商', child: Text('批发商')),
              ],
              onChanged: (v) => setState(() => _tier = v ?? '普通'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _creditLimitCtrl,
                    decoration: const InputDecoration(
                      labelText: '信用额度',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dueDaysCtrl,
                    decoration: const InputDecoration(
                      labelText: '账期天数',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
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
