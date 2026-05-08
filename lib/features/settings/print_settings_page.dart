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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('纸张类型', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...AppConstants.paperTypes.entries.map((e) => RadioListTile<String>(
                      title: Text(e.value),
                      value: e.key,
                      groupValue: settings.paperType,
                      onChanged: (v) => settings.setPaperType(v!),
                    )),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              // 三联单联数提示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('三联单说明', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('标准三联销售单，一页 A4 纸打印三联，通过分隔线区分。', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                    const SizedBox(height: 4),
                    Text('白联(存根) · 红联(客户) · 蓝联(记账)', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
