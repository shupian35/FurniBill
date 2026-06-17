import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/inventory_check.dart';
import '../../widgets/common/widgets.dart';
import 'inventory_check_page.dart';

class InventoryCheckListPage extends StatefulWidget {
  const InventoryCheckListPage({super.key});

  @override
  State<InventoryCheckListPage> createState() => _InventoryCheckListPageState();
}

class _InventoryCheckListPageState extends State<InventoryCheckListPage> {
  List<InventoryCheck> _checks = [];
  bool _loading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final rows = await db.query('inventory_checks', orderBy: 'create_time DESC');
    _checks = rows.map((r) => InventoryCheck.fromMap(r)).toList();
    setState(() => _loading = false);
  }

  List<InventoryCheck> get _filteredChecks {
    if (_statusFilter.isEmpty) return _checks;
    return _checks.where((c) => c.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('库存盘点'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChecks,
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(child: _buildList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCheck,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': '', 'label': '全部'},
      {'key': 'draft', 'label': '盘点中'},
      {'key': 'completed', 'label': '已完成'},
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final selected = _statusFilter == f['key'];
          return FilterChip(
            label: Text(f['label']!),
            selected: selected,
            onSelected: (_) => setState(() {
              _statusFilter = selected ? '' : f['key']!;
            }),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    final checks = _filteredChecks;
    if (checks.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        message: '暂无盘点记录',
        actionLabel: '新建盘点',
        onAction: _createNewCheck,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: checks.length,
      itemBuilder: (context, index) => _CheckCard(check: checks[index]),
    );
  }

  void _createNewCheck() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const InventoryCheckPage()),
    );
    if (result == true) _loadChecks();
  }
}

class _CheckCard extends StatelessWidget {
  final InventoryCheck check;
  const _CheckCard({required this.check});

  String get _statusLabel {
    switch (check.status) {
      case 'draft':
        return '盘点中';
      case 'completed':
        return '已完成';
      default:
        return check.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: check.status == 'completed'
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          child: Icon(
            check.status == 'completed' ? Icons.check : Icons.edit_note,
            color: check.status == 'completed' ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          check.checkNo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('创建时间：${check.createTime.toString().substring(0, 16)}'),
            if (check.completeTime != null)
              Text('完成时间：${check.completeTime.toString().substring(0, 16)}'),
            if (check.remark != null && check.remark!.isNotEmpty)
              Text('备注：${check.remark}'),
          ],
        ),
        trailing: StatusChip(status: _statusLabel),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InventoryCheckPage(checkId: check.id),
            ),
          );
        },
      ),
    );
  }
}
