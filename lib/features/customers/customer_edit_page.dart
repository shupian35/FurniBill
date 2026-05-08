import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/customer.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/constants/app_constants.dart';

class CustomerEditPage extends StatefulWidget {
  final Customer? customer;
  const CustomerEditPage({super.key, this.customer});

  @override
  State<CustomerEditPage> createState() => _CustomerEditPageState();
}

class _CustomerEditPageState extends State<CustomerEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  String _grade = '普通';
  double _discount = 1.0;
  double? _creditLimit;
  bool _saving = false;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      final c = widget.customer!;
      _nameCtrl.text = c.name;
      _companyCtrl.text = c.companyName ?? '';
      _phoneCtrl.text = c.phone;
      _regionCtrl.text = c.region ?? '';
      _addressCtrl.text = c.address ?? '';
      _remarkCtrl.text = c.remark ?? '';
      _grade = c.grade;
      _discount = c.discount;
      _creditLimit = c.creditLimit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _regionCtrl.dispose();
    _addressCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<CustomerProvider>();
    final customer = Customer(
      id: widget.customer?.id,
      name: _nameCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      grade: _grade,
      discount: _discount,
      creditLimit: _creditLimit,
      remark: _remarkCtrl.text.trim(),
      owing: widget.customer?.owing ?? 0,
    );
    if (isEdit) {
      await provider.updateCustomer(customer);
    } else {
      await provider.addCustomer(customer);
    }
    if (mounted) Navigator.pop(context, true);
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
              decoration: const InputDecoration(labelText: '店主姓名 *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty == true ? '请输入姓名' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _companyCtrl, decoration: const InputDecoration(labelText: '公司名称', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: '电话 *', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.trim().isEmpty == true ? '请输入电话' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _regionCtrl, decoration: const InputDecoration(labelText: '区域', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: '地址', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 16),
            // 客户等级
            DropdownButtonFormField<String>(
              value: _grade,
              decoration: const InputDecoration(labelText: '客户等级', border: OutlineInputBorder()),
              items: AppConstants.customerGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _grade = v;
                    _discount = AppConstants.gradeDiscounts[v] ?? 1.0;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('默认折扣'),
              trailing: Text('${(_discount * 100).toStringAsFixed(0)}%'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: TextEditingController(text: _creditLimit?.toString() ?? ''),
              decoration: const InputDecoration(labelText: '欠款限额（可选）', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => _creditLimit = double.tryParse(v),
            ),
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
}
