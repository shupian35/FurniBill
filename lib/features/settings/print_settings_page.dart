import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/constants/app_constants.dart';

class PrintSettingsPage extends StatelessWidget {
  const PrintSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打印设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 纸张类型
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '纸张类型',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...AppConstants.paperTypes.entries.map(
                        (e) => RadioListTile<String>(
                          title: Text(e.value),
                          value: e.key,
                          groupValue: settings.paperType,
                          onChanged: (v) => settings.setPaperType(v!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 三联单设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '三联单设置',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      // 三联单开关
                      SwitchListTile(
                        title: const Text('启用三联单'),
                        subtitle: const Text('打印时生成白联、红联、蓝联三份'),
                        value: settings.tripleFormEnabled,
                        onChanged: settings.setTripleFormEnabled,
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (settings.tripleFormEnabled) ...[
                        const Divider(),
                        const SizedBox(height: 8),

                        // 联数选择
                        const Text(
                          '打印联数',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: AppConstants.tripleFormColors
                              .asMap()
                              .entries
                              .map((e) {
                                final index = e.key;
                                final color = e.value;
                                final isSelected = settings.tripleFormCopies
                                    .contains(index);
                                return FilterChip(
                                  label: Text(color),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    final copies = List<int>.from(
                                      settings.tripleFormCopies,
                                    );
                                    if (selected) {
                                      copies.add(index);
                                    } else {
                                      copies.remove(index);
                                    }
                                    settings.setTripleFormCopies(copies);
                                  },
                                );
                              })
                              .toList(),
                        ),
                        const SizedBox(height: 12),

                        // 打印模式
                        const Text(
                          '打印模式',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        RadioListTile<String>(
                          title: const Text('连续打印'),
                          subtitle: const Text('三联打印在同一张纸上'),
                          value: 'continuous',
                          groupValue: settings.tripleFormMode,
                          onChanged: (v) => settings.setTripleFormMode(v!),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<String>(
                          title: const Text('分页打印'),
                          subtitle: const Text('每联单独一页'),
                          value: 'separate',
                          groupValue: settings.tripleFormMode,
                          onChanged: (v) => settings.setTripleFormMode(v!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 三联单说明
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '三联单说明',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '标准三联销售单，用于批发开单场景：',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildColorLegend(context, '白联(存根)', '留底备查'),
                      _buildColorLegend(context, '红联(客户)', '交给客户'),
                      _buildColorLegend(context, '蓝联(记账)', '财务记账'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorLegend(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: _getColor(title)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text(
            '- $description',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Color _getColor(String title) {
    if (title.contains('白')) return Colors.grey;
    if (title.contains('红')) return Colors.red;
    if (title.contains('蓝')) return Colors.blue;
    return Colors.grey;
  }
}
