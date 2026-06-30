import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/order_provider.dart';
import '../../widgets/common/widgets.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _dailySales = [];
  List<Map<String, dynamic>> _monthlySales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<OrderProvider>();
    final results = await Future.wait([
      provider.getSalesTrend('week'),
      provider.getSalesTrend('month'),
    ]);
    setState(() {
      _dailySales = List<Map<String, dynamic>>.from(results[0]);
      _monthlySales = List<Map<String, dynamic>>.from(results[1]);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('销售统计'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: '日趋势'),
            Tab(text: '月趋势'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildChart(_dailySales, '日'),
                _buildChart(_monthlySales, '月'),
              ],
            ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data, String unit) {
    if (data.isEmpty) return const EmptyState(message: '暂无数据');
    final maxY =
        data
            .map((d) => (d['amount'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b) *
        1.3;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['amount'] as num).toDouble(),
                        color: Theme.of(context).colorScheme.primary,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length)
                          return const SizedBox();
                        return Text(
                          data[idx]['period'].toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '销售额合计: ¥${data.fold<double>(0, (s, d) => s + (d['amount'] as num).toDouble()).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
