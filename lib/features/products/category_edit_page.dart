import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/category.dart';
import '../../core/providers/category_provider.dart';

class CategoryEditPage extends StatefulWidget {
  final Category? category;
  const CategoryEditPage({super.key, this.category});

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  int? _parentId;
  bool _saving = false;

  bool get isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      final c = widget.category!;
      _nameCtrl.text = c.name;
      _sortCtrl.text = c.sortOrder.toString();
      _parentId = c.parentId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<CategoryProvider>();
    final category = Category(
      id: widget.category?.id,
      name: _nameCtrl.text.trim(),
      parentId: _parentId,
      sortOrder: int.tryParse(_sortCtrl.text) ?? 0,
    );
    if (isEdit) {
      await provider.updateCategory(category);
    } else {
      await provider.addCategory(category);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final availableParents = categories.where((c) => c.id != widget.category?.id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑分类' : '新建分类')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '分类名称 *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty == true ? '请输入名称' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _parentId,
              decoration: const InputDecoration(labelText: '上级分类', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('无（顶级分类）'),
                ),
                ...availableParents.map((c) => DropdownMenuItem<int?>(
                  value: c.id,
                  child: Text(c.name),
                )),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sortCtrl,
              decoration: const InputDecoration(labelText: '排序', border: OutlineInputBorder(), hintText: '数字越小越靠前'),
              keyboardType: TextInputType.number,
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
