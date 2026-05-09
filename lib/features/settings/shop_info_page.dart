import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';

class ShopInfoPage extends StatefulWidget {
  const ShopInfoPage({super.key});

  @override
  State<ShopInfoPage> createState() => _ShopInfoPageState();
}

class _ShopInfoPageState extends State<ShopInfoPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _nameCtrl.text = s.shopName;
    _phoneCtrl.text = s.shopPhone;
    _addressCtrl.text = s.shopAddress;
    _bankCtrl.text = s.bankAccount;
    _footerCtrl.text = s.footerText;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bankCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.read<SettingsProvider>();
    await s.setShopName(_nameCtrl.text.trim());
    await s.setShopPhone(_phoneCtrl.text.trim());
    await s.setShopAddress(_addressCtrl.text.trim());
    await s.setBankAccount(_bankCtrl.text.trim());
    await s.setFooterText(_footerCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('店铺信息')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '店铺名称', border: OutlineInputBorder(), hintText: '用于三联单抬头'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '电话', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: '地址', border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 12),
          TextField(controller: _bankCtrl, decoration: const InputDecoration(labelText: '银行账户', border: OutlineInputBorder(), hintText: '农行：6228 4534 7002 3535 717 户名（谢月亮）')),
          const SizedBox(height: 12),
          TextField(controller: _footerCtrl, decoration: const InputDecoration(labelText: '页脚文字', border: OutlineInputBorder(), hintText: '三联单底部温馨提示')),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
    );
  }
}
