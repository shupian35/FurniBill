import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/order_provider.dart';
import '../../widgets/common/widgets.dart';
import '../orders/order_create_page.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator();
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日概览'),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_outline), tooltip: '草稿', onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftListPage()));
          }),
          IconButton(icon: const Icon(Icons.bar_chart), tooltip: '统计', onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsPage()));
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 快速开单
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderCreatePage()));
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Icon(Icons.add_circle, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('新建销售单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text('快速开单，支持挂单', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7))),
                    ])),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 统计卡片
            Row(children: [
              Expanded(child: _StatCard(label: '开单数', value: _todayStats['order_count']?.toInt().toString() ?? '0', icon: Icons.receipt_long, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: '销售额', value: '¥${(_todayStats['total_sales'] ?? 0).toStringAsFixed(0)}', icon: Icons.trending_up, color: Colors.green)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StatCard(label: '回款', value: '¥${(_todayStats['total_received'] ?? 0).toStringAsFixed(0)}', icon: Icons.payments, color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: '新增欠款', value: '¥${(_todayStats['total_owing'] ?? 0).toStringAsFixed(0)}', icon: Icons.money_off, color: Colors.red)),
            ]),
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
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}
