import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/inventory_check.dart';
import '../../core/models/product.dart';
import '../../core/providers/product_provider.dart';
import '../../widgets/common/widgets.dart';

class InventoryCheckPage extends StatefulWidget {
  final int? checkId;
  const InventoryCheckPage({super.key, this.checkId});

  @override
  State<InventoryCheckPage> createState() => _InventoryCheckPageState();
}

class _InventoryCheckPageState extends State<InventoryCheckPage> {
  final _db = DatabaseHelper.instance;
  List<_CheckRow> _rows = [];
  bool _loading = true;
  bool _saving = false;
  String? _remark;
  int? _warehouseId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = context.read<ProductProvider>().products;
    final rows = <_CheckRow>[];
    for (final p in products) {
      int systemStock = p.stock;
      int? actualStock;
      if (widget.checkId != null) {
        final itemRows = await _db.query(
          'inventory_check_items',
          where: 'check_id = ? AND product_id = ?',
          whereArgs: [widget.checkId, p.id],
        );
        if (itemRows.isNotEmpty) {
          actualStock = itemRows.first['actual_stock'] as int?;
        }
      }
      rows.add(_CheckRow(product: p, systemStock: systemStock, actualStock: actualStock));
    }
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  int get _totalDifference {
    int diff = 0;
    for (final r in _rows) {
      if (r.actualStock != null) {
        diff += (r.actualStock! - r.systemStock);
      }
    }
    return diff;
  }

  int get _checkedCount => _rows.where((r) => r.actualStock != null).length;

  Future<void> _saveCheck() async {
    if (_checkedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少盘点一个商品')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now().toIso8601String();
      final checkNo = 'PC${now.substring(0, 10).replaceAll('-', '')}${now.substring(11, 13)}${now.substring(14, 16)}';

      final checkData = {
        'check_no': checkNo,
        'warehouse_id': _warehouseId ?? 1,
        'status': 'completed',
        'remark': _remark,
        'create_time': now,
        'complete_time': now,
      };
      final checkId = await _db.insert('inventory_checks', checkData);

      for (final row in _rows) {
        if (row.actualStock != null) {
          await _db.insert('inventory_check_items', {
            'check_id': checkId,
            'product_id': row.product.id,
            'system_stock': row.systemStock,
            'actual_stock': row.actualStock,
            'difference': row.actualStock! - row.systemStock,
          });
          if (row.actualStock != row.systemStock) {
            final change = row.actualStock! - row.systemStock;
            await context.read<ProductProvider>().updateStock(
              row.product.id!,
              change,
              orderNo: checkNo,
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('盘点完成')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.checkId != null ? '盘点详情' : '新建盘点'),
        actions: [
          if (widget.checkId == null)
            TextButton(
              onPressed: _saving ? null : _saveCheck,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : Column(
              children: [
                _buildSummaryCard(),
                Expanded(child: _buildProductList()),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final diff = _totalDifference;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _SummaryItem(label: '已盘点', value: '$_checkedCount/${_rows.length}'),
            const SizedBox(width: 24),
            _SummaryItem(
              label: '差异数',
              value: diff.toString(),
              color: diff == 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_rows.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        message: '暂无商品',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _rows.length,
      itemBuilder: (context, index) => _ProductCheckRow(
        row: _rows[index],
        onChanged: (val) {
          setState(() {
            _rows[index] = _rows[index].copyWith(actualStock: val);
          });
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _ProductCheckRow extends StatelessWidget {
  final _CheckRow row;
  final ValueChanged<int?> onChanged;

  const _ProductCheckRow({required this.row, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final diff = row.actualStock != null ? row.actualStock! - row.systemStock : 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (row.product.spec != null)
                    Text(row.product.spec!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Text('系统', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline)),
                  Text(row.systemStock.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Text('实际', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline)),
                  SizedBox(
                    width: 60,
                    height: 32,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        hintText: '-',
                      ),
                      controller: TextEditingController(
                        text: row.actualStock?.toString() ?? '',
                      ),
                      onChanged: (val) {
                        final n = int.tryParse(val);
                        onChanged(n);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Text('差异', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline)),
                  Text(
                    row.actualStock != null ? diff.toString() : '-',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: row.actualStock == null
                          ? Colors.grey
                          : diff == 0
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow {
  final Product product;
  final int systemStock;
  final int? actualStock;

  const _CheckRow({required this.product, required this.systemStock, this.actualStock});

  _CheckRow copyWith({int? actualStock}) {
    return _CheckRow(
      product: product,
      systemStock: systemStock,
      actualStock: actualStock ?? this.actualStock,
    );
  }
}
