import 'package:flutter/material.dart';
import '../../../core/models/product.dart';
import '../../../widgets/common/widgets.dart';

/// 选商品 BottomSheet：搜索 + 列表 + 已加入提示
class ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final Set<int> addedIds;
  final ScrollController scrollCtrl;
  final VoidCallback onAddCustom;

  const ProductPickerSheet({
    super.key,
    required this.products,
    required this.addedIds,
    required this.scrollCtrl,
    required this.onAddCustom,
  });

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    if (_query.isEmpty) return widget.products;
    final q = _query.toLowerCase();
    return widget.products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.spec?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    return Column(
      children: [
        // 顶部 HandleBar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Text('选择商品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onAddCustom,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('临时商品'),
            ),
          ]),
        ),
        // 搜索栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            autofocus: false,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: '搜索商品名称 / 规格',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(icon: Icons.search_off, message: '没有匹配的商品')
              : ListView.separated(
                  controller: widget.scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    final added = widget.addedIds.contains(p.id);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Icon(Icons.chair, color: cs.onPrimaryContainer, size: 18),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(children: [
                            if (p.spec != null && p.spec!.isNotEmpty) ...[
                              Text(p.spec!, style: TextStyle(fontSize: 12, color: cs.outline)),
                              const SizedBox(width: 8),
                            ],
                            AmountText(amount: p.price, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                            if (p.unit != null && p.unit!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text('/${p.unit}', style: TextStyle(fontSize: 12, color: cs.outline)),
                            ],
                          ]),
                        ),
                        trailing: added
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('已加入', style: TextStyle(color: cs.onTertiaryContainer, fontSize: 11)),
                              )
                            : Icon(Icons.add_circle, color: cs.primary),
                        onTap: () => Navigator.pop(context, p),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
