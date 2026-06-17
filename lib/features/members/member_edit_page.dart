import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/member.dart';
import '../../core/models/customer.dart';
import '../../core/providers/member_provider.dart';
import '../../core/providers/customer_provider.dart';

class MemberEditPage extends StatefulWidget {
  final Member? member;
  const MemberEditPage({super.key, this.member});

  @override
  State<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends State<MemberEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _memberNoCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _level = '普通会员';
  int _points = 0;
  int? _customerId;
  bool _saving = false;

  bool get isEdit => widget.member != null;

  static const _levels = ['普通会员', '银卡会员', '金卡会员', 'VIP会员'];

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      final m = widget.member!;
      _memberNoCtrl.text = m.memberNo;
      _nameCtrl.text = m.name;
      _phoneCtrl.text = m.phone ?? '';
      _level = m.level;
      _points = m.points;
      _customerId = m.customerId;
    }
  }

  @override
  void dispose() {
    _memberNoCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _generateMemberNo() {
    final now = DateTime.now();
    final ts = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = (DateTime.now().microsecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'M$ts$rand';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<MemberProvider>();
    final member = Member(
      id: widget.member?.id,
      customerId: _customerId,
      memberNo: _memberNoCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      points: _points,
      level: _level,
    );
    try {
      if (isEdit) {
        await provider.updateMember(member);
      } else {
        await provider.addMember(member);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }

  void _selectCustomer() {
    final customers = context.read<CustomerProvider>().customers;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择关联客户', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() => _customerId = null);
                      Navigator.pop(ctx);
                    },
                    child: const Text('取消关联'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: customers.isEmpty
                  ? const Center(child: Text('暂无客户'))
                  : ListView.builder(
                      controller: controller,
                      itemCount: customers.length,
                      itemBuilder: (_, index) {
                        final c = customers[index];
                        final selected = c.id == _customerId;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(c.name.isNotEmpty ? c.name[0] : '?'),
                          ),
                          title: Text(c.name),
                          subtitle: Text(c.phone),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() => _customerId = c.id);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;
    final linkedCustomer = _customerId != null
        ? customers.where((c) => c.id == _customerId).toList()
        : <Customer>[];

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑会员' : '添加会员')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 会员编号
            TextFormField(
              controller: _memberNoCtrl,
              decoration: InputDecoration(
                labelText: '会员编号 *',
                border: const OutlineInputBorder(),
                suffixIcon: isEdit
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.auto_fix_high),
                        tooltip: '自动生成',
                        onPressed: () {
                          _memberNoCtrl.text = _generateMemberNo();
                        },
                      ),
              ),
              validator: (v) => v?.trim().isEmpty == true ? '请输入会员编号' : null,
            ),
            const SizedBox(height: 12),

            // 姓名
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '姓名 *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty == true ? '请输入姓名' : null,
            ),
            const SizedBox(height: 12),

            // 电话
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: '电话', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            // 会员等级
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: '会员等级', border: OutlineInputBorder()),
              items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _level = v!),
            ),
            const SizedBox(height: 12),

            // 积分（仅编辑时可修改）
            TextFormField(
              initialValue: '$_points',
              decoration: const InputDecoration(labelText: '积分', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => _points = int.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 12),

            // 关联客户
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('关联客户'),
                subtitle: Text(
                  linkedCustomer.isNotEmpty ? linkedCustomer.first.name : '未关联',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectCustomer,
              ),
            ),
            const SizedBox(height: 24),

            // 保存按钮
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
