import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models/order.dart';
import '../../core/providers/order_provider.dart';
import '../../widgets/common/widgets.dart';
import '../orders/order_create_page.dart';
import '../orders/order_detail_page.dart';
import '../orders/draft_list_page.dart';
import '../statistics/statistics_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, double> _todayStats = {};
  List<Map<String, dynamic>> _weeklySales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final orderProvider = context.read<OrderProvider>();
    final results = await Future.wait([
      orderProvider.getTodayStats(),
      orderProvider.getSalesTrend('week'),
    ]);
    setState(() {
      _todayStats = results[0] as Map<String, double>;
      _weeklySales = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  List<Order> _recentOrders(BuildContext context) {
    final all = context.watch<OrderProvider>().orders;
    return all.where((o) => !o.isDraft).take(3).toList();
  }

  int _draftCount(BuildContext context) {
    return context.watch<OrderProvider>().drafts.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator();
    final draftCount = _draftCount(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日概览'),
        actions: [
          _AppBarBadge(
            icon: Icons.bookmark_outline,
            tooltip: '草稿',
            badge: draftCount > 0 ? '$draftCount' : null,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftListPage()));
            },
          ),
          IconButton(icon: const Icon(Icons.bar_chart), tooltip: '统计', onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsPage()));
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // 快速开单
            _QuickCreateCard(),
            const SizedBox(height: 12),
            // 统计卡片
            Row(children: [
              Expanded(child: _StatCard(label: '开单数', value: _todayStats['order_count']?.toInt().toString() ?? '0', icon: Icons.receipt_long, color: Colors.blue)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: '销售额', value: '¥${(_todayStats['total_sales'] ?? 0).toStringAsFixed(0)}', icon: Icons.trending_up, color: Colors.green)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _StatCard(label: '回款', value: '¥${(_todayStats['total_received'] ?? 0).toStringAsFixed(0)}', icon: Icons.payments, color: Colors.orange)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: '新增欠款', value: '¥${(_todayStats['total_owing'] ?? 0).toStringAsFixed(0)}', icon: Icons.money_off, color: Colors.red)),
            ]),
            const SizedBox(height: 16),
            // 草稿入口
            if (draftCount > 0) ...[
              _DraftEntryCard(count: draftCount),
              const SizedBox(height: 16),
            ],
            // 最近订单
            _RecentOrdersCard(orders: _recentOrders(context)),
            const SizedBox(height: 16),
            // 周销售趋势
            if (_weeklySales.isNotEmpty) ...[
              const Text('近7天销售趋势', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _weeklySales.map((s) => (s['amount'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.3,
                    barGroups: _weeklySales.asMap().entries.map((e) {
                      final amount = (e.value['amount'] as num).toDouble();
                      return BarChartGroupData(x: e.key, barRods: [
                        BarChartRodData(toY: amount, color: Theme.of(context).colorScheme.primary, width: 16, borderRadius: BorderRadius.circular(4)),
                      ]);
                    }).toList(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _weeklySales.length) return const SizedBox();
                          final period = _weeklySales[idx]['period'] as String;
                          return Text(period.length >= 5 ? period.substring(5) : period, style: const TextStyle(fontSize: 10));
                        },
                      )),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickCreateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderCreatePage()));
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_circle, size: 28, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('新建销售单', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
              const SizedBox(height: 2),
              Text('快速开单，支持草稿', style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.7), fontSize: 12)),
            ])),
            Icon(Icons.chevron_right, color: cs.onPrimaryContainer),
          ]),
        ),
      ),
    );
  }
}

class _DraftEntryCard extends StatelessWidget {
  final int count;
  const _DraftEntryCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftListPage()));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bookmark_outline, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('草稿订单', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: cs.outline),
          ]),
        ),
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  final List<Order> orders;
  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(children: [
              Text('最近订单', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
              const Spacer(),
            ]),
          ),
          ...orders.map((o) => _RecentOrderRow(order: o)),
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  final Order order;
  const _RecentOrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final owing = order.owing;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id!)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${order.customerName ?? '散客'} · ${order.items.length}单',
                  style: TextStyle(color: cs.outline, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                amount: order.receivable,
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (owing > 0) ...[
                const SizedBox(height: 2),
                Text('欠 ¥${owing.toStringAsFixed(0)}', style: TextStyle(color: Colors.red.shade400, fontSize: 10)),
              ],
            ],
          ),
        ]),
      ),
    );
  }
}

class _AppBarBadge extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final String? badge;
  final VoidCallback onTap;

  const _AppBarBadge({required this.icon, this.tooltip, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onTap),
        if (badge != null)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge!,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}
