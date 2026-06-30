import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';

class PrintTemplatePage extends StatefulWidget {
  const PrintTemplatePage({super.key});

  @override
  State<PrintTemplatePage> createState() => _PrintTemplatePageState();
}

class _PrintTemplatePageState extends State<PrintTemplatePage> {
  String _selectedTemplate = 'default';

  static const _templates = [
    _TemplateInfo(
      id: 'default',
      name: '标准模板',
      description: '完整的销售单格式，包含店铺信息、商品明细、合计金额和页脚',
      icon: Icons.receipt_long,
    ),
    _TemplateInfo(
      id: 'compact',
      name: '紧凑模板',
      description: '简化版格式，适合小票打印，仅保留核心信息',
      icon: Icons.view_compact,
    ),
    _TemplateInfo(
      id: 'detailed',
      name: '详细模板',
      description: '增强版格式，包含备注、签名栏和更多单据信息',
      icon: Icons.article,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _selectedTemplate = settings.printTemplate;
  }

  Future<void> _saveTemplate() async {
    await context.read<SettingsProvider>().setPrintTemplate(_selectedTemplate);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('模板已保存')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打印模板')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final t = _templates[index];
                final selected = t.id == _selectedTemplate;
                return _TemplateCard(
                  template: t,
                  selected: selected,
                  onTap: () => setState(() => _selectedTemplate = t.id),
                );
              },
            ),
          ),

          // 预览区域
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: _buildPreview(context),
          ),
          const SizedBox(height: 16),

          // 保存按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveTemplate,
                child: const Text('保存模板设置'),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final shopName = context.read<SettingsProvider>().shopName.isNotEmpty
        ? context.read<SettingsProvider>().shopName
        : '店铺名称';
    final colorScheme = Theme.of(context).colorScheme;

    switch (_selectedTemplate) {
      case 'compact':
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shopName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Divider(height: 8),
              _previewRow('商品A ×2', '¥100.00'),
              _previewRow('商品B ×1', '¥200.00'),
              const Divider(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '合计',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '¥300.00',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 'detailed':
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '家具销售单',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ),
              const SizedBox(height: 4),
              _previewRow('单号：NO20260617001', '日期：2026-06-17'),
              _previewRow('客户：示例客户', ''),
              const Divider(height: 8),
              _previewRow('商品A ×2', '¥100.00'),
              _previewRow('商品B ×1', '¥200.00'),
              const Divider(height: 8),
              _previewRow('合计金额：¥300.00', ''),
              const SizedBox(height: 4),
              Text(
                '备注：示例备注',
                style: TextStyle(fontSize: 10, color: colorScheme.outline),
              ),
              const Spacer(),
              _previewRow('客户签名：________', '日期：________'),
            ],
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '家具销售单',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ),
              const SizedBox(height: 4),
              _previewRow('单号：NO20260617001', '客户：示例客户'),
              const Divider(height: 8),
              _previewRow('商品A ×2', '¥100.00'),
              _previewRow('商品B ×1', '¥200.00'),
              const Divider(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '合计',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '¥300.00',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _previewRow(String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: const TextStyle(fontSize: 11)),
          if (right.isNotEmpty)
            Text(right, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _TemplateInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const _TemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class _TemplateCard extends StatelessWidget {
  final _TemplateInfo template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: selected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            template.icon,
            color: selected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          template.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : Icon(Icons.radio_button_unchecked, color: colorScheme.outline),
        onTap: onTap,
      ),
    );
  }
}
